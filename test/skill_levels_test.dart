// What trains each skill, the reader's level in it, and the small mark a
// card carries in its head when it trains a skill the reader put in focus
// (lib/data/skill_levels.dart, lib/widgets/skill_mark.dart).
//
//   flutter test test/skill_levels_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/skill_levels.dart';
import 'package:astuto/data/skill_scores.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/skills_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/skill_mark.dart';
import 'package:astuto/widgets/skill_score.dart';

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
      expect(each[s], greaterThanOrEqualTo(150), reason: s.name);
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

  testWidgets("a card that trains a skill in focus carries the skill's mark "
      'in its head on the right, where a liked card has its heart, or just '
      'before the heart; a tap on it, on the card being read, says what it '
      'means', (tester) async {
    final Pill pill = bank.firstWhere(
      (p) => p.web == null && Skill.money.fitOf(p) == 0,
    );
    int taps = 0;
    Future<void> card({bool liked = false, bool live = true}) =>
        tester.pumpWidget(
          host(
            Center(
              child: SizedBox(
                width: 380,
                height: 700,
                child: PillCard(
                  pill: pill,
                  flipped: false,
                  skill: Skill.money,
                  liked: liked,
                  controlsLive: live,
                  onSkill: () => taps++,
                ),
              ),
            ),
          ),
        );
    const ValueKey<String> key = ValueKey('skill-mark-money');
    await card();
    await tester.pumpAndSettle();
    final Rect face = tester.getRect(find.byType(PillCard).first);
    Rect mark = tester.getRect(find.byKey(key));
    // Where the heart's right side stands, 28 in, at the head's middle.
    expect(
      face.right - (mark.center.dx + SkillMark.size / 2),
      closeTo(28, 0.5),
    );
    expect(mark.center.dy - face.top, closeTo(34, 2));
    await tester.tap(find.byKey(key));
    expect(taps, 1);

    await card(liked: true);
    await tester.pumpAndSettle();
    final Rect heart = tester.getRect(
      find.byKey(const ValueKey('liked-heart')),
    );
    mark = tester.getRect(find.byKey(key));
    expect(
      heart.left - (mark.center.dx + SkillMark.size / 2),
      closeTo(SkillMark.gap, 0.5),
    );
    expect(mark.center.dy, closeTo(heart.center.dy, 0.5));

    // On a card waiting under the one being read, seen but not pressed.
    await card(live: false);
    await tester.pumpAndSettle();
    expect(find.byKey(key), findsOneWidget);
    await tester.tap(find.byKey(key), warnIfMissed: false);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the mark is left out where the head has no room for it beside '
      'the subject and its chip', (tester) async {
    final Pill pill = bank.firstWhere(
      (p) => p.web == null && Skill.money.fitOf(p) == 0,
    );
    final l = lookupAppLocalizations(const Locale('en'));
    // The narrowest card whose head has room for it, beside "Again".
    final int room = [for (int w = 200; w < 600; w++) w].firstWhere(
      (w) => SkillMark.fits(
        width: w.toDouble(),
        middle: 28 + SkillMark.size / 2,
        subject: l.subjectOf(pill.topic),
        chip: l.againChip,
      ),
    );
    Future<void> card(double width) async {
      await tester.pumpWidget(
        host(
          Center(
            child: SizedBox(
              width: width,
              height: 640,
              child: PillCard(
                pill: pill,
                flipped: false,
                isReview: true,
                skill: Skill.money,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await card(room - 1);
    expect(find.byKey(const ValueKey('skill-mark-money')), findsNothing);
    await card(room.toDouble());
    expect(find.byKey(const ValueKey('skill-mark-money')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("the mark's sheet: the skill, why, the reader's score in it "
      'with its week and its answers, and the way to What to learn', (
    tester,
  ) async {
    final List<Pill> read = bank
        .where((p) => Skill.money.fitOf(p) == 0 && p.isGraded)
        .take(4)
        .toList();
    final AppState app = await tester.runAsync(
      () => readyApp({
        'knowit.skills': <String>['money'],
        'knowit.seenIds': [for (final Pill p in read) p.id],
        'knowit.judgements': judgementsOf(read),
      }),
    ) as AppState;
    final SkillScore score = scoreBookOf(app).of(Skill.money);
    expect(score.now, greaterThan(0));
    expect(score.answers, 4);
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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('skill-mark-level')),
        matching: find.text(
          NumberFormat.decimalPattern('en').format(score.now),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(l.scoreWeek('+${score.week}'), findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining(l.scoreAnswers(4), findRichText: true),
      findsOneWidget,
    );
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
