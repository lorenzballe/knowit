// The reader's training (lib/widgets/training.dart): the skills they picked
// with their level in each, first in Your journey and as a box on the
// profile, and the sheet that rises when the day's cards are done, each bar
// filling from where it stood that morning.
//
//   flutter test test/training_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/skill_levels.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/skills_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/training.dart';

import 'explore/core_harness.dart';

/// [n] cards of the bank that train [s], from the [from]th; with [not],
/// only those that do not also train it.
List<String> training(Skill s, int n, {int from = 0, Skill? not}) => [
  for (final Pill p
      in PillBank.cards
          .where((p) => s.trains(p) && !(not?.trains(p) ?? false))
          .skip(from)
          .take(n))
    p.id,
];

void main() {
  setUpAll(loadFonts);
  setUp(PillBank.reset);

  group('a level', () {
    test('passes through parts of a card, and says how far the next is', () {
      expect(SkillLevel.between(5).level, 1);
      expect(SkillLevel.between(5).toNext, closeTo(0.5, 1e-9));
      expect(SkillLevel.between(9.5).toNext, closeTo(0.95, 1e-9));
      expect(SkillLevel.between(10).level, 2);
      expect(SkillLevel.between(200).level, SkillLevel.top);
      expect(SkillLevel.of(0).toNextCards, 10);
      expect(SkillLevel.of(12).toNextCards, 18);
      expect(SkillLevel.of(150).toNextCards, isNull);
    });
  });

  group('what the day trained', () {
    test('counts the day\'s cards in the skills picked, most first, three at '
        'most; a card back for another go counts for nothing', () async {
      final List<String> money = training(Skill.money, 4, not: Skill.numbers);
      final List<String> numbers = training(Skill.numbers, 2, not: Skill.money);
      final AppState app = await readyApp({
        'knowit.skills': ['numbers', 'money'],
        'knowit.seenIds': [
          ...training(Skill.money, 8, from: 10, not: Skill.numbers),
          ...money,
          ...numbers,
        ],
      });
      // Three money cards new today, two of numbers, and the fourth money
      // card, read before, back today for another go.
      app.todaysDeck = [
        for (final String id in [...money, ...numbers]) PillBank.byId(id)!,
      ];
      app.reviewIdsToday = {money[3]};
      final List<DayTraining> day = dayTrainingOf(app);
      expect(day.map((d) => d.skill), [Skill.money, Skill.numbers]);
      expect([for (final d in day) d.plus], [3, 2]);
      // Nine money cards before the day, twelve with it: level 2 today.
      expect(day.first.before, 9);
      expect(day.first.after, 12);
      expect(day.first.levelled, isTrue);
      expect(day.last.levelled, isFalse);
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
    testWidgets('the skills picked, three at most, each with its level and '
        'bar; the box opens What to learn', (tester) async {
      await phone(tester, const Size(390, 844));
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.skills': ['money', 'decisions', 'fakes', 'focus', 'lead'],
          'knowit.seenIds': training(Skill.money, 12),
        }),
      ) as AppState;
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
          matching: find.text(l.skillLevel(2)),
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
    testWidgets('each skill picked at full size with the cards to its next '
        'level, the others small with theirs; Edit opens What to learn', (
      tester,
    ) async {
      await phone(tester, const Size(390, 1400));
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.skills': ['money', 'numbers'],
          'knowit.seenIds': training(Skill.money, 12),
        }),
      ) as AppState;
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
      // Twelve money cards read: level 2, eighteen to level 3.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('training-row-money')),
          matching: find.text(l.trainingToNext(18, 3)),
        ),
        findsOneWidget,
      );
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
      const DayTraining(skill: Skill.science, plus: 3, before: 8, after: 11),
      const DayTraining(skill: Skill.money, plus: 1, before: 31, after: 32),
      const DayTraining(skill: Skill.people, plus: 1, before: 0, after: 1),
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

    testWidgets('says the day is done and what it trained, each bar filling; '
        'a level reached is said', (tester) async {
      await phone(tester, const Size(390, 844));
      await sheet(tester);
      final l = lookupAppLocalizations(const Locale('en'));
      expect(find.text('Five for five.'), findsOneWidget);
      expect(find.text(l.trainingDayLine), findsOneWidget);
      for (final DayTraining d in day) {
        expect(
          find.byKey(ValueKey('day-training-${d.skill.name}')),
          findsOneWidget,
        );
        expect(find.text('+${d.plus}'), findsWidgets);
      }
      // Before the bars fill, science is at level 1.
      expect(find.text(l.trainingNewLevel(2)), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(l.trainingNewLevel(2)), findsOneWidget);
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
