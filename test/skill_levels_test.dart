// What trains each skill, the reader's level in it, and the line a card
// carries when it trains a skill the reader put in focus
// (lib/data/skill_levels.dart, lib/data/why.dart, lib/widgets/skill_mark.dart).
//
//   flutter test test/skill_levels_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/skill_levels.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/data/why.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/skills_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/skill_mark.dart';
import 'package:astuto/widgets/why_sheet.dart' show whyIcon, whyLine;

import 'explore/core_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final List<Pill> bank = PillBank.cards;

  test('every card trains a skill, and every skill has cards enough to '
      'climb on', () {
    final Map<Skill, int> each = cardsTrainingEach(bank.map((p) => p.id));
    for (final Pill p in bank) {
      expect(Skill.values.any((s) => s.trains(p)), isTrue, reason: p.id);
    }
    for (final Skill s in Skill.values) {
      expect(
        each[s],
        greaterThanOrEqualTo(SkillLevel.from.last),
        reason: s.name,
      );
    }
  });

  test("a skill's genres are genres the bank has, so none is misspelt", () {
    final Set<String> genres = {for (final Pill p in bank) p.genre};
    for (final Skill s in Skill.values) {
      for (final String g in s.genres) {
        expect(genres, contains(g), reason: '${s.name}: $g');
      }
    }
  });

  test('a card is marked by the picked skill it trains most closely, of two '
      'as close the first; none when it trains none of them', () {
    final Pill decision = bank.firstWhere(
      (p) => p.genre == 'history.decisions_that_changed_history',
    );
    // A genre of Better decisions, a subject of General knowledge.
    expect(Skill.decisions.fitOf(decision), 0);
    expect(Skill.culture.fitOf(decision), 2);
    expect(skillMarkOf(decision, ['culture', 'decisions']), Skill.decisions);
    expect(skillMarkOf(decision, ['culture']), Skill.culture);
    // A genre of Leadership too: as close, and What to learn's order says.
    expect(Skill.lead.fitOf(decision), 0);
    expect(skillMarkOf(decision, ['lead', 'decisions']), Skill.decisions);
    expect(skillMarkOf(decision, const []), isNull);
    expect(skillMarkOf(decision, ['money', 'talk']), isNull);
    // A key this build does not know marks nothing.
    expect(skillMarkOf(decision, ['juggling']), isNull);
  });

  test('a level from the cards read: 1 from the first, 2 from 10, 3 from 30, '
      '4 from 70, 5 from 150; the bar fills towards the next', () {
    SkillLevel at(int n) => SkillLevel.of(n);
    expect(at(0).level, 1);
    expect(at(0).toNext, 0);
    expect(at(5).toNext, closeTo(0.5, 1e-9));
    expect(at(9).level, 1);
    expect(at(10).level, 2);
    expect(at(10).toNext, 0);
    expect(at(29).level, 2);
    expect(at(30).level, 3);
    expect(at(69).level, 3);
    expect(at(70).level, 4);
    expect(at(149).level, 4);
    expect(at(150).level, 5);
    expect(at(150).toNext, 1);
    expect(at(4000).level, 5);
    expect(at(-3).level, 1);
    expect(at(18).cards, 18);
  });

  test("the cards read count for every skill they train, and a card the "
      'bank no longer has for none', () {
    final List<Pill> money = bank.where(Skill.money.trains).take(12).toList();
    final Map<Skill, int> each = cardsTrainingEach([
      for (final Pill p in money) p.id,
      'a-card-long-gone',
    ]);
    expect(each[Skill.money], 12);
    for (final Skill s in Skill.values) {
      expect(each[s], money.where(s.trains).length, reason: s.name);
    }
  });

  Widget host(Widget child, {Locale locale = const Locale('en')}) =>
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(body: child),
      );

  test('a card that trains a skill in focus says so under its head, before '
      'the reasons a skill outweighs, after those it does not', () async {
    final Pill money = bank.firstWhere(
      (p) =>
          Skill.money.fitOf(p) == 0 &&
          p.place == null &&
          skillMarkOf(p, ['money']) == Skill.money,
    );
    final AppState app = await readyApp({
      'knowit.plus': true,
      'knowit.skills': <String>['money'],
    });
    final CardWhy why = whyOf(app, money);
    expect(why.kind, WhyKind.skill);
    expect(why.skill, Skill.money);
    final l = lookupAppLocalizations(const Locale('en'));
    expect(whyLine(l, why), l.whySkill(l.skillName('money')));
    // In the plain mark every line carries, no dot of colour.
    expect(whyIcon(WhyKind.skill), Icons.fitness_center_rounded);
    // A card back on the review ladder says that first.
    app.reviewIdsToday.add(money.id);
    expect(whyOf(app, money).kind, isNot(WhyKind.skill));
    app.reviewIdsToday.remove(money.id);
    // Nothing in focus, nothing said of it.
    final AppState none = await readyApp({'knowit.plus': true});
    expect(whyOf(none, money).kind, isNot(WhyKind.skill));
  });

  testWidgets("the mark's sheet: the skill, why, the reader's level in it, "
      'and the way to What to learn', (tester) async {
    final List<Pill> read = bank.where(Skill.money.trains).take(12).toList();
    final AppState app = await tester.runAsync(
      () => readyApp({
        'knowit.skills': <String>['money'],
        'knowit.seenIds': [for (final Pill p in read) p.id],
      }),
    ) as AppState;
    final l = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showSkillMarkSheet(context, app, Skill.money),
              child: const Text('mark'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('mark'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('skill-mark-sheet')), findsOneWidget);
    expect(find.text(l.skillMarkKicker), findsOneWidget);
    expect(find.text(l.skillName('money')), findsOneWidget);
    expect(find.text(l.skillMarkBody), findsOneWidget);
    expect(find.text('${l.skillLevel(2)} · ${l.nCards(12)}'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skill-mark-open')));
    await tester.pumpAndSettle();
    expect(find.byType(SkillsScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('skill-mark-sheet')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final String language in ['en', 'it', 'de', 'ru', 'ja']) {
    testWidgets('the sheet lays out on a small phone in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.skills': <String>['fakes'],
        }),
      ) as AppState;
      await tester.pumpWidget(
        host(
          SkillMarkSheet(app: app, skill: Skill.fakes),
          locale: Locale(language),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
