/// The levels of the Astute score (lib/data/skill_scores.dart): a short
/// ladder of the qualities good thinking is made of, each reached at a
/// score, and told once, the whole screen black, at a calm moment after the
/// score has crossed it (lib/widgets/level_up.dart).
///
/// Every level is set on the score as the reader sees it ([shownScore]),
/// never on the score the engine keeps, so the shown scale can change in
/// one place and every level keeps its meaning. A [SkillScore]'s figures
/// are shown scores already, made by [shownScore] as the engine runs: the
/// levels read them as they are.
///
/// A level once reached is kept: a score that falls back under it, as a
/// score moved by every answer will, does not take it away, and it is never
/// told twice. The highest level told is kept on the phone ([LevelMemory]).
library;

import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pill.dart';
import 'pills_repository.dart' show dateKey;
import 'skill_scores.dart';
import 'skills.dart';

/// A score as the reader sees it, from the rating the engine keeps
/// ([kept]) and the lowest that rating has ever stood, its start included
/// ([lowest]: [kScoreStart], until a wrong answer takes it under).
///
/// The one place a kept score becomes the shown one. The engine shows every
/// score through it as it runs (lib/data/skill_scores.dart), so the Astute
/// score and each skill's are on one scale wherever they are shown — Your
/// journey, the profile, a card's back, the levels — and every level of
/// [kScoreLevels] is set on it. Shown, a new reader starts from 0, not from
/// 1,000, and a score never goes under nothing: it is how far the reader's
/// answers have carried the rating from the lowest it has been, so after a
/// few misses at the start each right answer still counts, rather than
/// climbing back unseen to a line the reader cannot see. When the shown
/// scale changes, this is the line to change, and the ladder and every
/// figure follow.
int shownScore(num kept, {num lowest = kScoreStart}) =>
    math.max(0, (kept - math.min(lowest, kScoreStart)).round());

/// One level: its name, looked up by [id] in the reader's language
/// (AppLocalizations.scoreLevel), and the shown score it is reached at.
class ScoreLevel {
  const ScoreLevel(this.id, this.from);

  final String id;

  /// The shown score ([shownScore]) the level is reached at.
  final int from;
}

/// The ladder, on the shown score.
///
/// Everybody starts on the first. The second comes in the first week of the
/// five a day, which ask about three graded answers a day: a reader right
/// six times in ten has its 25 points on the fourth day, as soon as ten
/// answers are behind the score; one right half the time, on the fifth.
/// After it each level asks 25 points more than the step before it — 50,
/// 75, 100, 125, 150 — and the later ones get rarer, because a score settles
/// where the reader's answers put it (right six times in ten on the medium
/// cards, worth 1050, settles near 120 shown): the third a week or two after
/// the second; the fourth to a reader right two times in three, in two weeks
/// to a month; the ones after only as the reader gets better, the last only
/// right more than eight times in ten on the hard cards, worth 1250.
///
/// The names are nouns, the quality rather than the person, so no language
/// has to give them a gender.
const List<ScoreLevel> kScoreLevels = [
  ScoreLevel('curiosity', 0),
  ScoreLevel('observation', 25),
  ScoreLevel('method', 75),
  ScoreLevel('judgement', 150),
  ScoreLevel('insight', 250),
  ScoreLevel('discernment', 375),
  ScoreLevel('acumen', 525),
];

/// How many answers a score needs behind it before it is worth a level:
/// ten, about three days of the five. Fewer, and three lucky answers on the
/// first day would be a level.
const int kLevelAnswers = 10;

/// The level a shown score stands at: the highest of [kScoreLevels] whose
/// points it has, once [answers] answers are behind it; the first before
/// then.
int levelAt(int shown, {required int answers}) {
  if (answers < kLevelAnswers) return 0;
  var at = 0;
  for (var i = 1; i < kScoreLevels.length; i++) {
    if (shown >= kScoreLevels[i].from) at = i;
  }
  return at;
}

/// Whether the reader's first answer is less than a week old, which is a
/// reader with no level from before levels were told: everything they reach
/// is news. Judgements are kept in the order they were made; one from
/// before the app dated them is from long ago.
bool isNewReader(List<Judgement> judgements, DateTime today) {
  if (judgements.isEmpty) return true;
  final String? first = judgements.first.on;
  if (first == null) return false;
  final String weekAgo = dateKey(
    DateTime(today.year, today.month, today.day - 6),
  );
  return first.compareTo(weekAgo) >= 0;
}

/// Where a reader stands on the ladder: the level their score stands at,
/// the highest they have reached, which a score that falls never takes
/// away, and the one to tell now, if any.
class LevelStanding {
  const LevelStanding({
    required this.shown,
    required this.answers,
    required this.at,
    required this.told,
  });

