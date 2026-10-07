import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/state/app_state.dart';
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

  group('the top of the journey', () {
    Widget host(AppState app) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: JourneyScreen(app: app, onBack: () {}),
    );

    Future<void> pump(WidgetTester tester, AppState app) async {
      tester.view.physicalSize = const Size(402, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(app));
      await tester.pumpAndSettle();
    }

    testWidgets('says how many points off, which way since last week, and '
        'how each level went', (tester) async {
      final app = await _app(
        _answered({
          50: [(4, 2), (4, 2)],
          70: [(4, 1), (4, 3)],
          90: [(8, 3), (6, 5)],
        }),
      );
      await pump(tester, app);

      final int now = app.confidenceGap!.round();
      final int before = app
          .confidenceGapOn(
            dateKey(app.today.subtract(const Duration(days: 7))),
          )!
          .round();
      expect(now, lessThan(before));
      expect(find.text('$now'), findsWidgets);
      expect(find.text('points off'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('journey-last-week')),
          matching: find.text('$before last week'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

      // The surest level first: 90%, eight of fourteen.
      expect(
        find.text('When you said 90% sure, you were right 57% of the time.'),
        findsOneWidget,
      );
      expect(find.text('14 answers'), findsOneWidget);

      // Another level, picked.
      await tester.tap(find.byKey(const ValueKey('journey-level-70')));
      await tester.pumpAndSettle();
      expect(
        find.text('When you said 70% sure, you were right 50% of the time.'),
        findsOneWidget,
      );
      expect(find.text('8 answers'), findsOneWidget);

      // A level never said cannot be picked.
      await tester.tap(find.byKey(const ValueKey('journey-level-60')));
      await tester.pumpAndSettle();
      expect(
        find.text('When you said 70% sure, you were right 50% of the time.'),
        findsOneWidget,
      );
    });

    testWidgets('a gap that grew says so, and one a week has not moved says '
        'that', (tester) async {
      final worse = await _app(
        _answered({
          90: [(12, 10), (12, 2)],
        }),
      );
      await pump(tester, worse);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

      final same = await _app(
        _answered({
          90: [(12, 9), (0, 0)],
        }),
      );
      await pump(tester, same);
      expect(find.text('same as last week'), findsOneWidget);
    });

    testWidgets('until there are enough answers, a dash and how many more', (
      tester,
    ) async {
      final app = await _app(
        _answered({
          80: [(0, 0), (5, 3)],
        }),
      );
      await pump(tester, app);
      expect(find.byKey(const ValueKey('journey-last-week')), findsNothing);
      expect(
        find.textContaining('7 more answers with how sure'),
        findsOneWidget,
      );
      // The curve is drawn from what there is, and says how little.
      expect(find.byKey(const ValueKey('journey-curve')), findsOneWidget);
      expect(find.text('5 answers'), findsOneWidget);
    });
  });
}
