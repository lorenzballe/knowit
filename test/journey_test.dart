import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/journey_record.dart';
import 'package:astuto/theme.dart';

/// A reader [days] days in: answers dated across the run, the rungs they
/// climbed and when, and the day's counts from [recordFrom] days ago on.
Map<String, Object> _history({int days = 60, int? recordFrom}) {
  final DateTime now = DateTime.now();
  String ago(int d) => dateKey(now.subtract(Duration(days: d)));
  final List<Map<String, Object>> judgements = [
    // Two weeks in: sure, and wrong as often as right.
    for (var i = 0; i < 8; i++)
      {'c': 90, 'k': i < 4, 'p': 'science-$i', 'd': ago(days - 1 - i)},
    for (var i = 0; i < 6; i++)
      {'c': 50, 'k': i < 3, 'p': 'space-$i', 'd': ago(days - 1 - i)},
    // Since: sure, and right nearly every time.
    for (var i = 0; i < 10; i++)
      {'c': 90, 'k': i < 9, 'p': 'history-$i', 'd': ago(10 - i % 10)},
    // From before the app dated an answer: counted today, never in the past.
    {'c': 80, 'k': false},
  ];
  return {
    'knowit.onboarded': true,
    'knowit.plus': true,
    'knowit.completedDates': [for (var d = days - 1; d >= 1; d--) ago(d)],
    'knowit.seenIds': [for (var i = 0; i < 90; i++) 'card-$i'],
    'knowit.judgements': jsonEncode(judgements),
    'knowit.rungDates': jsonEncode({
      'day_one': ago(days - 1),
      'reading': ago(days - 5),
      'answering': ago(days - 12),
      'saying_how_sure': ago(20),
    }),
    'knowit.recordDays': jsonEncode({
      if (recordFrom == null || recordFrom >= days - 1)
        ago(days - 1): [5, 0, 0],
      if (recordFrom == null || recordFrom >= days - 10)
        ago(days - 10): [44, 0, 0],
      ago(5): [80, 2, 1],
    }),
  };
}

Future<AppState> _app(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final app = AppState();
  await app.init();
  return app;
}

void main() {
  group('two weeks in', () {
    test('starts on the first day the app knew, and is the fourteenth', () {
      expect(journeyStart({}, []), isNull);
      expect(
        journeyStart({'day_one': '2026-07-20'}, ['2026-07-14', '2026-07-21']),
        '2026-07-14',
      );
      expect(twoWeeksIn('2026-07-14'), '2026-07-27');
      expect(dayOf('2026-07-14', DateTime(2026, 10, 7)), 86);
      // Offered once it is a week behind the reader, not before.
      expect(canCompare('2026-07-14', DateTime(2026, 8, 2)), isFalse);
      expect(canCompare('2026-07-14', DateTime(2026, 8, 3)), isTrue);
    });

    test('points off are counted as the app counts them, and only once '
        'there are enough answers', () async {
      final app = await _app(_history());
      final List<CalibrationBucket> all = bucketsOf(app.judgements);
      expect(gapOf(all), app.confidenceGap);
      expect(gapOf(bucketsOf(app.judgements.take(5))), isNull);
      // Right when sure: 80% sure or more.
      expect(
        sureRightOf([
          const Judgement(90, correct: true),
          const Judgement(80, correct: false),
          const Judgement(70, correct: true),
        ]),
        50,
      );
      expect(sureRightOf([const Judgement(60, correct: true)]), isNull);
    });

    test('the reader then: the rung they stood on, their answers until '
        'that day, and the counts written down by it', () async {
      final app = await _app(_history());
      final String start = journeyStart(app.rungDates, app.completedDates)!;
      final RecordAt then = recordOn(app, twoWeeksIn(start));
      expect(then.level, 2, reason: 'answering, reached on day twelve');
      expect(then.sureRight, 50, reason: 'four of eight, and nothing undated');
      expect(then.gap, isNotNull);
      expect(then.read, 44);
      expect(then.held, 0);
      final RecordAt now = recordNow(app);
      expect(now.level, app.standing.at);
      expect(now.read, 90);
      expect(now.sureRight, closeTo(13 / 19 * 100, 0.001));
    });

    test('what was not written down then is not worked out now', () async {
      final app = await _app(_history(recordFrom: 20));
      final String start = journeyStart(app.rungDates, app.completedDates)!;
      final RecordAt then = recordOn(app, twoWeeksIn(start));
      expect(then.read, isNull);
      expect(then.held, isNull);
      expect(then.moves, isNull);
      expect(then.level, 2);
    });

    test('the day\'s counts are written down as the reader goes', () async {
      final app = await _app({
        'knowit.onboarded': true,
        'knowit.seenIds': ['a', 'b', 'c'],
      });
      final List<int>? today = app.recordDays[dateKey(app.today)];
      expect(today, [3, app.heldCards, app.movesDown]);
      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('knowit.recordDays')!) as Map;
      expect(stored[dateKey(app.today)], [3, app.heldCards, app.movesDown]);
    });
  });

  group('the top of the journey', () {
    Widget host(AppState app) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: JourneyScreen(app: app, onBack: () {}),
    );

    Finder row(String key, String text) => find.descendant(
      of: find.byKey(ValueKey('journey-row-$key')),
      matching: find.text(text),
    );

    testWidgets('sets two weeks in beside today, a tap apart', (tester) async {
      tester.view.physicalSize = const Size(402, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = await _app(_history());
      await tester.pumpWidget(host(app));
      await tester.pumpAndSettle();

      // Today, with how far each number has come.
      expect(
        find.text('DAY 60 · LEVEL ${app.standing.at + 1} OF 7'),
        findsOneWidget,
      );
      expect(row('read', '90'), findsOneWidget);
      expect(row('read', '+46'), findsOneWidget);
      expect(row('sure', '68%'), findsOneWidget);
      expect(row('sure', '+18'), findsOneWidget);
      expect(find.byKey(const ValueKey('journey-curve')), findsOneWidget);

      // Two weeks in: the rung then, the numbers then, and no deltas.
      await tester.tap(find.byKey(const ValueKey('journey-then')));
      await tester.pumpAndSettle();
      expect(find.text('TWO WEEKS IN · LEVEL 3 OF 7'), findsOneWidget);
      expect(find.text('Answering'), findsOneWidget);
      expect(
        find.text('You commit before you turn the card over.'),
        findsOneWidget,
      );
      expect(row('read', '44'), findsOneWidget);
      expect(row('sure', '50%'), findsOneWidget);
      expect(row('read', '+46'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('journey-now')));
      await tester.pumpAndSettle();
      expect(row('read', '90'), findsOneWidget);
    });

    testWidgets('a past nobody wrote down shows as a dash', (tester) async {
      tester.view.physicalSize = const Size(402, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = await _app(_history(recordFrom: 20));
      await tester.pumpWidget(host(app));
      await tester.pumpAndSettle();
      expect(row('read', '90'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('journey-row-read')),
          matching: find.textContaining('+'),
        ),
        findsNothing,
        reason: 'no delta against a number that was never written down',
      );
      await tester.tap(find.byKey(const ValueKey('journey-then')));
      await tester.pumpAndSettle();
      expect(row('read', '—'), findsOneWidget);
      expect(row('sure', '50%'), findsOneWidget);
    });
  });
}
