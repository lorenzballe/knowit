// Paths that go deeper, a path's own page, an area's own page, the search
// before anything is typed, and a subject's own home: what the reader can
// open, what the free plan opens, and that each fits a small phone in every
// language.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/genres.dart';
import 'package:astuto/data/goals.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show searchPills;
import 'package:astuto/explore/blocks/core/paths_block.dart';
import 'package:astuto/explore/blocks/core/subject_levels_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/area_screen.dart';
import 'package:astuto/screens/card_path_screen.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/subject_home_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/search_start.dart';

final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
final DateTime day = DateTime(2026, 11, 19, 9);

Future<AppState> opened(WidgetTester? tester, {bool plus = false}) async {
  Future<AppState> make() async {
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.plus': plus,
    });
    final AppState app = AppState(clock: () => day);
    await app.init();
    return app;
  }

  if (tester == null) return make();
  return await tester.runAsync(make) as AppState;
}

/// A theme deep enough for three parts.
(Genre, String) deepTheme() {
  for (final MapEntry<String, List<Genre>> s in kGenres.entries) {
    for (final Genre g in s.value) {
      if (partsOf(g, s.key, PillBank.live).length == kPathParts) {
        return (g, s.key);
      }
    }
  }
  throw StateError('no theme of thirty cards');
}

