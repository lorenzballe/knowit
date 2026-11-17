// The problem of the day (explore/blocks/core/maths_daily_block.dart): one
// maths problem a day on the Maths page of Explore, the same for everyone,
// answered there, counted in days in a row and sent like a puzzle's result.
//
//   flutter test test/explore/maths_daily_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/explore/blocks/core/maths_daily_block.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';

import 'core_harness.dart';

Future<AppState> _app(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final app = AppState();
  await app.init();
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final String maths = kTopics['maths']!.name;

  final sections = sectionsOf([
    {
      'id': 'maths-daily',
      'block': 'maths-daily',
      'title': {'en': 'Problem of the day'},
    },
  ]);

  test('the problems are maths cards with an answer to give, in an order '
      'of their own, and a day brings one', () async {
    final List<Pill> pool = mathsProblems();
    expect(pool.length, greaterThan(30));
    expect(pool.every((p) => p.topic == maths && p.isGraded), isTrue);
    // The same order every time it is asked.
    expect(
      [for (final p in mathsProblems()) p.id],
      [for (final p in pool) p.id],
    );
    final app = await _app({});
    final DateTime monday = DateTime(2026, 11, 16);
    final Pill? one = mathsProblemOf(app, monday);
    final Pill? next = mathsProblemOf(
      app,
      monday.add(const Duration(days: 1)),
    );
    expect(one, isNotNull);
    expect(next?.id, isNot(one?.id));
  });

  test('a problem answered before is skipped; the one answered today stays '
      'today\'s; the days in a row count from yesterday while today is open',
      () async {
    final DateTime today = DateTime.now();
    final String key = dateKey(today);
    final String yesterday = dateKey(today.subtract(const Duration(days: 1)));
    final empty = await _app({});
    final Pill first = mathsProblemOf(empty, today)!;

    // Answered on another day: not set again.
    final before = await _app({
      'knowit.answersJson': jsonEncode({
        first.id: {'r': '0', 'd': yesterday},
      }),
    });
    expect(mathsProblemOf(before, today)?.id, isNot(first.id));

    // Answered today: it is today's, and today counts.
    final now = await _app({
      'knowit.answersJson': jsonEncode({
        first.id: {'r': '0', 'd': key},
      }),
      'knowit.judgements': jsonEncode([
        {'k': true, 'p': first.id, 'd': key},
        {'k': false, 'p': mathsProblems().last.id, 'd': yesterday},
      ]),
    });
    expect(mathsProblemOf(now, today)?.id, first.id);
    expect(mathsStreak(now, today), 2);
    // Nothing today yet: yesterday's run still stands.
    final open = await _app({
      'knowit.judgements': jsonEncode([
        {'k': true, 'p': mathsProblems().last.id, 'd': yesterday},
      ]),
    });
    expect(mathsStreak(open, today), 1);
    expect(mathsStreak(empty, today), 0);
  });

  testWidgets('on the Maths page only: the day\'s problem, a tap from the '
      'deck', (tester) async {
    final app = await _app({});
    final host = CoreHost(app, subject: maths);
    await pumpSections(tester, host, sections);
    expect(find.text('Problem of the day'), findsOneWidget);
    final Pill problem = mathsProblemOf(app, app.today)!;
    expect(find.text(problem.question), findsOneWidget);
    expect(find.text('Solve it'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('maths-daily')));
    expect(host.opened.single, ('maths-daily', problem.id));

    // Explore for every subject, or another one: nothing.
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text('Problem of the day'), findsNothing);
    await pumpSections(
      tester,
      CoreHost(app, subject: kTopics['space']!.name),
      sections,
    );
    expect(find.text('Problem of the day'), findsNothing);
  });

  testWidgets('answered today: the verdict, tomorrow\'s promise and the way '
      'to send it', (tester) async {
    final String key = dateKey(DateTime.now());
    final empty = await _app({});
    final Pill problem = mathsProblemOf(empty, empty.today)!;
    final app = await _app({
      'knowit.answersJson': jsonEncode({
        problem.id: {'r': '0', 'd': key},
      }),
      'knowit.judgements': jsonEncode([
        {'k': true, 'p': problem.id, 'd': key},
      ]),
    });
    await pumpSections(tester, CoreHost(app, subject: maths), sections);
    expect(find.text('✓  Solved'), findsOneWidget);
    expect(find.text('A new one tomorrow'), findsOneWidget);
    expect(find.byKey(const ValueKey('maths-daily-share')), findsOneWidget);
    expect(find.text('🔥 1 day in a row'), findsOneWidget);
    // Another like it is offered only where the answers by Claude are on.
    expect(find.byKey(const ValueKey('maths-daily-another')), findsNothing);
    debugToolsOn = true;
    addTearDown(() => debugToolsOn = false);
    await pumpSections(tester, CoreHost(app, subject: maths), sections);
    expect(find.byKey(const ValueKey('maths-daily-another')), findsOneWidget);
  });
}
