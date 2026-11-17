// What the reader wants to get better at (lib/data/goals.dart,
// explore/blocks/core/goal_block.dart): picked on Explore, kept, a shelf of
// its own there, the mix leaned to it, and a line for the coach.
//
//   flutter test test/explore/goal_block_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/goals.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/journey_screen.dart' show coachStats;
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

  final sections = sectionsOf([
    {
      'id': 'goal',
      'block': 'goal',
      'title': {'en': 'What do you want to get better at?'},
      'subtitle': {
        'en': 'Pick one: Explore and your coach will lean that way.',
      },
    },
  ]);

  test('a goal is its subjects and its moves: its cards are those that fit, '
      'the moves first, none read, in an order of the day', () {
    final DateTime day = DateTime(2026, 11, 18);
    for (final Goal g in Goal.values) {
      final List<Pill> cards = g.cardsFor(day, const {});
      expect(cards, hasLength(10), reason: g.key);
      expect(cards.every(g.fits), isTrue, reason: g.key);
    }
    final List<Pill> decide = Goal.decide.cardsFor(
      day,
      const {},
      count: 1 << 20,
    );
    final int other = decide.indexWhere(
      (p) => !Goal.decide.moves.contains(p.principle),
    );
    expect(other, greaterThan(0));
    expect(
      decide.skip(other).every((p) => !Goal.decide.moves.contains(p.principle)),
      isTrue,
    );
    expect(
      Goal.decide.cardsFor(day, {decide.first.id}).map((p) => p.id),
      isNot(contains(decide.first.id)),
    );
    expect(
      [for (final p in Goal.world.cardsFor(day, const {})) p.id],
      isNot([
        for (final p in Goal.world.cardsFor(
          day.add(const Duration(days: 1)),
          const {},
        ))
          p.id,
      ]),
    );
    expect(Goal.of('money'), Goal.money);
    expect(Goal.of('nope'), isNull);
  });

  test(
    'the goal is kept, and the mix leans half again to its subjects',
    () async {
      final app = await _app({});
      expect(app.goal, isNull);
      final Map<String, double> before = app.leanedWeights;
      await app.setGoal('business');
      expect(app.goal, 'business');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.goal'), 'business');
      final Map<String, double> after = app.leanedWeights;
      expect(
        after['economics'],
        closeTo((before['economics'] ?? 1.0) * 1.5, 1e-9),
      );
      expect(
        after['technology'],
        closeTo((before['technology'] ?? 1.0) * 1.5, 1e-9),
      );
      expect(after['space'], before['space'] ?? 1.0);
      await app.setGoal(null);
      expect(app.goal, isNull);
      expect(prefs.getString('knowit.goal'), isNull);
      // A goal this build does not know is no goal.
      expect((await _app({'knowit.goal': 'flying'})).goal, isNull);
    },
  );

  testWidgets('not said yet: the question and the goals; picked: its shelf and '
      'a way to change it; only on Explore for every subject', (tester) async {
    final app = await _app({});
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text('What do you want to get better at?'), findsOneWidget);
    for (final Goal g in Goal.values) {
      expect(find.byKey(ValueKey('goal-${g.key}')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('goal-business')));
    await tester.pump();
    expect(app.goal, 'business');

    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text('For your goal: Starting a business'), findsOneWidget);
    expect(find.text('What do you want to get better at?'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('goal-change')));
    await tester.pump();
    expect(app.goal, isNull);

    await pumpSections(
      tester,
      CoreHost(app, subject: kTopics['economics']!.name),
      sections,
    );
    expect(find.text('What do you want to get better at?'), findsNothing);
  });

  testWidgets('the coach is told the goal, in the reader\'s words', (
    tester,
  ) async {
    final app = await _app({'knowit.goal': 'people'});
    late Map<String, Object?> stats;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: Builder(
          builder: (context) {
            stats = coachStats(context, app);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(stats['goal'], 'Parlare con le persone');
    await app.setGoal(null);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            stats = coachStats(context, app);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(stats.containsKey('goal'), isFalse);
  });
}
