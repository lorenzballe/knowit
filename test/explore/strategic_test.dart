// The strategic Explore's own blocks: the reader's day, the quick games,
// the subjects' levels and more like what was saved — each drawn with its
// data, gone without it, whole on a 375-point phone at 1x and 2x text, and
// doing what a tap on it promises; the record of Sixty seconds kept past the
// day; the page a game opens on; and the streak beside Explore's search.
//
//   flutter test test/explore/strategic_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/core/like_saved_block.dart';
import 'package:astuto/explore/blocks/core/quick_games_block.dart';
import 'package:astuto/explore/blocks/core/shelves.dart';
import 'package:astuto/explore/blocks/core/subject_levels_block.dart';
import 'package:astuto/explore/blocks/core/your_day_block.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/section_page.dart';
import 'package:astuto/widgets/explore/sixty_seconds.dart';

import 'core_harness.dart';

/// Wednesday 11 November 2026, at ten in the morning: a week of Monday 9
/// to Sunday 15.
DateTime _wednesday() => DateTime(2026, 11, 11, 10);

ExploreSection _section(String block, [Map<String, Object?> more = const {}]) =>
    ExploreSection.fromJson({'id': block, 'block': block, ...more});

/// The cards of [subject] (a topic's name), in the bank's order.
List<Pill> _of(String subject) =>
    PillBank.cards.where((p) => p.topic == subject).toList();

/// A card with at least [n] others in its strand, none of them about a place.
Pill _withSiblings(int n) {
  final Map<String, List<Pill>> byStrand = {};
  for (final Pill p in PillBank.cards) {
    if (p.strand.isNotEmpty) byStrand.putIfAbsent(p.strand, () => []).add(p);
  }
  return byStrand.values.firstWhere((cards) => cards.length > n).first;
}

