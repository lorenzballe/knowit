// Where a card pays off in a life (lib/data/goals.dart,
// explore/blocks/core/goal_block.dart): six areas, each named on the back
// of its cards and a shelf on Explore a day each; the one the reader picks
// on the profile, kept, leaning the mix, its shelf on Explore every day,
// told the coach.
//
//   flutter test test/explore/goal_block_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/goals.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/explore/blocks/core/goal_block.dart' show withAimShelf;
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/widgets/area_marks.dart';
import 'package:astuto/screens/journey_screen.dart' show coachStats;
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/debug_looks.dart';

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
      [for (final p in Goal.news.cardsFor(day, const {})) p.id],
      isNot([
        for (final p in Goal.news.cardsFor(
          day.add(const Duration(days: 1)),
          const {},
        ))
          p.id,
      ]),
    );
    expect(Goal.of('money'), Goal.money);
    expect(Goal.of('nope'), isNull);
    // What a build before offered: spotting nonsense is the news now; the
    // goals that were no place in a life are no area.
    expect(Goal.of('nonsense'), Goal.news);
    expect(Goal.of('culture'), isNull);
    // A card of an area's own names it; one only about its subjects not.
    final Pill bad = Goal.news.cardsFor(day, const {}).first;
    expect(Goal.bestFor(bad), isNotNull);
  });

  test('the goal is kept, asked once, and the mix leans half again to its '
      'subjects', () async {
    final app = await _app({});
    expect(app.goal, isNull);
    expect(app.goalAsked, isFalse);
    final Map<String, double> before = app.leanedWeights;
    await app.setGoal('business');
    expect(app.goal, 'business');
    expect(app.goals, ['business']);
    expect(app.goalAsked, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('knowit.goals'), ['business']);
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

  test('up to three goals: kept in the order picked, each once, the mix '
      'leaned to all their subjects; the one goal a build before kept is '
      'read as the first', () async {
    final app = await _app({});
    final Map<String, double> before = app.leanedWeights;
    await app.setGoals([
      'money',
      'news',
      'money',
      'flying',
      'culture',
      'health',
      'people',
    ]);
    expect(app.goals, ['money', 'news', 'health']);
    expect(app.goal, 'money');
    final Map<String, double> after = app.leanedWeights;
    // Money's economics and maths, the news's science and technology,
    // health's body, medicine, food and sport.
    for (final String t in [
      'economics',
      'maths',
      'science',
      'technology',
      'human_body',
      'food',
    ]) {
      expect(after[t], closeTo((before[t] ?? 1.0) * 1.5, 1e-9), reason: t);
    }
    expect(after['space'], before['space'] ?? 1.0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('knowit.goals'), ['money', 'news', 'health']);
    // None at all: no goal, and asked.
    await app.setGoals([]);
    expect(app.goals, isEmpty);
    expect(app.goalAsked, isTrue);

    // A build before kept one goal under knowit.goal: it is the first.
    final old = await _app({'knowit.goal': 'people'});
    expect(old.goals, ['people']);
    expect(old.goalAsked, isTrue);
    await old.setGoals(['people', 'business']);
    final kept = await SharedPreferences.getInstance();
    expect(kept.getString('knowit.goal'), isNull);
    expect(kept.getStringList('knowit.goals'), ['people', 'business']);
    // Spotting nonsense, kept by a build before, comes back as the news.
    expect((await _app({'knowit.goal': 'nonsense'})).goals, ['news']);
  });

  testWidgets("on Explore: the area of the day, for everybody, a day each, "
      "under the words its cards carry; nothing asked, and not on a "
      "subject's page", (tester) async {
    final app = await _app({});
    final Goal area = Goal.ofDay(app.today);
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text(l.goalShelf(goalName(l, area))), findsOneWidget);
    expect(find.text(goalLine(l, area)), findsOneWidget);
    expect(find.byKey(const ValueKey('goal-ask')), findsNothing);
    expect(find.byKey(const ValueKey('goal-change')), findsNothing);
    // Each area in turn, a day each.
    final DateTime day = DateTime(2026, 11, 18);
    expect({
      for (var d = 0; d < Goal.values.length; d++)
        Goal.ofDay(day.add(Duration(days: d))),
    }, Goal.values.toSet());
    expect(Goal.ofDay(day), Goal.ofDay(day.add(const Duration(hours: 20))));
    // Not on a subject's page.
    await pumpSections(
      tester,
      CoreHost(app, subject: kTopics['economics']!.name),
      sections,
    );
    expect(find.text(l.goalShelf(goalName(l, area))), findsNothing);
  });

  testWidgets('a reader who said where they want to see more clearly has '
      'its shelf every day, after Today\'s five and what to continue, in '
      'every look of What to learn; with none, Explore as it was sent', (
    tester,
  ) async {
    const List<ExploreSection> sent = [
      ExploreSection(id: 'three', block: 'three'),
      ExploreSection(id: 'your-five', block: 'your-five'),
      ExploreSection(id: 'continue', block: 'continue'),
      ExploreSection(id: 'news-today', block: 'news-today'),
    ];
    final bool tools = debugToolsOn;
    debugToolsOn = true;
    addTearDown(() {
      debugToolsOn = tools;
      DebugLooks.reset();
    });
    final app = await _app({
      'knowit.goals': ['news'],
    });
    for (final LearnLook look in LearnLook.values) {
      DebugLooks.learn.value = look;
      expect(
        [for (final s in withAimShelf(app, sent)) s.id],
        ['three', 'your-five', 'continue', 'goal', 'news-today'],
        reason: look.name,
      );
    }
    // A shelf the server placed itself stays where it is, and is the goal's.
    final placed = [...sent, const ExploreSection(id: 'goal', block: 'goal')];
    expect(withAimShelf(app, placed), same(placed));
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text(l.goalShelf(l.goalNews)), findsOneWidget);
    expect(withAimShelf(await _app({}), sent), same(sent));
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
    expect(stats['goal'], 'Le persone');
    expect(stats['goals'], ['Le persone']);
    await app.setGoals(['people', 'health']);
    await pump(const Locale('it'));
    expect(stats['goal'], 'Le persone');
    expect(stats['goals'], ['Le persone', 'Salute']);
    await app.setGoal(null);
    await pump(const Locale('en'));
    expect(stats.containsKey('goal'), isFalse);
    expect(stats.containsKey('goals'), isFalse);
  });
}
