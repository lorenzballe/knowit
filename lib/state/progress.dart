/// What the reader has to show for it.
///
/// Everything here is worked out from what the app already writes down —
/// the cards read, the answers committed to, how sure the reader said they
/// were, and which cards came back and stuck. Nothing new is asked of the
/// reader to make any of it true.
library;

import '../data/pills_data.dart';
import '../models/pill.dart';

/// How many judgements before the app is willing to say anything about how
/// well calibrated somebody is. Under this, a run of luck says more than
/// the reader does.
const int kCalibrationFloor = 12;

/// A card is held once it has come back and been got right twice: past the
/// second rung of the review ladder, the app stops asking for a while.
const int kHeldFromStage = 2;

/// Calibration lives where the judgements live — this file does not
/// recount it, it only asks how far off the reader is.

/// A step on the way up.
///
/// Deliberately not a syllabus. The cards are mixed on purpose — a day is
/// five of whatever the reader's mix throws up — so the path cannot be
/// "fifteen cards on this, then fifteen on that". It is the reader who
/// climbs, not the subject: every rung is a claim about how they think,
/// and any five cards at all can carry them up it.
class Rung {
  const Rung(
    this.name,
    this.claim, {
    this.read = 0,
    this.answered = 0,
    this.judged = 0,
    this.gap,
    this.held = 0,
  });

  /// What the rung is called, and what standing on it says about you.
  final String name;
  final String claim;

  /// What it takes: cards read, cards committed to, answers that carried a
  /// confidence, how far off that confidence may be, and cards held.
  final int read;
  final int answered;
  final int judged;
  final double? gap;
  final int held;
}

/// The ladder. Each rung asks for one thing more than the last, and the
/// order is the order in which the habit actually forms: read at all,
/// commit before turning the card over, say how sure you are, be right
/// about how sure you are, and keep what you got.
const List<Rung> kRungs = [
  Rung('Day one', 'Everybody starts here.'),
  Rung('Reading', 'The habit has started.', read: 20),
  Rung(
    'Answering',
    'You commit before you turn the card over.',
    read: 40,
    answered: 20,
  ),
  Rung(
    'Saying how sure',
    'You put a number on what you think you know.',
    read: 70,
    answered: 40,
    judged: 30,
  ),
  Rung(
    'Calibrated',
    'What you say you know, you know.',
    read: 110,
    answered: 70,
    judged: 50,
    gap: 15,
    held: 8,
  ),
  Rung(
    'Holding',
    'It stays with you weeks later.',
    read: 170,
    answered: 110,
    judged: 80,
    gap: 15,
    held: 25,
  ),
  Rung(
    'Sharp',
    'Sure when you should be, and right when you are.',
    read: 260,
    answered: 180,
    judged: 130,
    gap: 10,
    held: 55,
  ),
];

/// What the reader has, measured against what the ladder asks.
class Standing {
  const Standing({
    required this.read,
    required this.answered,
    required this.judged,
    required this.held,
    required this.gap,
  });

  final int read;
  final int answered;
  final int judged;
  final int held;

  /// How far off the reader's confidence is, in points, whichever way —
  /// null until there is enough of a record to mean anything.
  final double? gap;

  bool _clears(Rung rung) =>
      read >= rung.read &&
      answered >= rung.answered &&
      judged >= rung.judged &&
      held >= rung.held &&
      (rung.gap == null || (gap != null && gap! <= rung.gap!));

  /// The highest rung cleared, and the one after it.
  int get at {
    var top = 0;
    for (var i = 0; i < kRungs.length; i++) {
      if (_clears(kRungs[i])) top = i;
    }
    return top;
  }

  Rung get rung => kRungs[at];
  Rung? get next => at + 1 < kRungs.length ? kRungs[at + 1] : null;

  /// How far along the reader is between the rung they are on and the next,
  /// 0 to 1 — the least finished of the things the next rung asks for, so
  /// the bar never runs ahead of the thing that is actually holding it up.
  double get toNext {
    final Rung? up = next;
    if (up == null) return 1;
    final parts = <double>[
      if (up.read > 0) read / up.read,
      if (up.answered > 0) answered / up.answered,
      if (up.judged > 0) judged / up.judged,
      if (up.held > 0) held / up.held,
      if (up.gap != null)
        gap == null ? judged / (up.judged == 0 ? 1 : up.judged) : 1,
    ];
    if (parts.isEmpty) return 1;
    return parts.reduce((a, b) => a < b ? a : b).clamp(0.0, 1.0);
  }

  /// The one thing to do next, named plainly. The furthest-behind of what
  /// the next rung asks for: telling somebody four things at once is
  /// telling them nothing.
  String? get step {
    final Rung? up = next;
    if (up == null) return null;
    final short = <(double, String)>[
      if (up.read > read)
        (read / up.read, '${up.read - read} more cards to read'),
      if (up.answered > answered)
        (
          answered / up.answered,
          '${up.answered - answered} more cards to answer',
        ),
      if (up.judged > judged)
        (
          judged / up.judged,
          '${up.judged - judged} more answers with how sure you are',
        ),
      if (up.held > held)
        (held / up.held, '${up.held - held} more cards to hold'),
      if (up.gap != null && gap != null && gap! > up.gap!)
        (
          up.gap! / gap!,
          'your confidence is ${gap!.round()} points off — '
              '${up.gap!.round()} does it',
        ),
      if (up.gap != null && gap == null)
        (
          judged / kCalibrationFloor,
          '${kCalibrationFloor - judged} more answers before '
              'the app will judge your confidence',
        ),
    ];
    if (short.isEmpty) return null;
    short.sort((a, b) => a.$1.compareTo(b.$1));
    return short.first.$2;
  }
}

