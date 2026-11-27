/// What the looks of What to learn read from the reader's answers
/// (lib/widgets/learn_looks.dart, DebugLooks.learn): the skills as the
/// answers rank them (C), the four skills an aim takes and where the reader
/// sees clearly among them (D), the week's one skill and how its week went
/// (E), and the cards to practise any of them on.
///
/// Nothing here is kept: every figure is worked out from the judgements and
/// the days read the app writes down already, so a look can be tried on a
/// phone with a history and show it at once.
library;

import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/debug_looks.dart';
import 'goals.dart';
import 'pill_bank.dart';
import 'pills_repository.dart' show dateKey, dealableOn;
import 'skill_levels.dart';
import 'skills.dart';

// ── C · The skills, ranked ─────────────────────────────────────────────────

/// How many answers a skill needs behind it to be ranked: fewer, and two
/// lucky answers would make it the reader's strong point.
const int kStrengthAnswers = 4;

/// A skill read from the reader's answers: how many were given on cards
/// that train it, and how many were right.
class SkillTally {
  const SkillTally(this.skill, this.answers, this.right);

  final Skill skill;
  final int answers;
  final int right;

  /// The share right, drawn a little towards a half while answers are few,
  /// so three right of three does not outrank twenty of twenty-four.
  double get rank => (right + 1) / (answers + 2);

  /// Whether enough answers are behind it to rank it.
  bool get ranked => answers >= kStrengthAnswers;
}

/// Every skill as the reader's answers have it, the ranked first, strongest
/// first (of two as strong, the one with more answers, then What to learn's
/// order), and after them the ones with too few answers, in that order.
/// Only the answers made before [before] and from [from] on, date keys, when
/// they are given; an answer kept without its day is from before them all.
List<SkillTally> skillTallies(AppState app, {String? before, String? from}) {
  final Map<Skill, int> answers = {for (final Skill s in Skill.values) s: 0};
  final Map<Skill, int> right = {for (final Skill s in Skill.values) s: 0};
  for (final Judgement j in app.judgements) {
    final String? id = j.pillId;
    if (id == null) continue;
    if (before != null && (j.on ?? '').compareTo(before) >= 0) continue;
    if (from != null && (j.on ?? '').compareTo(from) < 0) continue;
    final Pill? p = PillBank.byId(id);
    if (p == null || !p.isGraded) continue;
    for (final Skill s in Skill.values) {
      if (!s.trains(p)) continue;
      answers[s] = answers[s]! + 1;
      if (j.correct) right[s] = right[s]! + 1;
    }
  }
  final List<SkillTally> all = [
    for (final Skill s in Skill.values) SkillTally(s, answers[s]!, right[s]!),
  ];
  final List<SkillTally> ranked =
      [
        for (final SkillTally t in all)
          if (t.ranked) t,
      ]..sort((a, b) {
        final int byRank = b.rank.compareTo(a.rank);
        if (byRank != 0) return byRank;
        final int byAnswers = b.answers.compareTo(a.answers);
        if (byAnswers != 0) return byAnswers;
        return a.skill.index.compareTo(b.skill.index);
      });
  return [
    ...ranked,
    for (final SkillTally t in all)
      if (!t.ranked) t,
  ];
}

