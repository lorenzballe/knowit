// The reader's training (lib/widgets/training.dart): their Astute score and
// the skills they picked with their score in each, first in Your journey and
// as a box on the profile, and the sheet that rises when the day's cards are
// done, each score counting from where it stood that morning.
//
//   flutter test test/training_test.dart
import 'dart:convert';

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
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/skill_score.dart';
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

  group('what the day did', () {
    test('the skills picked that today\'s cards trained or today\'s answers '
        'moved, the most moved first, each from where it stood last night; '
        'a card back for another go is not one of the day\'s', () async {
      final List<Pill> money = trainingCards(
        Skill.money,
        4,
        not: Skill.numbers,
      );
      final List<Pill> numbers = trainingCards(
        Skill.numbers,
        2,
        not: Skill.money,
      );
      final AppState app = await readyApp({
        'knowit.skills': ['numbers', 'money'],
        'knowit.seenIds': [
          for (final Pill p in [...money, ...numbers]) p.id,
        ],
        // Three money cards right today, both numbers cards wrong.
        'knowit.judgements': jsonEncode([
          ...jsonDecode(judgementsOf(money.take(3))) as List,
          ...jsonDecode(judgementsOf(numbers, right: false)) as List,
        ]),
      });
      app.todaysDeck = [...money, ...numbers];
      app.reviewIdsToday = {money[3].id};
      final List<DayTraining> day = dayTrainingOf(app);
      expect(day.map((d) => d.skill).toSet(), {Skill.money, Skill.numbers});
      final DayTraining m = day.firstWhere((d) => d.skill == Skill.money);
      final DayTraining n = day.firstWhere((d) => d.skill == Skill.numbers);
      expect(m.plus, 3);
      expect(n.plus, 2);
      expect(m.before, kScoreStart);
      expect(m.moved, greaterThan(0));
      expect(n.moved, lessThan(0));
      expect(day.first.moved.abs(), greaterThanOrEqualTo(day.last.moved.abs()));
    });

    test('nothing when the reader picked no skill', () async {
      final AppState app = await readyApp({
        'knowit.seenIds': training(Skill.money, 3),
      });
      app.todaysDeck = [
        for (final String id in training(Skill.money, 3)) PillBank.byId(id)!,
      ];
      expect(dayTrainingOf(app), isEmpty);
    });
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
      expect(score.now, greaterThan(kScoreStart));
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
      await tester.tap(find.byKey(const ValueKey('profile-skills')));
      await tester.pumpAndSettle();
      expect(find.byType(SkillsScreen), findsOneWidget);
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
    testWidgets('the Astute score at the head; each skill picked at full size '
        'with its score and its week, or how it starts; the others small '
        'with theirs; Edit opens What to learn', (tester) async {
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
      expect(book.overall.now, greaterThan(kScoreStart));
      Finder inRow(String skill, String text) => find.descendant(
        of: find.byKey(ValueKey('training-row-$skill')),
        matching: find.text(text),
      );
      final SkillScore m = book.of(Skill.money);
      expect(inRow('money', _n(m.now)), findsOneWidget);
      expect(inRow('money', l.scoreWeek('+${m.week}')), findsOneWidget);
      expect(inRow('numbers', l.scoreStart), findsOneWidget);
      expect(inRow('numbers', _n(kScoreStart)), findsOneWidget);
      for (final Skill s in Skill.values) {
        final bool picked = s == Skill.money || s == Skill.numbers;
        expect(
          find.byKey(ValueKey('training-other-${s.name}')),
          picked ? findsNothing : findsOneWidget,
          reason: s.name,
        );
      }
      await tester.tap(find.byKey(const ValueKey('training-change')));
      await tester.pumpAndSettle();
      expect(find.byType(SkillsScreen), findsOneWidget);
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

  group('the finished day', () {
    final List<DayTraining> day = [
      const DayTraining(
        skill: Skill.science,
        plus: 3,
        before: 1180,
        after: 1204,
      ),
      const DayTraining(skill: Skill.money, plus: 1, before: 1290, after: 1284),
      const DayTraining(
        skill: Skill.people,
        plus: 1,
        before: 1000,
        after: 1000,
      ),
    ];

    Future<AppState> sheet(
      WidgetTester tester, {
      String language = 'en',
    }) async {
      final AppState app = await tester.runAsync(readyApp) as AppState;
      await show(
        tester,
        (_) => DayTrainingSheet(app: app, items: day, cards: 5),
        language: language,
      );
      return app;
    }

    testWidgets('says the day is done, the Astute score and how far today '
        'moved it, and each skill\'s score counting from last night to now, '
        'with how far it moved', (tester) async {
      await phone(tester, const Size(390, 844));
      await sheet(tester);
      final l = lookupAppLocalizations(const Locale('en'));
      expect(find.text('Five for five.'), findsOneWidget);
      expect(
        find.textContaining(l.scoreTitle, findRichText: true),
        findsOneWidget,
      );
      for (final DayTraining d in day) {
        expect(
          find.byKey(ValueKey('day-training-${d.skill.name}')),
          findsOneWidget,
        );
      }
      expect(find.text('+24'), findsOneWidget);
      expect(find.text('\u22126'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      // Before the scores count, science stands where it did last night.
      expect(find.text(_n(1180)), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(_n(1204)), findsOneWidget);
      expect(find.text(_n(1284)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final String language in AppLocalizations.supportedLocales.map(
      (l) => l.languageCode,
    )) {
      testWidgets('fits the smallest phone at a large text size in $language, '
          'and so do the profile\'s box and the journey\'s chapter', (
        tester,
      ) async {
        await phone(tester, const Size(320, 568), text: 1.3);
        await sheet(tester, language: language);
        await tester.pump(const Duration(seconds: 3));
        expect(tester.takeException(), isNull, reason: 'sheet');
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
