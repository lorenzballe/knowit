// How an answer moves the reader's score, said on the card the moment its
// back comes round: the skill in focus the card trains, or else the score of
// every skill together, and by how much (lib/data/skill_scores.dart
// lastMoveOn, lib/widgets/skill_score.dart todayMoveOf and ScoreMoveChip,
// the verdict in lib/widgets/pill_card.dart).
//
//   flutter test test/score_move_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/data/skill_levels.dart';
import 'package:astuto/data/skill_scores.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/skill_score.dart';

import 'explore/core_harness.dart';

void main() {
  setUpAll(loadFonts);
  setUp(PillBank.reset);

  final DateTime today = DateTime(2026, 11, 23, 10);
  String daysAgo(int n) =>
      dateKey(DateTime(today.year, today.month, today.day - n));
  Judgement said(Pill p, bool right, {int ago = 0}) =>
      Judgement(null, correct: right, pillId: p.id, on: daysAgo(ago));

  List<Pill> graded() => PillBank.cards
      .where((p) => p.isGraded && p.challenge is PickOne && !p.hasPage)
      .toList();

  group('the move of one answer', () {
    test(
      'the last answer on a card, in the skill it trains: from where '
      'the score stood just before it to where it stood just after',
      () async {
        await readyApp();
        final List<Pill> money = graded()
            .where((p) => Skill.money.fitOf(p) == 0)
            .take(3)
            .toList();
        final List<Judgement> js = [
          said(money[0], true, ago: 2),
          said(money[1], false, ago: 1),
          said(money[2], true),
        ];
        final ScoreMove move = lastMoveOn(money[2].id, js, skill: Skill.money)!;
        expect(move.skill, Skill.money);
        expect(move.on, daysAgo(0));
        int scoreAfter(int n) =>
            scoresOf(js.take(n), today: today).of(Skill.money).now;
        expect(move.before, scoreAfter(2));
        expect(move.after, scoreAfter(3));
        expect(move.by, greaterThan(0));

        // An answer in the middle is said as it moved the score then.
        final ScoreMove middle = lastMoveOn(
          money[1].id,
          js,
          skill: Skill.money,
        )!;
        expect(middle.before, scoreAfter(1));
        expect(middle.after, scoreAfter(2));
        expect(middle.by, lessThan(0));
      },
    );

    test('a card that does not train the skill moves the score of every '
        'skill together; a card never answered moves nothing', () async {
      await readyApp();
      final List<Pill> others = graded()
          .where((p) => Skill.money.fitOf(p) == null)
          .take(2)
          .toList();
      final Pill first = others[0], other = others[1];
      final Pill never = graded().firstWhere(
        (p) => p.id != other.id && p.id != first.id,
      );
      final List<Judgement> js = [said(first, true), said(other, false)];
      final ScoreMove move = lastMoveOn(other.id, js, skill: Skill.money)!;
      expect(move.skill, isNull);
      expect(move.before, scoresOf(js.take(1), today: today).overall.now);
      expect(move.after, scoresOf(js, today: today).overall.now);
      expect(move.by, lessThan(0));
      expect(lastMoveOn(other.id, js), isNotNull);
      expect(lastMoveOn(never.id, js), isNull);
    });

    test('a wrong answer at nothing moves nothing shown, and the card says '
        'nothing of it', () async {
      await readyApp();
      final Pill other = graded().firstWhere(
        (p) => Skill.money.fitOf(p) == null,
      );
      final List<Judgement> js = [said(other, false)];
      final ScoreMove move = lastMoveOn(other.id, js)!;
      expect(move.before, 0);
      expect(move.after, 0);
      expect(move.by, 0);
    });
  });

  group('on the card', () {
    test('answered today, the move is said; answered on another day, or '
        'not at all, it is not', () async {
      final List<Pill> money = graded()
          .where((p) => Skill.money.fitOf(p) == 0)
          .take(2)
          .toList();
      final AppState app = await readyApp({
        'knowit.skills': ['money'],
        'knowit.judgements': jsonEncode([
          ...jsonDecode(judgementsOf([money[0]], daysAgo: 1)) as List,
        ]),
      });
      expect(todayMoveOf(app, money[0], Skill.money), isNull);
      expect(todayMoveOf(app, money[1], Skill.money), isNull);

      final PickOne c = money[1].challenge as PickOne;
      await app.recordAnswer(money[1].id, '${c.correct}', confidence: 70);
      final ScoreMove move = todayMoveOf(app, money[1], Skill.money)!;
      expect(move.skill, Skill.money);
      expect(move.by, greaterThan(0));
      expect(move.after, scoreBookOf(app).of(Skill.money).now);
      // Not a skill in focus the card trains: the Astute score.
      expect(todayMoveOf(app, money[1], null)!.skill, isNull);
    });

    Future<void> pumpBack(WidgetTester tester, Pill pill, ScoreMove? move) {
      final PickOne c = pill.challenge as PickOne;
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 354,
                height: 624,
                child: PillCard(
                  pill: pill,
                  flipped: true,
                  given: Answer('${c.correct}', confidence: 80),
                  move: move,
                  onSave: () {},
                  onShare: () {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('the back says the move right after its verdict, counts up '
        'to it, and reads it out', (tester) async {
      await tester.runAsync(readyApp);
      final Pill pill = graded().firstWhere((p) => Skill.money.fitOf(p) == 0);
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpBack(
        tester,
        pill,
        const ScoreMove(before: 1012, after: 1024, skill: Skill.money, on: ''),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final Finder chip = find.byKey(const ValueKey('score-move'));
      expect(chip, findsOneWidget);
      // Counting: not there yet.
      expect(
        find.descendant(of: chip, matching: find.text('+12')),
        findsNothing,
      );
      final Size first = tester.getSize(chip);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: chip, matching: find.text('+12')),
        findsOneWidget,
      );
      // It took its room from the start, so nothing after it moved.
      expect(tester.getSize(chip), first);
      expect(
        find.bySemanticsLabel('Money and saving: +12 for this answer'),
        findsOneWidget,
      );
      // Right after the verdict, on its line.
      final Rect verdict = tester.getRect(
        find.textContaining('Right.', findRichText: true).first,
      );
      expect(tester.getRect(chip).top, lessThan(verdict.top + 24));
      semantics.dispose();
    });

    testWidgets('the score of every skill together, going down, with an '
        'arrow; no move, nothing', (tester) async {
      await tester.runAsync(readyApp);
      final Pill pill = graded().first;
      await pumpBack(
        tester,
        pill,
        const ScoreMove(before: 1031, after: 1022, on: ''),
      );
      await tester.pumpAndSettle();
      final Finder chip = find.byKey(const ValueKey('score-move'));
      expect(
        find.descendant(of: chip, matching: find.text('−9')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: chip,
          matching: find.byIcon(Icons.arrow_downward_rounded),
        ),
        findsOneWidget,
      );

      await pumpBack(tester, pill, null);
      await tester.pumpAndSettle();
      expect(chip, findsNothing);
    });
  });
}
