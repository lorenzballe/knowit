// What to learn, three other ways, as the developer tools try them beside
// the one that ships (lib/widgets/learn_looks.dart, DebugLooks.learn):
// A, the Astute score alone; B, one aim, where the reader wants to be
// sharper, asked once and said in words; C, nothing picked, the skills
// ranked from the reader's answers, the weakest to practise.
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
    expect(learnLook, LearnLook.today);
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

    testWidgets('on the profile: the aim in words, the week\'s cards of it '
        'and the answers on them, and on the free plan what Astute+ adds', (
      tester,
    ) async {
      await phone(tester, const Size(390, 844));
      final List<Pill> cards = _forArea(Goal.money, 5);
      final String today = dateKey(DateTime.now());
      Map<String, Object> reader({required bool plus}) => {
        'knowit.debug.learn': 'aim',
        'knowit.plus': plus,
        'knowit.goals': ['money'],
        'knowit.readDays': jsonEncode({
          today: [for (final Pill p in cards) p.id],
        }),
        'knowit.judgements': _answers(cards, right: 3),
      };
      final l = lookupAppLocalizations(const Locale('en'));

      final AppState free = await tester.runAsync(
        () => readyApp(reader(plus: false)),
      ) as AppState;
      expect(aimTally(free, Goal.money), (cards: 5, answers: 5, right: 3));
      await show(tester, LearnProfileBox(app: free));
      expect(find.byKey(const ValueKey('profile-aim-card')), findsOneWidget);
      expect(find.text(l.goalMoney), findsOneWidget);
      expect(find.text(l.aimWeek(5)), findsOneWidget);
      expect(find.text(l.answersRightOf(3, 5)), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-aim-plus')), findsOneWidget);
      expect(find.byType(ProfileTraining), findsNothing);

      final AppState plus =
          await tester.runAsync(() => readyApp(reader(plus: true))) as AppState;
      await show(tester, LearnProfileBox(app: plus));
      expect(find.byKey(const ValueKey('profile-aim-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-aim-plus')), findsNothing);

      // With no aim, what one does, and the way to pick it.
      final AppState none = await tester.runAsync(
        () => readyApp({'knowit.debug.learn': 'aim'}),
      ) as AppState;
      await show(tester, LearnProfileBox(app: none));
      expect(find.text(l.aimNone), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('Explore has the aim\'s shelf after Today\'s five and what to '
        'continue, only in B and only with an aim', () async {
      const List<ExploreSection> sections = [
        ExploreSection(id: 'three', block: 'three'),
        ExploreSection(id: 'your-five', block: 'your-five'),
        ExploreSection(id: 'continue', block: 'continue'),
        ExploreSection(id: 'news-today', block: 'news-today'),
      ];
      final AppState app = await readyApp({
        'knowit.debug.learn': 'aim',
        'knowit.goals': ['news'],
      });
      expect(learnLook, LearnLook.aim);
      expect(
        [for (final s in withAimShelf(app, sections)) s.id],
        ['three', 'your-five', 'continue', 'goal', 'news-today'],
      );
      for (final LearnLook look in [
        LearnLook.today,
        LearnLook.score,
        LearnLook.profile,
      ]) {
        DebugLooks.learn.value = look;
        expect(withAimShelf(app, sections), same(sections), reason: look.name);
      }
      final AppState none = await readyApp({'knowit.debug.learn': 'aim'});
      expect(learnLook, LearnLook.aim);
      expect(withAimShelf(none, sections), same(sections));
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
        AimBox(app: app),
        StrengthsPanel(app: app),
        StrengthsBox(app: app),
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
}