Future<void> pump(
  WidgetTester tester,
  Widget page, {
  Locale locale = const Locale('en'),
  Size phone = const Size(390, 844),
  double text = 1,
  Brightness brightness = Brightness.dark,
}) async {
  tester.view.physicalSize = phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(text)),
        child: child!,
      ),
      home: page,
    ),
  );
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(PillBank.reset);

  group('paths go deeper', () {
    test('a theme of thirty cards is three parts of ten, easier first', () {
      final (Genre g, String key) = deepTheme();
      final List<CardPath> parts = partsOf(g, key, PillBank.live);
      expect(parts, hasLength(kPathParts));
      final List<int> levels = [
        for (final CardPath part in parts)
          for (final Pill p in part.cards) p.difficulty.index,
      ];
      expect(levels, orderedEquals([...levels]..sort()));
      for (final (int i, CardPath part) in parts.indexed) {
        expect(part.cards, hasLength(kPathLength));
        expect(part.part, i + 1);
        expect(part.parts, kPathParts);
      }
      // No card in two parts.
      final Set<String> ids = {
        for (final part in parts) ...part.cards.map((p) => p.id),
      };
      expect(ids, hasLength(kPathLength * kPathParts));
    });

    test('the reader is at the first part not read through', () {
      final (Genre g, String key) = deepTheme();
      final List<CardPath> parts = partsOf(g, key, PillBank.live);
      expect(currentPart(parts, const {}).part, 1);
      final Set<String> first = {...parts[0].cards.map((p) => p.id)};
      expect(currentPart(parts, first).part, 2);
      final Set<String> all = {
        for (final part in parts) ...part.cards.map((p) => p.id),
      };
      expect(currentPart(parts, all).part, kPathParts);
      expect(partOf(parts[0], 2)!.cards.first.id, parts[1].cards.first.id);
      expect(partOf(parts[0], kPathParts + 1), isNull);
    });

    test('the row shows each theme at the part the reader has got to', () {
      final List<CardPath> week = pathsOf(PillBank.live, today: day);
      final CardPath deep = week.firstWhere(
        (p) => p.parts > 1,
        orElse: () => week.first,
      );
      final Set<String> read = {...deep.cards.map((p) => p.id)};
      final List<CardPath> after = pathsOf(
        PillBank.live,
        today: day,
        read: read,
      );
      final CardPath same = after.firstWhere(
        (p) => p.genre.id == deep.genre.id,
      );
      expect(same.part, deep.parts > 1 ? 2 : 1);
    });
  });

  group('a path\'s own page', () {
    testWidgets('on the free plan: two cards open, the rest behind the plans', (
      tester,
    ) async {
      final AppState app = await opened(tester);
      final CardPath path = pathsOf(PillBank.live, today: day).first;
      await pump(tester, CardPathScreen(app: app, path: path));
      expect(tester.takeException(), isNull);
      expect(find.text(en.pathFreeTag.toUpperCase()), findsNWidgets(kPathFree));
      expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
      // The way on stays at the foot, with what the free plan opens.
      expect(find.text(en.pathStart), findsOneWidget);
      expect(find.text(en.pathFreeLine), findsOneWidget);
      for (int i = 0; i < kPathLength; i++) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('path-card-$i')),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byKey(ValueKey('path-card-$i')), findsOneWidget);
      }

      await tester.tap(find.byKey(const ValueKey('path-go')));
      await settle(tester);
      final DeckViewerScreen viewer = tester.widget(
        find.byType(DeckViewerScreen),
      );
      expect(viewer.deck, hasLength(kPathFree));
      expect(viewer.end, isA<PathMore>());
    });

    testWidgets('a locked card goes through the plans', (tester) async {
      final AppState app = await opened(tester);
      final CardPath path = pathsOf(PillBank.live, today: day).first;
      await pump(tester, CardPathScreen(app: app, path: path));
      final Finder locked = find.byKey(ValueKey('path-card-$kPathFree'));
      await tester.ensureVisible(locked);
      await tester.tap(locked);
      await settle(tester);
      expect(find.byType(PaywallScreen), findsOneWidget);
    });

    testWidgets('on Astute+: every card open; read through, the next part', (
      tester,
    ) async {
      final AppState app = await opened(tester, plus: true);
      final (Genre g, String key) = deepTheme();
      final CardPath first = partsOf(g, key, PillBank.live).first;
      await pump(tester, CardPathScreen(app: app, path: first));
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
      expect(find.text(en.pathStart), findsOneWidget);
      expect(find.text(en.pathPartOf(1, kPathParts)), findsOneWidget);

      await tester.runAsync(() async {
        for (final Pill p in first.cards.take(3)) {
          await app.markReadElsewhere(p.id);
        }
      });
      await settle(tester);
      expect(find.text(en.pathContinueAt(4)), findsOneWidget);
      expect(find.text(en.pathReadOf(3, kPathLength)), findsOneWidget);

      await tester.runAsync(() async {
        for (final Pill p in first.cards) {
          await app.markReadElsewhere(p.id);
        }
      });
      await settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('path-deeper')));
      await tester.tap(find.byKey(const ValueKey('path-deeper')));
      await settle(tester);
      expect(find.text(en.pathPartOf(2, kPathParts)), findsOneWidget);
    });
  });

  group('an area\'s own page', () {
    testWidgets('its paths at the reader\'s part, its moves, more cards; a '
        'path opens its page', (tester) async {
      final AppState app = await opened(tester);
      const Goal area = Goal.money;
      final List<CardPath> paths = pathsForArea(area);
      expect(paths, isNotEmpty);
      expect(paths.every((p) => area.genres.contains(p.genre.id)), isTrue);
      await pump(tester, AreaScreen(app: app, area: area));
      expect(tester.takeException(), isNull);
      expect(find.text(en.goalMoney), findsOneWidget);
      expect(
        find.text(en.areaPaths(paths.length).toUpperCase()),
        findsOneWidget,
      );
      final Finder first = find.byKey(
        ValueKey('area-path-${paths.first.genre.id}'),
      );
      await tester.ensureVisible(first);
      await tester.pump();
      await tester.tap(first);
      await settle(tester);
      expect(find.byType(CardPathScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(CardPathScreen))).pop();
      await settle(tester);

      final List<(Principle, Pill)> moves = movesOf(area, const {});
      expect(moves, isNotEmpty);
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('area-move-${moves.first.$1.name}')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(moves.first.$2.question), findsOneWidget);
    });
  });

  group('the search before anything is typed', () {
    test('words to try that find cards, the same all day', () {
      final List<String> words = searchSuggestions(day);
      expect(words, hasLength(6));
      expect(searchSuggestions(day), words);
      for (final String w in words) {
        expect(searchPills(w).length, greaterThanOrEqualTo(5), reason: w);
      }
    });

    test('every kind finds its cards, and only them', () {
      for (final CardKind kind in CardKind.values) {
        final List<Pill> cards = cardsOfKind(kind, day: day);
        expect(cards, isNotEmpty, reason: kind.name);
        expect(cards.every(kind.fits), isTrue, reason: kind.name);
      }
    });

    testWidgets('words to try, the areas, the kinds; each goes somewhere', (
      tester,
    ) async {
      String? tried;
      Goal? area;
      CardKind? kind;
      await pump(
        tester,
        Scaffold(
          body: SearchStart(
            day: day,
            onTry: (w) => tried = w,
            onArea: (g) => area = g,
            onKind: (k) => kind = k,
          ),
        ),
      );
      final String word = searchSuggestions(day).first;
      await tester.tap(find.byKey(ValueKey('search-try-$word')));
      expect(tried, word);
      for (final Goal g in Goal.values) {
        expect(find.byKey(ValueKey('search-need-${g.key}')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('search-need-health')));
      expect(area, Goal.health);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('search-kind-debate')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('search-kind-debate')));
      expect(kind, CardKind.debate);
    });
  });

  group('a subject\'s own home', () {
    testWidgets('its level as Explore counts it, what the next asks, the next '
        'card, its themes', (tester) async {
      final AppState app = await opened(tester);
      final List<Pill> economics = [
        for (final Pill p in PillBank.live)
          if (p.topic == 'Economics' && p.book == null) p,
      ];
      await tester.runAsync(() async {
        for (final Pill p in economics.take(6)) {
          await app.markReadElsewhere(p.id);
        }
      });
      final SubjectHome home = subjectHomeOf(app, 'economics');
      final SubjectLevel explore = subjectLevels(app)
          .firstWhere((s) => s.key == 'economics');
      expect(home.level.level, explore.level);
      expect(home.level.read, 6);
      expect(home.next, isNotNull);
      expect(app.seenIds.contains(home.next!.id), isFalse);
      expect(home.themes, isNotEmpty);
      expect(home.rightToNext, greaterThan(0));

      await pump(tester, SubjectHomeScreen(app: app, topicKey: 'economics'));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('subject-ring')), findsOneWidget);
      expect(find.text(en.subjectReadOf(6, home.total)), findsOneWidget);
      expect(
        find.text(en.subjectToNext(home.rightToNext, home.level.level + 1)),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('subject-next')), findsOneWidget);
    });
  });

  testWidgets('the new pages fit the smallest phone at a large text size, in '
      'every language, dark and light', (tester) async {
    final AppState app = await opened(tester);
    final CardPath path = pathsOf(PillBank.live, today: day).first;
    for (final Locale locale in AppLocalizations.supportedLocales) {
      for (final Widget page in [
        CardPathScreen(app: app, path: path),
        AreaScreen(app: app, area: Goal.decide),
        SubjectHomeScreen(app: app, topicKey: 'psychology'),
        Scaffold(
          body: SearchStart(
            day: day,
            onTry: (_) {},
            onArea: (_) {},
            onKind: (_) {},
          ),
        ),
      ]) {
        await pump(
          tester,
          page,
          locale: locale,
          phone: const Size(320, 568),
          text: 1.4,
          brightness: locale.languageCode == 'it'
              ? Brightness.light
              : Brightness.dark,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '$locale ${page.runtimeType}',
        );
      }
    }
  });
}
