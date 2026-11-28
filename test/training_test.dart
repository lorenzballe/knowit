// The reader's training (lib/widgets/training.dart): their Astute score and
// the skills they picked with their score in each, first in Your journey —
// the one number large, the skills tight under it and the others two to a
// row below — and as a box on the profile. Nothing rises over the finished
// day any more: the scores count up in the journey (test/journey_test.dart).
//
//   flutter test test/training_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/skill_levels.dart';
import 'package:astuto/data/skill_scores.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/skills_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/skill_score.dart';
import 'package:astuto/widgets/skills_sheet.dart';
import 'package:astuto/widgets/training.dart';

import 'explore/core_harness.dart';

/// [n] cards of the bank that train [s], from the [from]th; with [not],
/// only those that do not also train it.
List<String> training(Skill s, int n, {int from = 0, Skill? not}) => [
  for (final Pill p in trainingCards(s, n, from: from, not: not)) p.id,
];

/// The same as cards, only those with a right answer.
List<Pill> trainingCards(Skill s, int n, {int from = 0, Skill? not}) => PillBank
    .cards
    .where((p) => p.isGraded && s.trains(p) && !(not?.trains(p) ?? false))
    .skip(from)
    .take(n)
    .toList();

String _n(int v) => NumberFormat.decimalPattern('en').format(v);

