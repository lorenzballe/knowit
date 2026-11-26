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
import 'package:astuto/widgets/skill_score.dart' show scoreBookOf;
import 'package:astuto/widgets/ui.dart' show BackCircle;

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

/// The Astute score [app]'s reader sees.
int _scoreOf(AppState app) => scoreBookOf(app).overall.now;

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
      tester.view.physicalSize = const Size(402, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(app));
      await tester.pumpAndSettle();
    }

    testWidgets('one number: the Astute score heads the journey, and no '
        'points or ladder of levels repeat it; practise comes right under it', (
      tester,
    ) async {
      final app = await _app({
        'knowit.onboarded': true,
        'knowit.plus': true,
        'knowit.skills': ['money'],
      });
      await pump(tester, app);
      expect(find.byKey(const ValueKey('training-score')), findsOneWidget);
      expect(find.text('YOUR SCORE'), findsNothing);
      expect(find.byKey(const ValueKey('journey-score')), findsNothing);
      expect(find.byKey(const ValueKey('journey-level')), findsNothing);
      final l = lookupAppLocalizations(const Locale('en'));
      double top(String chapter) => tester.getTopLeft(find.text(chapter)).dy;
      expect(
        top('2  ·  ${l.storyChapterPractice.toUpperCase()}'),
        lessThan(top('3  ·  ${l.storyChapterWeek.toUpperCase()}')),
      );
      expect(
        tester
            .getTopLeft(find.textContaining(l.journeyChapterKnow.toUpperCase()))
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.textContaining(l.storyChapterReason.toUpperCase()),
              )
              .dy,
        ),
      );
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

    testWidgets('before there is anything to say, how many more answers '
        'it takes, said once, and no empty chart', (tester) async {
      final app = await _app(
        _answered({
          80: [(0, 0), (5, 3)],
        }),
      );
      await pump(tester, app);
      expect(find.byKey(const ValueKey('journey-gap')), findsNothing);
      expect(
        find.textContaining('7 more answers saying how sure'),
        findsOneWidget,
      );
      expect(find.text('LEVEL 1 OF 7'), findsNothing);
      expect(find.text('Counted from today'), findsOneWidget);
      expect(find.text('nothing dated yet'), findsOneWidget);
    });
  });

  group('since the last visit', () {
    /// Six cards answered right today, on cards the bank has: a score to
    /// count up to.
    Map<String, Object> answeredToday({Map<String, Object> also = const {}}) {
      final List<Pill> right = PillBank.cards
          .where((p) => p.isGraded)
          .take(6)
          .toList();
      final String today = dateKey(DateTime.now());
      return {
        'knowit.onboarded': true,
        'knowit.plus': true,
        'knowit.seenIds': [for (final p in right) p.id],
        'knowit.judgements': jsonEncode([
          for (final p in right) {'c': 80, 'k': true, 'p': p.id, 'd': today},
        ]),
        ...also,
      };
    }

    String daysAgo(int n) =>
        dateKey(DateTime.now().subtract(Duration(days: n)));

    Widget host(AppState app, {bool still = false}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: child!,
      ),
      home: JourneyScreen(app: app, onBack: () {}),
    );

    Finder inScore(String text) => find.descendant(
      of: find.byKey(const ValueKey('training-score')),
      matching: find.text(text),
    );

    Finder markIn(Finder where) => find.descendant(
      of: where,
      matching: find.byKey(const ValueKey('since-mark')),
    );

    double opacityOf(WidgetTester tester, Finder mark) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(of: mark, matching: find.byType(AnimatedOpacity)),
        )
        .opacity;

    testWidgets('a figure that moved since the reader last looked stands '
        'where it was, counts calmly to where it is, and keeps a quiet mark '
        'of how far; what they saw is written down for next time', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(402, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = await _app(
        answeredToday(
          also: {
            'knowit.journeySeen': jsonEncode({'score': 10}),
            'knowit.journeySeenOn': daysAgo(2),
          },
        ),
      );
      final int now = _scoreOf(app);
      expect(now, greaterThan(30));
      await tester.pumpWidget(host(app));
      await tester.pump();
      // Where it was, while the page arrives.
      expect(inScore('10'), findsOneWidget);
      expect(
        markIn(find.byKey(const ValueKey('training-score'))),
        findsOneWidget,
      );
      expect(
        opacityOf(tester, markIn(find.byKey(const ValueKey('training-score')))),
        0,
      );
      await tester.pump(const Duration(milliseconds: 1000));
      // On its way: neither where it was nor where it is.
      expect(inScore('10'), findsNothing);
      expect(inScore('$now'), findsNothing);
      await tester.pumpAndSettle();
      expect(inScore('$now'), findsOneWidget);
      final Finder mark = markIn(find.byKey(const ValueKey('training-score')));
      expect(tester.widget<Text>(mark).data, '+${now - 10}');
      expect(opacityOf(tester, mark), 1);
      // When the last visit was, under the title.
      expect(find.text('Since your last visit, 2 days ago'), findsOneWidget);
      // Written down: next time it counts from here.
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> seen = jsonDecode(
        prefs.getString('knowit.journeySeen')!,
      ) as Map<String, dynamic>;
      expect(seen['score'], now);
      expect(prefs.getString('knowit.journeySeenOn'), daysAgo(0));
      expect(app.journeySeen['score'], now);
    });

    testWidgets('opened again with nothing new, nothing counts and nothing '
        'is marked; the first time, nothing is either', (tester) async {
      tester.view.physicalSize = const Size(402, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = await _app(answeredToday());
      await tester.pumpWidget(host(app));
      await tester.pump();
      expect(inScore('${_scoreOf(app)}'), findsOneWidget);
      expect(find.byKey(const ValueKey('since-mark')), findsNothing);
      expect(find.byKey(const ValueKey('journey-since')), findsNothing);
      await tester.pumpAndSettle();
      expect(app.journeySeen['score'], _scoreOf(app));
      // Again: what was seen is where it stands.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host(app));
      await tester.pump();
      expect(inScore('${_scoreOf(app)}'), findsOneWidget);
      expect(find.byKey(const ValueKey('since-mark')), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('whoever asked for less motion gets every figure where it '
        'stands, with its mark', (tester) async {
      tester.view.physicalSize = const Size(402, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = await _app(
        answeredToday(
          also: {
            'knowit.journeySeen': jsonEncode({'score': 10}),
            'knowit.journeySeenOn': daysAgo(1),
          },
        ),
      );
      final int now = _scoreOf(app);
      await tester.pumpWidget(host(app, still: true));
      await tester.pump();
      await tester.pump();
      expect(inScore('$now'), findsOneWidget);
      final Finder mark = markIn(find.byKey(const ValueKey('training-score')));
      expect(opacityOf(tester, mark), 1);
      expect(find.text('Since your last visit, yesterday'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a figure below the fold counts when it is reached, not '
        'before, and one never reached is not written down as seen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(402, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = await _app(
        answeredToday(
          also: {
            'knowit.streak': 3,
            'knowit.lastCompletionDate': daysAgo(0),
            'knowit.journeySeen': jsonEncode({'streak': 1, 'score': 10}),
            'knowit.journeySeenOn': daysAgo(2),
          },
        ),
      );
      final int streak = app.liveStreak;
      expect(streak, greaterThan(1));
      await tester.pumpWidget(host(app));
      await tester.pumpAndSettle();
      // The days in a row are far down the page: not seen yet.
      expect(app.journeySeen['streak'], 1);
      final Finder list = find.byKey(const ValueKey('journey-page'));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('journey-week')),
        300,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      // Brought to the top of the page by the scroll: down a little, into
      // the middle of it.
      await tester.drag(list, const Offset(0, 200));
      await tester.pump();
      final Finder row = find.byKey(const ValueKey('journey-week'));
      expect(
        find.descendant(of: row, matching: find.text('1 day')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: row, matching: find.text('$streak days')),
        findsOneWidget,
      );
      expect(tester.widget<Text>(markIn(row)).data, '+${streak - 1}');
      expect(app.journeySeen['streak'], streak);
    });

    testWidgets('the whole page scrolls, its title with it; only the way '
        'back stays, and the page goes soft under the status bar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.reset);
      final app = await _app(answeredToday());
      await tester.pumpWidget(host(app));
      await tester.pumpAndSettle();
      final Finder back = find.byType(BackCircle);
      final Finder title = find.text('Your journey');
      final Offset backAt = tester.getTopLeft(back);
      final double titleAt = tester.getCenter(title).dy;
      // At rest, the title beside the way back, under the status bar.
      expect(backAt.dy, greaterThanOrEqualTo(47));
      expect((titleAt - tester.getCenter(back).dy).abs(), lessThan(4));
      expect(
        tester.getSize(find.byKey(const ValueKey('journey-top-edge'))).height,
        47,
      );
      // Not so far that the title leaves the screen: it rises under the
      // status bar while the way back stays where it was.
      await tester.drag(
        find.byKey(const ValueKey('journey-page')),
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(back), backAt);
      expect(tester.getCenter(title).dy, closeTo(titleAt - 60, 1));
      // Still the way back, over whatever runs under it.
      await tester.tap(back);
    });

    testWidgets('what has stayed is part of what the reader knows, not a '
        'chapter of its own', (tester) async {
      tester.view.physicalSize = const Size(402, 9000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final Pill card = PillBank.cards.firstWhere(
        (p) => p.challenge is PickOne,
      );
      final app = await _app({
        'knowit.onboarded': true,
        'knowit.plus': true,
        'knowit.seenIds': [card.id],
        'knowit.answersJson': jsonEncode({
          card.id: {'r': '${(card.challenge as PickOne).correct}', 's': 3},
        }),
      });
      expect(app.heldCards, 1);
      await tester.pumpWidget(host(app));
      await tester.pumpAndSettle();
      final l = lookupAppLocalizations(const Locale('en'));
      expect(find.byKey(const ValueKey('journey-memory')), findsOneWidget);
      expect(find.textContaining('WHAT STAYS WITH YOU'), findsNothing);
      final double memory = tester
          .getTopLeft(find.byKey(const ValueKey('journey-memory')))
          .dy;
      expect(
        memory,
        greaterThan(
          tester
              .getTopLeft(
                find.textContaining(l.journeyChapterKnow.toUpperCase()),
              )
              .dy,
        ),
      );
      expect(
        memory,
        lessThan(
          tester
              .getTopLeft(
                find.textContaining(l.storyChapterReason.toUpperCase()),
              )
              .dy,
        ),
      );
    });
  });
}
