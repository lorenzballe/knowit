// The card after the fifth, on the free plan (lib/state/sixth_line.dart,
// lib/widgets/sixth_card.dart): one true thing a day from the reader's own
// state, and what Astute+ would have done with that day; the same all day,
// never what the last day said; and, dealt after the five, not met again
// on the shelf.
//
//   flutter test test/sixth_line_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/sixth_line.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/magic_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/sixth_card.dart';

final AppLocalizations _en = lookupAppLocalizations(const Locale('en'));

/// A Monday, the reader's week starting.
final DateTime _monday = DateTime(2026, 11, 2);

DateTime _day(int n) => DateTime(_monday.year, _monday.month, _monday.day + n);

/// The free reader on day [n] after [_monday], with [prefs] besides, the
/// phone's memory kept from one day to the next.
Future<AppState> _on(int n, {Map<String, Object>? prefs}) async {
  if (prefs != null) {
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.plus': false,
      ...prefs,
    });
  }
  final DateTime now = DateTime(_day(n).year, _day(n).month, _day(n).day, 20);
  final AppState app = AppState(
    hasPermission: () async => false,
    askPermission: () async => false,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
    clock: () => now,
  );
  await app.init();
  return app;
}

/// The cards of one subject that ask something with a right answer.
List<Pill> _graded(String subject, int n) => PillBank.cards
    .where((p) => p.isGraded && topicKeyForName(p.topic) == subject)
    .take(n)
    .toList();