void main() {
  setUpAll(loadFonts);
  setUp(PillBank.reset);

  Future<void> phone(WidgetTester tester, Size size, {double text = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = text;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> show(
    WidgetTester tester,
    Widget Function(BuildContext context) child, {
    String language = 'en',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child(context),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('on the profile', () {
    testWidgets('the skills picked, three at most, each with its score and '
        'its week; the box opens What to learn', (tester) async {
      await phone(tester, const Size(390, 844));
      final List<Pill> money = trainingCards(Skill.money, 5);
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.skills': ['money', 'decisions', 'fakes', 'focus', 'lead'],
          'knowit.seenIds': [for (final Pill p in money) p.id],
          'knowit.judgements': judgementsOf(money),
        }),
      ) as AppState;
      final SkillScore score = scoreBookOf(app).of(Skill.money);
      expect(score.now, greaterThan(0));
      await show(tester, (_) => ProfileTraining(app: app));
      final l = lookupAppLocalizations(const Locale('en'));
      for (final String k in ['money', 'decisions', 'fakes']) {
        expect(find.byKey(ValueKey('profile-training-$k')), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('profile-training-focus')),
        findsNothing,
      );
      expect(find.text(l.trainingMore(2)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('profile-training-money')),
          matching: find.text(_n(score.now)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('profile-training-money')),
          matching: find.text(l.scoreWeek('+${score.week}')),
        ),
        findsOneWidget,
      );
      // The box opens What to learn in a sheet, as the owner picked it: a
      // page like the goal's, the twelve one under another, each with its
      // line, the picked ones ticked, more than one at once.
      await tester.tap(find.byKey(const ValueKey('profile-skills')));
      await tester.pumpAndSettle();
      expect(find.byType(SkillsSheet), findsOneWidget);
      expect(find.text(l.skillLine('money')), findsOneWidget);
      for (final Skill s in Skill.values) {
        expect(
          find.byKey(ValueKey('profile-skills-${s.name}')),
          findsOneWidget,
          reason: s.name,
        );
      }
      SkillRow tile(String k) =>
          tester.widget<SkillRow>(find.byKey(ValueKey('profile-skills-$k')));
      expect(tile('money').on, isTrue);
      expect(tile('science').on, isFalse);
      // A tap picks a skill at once, and another lets it go.
      final Finder science = find.byKey(
        const ValueKey('profile-skills-science'),
      );
      await tester.ensureVisible(science);
      await tester.pumpAndSettle();
      await tester.tap(science);
      await tester.pumpAndSettle();
      expect(app.skills, contains('science'));
      expect(tile('science').on, isTrue);
      await tester.tap(science);
      await tester.pumpAndSettle();
      expect(app.skills, isNot(contains('science')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('with none picked, what training is, and the way to pick', (
      tester,
    ) async {
      await phone(tester, const Size(390, 844));
      final AppState app = await tester.runAsync(readyApp) as AppState;
      await show(tester, (_) => ProfileTraining(app: app));
      final l = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l.trainingEmpty), findsOneWidget);
      expect(find.byType(SkillBadge), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('in Your journey', () {
    testWidgets('the Astute score at the head, large; each skill picked '
        'under it, tight, with its score and its week, or how it starts; the '
        'others two to a row with theirs; Edit opens What to learn', (
      tester,
    ) async {
      await phone(tester, const Size(390, 1400));
      final List<Pill> money = trainingCards(
        Skill.money,
        5,
        not: Skill.numbers,
      );
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.skills': ['money', 'numbers'],
          'knowit.seenIds': [for (final Pill p in money) p.id],
          'knowit.judgements': judgementsOf(money),
        }),
      ) as AppState;
      final ScoreBook book = scoreBookOf(app);
      await show(
        tester,
        (context) => Column(
          children: [
            TrainingChapter.change(context, app),
            TrainingChapter(app: app),
          ],
        ),
      );
      final l = lookupAppLocalizations(const Locale('en'));
      expect(find.byKey(const ValueKey('training-row-money')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('training-row-numbers')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('training-score')),
          matching: find.text(_n(book.overall.now)),
        ),
        findsOneWidget,
      );
      expect(book.overall.now, greaterThan(0));
      Finder inRow(String skill, String text) => find.descendant(
        of: find.byKey(ValueKey('training-row-$skill')),
        matching: find.text(text),
      );
      final SkillScore m = book.of(Skill.money);
      expect(inRow('money', _n(m.now)), findsOneWidget);
      expect(inRow('money', l.scoreWeek('+${m.week}')), findsOneWidget);
      expect(inRow('numbers', l.scoreStart), findsOneWidget);
      // Nobody starts high: a skill no answer has moved is at nothing.
      expect(inRow('numbers', _n(0)), findsOneWidget);
      for (final Skill s in Skill.values) {
        final bool picked = s == Skill.money || s == Skill.numbers;
        expect(
          find.byKey(ValueKey('training-other-${s.name}')),
          picked ? findsNothing : findsOneWidget,
          reason: s.name,
        );
      }
      // The one number stays large; the skills are a size and more under
      // it, a row each no taller than its badge and two lines; the others
      // sit two to a row.
      double sizeOf(Finder text) => tester.widget<Text>(text).style!.fontSize!;
      final double big = sizeOf(
        find.descendant(
          of: find.byKey(const ValueKey('training-score')),
          matching: find.text(_n(book.overall.now)),
        ),
      );
      expect(sizeOf(inRow('money', _n(m.now))), lessThan(big / 2));
      expect(
        tester.getSize(find.byKey(const ValueKey('training-row-money'))).height,
        lessThan(48),
      );
      final Offset a = tester.getTopLeft(
        find.byKey(const ValueKey('training-other-critical')),
      );
      final Offset b = tester.getTopLeft(
        find.byKey(const ValueKey('training-other-decisions')),
      );
      expect(b.dy, a.dy, reason: 'two to a row');
      expect(b.dx, greaterThan(a.dx));
      // As it ships, the owner's mix: the reading of the answers under the
      // scores, where the reader sees clearly and their blind spot.
      expect(
        find.byKey(const ValueKey('profile-skills-reading')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('training-change')));
      await tester.pumpAndSettle();
      expect(find.byType(SkillsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('in Now, picked in the debug section, What to learn as it '
        'was: the box opens its screen, the chapter has no reading', (
      tester,
    ) async {
      await phone(tester, const Size(390, 1400));
      final bool tools = debugToolsOn;
      debugToolsOn = true;
      addTearDown(() {
        debugToolsOn = tools;
        DebugLooks.reset();
      });
      final List<Pill> money = trainingCards(Skill.money, 5);
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.skills': ['money', 'numbers'],
          'knowit.seenIds': [for (final Pill p in money) p.id],
          'knowit.judgements': judgementsOf(money),
        }),
      ) as AppState;
      // Picked once the app has read the phone's own, as in the section.
      DebugLooks.learn.value = LearnLook.today;
      await show(tester, (_) => TrainingChapter(app: app));
      expect(
        find.byKey(const ValueKey('profile-skills-reading')),
        findsNothing,
      );
      await show(tester, (_) => ProfileTraining(app: app));
      await tester.tap(find.byKey(const ValueKey('profile-skills')));
      await tester.pumpAndSettle();
      expect(find.byType(SkillsScreen), findsOneWidget);
      expect(find.byType(SkillsSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with none picked, the way to pick', (tester) async {
      await phone(tester, const Size(390, 1400));
      final AppState app = await tester.runAsync(readyApp) as AppState;
      await show(tester, (_) => TrainingChapter(app: app));
      await tester.tap(find.byKey(const ValueKey('training-pick')));
      await tester.pumpAndSettle();
      expect(find.byType(SkillsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('in every language', () {
    for (final String language in AppLocalizations.supportedLocales.map(
      (l) => l.languageCode,
    )) {
      testWidgets('the profile\'s box and the journey\'s chapter fit the '
          'smallest phone at a large text size in $language', (tester) async {
        await phone(tester, const Size(320, 568), text: 1.3);
        final AppState app = await tester.runAsync(
          () => readyApp({
            'knowit.skills': ['science', 'people', 'fakes', 'lead'],
          }),
        ) as AppState;
        await show(
          tester,
          (_) => Column(
            children: [
              ProfileTraining(app: app),
              TrainingChapter(app: app),
            ],
          ),
          language: language,
        );
        expect(tester.takeException(), isNull, reason: 'profile, journey');
      });
    }
  });
}
