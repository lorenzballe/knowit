// What to learn, five other ways, as the developer tools try them beside
// the one that ships (lib/widgets/learn_looks.dart, DebugLooks.learn):
// A, the Astute score alone; B, the aim alone, where the reader wants to be
// sharper, said in words; C, nothing picked, the skills ranked from the
// reader's answers, the weakest to practise; D, the aim read, its four
// skills ranked, the blind spot named; E, one of the aim's skills a week,
// day by day, its mark, its shelf and Sunday's result. And every look on a
// small phone in German.
//
//   flutter test test/learn_looks_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/goals.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/data/skill_levels.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/explore/blocks/core/goal_block.dart' show withAimShelf;
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/chunky.dart';
import 'package:astuto/widgets/learn_looks.dart';
import 'package:astuto/widgets/training.dart';

import 'explore/core_harness.dart';

/// Cards that ask, of which [s] is the closest fit.
List<Pill> _closest(Skill s, int n, {int from = 0}) => PillBank.cards
    .where((p) => p.isGraded && s.fitOf(p) == 0)
    .skip(from)
    .take(n)
    .toList();

/// Cards that ask and are one of [g]'s own (its genres or its moves).
List<Pill> _forArea(Goal g, int n) => PillBank.cards
    .where((p) => p.isGraded && (g.fitOf(p) ?? 2) < 2)
    .take(n)
    .toList();

/// Answers kept as the phone keeps them: [right] of them right, the rest
/// wrong, made today.
String _answers(List<Pill> cards, {required int right, int daysAgo = 0}) {
  final DateTime now = DateTime.now();
  final String on = dateKey(DateTime(now.year, now.month, now.day - daysAgo));
  return jsonEncode([
    for (final (int i, Pill p) in cards.indexed)
      {'c': null, 'k': i < right, 'p': p.id, 'd': on},
  ]);
}