void main() {
  setUp(Remote.reset);

  group('what is true tonight', () {
    test(
      'how many of today\'s five, and of tomorrow\'s, come at random',
      () async {
        final AppState app = await _on(1, prefs: {});
        final Map<SixthKind, SixthLine> lines = sixthLinesOf(app);
        // The free plan's day: two of the reader's own, the rest at random.
        expect(
          lines[SixthKind.today]!.n,
          kPillsPerDay - app.ownIdsToday.length,
        );
        expect(lines[SixthKind.today]!.n, app.randomToday);
        expect(
          lines[SixthKind.tomorrow]!.n,
          kPillsPerDay - app.ownCardsOn(_day(2)),
        );
        // Nothing else is true of a reader who has answered nothing.
        expect(
          lines.keys,
          unorderedEquals([SixthKind.today, SixthKind.tomorrow]),
        );
      },
    );

    test('a card missed today at 80% sure or more, the surest', () async {
      final List<Pill> cards = _graded('history', 3);
      final AppState app = await _on(
        1,
        prefs: {
          'knowit.judgements': jsonEncode([
            {'c': 80, 'k': false, 'p': cards[0].id, 'd': dateKey(_day(1))},
            {'c': 90, 'k': false, 'p': cards[1].id, 'd': dateKey(_day(1))},
            // Yesterday's, and a sure one that was right: neither.
            {'c': 90, 'k': false, 'p': cards[2].id, 'd': dateKey(_day(0))},
            {'c': 90, 'k': true, 'p': cards[2].id, 'd': dateKey(_day(1))},
          ]),
        },
      );
      expect(sixthLinesOf(app)[SixthKind.sure]!.n, 90);
    });

    test('cards got wrong, back and waiting in Explore', () async {
      final List<Pill> cards = _graded('science', 4);
      final AppState app = await _on(
        3,
        prefs: {
          'knowit.answersJson': jsonEncode({
            // Got wrong, due back today: two of them.
            cards[0].id: {'r': '0', 'd': dateKey(_day(3))},
            cards[1].id: {'r': '0', 'd': dateKey(_day(2))},
            // Got right, due back: back, but not a miss.
            cards[2].id: {'r': '0', 's': 1, 'd': dateKey(_day(3))},
            // Got wrong, not due yet.
            cards[3].id: {'r': '0', 'd': dateKey(_day(5))},
          }),
        },
      );
      expect(sixthLinesOf(app)[SixthKind.misses]!.n, 2);
    });

    test('a subject the answers measure above the level the free plan '
        'deals it at', () async {
      final List<Pill> cards = _graded('history', 8);
      final AppState app = await _on(
        1,
        prefs: {
          'knowit.topicLevels': jsonEncode({'history': 0}),
          'knowit.judgements': jsonEncode([
            for (final (int i, Pill p) in cards.indexed)
              {'c': null, 'k': i != 3, 'p': p.id, 'd': dateKey(_day(0))},
          ]),
        },
      );
      final SixthLine level = sixthLinesOf(app)[SixthKind.level]!;
      expect(level.subject, 'history');
      expect((level.n, level.of), (7, 8));
      // On Astute+ the same answers deal it a level up: what the line says.
      expect(app.measuredLevels['history'], 2);
      expect(app.profile.levelsUnder(app.topicLevels)['history'], 0);
    });

    test('and no level line where the answers measure the level already '
        'dealt', () async {
      final List<Pill> cards = _graded('history', 8);
      final AppState app = await _on(
        1,
        prefs: {
          'knowit.topicLevels': jsonEncode({'history': 2}),
          'knowit.judgements': jsonEncode([
            for (final Pill p in cards)
              {'c': null, 'k': true, 'p': p.id, 'd': dateKey(_day(0))},
          ]),
        },
      );
      expect(sixthLinesOf(app)[SixthKind.level], isNull);
    });
  });

  group('one a day, never the last day\'s', () {
    test('the first evening says tomorrow, and says it all day', () async {
      final AppState app = await _on(1, prefs: {});
      final SixthLine first = sixthLineOf(app)!;
      expect(first.kind, SixthKind.tomorrow);
      await app.noteSixthSaid(first.keptAs(app.today));
      expect(sixthLineOf(app), first);
      expect(app.sixthSaid, '${dateKey(_day(1))}|tomorrow');
    });

    test('across a week, never the same two days running, and only what is '
        'true each day', () async {
      // Cards that ask for a pick: '-1' is no option, and always wrong.
      final List<Pill> cards = PillBank.cards
          .where((p) => p.challenge is PickOne)
          .take(12)
          .toList();
      await _on(0, prefs: {});
      SixthKind? last;
      final List<SixthKind> said = [];
      for (int n = 0; n < 8; n++) {
        final AppState app = await _on(n);
        // Some days a card missed at 90%, some days not.
        if (n.isEven) {
          await app.recordAnswer(cards[n].id, '-1', confidence: 90);
        }
        final SixthLine line = sixthLineOf(app)!;
        expect(sixthLinesOf(app)[line.kind], line, reason: 'day $n');
        expect(line.kind, isNot(last), reason: 'day $n after $last');
        await app.noteSixthSaid(line.keptAs(app.today));
        last = line.kind;
        said.add(line.kind);
      }
      // The random ones come round: free versus Astute+ is said in so many
      // words most weeks.
      expect(said, contains(SixthKind.tomorrow));
      expect(said, contains(SixthKind.today));
    });

    test('what was said earlier today is kept while it is true', () async {
      final AppState app = await _on(
        2,
        prefs: {'knowit.sixthSaid': '${dateKey(_day(2))}|today'},
      );
      expect(sixthLineOf(app)!.kind, SixthKind.today);
    });

    test('a day kept from the last one is not said again', () async {
      final AppState app = await _on(
        2,
        prefs: {'knowit.sixthSaid': '${dateKey(_day(1))}|tomorrow'},
      );
      expect(sixthLineOf(app)!.kind, isNot(SixthKind.tomorrow));
    });
  });

  group('the card', () {
    testWidgets('says the day\'s one thing, large, and what Astute+ would have '
        'done under it, then the door', (tester) async {
      final AppState app = await _on(1, prefs: {});
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 330,
                height: 520,
                child: SixthCard(app: app, onAction: () => opened++),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final int random = kPillsPerDay - app.ownCardsOn(_day(2));
      expect(
        find.text('Tomorrow $random of your five will come at random.'),
        findsOneWidget,
      );
      expect(find.text(_en.sixthRandomTomorrowPlus), findsOneWidget);
      expect(find.text(_en.plusCardHeadline), findsNothing);
      expect(find.byType(MagicCard), findsOneWidget);
      await tester.tap(find.text('Try 14 days free'));
      expect(opened, 1);
      // Kept for the day once it is on screen.
      await tester.pump();
      expect(app.sixthSaid, '${dateKey(_day(1))}|tomorrow');
    });

    testWidgets('every one of them fits the card on a small phone, in every '
        'language, the week\'s note over it', (tester) async {
      // The card's size on an SE, measured in the app itself, as the offer
      // as it always read is measured (test/widget_test.dart): the five
      // thrown, and the card after them on the table.
      tester.view.physicalSize = const Size(375, 667) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.plus': false,
      });
      await tester.pumpWidget(const AstutoApp());
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (var i = 0; i < kPillsPerDay; i++) {
        final Rect deck = tester.getRect(find.byType(PillCardStack));
        await tester.flingFrom(
          Offset(deck.center.dx, deck.top + 90),
          const Offset(-320, 0),
          900,
        );
        for (var f = 0; f < 10; f++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      final Size card = tester.getSize(
        find.byKey(const ValueKey('magic-card')),
      );
      for (final Locale locale in AppLocalizations.supportedLocales) {
        final AppLocalizations l = lookupAppLocalizations(locale);
        for (final SixthLine said in const [
          SixthLine(SixthKind.tomorrow, n: 3),
          SixthLine(SixthKind.today, n: 3),
          SixthLine(SixthKind.sure, n: 90),
          SixthLine(SixthKind.misses, n: 12),
          SixthLine(SixthKind.level, n: 7, of: 8, subject: 'human_body'),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildAstutoTheme(Brightness.dark),
              home: Scaffold(
                body: Center(
                  child: SizedBox.fromSize(
                    size: card,
                    child: Builder(
                      builder: (context) => sixthCardOf(
                        context,
                        said,
                        note: ('note', l.weekKeptSundayFourOwn),
                        action: l.magicUnlock(14),
                        onAction: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '${locale.languageCode} ${said.kind.name} in $card',
          );
        }
      }
    });
  });

  group('on the shelf', () {
    test('not after the five on a day it was dealt there, and back the day '
        'after', () async {
      final AppState app = await _on(1, prefs: {});
      final int five = app.todaysDeck.length;
      expect(TodayDoneView.countOf(app), five + 1);
      await app.noteSixthDealt();
      expect(app.sixthDealtToday, isTrue);
      expect(TodayDoneView.countOf(app), five);
      final AppState tomorrow = await _on(2);
      expect(tomorrow.sixthDealtToday, isFalse);
      expect(TodayDoneView.countOf(tomorrow), tomorrow.todaysDeck.length + 1);
    });
  });
}
