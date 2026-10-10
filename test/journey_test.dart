import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/journey_record.dart';
import 'package:astuto/theme.dart';

/// Answers said how sure, level by level: (count, right) before the last
/// week and (count, right) in it. Plus, if asked, some from before the app
/// dated an answer.
Map<String, Object> _answered(
  Map<int, List<(int, int)>> plan, {
  int undated = 0,
}) {
  final DateTime now = DateTime.now();
  String ago(int days) => dateKey(now.subtract(Duration(days: days)));
  final judgements = <Map<String, Object>>[
    for (var i = 0; i < undated; i++) {'c': 90, 'k': false},
  ];
  var n = 0;
  for (final MapEntry<int, List<(int, int)>> level in plan.entries) {
    for (final (int part, (int count, int right)) in level.value.indexed) {
      for (var i = 0; i < count; i++) {
        judgements.add({
          'c': level.key,
          'k': i < right,
          'p': 'science-${n++}',
          'd': ago(part == 0 ? 20 : 2),
        });
      }
    }
  }
  return {
    'knowit.onboarded': true,
    'knowit.plus': true,
    'knowit.judgements': jsonEncode(judgements),
  };
}

Future<AppState> _app(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final app = AppState();
  await app.init();
  return app;
}

/// A record on its own, for a Wednesday.
JourneyRecord _record({
  Map<String, List<String>> readDays = const {},
  Set<String> seen = const {},
  Map<String, List<int>> dayLog = const {},
  List<Judgement> judgements = const [],
  Map<String, Answer> answers = const {},
  List<String> completedDates = const [],
  int live = 0,
}) => JourneyRecord(
  today: DateTime(2026, 10, 7, 9, 30),
  seen: seen,
  readDays: readDays,
  dayLog: dayLog,
  judgements: judgements,
  answers: answers,
  completedDates: completedDates,
  cards: {for (final p in PillBank.cards) p.id: p},
  liveScore: live,
);

