// What the reader wants to get better at (lib/data/goals.dart,
// screens/goal_screen.dart, explore/blocks/core/goal_block.dart): asked on
// the first run, kept, a shelf of its own on Explore, the mix leaned to it,
// a line for the coach; asked once on Explore of a reader who came before.
//
//   flutter test test/explore/goal_block_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/goals.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/goal_screen.dart';
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
    {'id': 'goal', 'block': 'goal'},
  ]);

  test('a goal is its genres, its moves and its subjects: its cards are the '
      'closest first, none read, in an order of the day', () {
    final DateTime day = DateTime(2026, 11, 18);
    for (final Goal g in Goal.values) {
      final List<Pill> cards = g.cardsFor(day, const {});
      expect(cards, hasLength(10), reason: g.key);
      expect(cards.every(g.fits), isTrue, reason: g.key);
    }
    // Talking with people starts on Life's cards about people.
    final List<Pill> people = Goal.people.cardsFor(day, const {});
    expect(people.first.genre, isIn(Goal.people.genres));
    final List<Pill> all = Goal.business.cardsFor(
      day,
      const {},
      count: 1 << 20,
    );
    final List<int> fits = [for (final p in all) Goal.business.fitOf(p)!];
    for (var i = 1; i < fits.length; i++) {
      expect(fits[i], greaterThanOrEqualTo(fits[i - 1]));
    }
    expect(fits.toSet(), {0, 1, 2});
    expect(
      Goal.people.cardsFor(day, {people.first.id}).map((p) => p.id),
      isNot(contains(people.first.id)),
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

  test('the goal is kept, asked once, and the mix leans half again to its '
      'subjects', () async {
    final app = await _app({});
    expect(app.goal, isNull);
    expect(app.goalAsked, isFalse);
    final Map<String, double> before = app.leanedWeights;
    await app.setGoal('business');
    expect(app.goal, 'business');
    expect(app.goalAsked, isTrue);
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
    // A goal this build does not know is no goal; asked is kept.
    expect((await _app({'knowit.goal': 'flying'})).goal, isNull);
    expect((await _app({'knowit.goalAsked': true})).goalAsked, isTrue);
  });

  testWidgets('the screen: eight goals, Next only with one picked, and the '
      'one held picked when it opens', (tester) async {
    String? done;
    var skipped = false;
    Future<void> pump({String? initial, bool editing = false}) =>
        tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GoalScreen(
              initial: initial,
              editing: editing,
              onDone: (key) => done = key,
              onSkip: () => skipped = true,
            ),
          ),
        );
    await pump();
    expect(find.text('What do you want to get better at?'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('goal-next')));
    expect(done, isNull);
    await tester.tap(find.byKey(const ValueKey('goal-tile-money')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('goal-next')));
    expect(done, 'money');
    await tester.tap(find.text('Skip'));
    expect(skipped, isTrue);

    // From Profile: it opens on the goal held, closes, and saves.
    done = null;
    await pump(initial: 'health', editing: true);
    expect(find.text('Save'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('goal-tile-health')),
      100,
    );
    await tester.tap(find.byKey(const ValueKey('goal-next')));
    expect(done, 'health');
  });

  testWidgets('on Explore: a reader never asked gets the question once, as a '
      'card; picked, the goal is a shelf with a way to change it', (
    tester,
  ) async {
    final app = await _app({});
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.byKey(const ValueKey('goal-ask')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('goal-ask-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goal-tile-business')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('goal-next')));
    await tester.pumpAndSettle();
    expect(app.goal, 'business');

    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text('For your goal: Starting a business'), findsOneWidget);
    expect(
      find.text('Incentives, risk and the numbers behind an idea.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('goal-ask')), findsNothing);
    expect(find.byKey(const ValueKey('goal-change')), findsOneWidget);

    // Not on a subject's page.
    await pumpSections(
      tester,
      CoreHost(app, subject: kTopics['economics']!.name),
      sections,
    );
    expect(find.text('For your goal: Starting a business'), findsNothing);
  });

  testWidgets('put away, or asked on the first run, the question is not on '
      'Explore', (tester) async {
    final app = await _app({});
    await pumpSections(tester, CoreHost(app), sections);
    await tester.tap(find.byKey(const ValueKey('goal-ask-later')));
    await tester.pump();
    expect(app.goalAsked, isTrue);
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.byKey(const ValueKey('goal-ask')), findsNothing);
    final asked = await _app({'knowit.goalAsked': true});
    await pumpSections(tester, CoreHost(asked), sections);
    expect(find.byKey(const ValueKey('goal-ask')), findsNothing);
  });

  testWidgets('the coach is told the goal, in the reader\'s words', (
    tester,
  ) async {
    final app = await _app({'knowit.goal': 'people'});
    late Map<String, Object?> stats;
    Future<void> pump(Locale locale) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Builder(
          builder: (context) {
            stats = coachStats(context, app);
            return const SizedBox();
          },
        ),
      ),
    );
    await pump(const Locale('it'));
    expect(stats['goal'], 'Parlare con le persone');
    await app.setGoal(null);
    await pump(const Locale('en'));
    expect(stats.containsKey('goal'), isFalse);
  });
}