  /// Works it out from the reader's [book], and [told], the highest level
  /// they have been told of (null on a phone that has never kept one).
  ///
  /// A reader never told is told only what their answers reach from today:
  /// the level their score stood at at the end of yesterday counts as told,
  /// so a level reached before levels were told, or kept on another phone,
  /// is not told again. Except to a [newReader], who has nothing from before
  /// to keep quiet about.
  factory LevelStanding.of(
    ScoreBook book, {
    int? told,
    bool newReader = false,
  }) {
    final SkillScore overall = book.overall;
    final int shown = overall.now;
    final int answers = overall.answers;
    return LevelStanding(
      shown: shown,
      answers: answers,
      at: levelAt(shown, answers: answers),
      told: told != null
          ? told.clamp(0, kScoreLevels.length - 1)
          : newReader
          ? 0
          : levelAt(overall.days[overall.days.length - 2], answers: answers),
    );
  }

  /// The shown score, and how many answers are behind it.
  final int shown;
  final int answers;

  /// The level the score stands at now.
  final int at;

  /// The highest level that counts as told.
  final int told;

  /// The highest level reached: the one the reader is on.
  int get reached => math.max(told, at);

  /// The level to tell now: the one the score stands at, when it is above
  /// every level told. Null when there is none.
  int? get due => at > told ? at : null;

  ScoreLevel get level => kScoreLevels[reached];

  /// The level after the one reached; null on the last.
  ScoreLevel? get next =>
      reached + 1 < kScoreLevels.length ? kScoreLevels[reached + 1] : null;

  /// How many answers the score still needs behind it for any level.
  int get answersShort => math.max(0, kLevelAnswers - answers);

  /// How many points the next level is away; null on the last.
  int? get pointsShort {
    final ScoreLevel? up = next;
    return up == null ? null : math.max(0, up.from - shown);
  }

  /// How far the score has come from the level reached towards the next,
  /// 0 to 1: nothing while it stands under the level reached, all of it on
  /// the last.
  double get toNext {
    final ScoreLevel? up = next;
    if (up == null) return 1;
    final int from = kScoreLevels[reached].from;
    return ((shown - from) / (up.from - from)).clamp(0.0, 1.0);
  }
}

/// What the screen of a level reached says: the level, the score as it
/// stands and where its count starts, and what got the reader there.
class LevelMoment {
  const LevelMoment({
    required this.level,
    required this.score,
    required this.from,
    required this.answers,
    this.skill,
    this.gain = 0,
  });

  /// The moment of [level] (an index of [kScoreLevels]) for a reader with
  /// [book], whose [picked] skills come first where two rose as much.
  factory LevelMoment.of(
    ScoreBook book,
    int level, {
    List<Skill> picked = const [],
  }) {
    final (Skill, int)? most = biggestGain(book, picked: picked);
    return LevelMoment(
      level: level,
      score: book.overall.now,
      from: countFrom(book.overall, kScoreLevels[level]),
      answers: book.overall.answers,
      skill: most?.$1,
      gain: most?.$2 ?? 0,
    );
  }

  /// The level reached, an index of [kScoreLevels].
  final int level;

  /// The shown score now, and where the screen's count starts.
  final int score;
  final int from;

  /// How many answers the score stands on: said when no skill rose.
  final int answers;

  /// The skill whose shown score rose most in the last seven days, and by
  /// how much; null when none rose.
  final Skill? skill;
  final int gain;
}

/// Where the count of a level's screen starts: the shown score at the end
/// of the last day, before today, that ended under [level], so the number
/// climbs past the level's points as the screen opens; from 0 when no day
/// of the month ended under it.
int countFrom(SkillScore overall, ScoreLevel level) {
  final List<int> days = overall.days;
  for (var i = days.length - 2; i >= 0; i--) {
    final int shown = days[i];
    if (shown < level.from) return shown;
  }
  return 0;
}

/// The skill whose shown score rose most in the last seven days, and by
/// how much; null when none rose. Of two that rose as much, the one picked
/// first ([picked]), then the first in What to learn's order.
(Skill, int)? biggestGain(ScoreBook book, {List<Skill> picked = const []}) {
  final List<Skill> order = [
    ...picked,
    for (final Skill s in Skill.values)
      if (!picked.contains(s)) s,
  ];
  (Skill, int)? best;
  for (final Skill s in order) {
    final SkillScore score = book.of(s);
    final int gain = score.now - score.days[score.days.length - 8];
    if (gain > 0 && (best == null || gain > best.$2)) best = (s, gain);
  }
  return best;
}

/// The highest level the reader has been told of, kept on the phone so a
/// level is told once, whatever restarts between. Starting over clears it
/// with everything else.
abstract final class LevelMemory {
  static const String key = 'knowit.levelTold';

  static Future<int?> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  static Future<void> keep(int level) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, level);
  }

  /// The day a level last rose on screen, as a date key: a day has one
  /// full-screen moment at most, and the first week's page and the first
  /// month's wait for a day no level rose on (lib/state/first_offers.dart).
  static const String roseKey = 'knowit.levelRoseOn';

  static Future<String?> roseOn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(roseKey);
  }

  static Future<void> rose(String day) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(roseKey, day);
  }
}
