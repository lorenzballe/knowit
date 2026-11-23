/// A reader's score in each skill of lib/data/skills.dart, and in all of
/// them together: a number with no top, moved by every answer given on a
/// card that trains the skill, the way a chess rating is moved by every
/// game.
///
/// A card is worth what it takes to get it right one time in two
/// ([cardScore]): right, the score rises by how unlikely that was; wrong, it
/// falls by how likely it was. So a hard card right counts the most, an easy
/// one wrong costs the most, and a reader's score settles where their answers
/// put it, and rises for as long as they keep getting better. A card back for
/// another go counts half; a card that trains the skill only by its subject
/// counts half, one that trains one of its reasoning moves a little less
/// than one of its own genre (lib/data/skill_levels.dart, [SkillTraining]).
///
/// Worked out afresh from the reader's judgements (AppState.judgements),
/// which are kept in the order they were made: nothing is stored, so the
/// rule can change and every score follows.
library;

import 'dart:math' as math;

import '../models/pill.dart';
import 'pill_bank.dart';
import 'pills_repository.dart' show dateKey;
import 'skill_levels.dart';
import 'skills.dart';

/// Where every score starts.
const int kScoreStart = 1000;

/// How far one answer can move a score: half of it for an answer that was
/// as likely right as wrong.
const double kScoreStep = 24;

/// How many days of a score are kept for its line, today the last.
const int kScoreDays = 30;

/// What a card is worth: the score at which it is got right one time in
/// two.
int cardScore(Pill p) => switch (p.difficulty) {
  Difficulty.easy => 900,
  Difficulty.medium => 1050,
  Difficulty.hard => 1250,
};

/// The chance that a reader at [score] gets a card worth [card] right.
double chanceRight(double score, int card) =>
    1 / (1 + math.pow(10, (card - score) / 400));

/// A score: where it stands, where it stood at the end of each of the last
/// [kScoreDays] days, and how many answers made it.
class SkillScore {
  const SkillScore({
    required this.now,
    required this.days,
    required this.answers,
  });

  /// A score no answer has moved yet.
  static final SkillScore start = SkillScore(
    now: kScoreStart,
    days: List.filled(kScoreDays, kScoreStart),
    answers: 0,
  );

  /// Where it stands.
  final int now;

  /// Where it stood at the end of each of the last [kScoreDays] days, the
  /// oldest first and today, as it stands, the last.
  final List<int> days;

  /// How many answers moved it.
  final int answers;

  /// How far it moved in the last seven days.
  int get week => now - days[days.length - 8];

  /// How far it moved today.
  int get today => now - days[days.length - 2];
}

/// Every score of a reader: in all the skills together and in each.
class ScoreBook {
  const ScoreBook({required this.overall, required this.skills});

  /// Every graded answer, whatever skill its card trains.
  final SkillScore overall;

  /// Each skill's, from the answers on the cards that train it.
  final Map<Skill, SkillScore> skills;

  SkillScore of(Skill s) => skills[s] ?? SkillScore.start;
}

/// How much an answer on a card counts for a skill it trains, by how closely
/// it trains it ([SkillTraining.fitOf]).
const List<double> _fitWeight = [1, 0.8, 0.5];

/// The reader's scores from their [judgements], as of [today]: worked out
/// in the order the judgements were made, each day's end kept for the line.
/// A judgement with no card, or on a card the bank no longer has or that is
/// not graded, moves nothing.
ScoreBook scoresOf(
  Iterable<Judgement> judgements, {
  required DateTime today,
  Pill? Function(String id)? cardOf,
}) {
  final Pill? Function(String id) find = cardOf ?? PillBank.byId;
  final String todayKey = dateKey(today);
  // The window's days, oldest first.
  final List<String> window = [
    for (int i = kScoreDays - 1; i >= 0; i--)
      dateKey(DateTime(today.year, today.month, today.day - i)),
  ];
  final String first = window.first;

  double overall = kScoreStart.toDouble();
  int overallAnswers = 0;
  final Map<Skill, double> each = {
    for (final Skill s in Skill.values) s: kScoreStart.toDouble(),
  };
  final Map<Skill, int> answers = {for (final Skill s in Skill.values) s: 0};
  final Set<String> met = {};

  // Each day's end, by the window's index; before the window, what the
  // scores were when it opened.
  final List<Map<Skill?, double>?> ends = List.filled(kScoreDays, null);
  Map<Skill?, double> snapshot() => {null: overall, ...each};
  Map<Skill?, double> before = snapshot();

  for (final Judgement j in judgements) {
    final String? id = j.pillId;
    if (id == null) continue;
    final Pill? card = find(id);
    if (card == null || !card.isGraded) continue;
    final String on = j.on ?? '';
    // Kept in the order made: a judgement dated before the window moves the
    // score the window opens on.
    final double again = met.add(id) ? 1 : 0.5;
    final int worth = cardScore(card);
    final double got = j.correct ? 1 : 0;
    overall += kScoreStep * again * (got - chanceRight(overall, worth));
    overallAnswers++;
    for (final Skill s in Skill.values) {
      final int? fit = s.fitOf(card);
      if (fit == null) continue;
      final double now = each[s]!;
      each[s] =
          now +
          kScoreStep *
              again *
              _fitWeight[fit] *
              (got - chanceRight(now, worth));
      answers[s] = answers[s]! + 1;
    }
    if (on.compareTo(first) < 0) {
      before = snapshot();
    } else {
      final int at = window.indexOf(on);
      if (at >= 0) ends[at] = snapshot();
      if (on.compareTo(todayKey) > 0) ends[kScoreDays - 1] = snapshot();
    }
  }

  // A day with no answer ends where the day before it did.
  final List<Map<Skill?, double>> days = [];
  Map<Skill?, double> carried = before;
  for (int i = 0; i < kScoreDays; i++) {
    carried = ends[i] ?? carried;
    days.add(carried);
  }
  days[kScoreDays - 1] = snapshot();

  SkillScore scoreOf(Skill? s, int n) => SkillScore(
    now: days.last[s]!.round(),
    days: [for (final Map<Skill?, double> d in days) d[s]!.round()],
    answers: n,
  );

  return ScoreBook(
    overall: scoreOf(null, overallAnswers),
    skills: {for (final Skill s in Skill.values) s: scoreOf(s, answers[s]!)},
  );
}
