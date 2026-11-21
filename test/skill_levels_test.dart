// What trains each skill, the reader's level in it, and the mark a card
// carries when it trains a skill the reader put in focus
// (lib/data/skill_levels.dart, lib/widgets/skill_mark.dart).
//
//   flutter test test/skill_levels_test.dart
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
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/skill_mark.dart';

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

  final Pill card = bank.firstWhere(
    (p) => p.web == null && p.challenge is NoChallenge && p.scene == null,
  );

  testWidgets('a card that trains a skill in focus carries its mark on its '
      'corner; a tap, on the card being read, says what it means', (
    tester,
  ) async {
    final List<Skill> tapped = [];
    Widget deck({Skill? Function(Pill)? skillOf}) => host(
      SizedBox(
        height: 640,
        child: PillCardStack(
          deck: [card],
          index: 0,
          onAdvance: () {},
          answerFor: (_) => null,
          onAnswer: (_, _, _, _) {},
          reviewIds: const {},
          isSaved: (_) => false,
          onSave: (_) {},
          onShare: (_) {},
          skillOf: skillOf,
          onSkill: (pill, skill) => tapped.add(skill),
        ),
      ),
    );

    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(deck(skillOf: (_) => Skill.money));
    await tester.pumpAndSettle();
    final Finder mark = find.byKey(const ValueKey('skill-mark-money'));
    expect(mark, findsOneWidget);
    // On the card's top right corner.
    final Rect face = tester.getRect(find.byType(PillCard).first);
    final Rect at = tester.getRect(mark);
    expect(at.right, closeTo(face.right, 1));
    expect(at.top, closeTo(face.top, 1));
    expect(
      find.bySemanticsLabel(
        'Trains ${lookupAppLocalizations(const Locale('en')).skillName('money')}',
      ),
      findsOneWidget,
    );
    semantics.dispose();
    await tester.tap(mark);
    await tester.pump();
    expect(tapped, [Skill.money]);

    // A card that trains none of them carries none.
    await tester.pumpWidget(deck(skillOf: (_) => null));
    await tester.pumpAndSettle();
    expect(find.byType(SkillMark), findsNothing);
    expect(tester.takeException(), isNull);
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