void main() {
  setUpAll(loadFonts);
  setUp(() {
    Served.useForTest(Served());
    // A fresh day of play and of bets: what an earlier test dealt or
    // played is not this one's.
    BetsDay.resetForTest(clock: _wednesday);
  });

  group('your day', () {
    Future<CoreHost> dayHost({String? subject, String language = 'en'}) async {
      final AppState app = await readyApp(const {}, _wednesday);
      app.todayIndex = 3;
      app.streak = 12;
      app.lastCompletionDate = '2026-11-10';
      app.completedDates = ['2026-11-09', '2026-11-10'];
      return CoreHost(app, subject: subject, language: language);
    }

    testWidgets('today read so far, the five as bars, the week from Monday '
        'with the days finished lit, the streak, and a tap goes to Today', (
      tester,
    ) async {
      final CoreHost host = await dayHost();
      await pumpSections(tester, host, [_section('your-day')]);
      expect(find.text('Today: 3 of 5 read · 2 left'), findsOneWidget);
      for (int i = 0; i < 5; i++) {
        expect(
          find.byKey(ValueKey('your-day-bar-$i-${i < 3 ? 'read' : 'unread'}')),
          findsOneWidget,
        );
      }
      // Monday and Tuesday finished; Wednesday is today, open; the rest to
      // come.
      expect(find.byKey(const ValueKey('your-day-1-done')), findsOneWidget);
      expect(find.byKey(const ValueKey('your-day-2-done')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('your-day-3-open-today')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('your-day-7-open')), findsOneWidget);
      expect(find.text('12 days'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('your-day')));
      expect(host.todays, 1);
    });

    testWidgets('the day finished says so, in the reader\'s language', (
      tester,
    ) async {
      final CoreHost host = await dayHost(language: 'it');
      host.app.lastCompletionDate = '2026-11-11';
      host.app.completedDates = [...host.app.completedDates, '2026-11-11'];
      await pumpSections(tester, host, [
        _section('your-day'),
      ], locale: const Locale('it'));
      expect(find.text('Oggi: 5 su 5 lette · tutte lette'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('your-day-3-done-today')),
        findsOneWidget,
      );
      expect(find.text('12 giorni'), findsOneWidget);
    });

    testWidgets('not there while Explore is narrowed to a subject, nor with '
        'no day dealt', (tester) async {
      await pumpSections(tester, await dayHost(subject: 'Space'), [
        _section('your-day'),
      ]);
      expect(find.byKey(const ValueKey('your-day')), findsNothing);

      final CoreHost bare = await dayHost();
      bare.app.todaysDeck = [];
      await pumpSections(tester, bare, [_section('your-day')]);
      expect(find.byKey(const ValueKey('your-day')), findsNothing);
    });

    for (final double text in [1.0, 2.0]) {
      testWidgets('at ${text}x, 375 wide: whole', (tester) async {
        await pumpSections(
          tester,
          await dayHost(language: 'de'),
          [_section('your-day')],
          text: text,
          locale: const Locale('de'),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(DayPanel), findsOneWidget);
      });
    }

    test('the week is Monday to Sunday of today\'s week', () async {
      final AppState app = await readyApp(const {}, _wednesday);
      app.completedDates = ['2026-11-08', '2026-11-09'];
      final week = weekOf(app, DateTime(2026, 11, 11));
      expect([for (final d in week) d.day.day], [9, 10, 11, 12, 13, 14, 15]);
      expect(
        [for (final d in week) d.done],
        [true, false, false, false, false, false, false],
      );
    });
  });

  group('quick games', () {
    testWidgets('four tiles, Sixty seconds with the record to set, and a '
        'tap opens the game on a page of its own', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(tester, host, [
        _section('quick-games', {'title': 'Quick games'}),
      ]);
      for (final String game in [
        'sixty',
        'spot-false',
        'true-false',
        'bets-bigger',
      ]) {
        expect(find.byKey(ValueKey('quick-game-$game')), findsOneWidget);
      }
      expect(find.text('Sixty seconds'), findsOneWidget);
      expect(find.text('Set your record'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('quick-game-sixty')));
      expect(host.pages, hasLength(1));
      expect(host.pages.single.block, 'sixty');
      expect(host.pages.single.id, 'quick-games-sixty');

      await tester.tap(find.byKey(const ValueKey('quick-game-true-false')));
      expect(host.pages.last.block, 'true-false');
      // True or false without the spot under it: that game has a tile.
      expect(host.pages.last.json['spot'], false);
    });

    testWidgets('the record, once there is one, and only the games the '
        'section names, in its order', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await host.app.noteSixtyRound(6);
      await host.app.noteSixtyRound(4);
      expect(host.app.sixtyBest, 6);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('knowit.sixtyBest'), 6);

      await pumpSections(tester, host, [
        _section('quick-games', {
          'games': ['bets-bigger', 'sixty'],
        }),
      ]);
      expect(find.text('Your record 6/8'), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-game-spot-false')), findsNothing);
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('quick-game-bets-bigger')))
            .dx,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('quick-game-sixty'))).dx,
        ),
      );
    });

    testWidgets('a game with nothing to play has no tile, and with none '
        'there is no section', (tester) async {
      // With no cards for its figures, Which is bigger has nothing to
      // compare: no tile, and alone it leaves no section. Sixty seconds,
      // dealt from the day's mix, still has its tile.
      final _NoCards host = _NoCards(await readyApp());
      await pumpSections(tester, host, [
        _section('quick-games', {'title': 'Quick games'}),
      ]);
      expect(find.byKey(const ValueKey('quick-game-sixty')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('quick-game-bets-bigger')),
        findsNothing,
      );
      await pumpSections(tester, host, [
        _section('quick-games', {
          'title': 'Quick games',
          'games': ['bets-bigger'],
        }),
      ]);
      expect(find.text('Quick games'), findsNothing);
      expect(find.byType(GameTile), findsNothing);
    });

    for (final double text in [1.0, 2.0]) {
      testWidgets('at ${text}x, 375 wide: whole', (tester) async {
        final CoreHost host = CoreHost(await readyApp(), language: 'de');
        await host.app.noteSixtyRound(7);
        await pumpSections(
          tester,
          host,
          [
            _section('quick-games', {'title': 'Schnelle Spiele'}),
          ],
          text: text,
          locale: const Locale('de'),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(GameTile), findsNWidgets(4));
      });
    }

    testWidgets('the page a game opens on draws the game, and a round played '
        'there keeps its record past the day', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      final ExploreSection sixty = kQuickGames.first.sectionUnder(
        _section('quick-games'),
      );
      await _pumpPage(tester, host, sixty);
      expect(find.byType(SixtySeconds), findsOneWidget);
      final List<Pill> claims = ExploreShelves.of(host).mix.sixty;
      final int expected = claims.where(trueOrFalseAnswer).length;

      await tester.tap(find.byKey(const ValueKey('sixty-start')));
      // The round grows out of the panel before its buttons can be hit.
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (int i = 0; i < 8; i++) {
        await tester.tap(find.byKey(const ValueKey('sixty-true')));
        await tester.pump(const Duration(milliseconds: 200));
      }
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const ValueKey('sixty-end')), findsOneWidget);
      expect(host.app.sixtyBest, expected);
    });

    testWidgets('a page whose game has nothing to play says so', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        CoreHost(await readyApp()),
        const ExploreSection(id: 'gone', block: 'block-from-a-later-build'),
      );
      expect(find.byKey(const ValueKey('section-page-none')), findsOneWidget);
    });
  });

  group('subject levels', () {
    test('the level: 1 to 10, from cards read and answered right, never '
        'down, each step wider than the one before', () {
      expect(SubjectLevel.levelFor(0), 1);
      expect(SubjectLevel.levelFor(2), 1);
      expect(SubjectLevel.levelFor(3), 2);
      expect(SubjectLevel.levelFor(11), 2);
      expect(SubjectLevel.levelFor(12), 3);
      expect(SubjectLevel.levelFor(242), 9);
      expect(SubjectLevel.levelFor(243), 10);
      expect(SubjectLevel.levelFor(100000), 10);
      int last = 1;
      for (int points = 0; points < 400; points++) {
        final int level = SubjectLevel.levelFor(points);
        expect(level, greaterThanOrEqualTo(last));
        last = level;
      }
      for (int n = 2; n < 10; n++) {
        expect(
          SubjectLevel.pointsFor(n + 1) - SubjectLevel.pointsFor(n),
          greaterThan(
            SubjectLevel.pointsFor(n) - SubjectLevel.pointsFor(n - 1),
          ),
        );
      }
      const SubjectLevel s = SubjectLevel(key: 'space', read: 10, right: 4);
      expect(s.points, 18);
      expect(s.level, 3);
      expect(s.toNext, closeTo((18 - 12) / (27 - 12), 1e-9));
    });

    testWidgets('the subjects read, furthest on first, a ring each, and a '
        'tap narrows Explore to one', (tester) async {
      final AppState app = await readyApp();
      final List<Pill> space = _of(kTopics['space']!.name);
      final List<Pill> history = _of(kTopics['history']!.name);
      app.seenIds.addAll([for (final p in space.take(30)) p.id]);
      app.seenIds.addAll([for (final p in history.take(3)) p.id]);
      final CoreHost host = CoreHost(app);
      await pumpSections(tester, host, [
        _section('subject-levels', {'title': 'Your subjects'}),
      ]);
      // 30 points is level 4; 3 is level 2.
      expect(
        find.byKey(const ValueKey('subject-level-space-4')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('subject-level-history-2')),
        findsOneWidget,
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('subject-level-space-4')))
            .dx,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('subject-level-history-2')))
              .dx,
        ),
      );
      expect(find.byType(LevelRing), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('subject-level-history-2')));
      expect(host.subjects, ['History']);
    });

    testWidgets('a right answer counts twice over a card read', (tester) async {
      final AppState app = await readyApp();
      final List<Pill> graded = _of(kTopics['space']!.name)
          .where((p) => p.challenge is PickOne)
          .take(4)
          .toList();
      for (final Pill p in graded) {
        app.seenIds.add(p.id);
        app.answers[p.id] = Answer('${(p.challenge as PickOne).correct}');
      }
      // Four read and four right: 12 points, level 3.
      expect(subjectLevels(app).single.points, 12);
      await pumpSections(tester, CoreHost(app), [_section('subject-levels')]);
      expect(
        find.byKey(const ValueKey('subject-level-space-3')),
        findsOneWidget,
      );
    });

    testWidgets('a reader who has read nothing has no subjects to show', (
      tester,
    ) async {
      await pumpSections(tester, CoreHost(await readyApp()), [
        _section('subject-levels', {'title': 'Your subjects'}),
      ]);
      expect(find.text('Your subjects'), findsNothing);
      expect(find.byType(LevelRing), findsNothing);
    });

    for (final double text in [1.0, 2.0]) {
      testWidgets('eight subjects at ${text}x, 375 wide: whole', (
        tester,
      ) async {
        final AppState app = await readyApp();
        for (final String key in kTopics.keys.take(10)) {
          app.seenIds.addAll([
            for (final p in _of(kTopics[key]!.name).take(5)) p.id,
          ]);
        }
        await pumpSections(
          tester,
          CoreHost(app, language: 'de'),
          [
            _section('subject-levels', {'title': 'Deine Fächer'}),
          ],
          text: text,
          locale: const Locale('de'),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(LevelRing), findsNWidgets(8));
      });
    }
  });

  group('more like what you saved', () {
    testWidgets('cards like the latest save, unread, with the reason; a tap '
        'opens one', (tester) async {
      final AppState app = await readyApp();
      final Pill saved = _withSiblings(4);
      app.savedIds = [saved.id];
      final CoreHost host = CoreHost(app);
      await pumpSections(tester, host, [
        _section('like-saved', {'title': 'More like what you saved'}),
      ]);
      expect(find.text('More like what you saved'), findsOneWidget);
      expect(
        find.text('Because you saved “${shortQuestion(saved.question)}”'),
        findsOneWidget,
      );
      expect(find.byKey(ValueKey('explore-${saved.id}')), findsNothing);
      final Finder tiles = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('explore-'),
      );
      expect(tiles, findsWidgets);
      await tester.tap(tiles.first);
      expect(host.opened.single.$1, 'like-saved');
      final Pill opened = PillBank.byId(host.opened.single.$2)!;
      expect(likeness(saved, opened), greaterThanOrEqualTo(kLikeFloor));
    });

    test('alike by strand, genre and keywords; the read and the saved left '
        'out; nothing alike, nothing at all', () {
      final Pill saved = _withSiblings(4);
      final List<Pill> sameStrand = PillBank.cards
          .where((p) => p.strand == saved.strand && p.id != saved.id)
          .toList();
      final like = likeSaved(
        savedIds: [saved.id],
        pool: PillBank.cards,
        isRead: (p) => p.id == sameStrand.first.id,
        most: 50,
      )!;
      expect(like.saved.id, saved.id);
      expect(like.cards.map((p) => p.id), isNot(contains(saved.id)));
      expect(like.cards.map((p) => p.id), isNot(contains(sameStrand.first.id)));
      expect(like.cards.map((p) => p.id), contains(sameStrand[1].id));
      // Furthest alike first.
      final List<int> points = [for (final p in like.cards) likeness(saved, p)];
      expect(points, [...points]..sort((a, b) => b.compareTo(a)));

      expect(
        likeSaved(
          savedIds: [saved.id],
          pool: [saved],
          isRead: (_) => false,
          most: 8,
        ),
        isNull,
      );
      expect(shortQuestion('Short?'), 'Short?');
      expect(
        shortQuestion(
          'How many of the stars you can see at night are already gone?',
        ),
        'How many of the stars you can…',
      );
    });

    testWidgets('nothing saved, or a save with nothing like it: no section', (
      tester,
    ) async {
      await pumpSections(tester, CoreHost(await readyApp()), [
        _section('like-saved', {'title': 'More like what you saved'}),
      ]);
      expect(find.text('More like what you saved'), findsNothing);

      final AppState app = await readyApp();
      app.savedIds = ['no-such-card'];
      await pumpSections(tester, CoreHost(app), [
        _section('like-saved', {'title': 'More like what you saved'}),
      ]);
      expect(find.text('More like what you saved'), findsNothing);
    });

    for (final double text in [1.0, 2.0]) {
      testWidgets('at ${text}x, 375 wide: whole', (tester) async {
        final AppState app = await readyApp();
        app.savedIds = [_withSiblings(4).id];
        await pumpSections(
          tester,
          CoreHost(app, language: 'it'),
          [
            _section('like-saved', {
              'title': 'Altre come quelle che hai salvato',
            }),
          ],
          text: text,
          locale: const Locale('it'),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('like-saved-because')),
          findsOneWidget,
        );
      });
    }
  });

  group('the streak by the title', () {
    testWidgets('a flame and the days beside the search, a tap to Today; '
        'nothing at 0', (tester) async {
      int todays = 0;
      await _pumpScreen(tester, await readyApp(), onToday: () => todays++);
      expect(find.byKey(const ValueKey('explore-streak')), findsNothing);

      final AppState app = await readyApp(const {}, _wednesday);
      app.streak = 12;
      app.lastCompletionDate = '2026-11-10';
      await _pumpScreen(tester, app, onToday: () => todays++);
      expect(find.byKey(const ValueKey('explore-streak')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('explore-streak')),
          matching: find.text('12 days'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('explore-streak')));
      expect(todays, 1);
    });
  });
}

/// A host whose sections' sources have no cards.
class _NoCards extends CoreHost {
  _NoCards(super.app);

  @override
  List<Pill> cardsFor(ExploreSection section, {int? limit}) => const [];
}

Future<void> _pumpPage(
  WidgetTester tester,
  ExploreHost host,
  ExploreSection section,
) async {
  tester.view.physicalSize = const Size(375, 667) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: ExploreSectionPage(host: host, section: section),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpScreen(
  WidgetTester tester,
  AppState app, {
  VoidCallback? onToday,
}) async {
  tester.view.physicalSize = const Size(375, 667) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(
        body: ExploreScreen(app: app, onToday: onToday),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}
