// The reader's scores (lib/data/skill_scores.dart): a number with no top in
// each skill, moved by every answer on a card that trains it, the way a
// chess rating is moved by every game.
//
//   flutter test test/skill_scores_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/data/skill_levels.dart';
import 'package:astuto/data/skill_scores.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/models/pill.dart';

import 'explore/core_harness.dart';

void main() {
  final DateTime today = DateTime(2026, 11, 23, 10);
  String daysAgo(int n) =>
      dateKey(DateTime(today.year, today.month, today.day - n));

  late Pill medium, hard, money, moneyBySubjectOnly;

  setUpAll(() async {
    await readyApp();
    final List<Pill> graded = PillBank.cards.where((p) => p.isGraded).toList();
    medium = graded.firstWhere((p) => p.difficulty == Difficulty.medium);
    hard = graded.firstWhere((p) => p.difficulty == Difficulty.hard);
    money = graded.firstWhere(
      (p) => Skill.money.fitOf(p) == 0 && p.difficulty == Difficulty.medium,
    );
    moneyBySubjectOnly = graded.firstWhere(
      (p) => Skill.money.fitOf(p) == 2 && p.difficulty == Difficulty.medium,
    );
  });

  Judgement said(Pill p, bool right, {int ago = 0}) =>
      Judgement(null, correct: right, pillId: p.id, on: daysAgo(ago));

  test('every score starts at nothing for a new reader, and no answer '
      'moves it', () {
    final ScoreBook book = scoresOf(const [], today: today);
    expect(book.overall.now, 0);
    expect(book.overall.week, 0);
    expect(book.overall.days, everyElement(0));
    for (final Skill s in Skill.values) {
      expect(book.of(s).now, 0);
    }
    expect(SkillScore.start.now, 0);
  });

  test('right raises it, wrong lowers it; a hard card right raises it most, '
      'a card back for another go counts half', () {
    int after(List<Judgement> js) => scoresOf(js, today: today).overall.now;
    final int right = after([said(medium, true)]);
    expect(right, greaterThan(0));
    // A wrong answer takes away what a right one gave, and no more.
    final int wrong = after([said(medium, true), said(hard, false)]);
    expect(wrong, lessThan(right));
    expect(wrong, greaterThanOrEqualTo(0));
    expect(after([said(hard, true)]), greaterThan(right));
    final int twice = after([said(medium, true), said(medium, true)]);
    final int two = after([said(medium, true), said(hard, true)]);
    expect(twice - right, lessThan(right));
    expect(two, greaterThan(twice));
  });

  test('a few cards in, a score is a few dozen, not a thousand', () {
    final List<Pill> five = PillBank.cards
        .where((p) => p.isGraded && p.difficulty == Difficulty.medium)
        .take(5)
        .toList();
    final int now = scoresOf([
      for (final Pill p in five) said(p, true),
    ], today: today).overall.now;
    expect(now, inInclusiveRange(30, 90));
  });

  test('never below nothing: a wrong answer at nothing costs nothing shown, '
      'and the next right one counts from there, as much as the rating '
      'underneath moves', () {
    final List<Pill> misses = PillBank.cards
        .where((p) => p.isGraded && p.id != medium.id)
        .take(4)
        .toList();
    expect(misses, hasLength(4));
    final List<Judgement> wrongs = [for (final Pill p in misses) said(p, false)];
    final ScoreBook low = scoresOf(wrongs, today: today);
    expect(low.overall.now, 0);
    expect(low.overall.days, everyElement(0));
    final ScoreBook back = scoresOf([
      ...wrongs,
      said(medium, true),
    ], today: today);
    // From nothing, by what the answer moved the rating: more than the
    // same answer moves a reader at the start, who stands higher.
    expect(back.overall.now, greaterThan(0));
    expect(
      back.overall.now,
      greaterThan(scoresOf([said(medium, true)], today: today).overall.now),
    );
    expect(back.overall.today, back.overall.now);
  });

  test('a skill moves with the cards that train it: most with its own, '
      'half with one only about its subject', () {
    final ScoreBook own = scoresOf([said(money, true)], today: today);
    final ScoreBook subject = scoresOf([
      said(moneyBySubjectOnly, true),
    ], today: today);
    final int byOwn = own.of(Skill.money).now;
    final int bySubject = subject.of(Skill.money).now;
    expect(byOwn, greaterThan(0));
    expect(bySubject, greaterThan(0));
    expect(bySubject, lessThan(byOwn));
    expect(own.of(Skill.money).answers, 1);
  });

  test(
    'the week counts the last seven days; the line keeps each day\'s end',
    () {
      final ScoreBook book = scoresOf([
        said(medium, true, ago: 20),
        said(hard, true, ago: 3),
        said(hard, true),
      ], today: today);
      final SkillScore s = book.overall;
      expect(s.days.length, kScoreDays);
      expect(s.days.last, s.now);
      // Twenty days ago is before the week: only the two hard cards count.
      final int start = scoresOf([
        said(medium, true, ago: 20),
      ], today: today).overall.now;
      expect(s.week, s.now - start);
      expect(s.today, greaterThan(0));
      // The line holds still on the days with no answer.
      expect(s.days[kScoreDays - 5], s.days[kScoreDays - 6]);
    },
  );

  test('there is no top: right after right on hard cards, it keeps rising', () {
    final List<Pill> hards = PillBank.cards
        .where((p) => p.isGraded && p.difficulty == Difficulty.hard)
        .take(400)
        .toList();
    final List<Judgement> run = [for (final Pill p in hards) said(p, true)];
    final int half = scoresOf(run.sublist(0, 200), today: today).overall.now;
    final int all = scoresOf(run, today: today).overall.now;
    expect(half, greaterThan(500));
    expect(all, greaterThan(half));
  });
}