void main() {
  setUpAll(loadFonts);
  setUp(PillBank.reset);

  late bool tools;
  setUp(() {
    tools = debugToolsOn;
    debugToolsOn = true;
  });
  tearDown(() {
    debugToolsOn = tools;
    DebugLooks.reset();
  });

  Future<void> phone(WidgetTester tester, Size size, {double text = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = text;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> show(
    WidgetTester tester,
    Widget child, {
    String language = 'en',
    bool scroll = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: scroll
            ? Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: child,
                ),
              )
            : child,
      ),
    );
    await tester.pump();
  }

  test('a phone without the tools ships What to learn as it is, whatever '
      'look a TestFlight build kept on it', () async {
    final AppState app = await readyApp({
      'knowit.skills': ['money'],
    });
    DebugLooks.learn.value = LearnLook.profile;
    debugToolsOn = false;
    expect(learnLook, DebugLooks.learnShips);
    expect(markedSkills(app), ['money']);
    final Pill money = _closest(Skill.money, 1).single;
    expect(skillMarkOf(money, markedSkills(app)), Skill.money);
    expect(goalUnsaid(app, marked: true), isTrue);
    expect(goalUnsaid(app, marked: false), isFalse);
  });

  group('A, the score alone', () {
    testWidgets('no card carries a skill\'s mark, the profile has no box, '
        'and Your journey opens on the score with nothing under it', (
      tester,
    ) async {
      await phone(tester, const Size(390, 844));
      final List<Pill> money = _closest(Skill.money, 6);
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.skills': ['money', 'fakes'],
          'knowit.judgements': _answers(money, right: 4),
        }),
      ) as AppState;
      DebugLooks.learn.value = LearnLook.score;
      expect(markedSkills(app), isEmpty);
      expect(skillMarkOf(money.first, markedSkills(app)), isNull);
      // A card for a goal kept by a build before says nothing of it.
      expect(goalUnsaid(app, marked: false), isTrue);

      await show(tester, LearnProfileBox(app: app));
      expect(find.byType(ProfileTraining), findsNothing);
      expect(find.byKey(const ValueKey('profile-skills')), findsNothing);

      await show(
        tester,
        TrainingChapter(app: app, skills: false, label: false),
      );
      expect(find.byKey(const ValueKey('training-score')), findsOneWidget);
      expect(find.byKey(const ValueKey('training-row-money')), findsNothing);
      expect(
        find.byKey(const ValueKey('training-other-critical')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('training-pick')), findsNothing);
      final l = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l.scoreTitle.toUpperCase()), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('B, one aim', () {
    testWidgets('at the end of the first run: Next waits for an aim, keeps '
        'the one picked as the reader\'s goal; Skip keeps none', (
      tester,
    ) async {
      await phone(tester, const Size(390, 844));
      final AppState app = await tester.runAsync(readyApp) as AppState;
      DebugLooks.learn.value = LearnLook.aim;
      await show(tester, AimScreen(app: app, firstRun: true), scroll: false);
      final Finder next = find.byKey(const ValueKey('aim-done'));
      expect(tester.widget<ChunkyButton>(next).onPressed, isNull);
      for (final Goal g in Goal.values) {
        expect(find.byKey(ValueKey('aim-${g.key}')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('aim-money')));
      await tester.pump();
      expect(tester.widget<ChunkyButton>(next).onPressed, isNotNull);
      await tester.tap(next);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(app.goals, ['money']);
      expect(aimOf(app), Goal.money);

      final AppState other = await tester.runAsync(readyApp) as AppState;
      await show(tester, AimScreen(app: other, firstRun: true), scroll: false);
      await tester.tap(find.byKey(const ValueKey('aim-people')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('aim-skip')));
      await tester.pumpAndSettle();
      expect(other.goals, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nothing under the question on the profile, which is the '
        'whole of it; in Your journey the aim in words, the week\'s cards of '
        'it and the answers on them; a card dealt for it says so', (
      tester,
    ) async {
      await phone(tester, const Size(390, 844));
      final List<Pill> cards = _forArea(Goal.money, 5);
      final String today = dateKey(DateTime.now());
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.goals': ['money'],
          'knowit.readDays': jsonEncode({
            today: [for (final Pill p in cards) p.id],
          }),
          'knowit.judgements': _answers(cards, right: 3),
        }),
      ) as AppState;
      DebugLooks.learn.value = LearnLook.aim;
      final l = lookupAppLocalizations(const Locale('en'));
      expect(markedSkills(app), isEmpty);
      expect(scoredSkills(app), isEmpty);
      expect(goalUnsaid(app, marked: false), isFalse);
      expect(learnAsksAim, isTrue);

      await show(tester, LearnProfileBox(app: app));
      expect(find.byType(ProfileTraining), findsNothing);
      expect(find.byType(Text), findsNothing);

      expect(aimTally(app, Goal.money), (cards: 5, answers: 5, right: 3));
      await show(tester, AimPanel(app: app, label: false));
      expect(find.text(l.goalMoney), findsOneWidget);
      expect(find.text(l.aimWeek(5)), findsOneWidget);
      expect(find.text(l.answersRightOf(3, 5)), findsOneWidget);
      // The chapter's head says "Your goal"; the panel does not again.
      expect(find.text(l.whyGoalRow.toUpperCase()), findsNothing);
      expect(find.byKey(const ValueKey('journey-aim-open')), findsOneWidget);

      // With no aim, what one does and the way to pick it.
      final AppState none = await tester.runAsync(readyApp) as AppState;
      await show(tester, AimPanel(app: none));
      expect(find.text(l.aimNone), findsOneWidget);
      expect(find.byKey(const ValueKey('journey-aim-pick')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('D, the aim read', () {
    test('every aim takes four skills, its own area\'s among them', () {
      for (final Goal g in Goal.values) {
        final List<Skill> skills = aimSkills(g);
        expect(skills.toSet(), hasLength(4), reason: g.key);
        expect(skills.any((s) => s.area == g.key), isTrue, reason: g.key);
      }
      expect(aimSkills(null).toSet(), hasLength(4));
    });

    test('the reading ranks the aim\'s skills alone, strongest first: the '
        'sharpest the first, the blind spot the last', () async {
      final AppState app = await readyApp({
        'knowit.goals': ['decide'],
        'knowit.judgements': jsonEncode([
          ...jsonDecode(_answers(_closest(Skill.decisions, 6), right: 6))
              as List,
          ...jsonDecode(_answers(_closest(Skill.persuade, 6), right: 0))
              as List,
          ...jsonDecode(_answers(_closest(Skill.money, 6), right: 6)) as List,
        ]),
      });
      final AimReading reading = aimReading(app, Goal.decide);
      final List<Skill> taken = aimSkills(Goal.decide);
      expect(reading.ranked, isNotEmpty);
      for (final SkillTally t in [...reading.ranked, ...reading.few]) {
        expect(taken, contains(t.skill));
      }
      for (int i = 1; i < reading.ranked.length; i++) {
        expect(
          reading.ranked[i].rank,
          lessThanOrEqualTo(reading.ranked[i - 1].rank),
        );
      }
      // Money and saving is not a skill everyday decisions take.
      expect(reading.ranked.map((t) => t.skill), isNot(contains(Skill.money)));
      expect(reading.blind?.skill, Skill.persuade);
      expect(reading.sharpest, reading.ranked.first);
      DebugLooks.learn.value = LearnLook.aimProfile;
      expect(markedSkills(app), isEmpty);
      expect(goalUnsaid(app, marked: false), isFalse);
      expect(learnAsksAim, isTrue);
    });

    testWidgets('on the profile: where the reader sees clearly and their '
        'blind spot on either plan, what Astute+ adds on the free plan; '
        'with no aim, the way to the question', (tester) async {
      await phone(tester, const Size(390, 844));
      Map<String, Object> reader({required bool plus}) => {
        'knowit.debug.learn': 'aimProfile',
        'knowit.plus': plus,
        'knowit.goals': ['decide'],
        'knowit.judgements': jsonEncode([
          ...jsonDecode(_answers(_closest(Skill.decisions, 6), right: 6))
              as List,
          ...jsonDecode(_answers(_closest(Skill.persuade, 6), right: 0))
              as List,
        ]),
      };
      final l = lookupAppLocalizations(const Locale('en'));
      DebugLooks.learn.value = LearnLook.aimProfile;

      final AppState free = await tester.runAsync(
        () => readyApp(reader(plus: false)),
      ) as AppState;
      await show(tester, LearnProfileBox(app: free));
      expect(find.text(l.readTitle.toUpperCase()), findsOneWidget);
      expect(find.text(l.strengthsBest.toUpperCase()), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-read-blind')), findsOneWidget);
      expect(find.text(l.skillName('persuade')), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-read-locked')), findsOneWidget);

      final AppState plus =
          await tester.runAsync(() => readyApp(reader(plus: true))) as AppState;
      await show(tester, LearnProfileBox(app: plus));
      expect(find.byKey(const ValueKey('profile-read-blind')), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-read-locked')), findsNothing);

      final AppState none = await tester.runAsync(
        () => readyApp({'knowit.debug.learn': 'aimProfile'}),
      ) as AppState;
      await show(tester, LearnProfileBox(app: none));
      expect(find.text(l.readNoAim), findsOneWidget);

      final AppState fresh = await tester.runAsync(
        () => readyApp({
          'knowit.debug.learn': 'aimProfile',
          'knowit.goals': ['decide'],
        }),
      ) as AppState;
      await show(tester, LearnProfileBox(app: fresh));
      expect(find.text(l.readEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('in Your journey: the aim\'s skills ranked, the blind spot '
        'named and five cards to practise it, then the rest of the profile', (
      tester,
    ) async {
      await phone(tester, const Size(390, 844));
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.plus': true,
          'knowit.goals': ['decide'],
          'knowit.judgements': jsonEncode([
            ...jsonDecode(_answers(_closest(Skill.decisions, 6), right: 5))
                as List,
            ...jsonDecode(_answers(_closest(Skill.persuade, 6), right: 1))
                as List,
            ...jsonDecode(_answers(_closest(Skill.money, 6), right: 4)) as List,
          ]),
        }),
      ) as AppState;
      final l = lookupAppLocalizations(const Locale('en'));
      DebugLooks.learn.value = LearnLook.aimProfile;
      await show(tester, AimReadPanel(app: app));
      final AimReading reading = aimReading(app, Goal.decide);
      for (final SkillTally t in reading.ranked) {
        expect(find.byKey(ValueKey('strength-${t.skill.name}')), findsWidgets);
      }
      expect(find.text(l.readBlind.toUpperCase()), findsOneWidget);
      expect(
        find.text(l.strengthsPractice(l.skillName(reading.blind!.skill.name))),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('journey-read-others')), findsOneWidget);
      expect(find.text(l.readOthers.toUpperCase()), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('E, a focus a week', () {
    // A Wednesday: its week began on Monday the 23rd.
    final DateTime wednesday = DateTime(2026, 11, 25, 10);

    /// Answers on [cards] made on [day], the first [right] of them right.
    String answered(List<Pill> cards, int right, DateTime day) => jsonEncode([
      for (final (int i, Pill p) in cards.indexed)
        {'c': null, 'k': i < right, 'p': p.id, 'd': dateKey(day)},
    ]);

    test('on the free plan the aim\'s four in turn, a week each, the same '
        'all week; the turn follows the aim', () async {
      Future<WeekFocus> focusOn(DateTime day, String aim) async {
        final AppState app = await readyApp({
          'knowit.goals': [aim],
        }, () => day);
        return weekFocusOf(app);
      }

      for (final Goal g in Goal.values) {
        final List<Skill> turn = aimSkills(g);
        final WeekFocus mon = await focusOn(DateTime(2026, 11, 23, 8), g.key);
        final WeekFocus sun = await focusOn(DateTime(2026, 11, 29, 22), g.key);
        final WeekFocus next = await focusOn(DateTime(2026, 11, 30, 8), g.key);
        expect(mon.skill, sun.skill, reason: g.key);
        expect(mon.chosen, isFalse);
        expect(mon.start, DateTime(2026, 11, 23));
        expect(turn, contains(mon.skill));
        expect(
          turn.indexOf(next.skill),
          (turn.indexOf(mon.skill) + 1) % turn.length,
          reason: g.key,
        );
      }
    });

    test('on Astute+ the aim\'s skill the reader got most wrong before the '
        'week, held all week whatever this week\'s answers say', () async {
      final DateTime friday = DateTime(2026, 11, 20, 12);
      Map<String, Object> reader({List<Object> more = const []}) => {
        'knowit.plus': true,
        'knowit.goals': ['decide'],
        'knowit.judgements': jsonEncode([
          ...jsonDecode(answered(_closest(Skill.decisions, 6), 6, friday))
              as List,
          ...jsonDecode(answered(_closest(Skill.critical, 6), 6, friday))
              as List,
          ...jsonDecode(answered(_closest(Skill.numbers, 6), 5, friday))
              as List,
          ...jsonDecode(answered(_closest(Skill.persuade, 6), 0, friday))
              as List,
          ...more,
        ]),
      };
      final AppState app = await readyApp(reader(), () => wednesday);
      final WeekFocus focus = weekFocusOf(app);
      expect(focus.skill, Skill.persuade);
      expect(focus.chosen, isTrue);

      // Persuasion all right this week does not move this week's skill.
      final AppState later = await readyApp(
        reader(
          more: (jsonDecode(
            answered(_closest(Skill.persuade, 6, from: 6), 6, wednesday),
          ) as List).cast<Object>(),
        ),
        () => wednesday,
      );
      expect(weekFocusOf(later).skill, Skill.persuade);

      // On the free plan, the turn.
      final AppState free = await readyApp({
        ...reader(),
        'knowit.plus': false,
      }, () => wednesday);
      expect(weekFocusOf(free).chosen, isFalse);
    });

    test('the week day by day: the answers on cards that train the skill, '
        'right and in all, and nothing for the days to come; its mark on '
        'the cards, the day\'s own leaning to it', () async {
      final AppState probe = await readyApp({
        'knowit.goals': ['decide'],
      }, () => wednesday);
      final Skill skill = weekFocusOf(probe).skill;
      final List<Pill> cards = _closest(skill, 3);
      final AppState app = await readyApp({
        'knowit.goals': ['decide'],
        'knowit.judgements': jsonEncode([
          {'c': null, 'k': true, 'p': cards[0].id, 'd': '2026-11-23'},
          {'c': null, 'k': false, 'p': cards[1].id, 'd': '2026-11-23'},
          {'c': null, 'k': true, 'p': cards[2].id, 'd': '2026-11-25'},
        ]),
      }, () => wednesday);
      final WeekFocus focus = weekFocusOf(app);
      expect(focus.skill, skill);
      final FocusWeek week = focusWeek(app, focus);
      expect(week.days, hasLength(7));
      expect(week.days[0], (answers: 2, right: 1));
      expect(week.days[1], (answers: 0, right: 0));
      expect(week.days[2], (answers: 1, right: 1));
      expect(week.days.skip(3), everyElement(isNull));
      expect((week.answers, week.right), (3, 2));

      DebugLooks.learn.value = LearnLook.weekly;
      expect(markedSkills(app), [focus.skill.name]);
      expect(scoredSkills(app), isEmpty);
      expect(learnAsksAim, isTrue);
      final Map<String, double> leaned = withFocusLean(app, const {});
      expect(leaned, isNotEmpty);
      for (final String g in focus.skill.genres) {
        expect(leaned['genre:$g'], kFocusLean);
      }
      DebugLooks.learn.value = LearnLook.today;
      expect(withFocusLean(app, const {'genre:x': 0.2}), {'genre:x': 0.2});
    });

    test('Explore has the week\'s shelf over the aim\'s in E alone', () async {
      final AppState app = await readyApp({
        'knowit.goals': ['decide'],
      });
      const List<ExploreSection> sections = [
        ExploreSection(id: 'three', block: 'three'),
        ExploreSection(id: 'continue', block: 'continue'),
        ExploreSection(id: 'cover', block: 'cover'),
      ];
      DebugLooks.learn.value = LearnLook.weekly;
      expect(
        [for (final ExploreSection s in withAimShelf(app, sections)) s.id],
        ['three', 'continue', 'focus', 'goal', 'cover'],
      );
      for (final LearnLook look in LearnLook.values) {
        if (look == LearnLook.weekly) continue;
        DebugLooks.learn.value = look;
        expect(
          [for (final ExploreSection s in withAimShelf(app, sections)) s.id],
          ['three', 'continue', 'goal', 'cover'],
          reason: look.name,
        );
      }
    });

    testWidgets('on the profile: the week\'s skill, its days and how the '
        'week is going, last week\'s; on Sunday how it went and the next; '
        'on the free plan what Astute+ changes', (tester) async {
      await phone(tester, const Size(390, 844));
      final l = lookupAppLocalizations(const Locale('en'));
      DebugLooks.learn.value = LearnLook.weekly;
      final AppState probe = await tester.runAsync(
        () => readyApp({
          'knowit.goals': ['decide'],
        }, () => DateTime(2026, 11, 18, 10)),
      ) as AppState;
      final Skill lastSkill = weekFocusOf(probe).skill;
      Map<String, Object> reader({required bool plus}) => {
        'knowit.debug.learn': 'weekly',
        'knowit.plus': plus,
        'knowit.goals': ['decide'],
        'knowit.judgements': answered(
          _closest(lastSkill, 2),
          2,
          DateTime(2026, 11, 18),
        ),
      };

      final AppState free = await tester.runAsync(
        () => readyApp(reader(plus: false), () => wednesday),
      ) as AppState;
      await show(tester, LearnProfileBox(app: free));
      final WeekFocus focus = weekFocusOf(free);
      expect(find.byKey(const ValueKey('profile-focus')), findsOneWidget);
      expect(find.text(l.focusTitle.toUpperCase()), findsOneWidget);
      expect(find.text(l.skillName(focus.skill.name)), findsOneWidget);
      expect(find.text(l.focusFromGoal), findsOneWidget);
      expect(find.byKey(const ValueKey('focus-days')), findsOneWidget);
      expect(find.byKey(const ValueKey('focus-last')), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-focus-plus')), findsOneWidget);

      final AppState plus = await tester.runAsync(
        () => readyApp(reader(plus: true), () => wednesday),
      ) as AppState;
      await show(tester, LearnProfileBox(app: plus));
      expect(find.byKey(const ValueKey('profile-focus-plus')), findsNothing);

      final AppState sunday = await tester.runAsync(
        () => readyApp(reader(plus: false), () => DateTime(2026, 11, 29, 20)),
      ) as AppState;
      await show(tester, LearnProfileBox(app: sunday));
      expect(find.byKey(const ValueKey('focus-result')), findsOneWidget);
      expect(find.byKey(const ValueKey('focus-next')), findsOneWidget);
      expect(find.byKey(const ValueKey('focus-last')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('C, where you are strong', () {
    test('ranked from the answers, strongest first, a skill with too few '
        'answers after the ranked; nothing picked', () async {
      final List<Pill> money = _closest(Skill.money, 6);
      final List<Pill> lead = _closest(Skill.lead, 6);
      final List<Pill> focus = _closest(Skill.focus, 2);
      final AppState app = await readyApp({
        'knowit.judgements': jsonEncode([
          ...jsonDecode(_answers(money, right: 6)) as List,
          ...jsonDecode(_answers(lead, right: 1)) as List,
          ...jsonDecode(_answers(focus, right: 2)) as List,
        ]),
      });
      final List<SkillTally> tallies = skillTallies(app);
      expect(tallies, hasLength(Skill.values.length));
      final List<SkillTally> ranked = [
        for (final SkillTally t in tallies)
          if (t.answers >= kStrengthAnswers) t,
      ];
      expect(ranked.first.right, ranked.first.answers);
      expect(Skill.money.fitOf(money.first), 0);
      expect(
        ranked.where((t) => t.skill == Skill.money).single.rank,
        ranked.first.rank,
      );
      // Leadership, one right of six, is as weak as the weakest: a card of
      // it can train general knowledge too, which then holds the same.
      final SkillTally leadTally = ranked.firstWhere(
        (t) => t.skill == Skill.lead,
      );
      expect(leadTally.right, 1);
      expect(leadTally.rank, ranked.last.rank);
      for (int i = 1; i < ranked.length; i++) {
        expect(ranked[i].rank, lessThanOrEqualTo(ranked[i - 1].rank));
      }
      // Two right of two is not a strong point yet.
      final SkillTally few = tallies.firstWhere((t) => t.skill == Skill.focus);
      expect(few.answers, lessThan(kStrengthAnswers));
      expect(tallies.indexOf(few), greaterThanOrEqualTo(ranked.length));
    });

    test('the cards to practise are five not yet read, that ask, and train '
        'the skill', () async {
      final List<Pill> read = _closest(Skill.persuade, 3);
      final AppState app = await readyApp({
        'knowit.seenIds': [for (final Pill p in read) p.id],
      });
      final List<Pill> cards = practiceCards(app, Skill.persuade);
      expect(cards, hasLength(5));
      for (final Pill p in cards) {
        expect(p.isGraded, isTrue);
        expect(Skill.persuade.trains(p), isTrue);
        expect(read.map((r) => r.id), isNot(contains(p.id)));
      }
      // The closest first.
      expect(Skill.persuade.fitOf(cards.first), 0);
    });

    testWidgets('on the profile: the strong point; on the free plan the '
        'rest behind a lock, on Astute+ where the reader slips most', (
      tester,
    ) async {
      await phone(tester, const Size(390, 844));
      final List<Pill> money = _closest(Skill.money, 6);
      final List<Pill> lead = _closest(Skill.lead, 6);
      Map<String, Object> reader({required bool plus}) => {
        'knowit.debug.learn': 'profile',
        'knowit.plus': plus,
        'knowit.judgements': jsonEncode([
          ...jsonDecode(_answers(money, right: 6)) as List,
          ...jsonDecode(_answers(lead, right: 1)) as List,
        ]),
      };
      final l = lookupAppLocalizations(const Locale('en'));

      final AppState free = await tester.runAsync(
        () => readyApp(reader(plus: false)),
      ) as AppState;
      final List<SkillTally> ranked = [
        for (final SkillTally t in skillTallies(free))
          if (t.answers >= kStrengthAnswers) t,
      ];
      final String best = l.skillName(ranked.first.skill.name);
      final String weakest = l.skillName(ranked.last.skill.name);
      await show(tester, LearnProfileBox(app: free));
      expect(find.text(l.strengthsBest.toUpperCase()), findsOneWidget);
      expect(find.text(best), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-strengths-locked')),
        findsOneWidget,
      );
      expect(find.text(weakest), findsNothing);

      final AppState plus =
          await tester.runAsync(() => readyApp(reader(plus: true))) as AppState;
      await show(tester, LearnProfileBox(app: plus));
      expect(find.text(l.strengthsWeak.toUpperCase()), findsOneWidget);
      expect(find.text(weakest), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-strengths-locked')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('in Your journey: every skill ranked with its right answers '
        'out of those given, the ones with too few named, and the weakest to '
        'practise', (tester) async {
      await phone(tester, const Size(390, 844));
      final List<Pill> money = _closest(Skill.money, 6);
      final List<Pill> lead = _closest(Skill.lead, 6);
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.plus': true,
          'knowit.judgements': jsonEncode([
            ...jsonDecode(_answers(money, right: 5)) as List,
            ...jsonDecode(_answers(lead, right: 2)) as List,
          ]),
        }),
      ) as AppState;
      final l = lookupAppLocalizations(const Locale('en'));
      await show(tester, StrengthsPanel(app: app));
      final SkillTally top = skillTallies(app).first;
      expect(
        find.descendant(
          of: find.byKey(ValueKey('strength-${top.skill.name}')),
          matching: find.text(l.answersRightOf(top.right, top.answers)),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('journey-strengths-few')),
        findsOneWidget,
      );
      final List<SkillTally> ranked = [
        for (final SkillTally t in skillTallies(app))
          if (t.answers >= kStrengthAnswers) t,
      ];
      expect(
        find.text(l.strengthsPractice(l.skillName(ranked.last.skill.name))),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('laid out in the long languages at a large text size on a '
      'small phone: the question, the aim and the ranking keep every word, '
      'nothing cut or run over', (tester) async {
    await phone(tester, const Size(320, 568), text: 1.3);
    final List<Pill> money = _closest(Skill.money, 6);
    final List<Pill> lead = _closest(Skill.lead, 6);
    final AppState app = await tester.runAsync(
      () => readyApp({
        'knowit.plus': true,
        'knowit.goals': ['decide'],
        'knowit.judgements': jsonEncode([
          ...jsonDecode(_answers(money, right: 5)) as List,
          ...jsonDecode(_answers(lead, right: 2)) as List,
        ]),
      }),
    ) as AppState;
    for (final String language in ['de', 'ru', 'fr', 'pl', 'it', 'ja']) {
      await show(
        tester,
        AimScreen(app: app, firstRun: true),
        language: language,
        scroll: false,
      );
      expect(tester.takeException(), isNull, reason: '$language question');
      for (final Widget panel in [
        AimPanel(app: app),
        StrengthsPanel(app: app),
        StrengthsBox(app: app),
        AimReadPanel(app: app),
        AimReadBox(app: app),
        FocusPanel(app: app),
        FocusBox(app: app),
      ]) {
        await show(tester, panel, language: language);
        expect(
          tester.takeException(),
          isNull,
          reason: '$language ${panel.runtimeType}',
        );
      }
    }
  });

  testWidgets('every look, on a small phone in German, on either plan and at '
      'two text sizes: its box on the profile, its head of Your journey and, '
      'in E, the sheet its mark opens, nothing cut or run over', (
    tester,
  ) async {
    // Answers on every skill, half of them a week back, so every box and
    // panel is at its fullest: a strong point, a blind spot, last week's.
    final List<Object> answers = [
      for (final (int i, Skill s) in Skill.values.indexed)
        ...jsonDecode(
          _answers(_closest(s, 5), right: i % 5, daysAgo: i.isEven ? 0 : 8),
        ) as List,
    ];
    for (final double text in [1.0, 1.3]) {
      await phone(tester, const Size(320, 568), text: text);
      for (final bool plus in [false, true]) {
        final AppState app = await tester.runAsync(
          () => readyApp({
            'knowit.plus': plus,
            'knowit.goals': ['news'],
            'knowit.skills': ['fakes', 'numbers', 'science'],
            'knowit.judgements': jsonEncode(answers),
          }),
        ) as AppState;
        for (final LearnLook look in LearnLook.values) {
          DebugLooks.learn.value = look;
          final List<Widget> drawn = [
            LearnProfileBox(app: app),
            switch (look) {
              LearnLook.today || LearnLook.mix => TrainingChapter(app: app),
              LearnLook.score => TrainingChapter(
                app: app,
                skills: false,
                label: false,
              ),
              LearnLook.aim => AimPanel(app: app, label: false),
              LearnLook.profile => StrengthsPanel(app: app, label: false),
              LearnLook.aimProfile => AimReadPanel(app: app),
              LearnLook.weekly => FocusPanel(app: app),
            },
            if (look == LearnLook.weekly)
              FocusMarkSheet(app: app, skill: weekFocusOf(app).skill),
          ];
          for (final Widget widget in drawn) {
            await show(tester, widget, language: 'de');
            expect(
              tester.takeException(),
              isNull,
              reason:
                  '${look.name} ${plus ? 'plus' : 'free'} $text '
                  '${widget.runtimeType}',
            );
          }
        }
      }
    }
  });
}