/// A card the reader was sure about and wrong about.
class Miss {
  const Miss(this.pill, this.confidence);
  final Pill pill;
  final int confidence;
}

/// The cards worth going back to: wrong, and said with some certainty.
/// Newest first, because the point is what you believed lately.
List<Miss> missesFrom(Iterable<Judgement> judgements, {int from = 70}) {
  final byId = {for (final p in kPillPool) p.id: p};
  final out = <Miss>[];
  for (final j in judgements.toList().reversed) {
    if (j.correct || j.confidence < from) continue;
    final pill = j.pillId == null ? null : byId[j.pillId];
    if (pill == null) continue;
    if (out.any((m) => m.pill.id == pill.id)) continue;
    out.add(Miss(pill, j.confidence));
  }
  return out;
}

/// How many weeks in a row the reader has kept, a week being kept at five
/// days out of seven.
///
/// The daily streak is the sharper number and the crueller one: a flight,
/// a fever or a Saturday and sixty days are gone. This one is what the
/// habit actually looks like from a distance, and it survives a life.
int weeksKept(Set<String> completedDates, DateTime today, {int of = 5}) {
  int days(DateTime monday) {
    var n = 0;
    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final key =
          '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      if (completedDates.contains(key)) n++;
    }
    return n;
  }

  final thisMonday = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: today.weekday - 1));

  var weeks = 0;
  // The week in hand counts only once it is already kept — a Monday is not
  // a broken week yet, so it never breaks the count either.
  var monday = days(thisMonday) >= of
      ? thisMonday
      : thisMonday.subtract(const Duration(days: 7));
  while (days(monday) >= of) {
    weeks++;
    monday = monday.subtract(const Duration(days: 7));
  }
  return weeks;
}

/// What a week came to.
///
/// The daily loop is what the app is; the week is what a reader can see
/// from far enough away to feel a direction. Everything here is counted
/// from the judgements dated since Monday — the ones recorded before the
/// app dated them simply do not appear, which is right: they were not
/// this week.
class WeekReport {
  const WeekReport({
    required this.days,
    required this.answered,
    required this.right,
    required this.gap,
    required this.gapBefore,
    required this.misses,
  });

  /// Days kept, Monday to Sunday.
  final int days;

  /// Answers that carried a confidence, and how many were right.
  final int answered;
  final int right;

  /// How far off that confidence was, this week and the week before —
  /// null where there is too little to say.
  final double? gap;
  final double? gapBefore;

  /// The cards the reader was sure about and wrong about, this week.
  final List<Miss> misses;

  bool get kept => days >= 5;
  bool get empty => days == 0 && answered == 0;

  /// True when the gap closed on last week, by enough to mean it.
  bool? get closing {
    final now = gap;
    final was = gapBefore;
    if (now == null || was == null || (now - was).abs() < 2) return null;
    return now < was;
  }
}

/// A week is short, so it is judged on less than the whole record is.
const int kWeekFloor = 6;

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// The Monday of the week [today] falls in.
DateTime mondayOf(DateTime today) => DateTime(
  today.year,
  today.month,
  today.day,
).subtract(Duration(days: today.weekday - 1));

double? _gapOf(List<Judgement> run) {
  if (run.length < kWeekFloor) return null;
  final counts = <int, int>{};
  final right = <int, int>{};
  for (final j in run) {
    counts[j.confidence] = (counts[j.confidence] ?? 0) + 1;
    if (j.correct) right[j.confidence] = (right[j.confidence] ?? 0) + 1;
  }
  var total = 0.0;
  for (final level in counts.keys) {
    final of = counts[level]!;
    final were = (right[level] ?? 0) * 100 / of;
    total += (level - were).abs() * of;
  }
  return total / run.length;
}

/// Reads a week out of the record.
WeekReport weekReport({
  required Iterable<Judgement> judgements,
  required Iterable<String> completedDates,
  required DateTime today,
}) {
  final monday = mondayOf(today);
  final before = monday.subtract(const Duration(days: 7));
  final String mondayKey = _key(monday);
  final String beforeKey = _key(before);

  final kept = completedDates.toSet();
  var days = 0;
  for (var i = 0; i < 7; i++) {
    if (kept.contains(_key(monday.add(Duration(days: i))))) days++;
  }

  final week = <Judgement>[];
  final last = <Judgement>[];
  for (final j in judgements) {
    final on = j.on;
    if (on == null) continue;
    if (on.compareTo(mondayKey) >= 0) {
      week.add(j);
    } else if (on.compareTo(beforeKey) >= 0) {
      last.add(j);
    }
  }

  return WeekReport(
    days: days,
    answered: week.length,
    right: week.where((j) => j.correct).length,
    gap: _gapOf(week),
    gapBefore: _gapOf(last),
    misses: missesFrom(week),
  );
}