/// Cards to practise [skill] on: not read yet, that ask, that can be dealt
/// today, the ones that train it most closely first, [count] at most.
List<Pill> practiceCards(AppState app, Skill skill, {int count = 5}) {
  final int seed = app.today.difference(DateTime(2026)).inDays;
  int mix(String id) {
    var h = 0x811c9dc5 ^ seed;
    for (final int c in id.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  final List<(int, int, Pill)> pool = [
    for (final Pill p in PillBank.cards)
      if (p.isGraded && !app.seenIds.contains(p.id) && dealableOn(p, app.today))
        if (skill.fitOf(p) case final int fit) (fit, mix(p.id), p),
  ]..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2.compareTo(b.$2));
  return [for (final (_, _, Pill p) in pool.take(count)) p];
}

// ── B · The aim's week ─────────────────────────────────────────────────────

/// Whether [p] is one of [aim]'s own cards: in one of its genres or
/// training one of its moves, as the card's back names it ("Useful for").
bool _forAim(Goal aim, Pill p) => (aim.fitOf(p) ?? 2) < 2;

/// What the last [days] days did for the reader's aim: the cards of it
/// read, and the answers given on them, right and in all.
({int cards, int answers, int right}) aimTally(
  AppState app,
  Goal aim, {
  int days = 7,
}) {
  final DateTime t = app.today;
  final String from = dateKey(DateTime(t.year, t.month, t.day - (days - 1)));
  final Set<String> read = {
    for (final MapEntry<String, List<String>> e in app.readDays.entries)
      if (e.key.compareTo(from) >= 0) ...e.value,
  };
  var cards = 0;
  for (final String id in read) {
    final Pill? p = PillBank.byId(id);
    if (p != null && _forAim(aim, p)) cards++;
  }
  var answers = 0, right = 0;
  for (final Judgement j in app.judgements) {
    final String? id = j.pillId, on = j.on;
    if (id == null || on == null || on.compareTo(from) < 0) continue;
    final Pill? p = PillBank.byId(id);
    if (p == null || !_forAim(aim, p)) continue;
    answers++;
    if (j.correct) right++;
  }
  return (
    cards: cards > answers ? cards : answers,
    answers: answers,
    right: right,
  );
}

// ── D · The aim, read ──────────────────────────────────────────────────────

/// The four skills [aim] takes, the one closest to it first: what D ranks
/// under the reader's aim and E turns through, a week each. Every skill
/// serves an area already (Skill.area); an area takes others besides, the
/// money pages' pricing tricks being persuasion as much as money. With no
/// aim, the four most of the cards train.
List<Skill> aimSkills(Goal? aim) => switch (aim) {
  Goal.money => const [
    Skill.money,
    Skill.numbers,
    Skill.persuade,
    Skill.decisions,
  ],
  Goal.business => const [
    Skill.lead,
    Skill.persuade,
    Skill.numbers,
    Skill.people,
  ],
  Goal.people => const [
    Skill.people,
    Skill.talk,
    Skill.persuade,
    Skill.critical,
  ],
  Goal.news => const [
    Skill.fakes,
    Skill.numbers,
    Skill.science,
    Skill.critical,
  ],
  Goal.health => const [
    Skill.science,
    Skill.fakes,
    Skill.focus,
    Skill.decisions,
  ],
  Goal.decide => const [
    Skill.decisions,
    Skill.critical,
    Skill.numbers,
    Skill.persuade,
  ],
  null => const [Skill.critical, Skill.decisions, Skill.numbers, Skill.fakes],
};

/// D's reading of [aim]: its skills with enough answers behind them,
/// strongest first; where the reader sees most clearly, the first; their
/// blind spot, the last, where two or more are ranked; and the ones with
/// too few answers yet.
class AimReading {
  const AimReading({required this.ranked, required this.few});

  final List<SkillTally> ranked;
  final List<SkillTally> few;

  SkillTally? get sharpest => ranked.isEmpty ? null : ranked.first;
  SkillTally? get blind => ranked.length > 1 ? ranked.last : null;
}

/// The reading of [aim] from every answer the reader gave.
AimReading aimReading(AppState app, Goal aim) {
  final List<Skill> skills = aimSkills(aim);
  final List<SkillTally> all = skillTallies(app);
  return AimReading(
    ranked: [
      for (final SkillTally t in all)
        if (t.ranked && skills.contains(t.skill)) t,
    ],
    few: [
      for (final SkillTally t in all)
        if (!t.ranked && skills.contains(t.skill)) t,
    ],
  );
}

// ── E · A focus a week ─────────────────────────────────────────────────────

/// The Monday of [day]'s week, where the reader is.
DateTime weekStartOf(DateTime day) =>
    DateTime(day.year, day.month, day.day - (day.weekday - 1));

/// Whole weeks from the Monday the turn is counted from to [monday]: on the
/// calendar, so a change of the clocks never makes a week short.
int _weeksFrom(DateTime monday) =>
    DateTime.utc(
      monday.year,
      monday.month,
      monday.day,
    ).difference(DateTime.utc(2026, 1, 5)).inDays ~/
    7;

/// The week's one skill: which, from which Monday, and whether the reader's
/// answers chose it (Astute+) or it came in its turn (the free plan, or
/// Astute+ before enough answers).
class WeekFocus {
  const WeekFocus(this.skill, {required this.start, required this.chosen});

  final Skill skill;

  /// The Monday the week starts on.
  final DateTime start;

  /// Whether the reader's answers chose it: the aim's skill they got most
  /// wrong in the two weeks before this one.
  final bool chosen;

  /// The week before.
  DateTime get lastStart => DateTime(start.year, start.month, start.day - 7);

  /// The week after.
  DateTime get nextStart => DateTime(start.year, start.month, start.day + 7);
}

/// The week's skill for the week of [on] (today unless given). On the free
/// plan the aim's four in turn, a week each, the same for every reader with
/// that aim; on Astute+ the one of them the reader got most wrong in the two
/// weeks before, so a week trained well lets the next weakest have its
/// turn; with too few answers in them, in all the weeks before; with too few
/// in those, the turn. Worked out from answers made before the week, so it
/// holds still all week.
WeekFocus weekFocusOf(AppState app, {DateTime? on}) {
  final DateTime start = weekStartOf(on ?? app.today);
  final String key =
      '${dateKey(start)}|${app.judgements.length}|${app.isPlus}|${app.goal}';
  final _Memo memo = _memos[app] ??= _Memo();
  if (memo.focus[key] case final WeekFocus kept) return kept;
  final List<Skill> turn = aimSkills(Goal.of(app.goal));
  WeekFocus? found;
  if (app.isPlus) {
    final String before = dateKey(start);
    final String twoWeeks = dateKey(
      DateTime(start.year, start.month, start.day - 14),
    );
    for (final String? from in [twoWeeks, null]) {
      final List<SkillTally> ranked = [
        for (final SkillTally t in skillTallies(
          app,
          before: before,
          from: from,
        ))
          if (t.ranked && turn.contains(t.skill)) t,
      ];
      // Ranked strongest first: the weakest is the last.
      if (ranked.length > 1) {
        found = WeekFocus(ranked.last.skill, start: start, chosen: true);
        break;
      }
    }
  }
  found ??= WeekFocus(
    turn[_weeksFrom(start) % turn.length],
    start: start,
    chosen: false,
  );
  if (memo.focus.length > 8) memo.focus.clear();
  return memo.focus[key] = found;
}

class _Memo {
  final Map<String, WeekFocus> focus = {};
}

final Expando<_Memo> _memos = Expando('week focus');

/// One day of the week's skill: the answers given on cards that train it,
/// and the right ones. Null for a day still to come.
typedef FocusDay = ({int answers, int right});

/// How [focus]'s week went: day by day, Monday first, and in all, with the
/// cards of it read.
class FocusWeek {
  const FocusWeek({
    required this.days,
    required this.cards,
    required this.answers,
    required this.right,
  });

  /// Monday to Sunday; null for a day after today.
  final List<FocusDay?> days;
  final int cards;
  final int answers;
  final int right;
}

/// The week of [focus] as the reader's record has it, up to today.
FocusWeek focusWeek(AppState app, WeekFocus focus) {
  final DateTime s = focus.start;
  final String today = dateKey(app.today);
  final List<String> keys = [
    for (int d = 0; d < 7; d++) dateKey(DateTime(s.year, s.month, s.day + d)),
  ];
  final Map<String, int> answers = {}, right = {};
  for (final Judgement j in app.judgements) {
    final String? id = j.pillId, on = j.on;
    if (id == null || on == null || !keys.contains(on)) continue;
    final Pill? p = PillBank.byId(id);
    if (p == null || !focus.skill.trains(p)) continue;
    answers[on] = (answers[on] ?? 0) + 1;
    if (j.correct) right[on] = (right[on] ?? 0) + 1;
  }
  var cards = 0;
  for (final String k in keys) {
    for (final String id in app.readDays[k] ?? const <String>[]) {
      final Pill? p = PillBank.byId(id);
      if (p != null && focus.skill.trains(p)) cards++;
    }
  }
  final int given = answers.values.fold(0, (a, b) => a + b);
  return FocusWeek(
    days: [
      for (final String k in keys)
        k.compareTo(today) > 0
            ? null
            : (answers: answers[k] ?? 0, right: right[k] ?? 0),
    ],
    cards: cards > given ? cards : given,
    answers: given,
    right: right.values.fold(0, (a, b) => a + b),
  );
}

/// How much more a card in one of the week's skill's genres is dealt among
/// the reader's own: as much again as a card of the reader's goal, held by
/// the dealer's own bounds (pills_repository.dart, leanOf).
const double kFocusLean = 0.8;

/// [lean], the dealer's lean on the cards' tags, with E's week's skill in
/// it: its genres leaned towards, so the day's own cards lean into the
/// week wherever the phone deals them (a day the server dealt is the
/// server's, which does not know the week's skill). As it ships, and in
/// every other look, [lean] as it was.
Map<String, double> withFocusLean(AppState app, Map<String, double> lean) {
  if (DebugLooks.learnPicked != LearnLook.weekly) return lean;
  final Skill skill = weekFocusOf(app).skill;
  final Map<String, double> out = Map.of(lean);
  for (final String g in skill.genres) {
    out['genre:$g'] = (out['genre:$g'] ?? 0) + kFocusLean;
  }
  return out;
}