void main() {
  group('points off, then and now', () {
    test('a week ago counts the answers made by then, and the ones from '
        'before answers were dated', () async {
      final app = await _app(
        _answered({
          90: [(10, 4), (10, 10)],
          50: [(4, 2), (0, 0)],
        }, undated: 2),
      );
      final String weekAgo = dateKey(
        app.today.subtract(const Duration(days: 7)),
      );
      // Then: 90% sure, 4 of 12 right (the two undated were wrong); 50%
      // sure, 2 of 4 — 56.7 and 0 points off over sixteen answers.
      expect(
        app.confidenceGapOn(weekAgo),
        closeTo((12 * (90 - 4 / 12 * 100) + 4 * 0) / 16, 1e-9),
      );
      // Today it is the gap the app has always shown.
      expect(app.confidenceGapOn(dateKey(app.today)), app.confidenceGap);
      // Too few answers by then to say anything.
      final few = await _app(
        _answered({
          90: [(3, 1), (20, 18)],
        }),
      );
      expect(
        few.confidenceGapOn(
          dateKey(few.today.subtract(const Duration(days: 7))),
        ),
        isNull,
      );
    });
  });

  group('the record over time', () {
    test('what each day dealt says when a card was first read', () {
      expect(
        readDaysFrom(
          {
            '2026-09-02': ['b', 'd'],
            '2026-09-01': ['a', 'b', 'c'],
          },
          {'a', 'b', 'd'},
        ),
        {
          '2026-09-01': ['a', 'b'],
          '2026-09-02': ['d'],
        },
      );
    });

    test('weeks run from the first day, the last one today', () {
      final record = _record(
        readDays: {
          '2026-09-28': ['a'],
        },
        seen: {'a'},
      );
      expect(record.start, '2026-09-28');
      expect(record.daysIn, 10);
      final weeks = record.weeks();
      expect(
        [for (final w in weeks) '${w.first}..${w.last}'],
        ['2026-09-28..2026-10-04', '2026-10-05..2026-10-07'],
      );
      expect(weeks.last.current, isTrue);
      expect(weeks.first.current, isFalse);
    });

    test('the score of a day: written down, worked out again, or live', () {
      final record = _record(
        readDays: {
          '2026-09-28': ['a', 'b', 'c', 'd', 'e'],
          '2026-10-01': ['f', 'g'],
        },
        // One card read before the app wrote reading down by day.
        seen: {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'x'},
        dayLog: {
          '2026-10-01': [40, 0, 0, 0, 0, 0],
        },
        live: 50,
      );
      // Before the first dated day only the undated card counts.
      expect(record.scoreOn('2026-09-27'), 1);
      // Before the log, counted again: six read, nothing else.
      expect(record.scoreOn('2026-09-29'), 6);
      // A day the log reaches is what it wrote, and a day after it too.
      expect(record.scoreOn('2026-10-01'), 40);
      expect(record.scoreOn('2026-10-03'), 40);
      // Today is the score as it stands.
      expect(record.scoreOn('2026-10-07'), 50);

      final weeks = record.weeks();
      expect(record.earnedIn(weeks.first), 40);
      expect(record.earnedIn(weeks.last), 10);
      expect(record.gainedIn(28), 50);
      expect(record.readBetween('2026-09-28', '2026-10-04').length, 7);
      expect(record.readOnDay('2026-10-01'), ['f', 'g']);
    });

    test('a card held counts from the day the dated answers held it', () {
      final Pill card = PillBank.cards.firstWhere(
        (p) => p.challenge is PickOne,
      );
      final record = _record(
        judgements: [
          Judgement(80, correct: true, pillId: card.id, on: '2026-09-20'),
          Judgement(80, correct: true, pillId: card.id, on: '2026-09-27'),
        ],
        answers: {
          card.id: Answer('${(card.challenge as PickOne).correct}', stage: 2),
        },
        live: 3,
      );
      expect(record.scoreOn('2026-09-26'), 0);
      expect(record.scoreOn('2026-09-27'), 3);
    });

    test('a card comes back on the ladder, and each wait is counted', () {
      // a: right, back a week later right, back three weeks later wrong.
      // b: wrong, back two days later right.
      final record = _record(
        judgements: const [
          Judgement(70, correct: true, pillId: 'a', on: '2026-09-01'),
          Judgement(70, correct: false, pillId: 'b', on: '2026-09-02'),
          Judgement(70, correct: true, pillId: 'b', on: '2026-09-04'),
          Judgement(70, correct: true, pillId: 'a', on: '2026-09-08'),
          Judgement(70, correct: false, pillId: 'a', on: '2026-09-29'),
        ],
      );
      Tally t(int wait, {String? by}) => record.recall(wait, by: by);
      expect([t(0).right, t(0).of], [1, 1]);
      expect([t(1).right, t(1).of], [1, 1]);
      expect([t(2).right, t(2).of], [0, 1]);
      // Four weeks before, the three-week return had not happened.
      expect(t(2, by: '2026-09-09').of, 0);
    });

    test('right when sure, over a window and all told', () {
      final record = _record(
        judgements: const [
          Judgement(90, correct: false, on: '2026-09-01'),
          Judgement(80, correct: true, on: '2026-10-01'),
          Judgement(80, correct: true, on: '2026-10-02'),
          Judgement(60, correct: false, on: '2026-10-02'),
          Judgement(90, correct: false),
        ],
      );
      final Tally all = record.sureBy('2026-10-07');
      expect([all.right, all.of], [2, 4]);
      final Tally lately = record.sureBetween('2026-09-10', '2026-10-07');
      expect([lately.right, lately.of], [2, 2]);
    });

    test('the part of the day most cards are read in, once there are some', () {
      expect(
        _record(
          dayLog: {
            '2026-10-01': [0, 0, 1, 0, 2, 0],
          },
        ).mostlyIn(),
        isNull,
      );
      expect(
        _record(
          dayLog: {
            '2026-10-01': [0, 0, 3, 1, 4, 0],
            '2026-10-02': [0, 0, 1, 0, 2, 1],
          },
        ).mostlyIn(),
        DayPart.evening,
      );
      expect(partOfDay(6), DayPart.morning);
      expect(partOfDay(13), DayPart.afternoon);
      expect(partOfDay(21), DayPart.evening);
      expect(partOfDay(2), DayPart.night);
    });
  });

  group('the phone writes the days down', () {
    test('a card read is written under today, with the score, the time on '
        'it and the part of the day', () async {
      final app = await _app({'knowit.onboarded': true, 'knowit.plus': true});
      final String card = app.todaysDeck.first.id;
      await app.advance();
      final String today = dateKey(app.today);
      expect(app.readDays[today], [card]);
      final List<int> log = app.dayLog[today]!;
      expect(log, hasLength(kDayLogLength));
      expect(log[kLogScore], app.score.total);
      expect(log.sublist(kLogParts).fold<int>(0, (a, b) => a + b), 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.readDays'), contains(card));
      expect(prefs.getString('knowit.dayLog'), isNotNull);
    });

    test('a phone that read before the days were written down gets them '
        'from what each day dealt', () async {
      final List<String> ids = PillBank.cards.take(3).map((p) => p.id).toList();
      final app = await _app({
        'knowit.onboarded': true,
        'knowit.seenIds': ids,
        'knowit.deckHistory': jsonEncode({
          '2026-09-01': ids.take(2).toList(),
          '2026-09-02': ids,
        }),
      });
      expect(app.readDays['2026-09-01'], ids.take(2).toList());
      expect(app.readDays['2026-09-02'], [ids[2]]);
    });
  });

  group('the screen', () {
    Widget host(AppState app) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: JourneyScreen(app: app, onBack: () {}),
    );

    Future<void> pump(WidgetTester tester, AppState app) async {
      tester.view.physicalSize = const Size(402, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(app));
      await tester.pumpAndSettle();
    }

    testWidgets('the score, a point a week, and the week tapped', (
      tester,
    ) async {
      final DateTime now = DateTime.now();
      String ago(int d) => dateKey(now.subtract(Duration(days: d)));
      final List<String> ids = PillBank.cards
          .take(20)
          .map((p) => p.id)
          .toList();
      final app = await _app({
        'knowit.onboarded': true,
        'knowit.plus': true,
        'knowit.seenIds': ids,
        'knowit.readDays': jsonEncode({
          ago(13): ids.take(12).toList(),
          ago(1): ids.skip(12).toList(),
        }),
      });
      await pump(tester, app);

      expect(find.text('YOUR SCORE'), findsOneWidget);
      expect(
        (tester.widget(
          find.byKey(const ValueKey('journey-score')),
        ) as Text).data,
        '${app.score.total}',
      );
      expect(find.text('+${app.score.total} in 4 weeks'), findsOneWidget);
      expect(find.byKey(const ValueKey('journey-week-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('journey-week-2')), findsNothing);

      // Tapping the first week says what that week earned.
      await tester.tap(find.byKey(const ValueKey('journey-week-0')));
      await tester.pumpAndSettle();
      expect(find.textContaining('you earned 12 points.'), findsOneWidget);
      expect(find.text('12 cards'), findsOneWidget);
    });

    testWidgets('the moves you keep missing and the week in questions '
        'moved here from the profile, each question a tap from its card', (
      tester,
    ) async {
      final DateTime now = DateTime.now();
      final String today = dateKey(now);
      final String yesterday = dateKey(
        DateTime(now.year, now.month, now.day - 1),
      );
      // A card answered wrong: its move is one the reader missed.
      final Pill missed = PillBank.cards.firstWhere(
        (p) =>
            p.isGraded &&
            p.principle.isReal &&
            !p.challenge.accepts('0') &&
            p.challenge.accepts('1'),
      );
      final List<Pill> read = PillBank.cards
          .where((p) => p.ask.isNotEmpty)
          .take(3)
          .toList();
      final app = await _app({
        'knowit.onboarded': true,
        'knowit.plus': true,
        'knowit.seenIds': [for (final p in read) p.id],
        // Yesterday's: today's is the day the app deals on opening.
        'knowit.deckHistory': jsonEncode({
          yesterday: [for (final p in read) p.id],
        }),
        'knowit.answersJson': jsonEncode({
          missed.id: {'r': '0', 'd': today},
        }),
      });
      expect(app.masteryByWeakness, isNotEmpty);
      await pump(tester, app);
      final Finder list = find.byType(Scrollable).first;

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('journey-missing')),
        300,
        scrollable: list,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('journey-missing')),
          matching: find.text(missed.principle.label),
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text(read.last.ask),
        300,
        scrollable: list,
      );
      for (final p in read) {
        expect(find.text(p.ask), findsOneWidget);
      }
      await tester.tap(find.text(read.first.ask));
      await tester.pumpAndSettle();
      expect(find.byType(DeckViewerScreen), findsOneWidget);
    });

    testWidgets('before there is anything to say, dashes and why', (
      tester,
    ) async {
      final app = await _app(
        _answered({
          80: [(0, 0), (5, 3)],
        }),
      );
      await pump(tester, app);
      expect(
        (tester.widget(find.byKey(const ValueKey('journey-gap'))) as Text).data,
        '—',
      );
      expect(
        find.textContaining('7 more answers with how sure'),
        findsOneWidget,
      );
      expect(find.text('LEVEL 1 OF 7'), findsOneWidget);
      expect(find.text('Counted from today'), findsOneWidget);
      expect(find.text('nothing dated yet'), findsOneWidget);
    });
  });
}
