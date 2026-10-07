/// The reader's record over time — what Your journey draws (artboard 137a).
///
/// Everything is counted from what the app wrote down with a date: the cards
/// first read each day ([AppState.readDays]), what each day came to
/// ([AppState.dayLog]), every answer with how sure ([Judgement.on]) and the
/// days the five were finished. What was read or answered before the app
/// dated it is older than anything dated, so it counts from the start; what
/// nothing recorded is left out rather than worked out, and the screen says
/// so instead of drawing it.
library;

import '../data/pills_repository.dart' show dateKey;
import '../models/pill.dart';
import 'progress.dart';

/// Sure, as the journey counts it: the top two of the five steps.
const int kSureFrom = 80;

/// What one day of [AppState.dayLog] holds, by position: the score at the
/// end of the day, the seconds spent on its cards, and the cards read in
/// each part of it.
const int kLogScore = 0;
const int kLogSeconds = 1;
const int kLogParts = 2;
const int kDayLogLength = kLogParts + 4;

/// The most a card is counted for, so a phone put down on a card does not
/// read as an hour spent on it.
const int kMostSecondsACard = 300;

/// The parts of the day a card can be read in.
enum DayPart { morning, afternoon, evening, night }

/// Which part of the day [hour] falls in.
DayPart partOfDay(int hour) {
  if (hour >= 5 && hour < 12) return DayPart.morning;
  if (hour >= 12 && hour < 17) return DayPart.afternoon;
  if (hour >= 17 && hour < 22) return DayPart.evening;
  return DayPart.night;
}

/// A date key back as a day, at midnight UTC so that adding days never
/// meets a change of the clocks.
DateTime dayOfKey(String key) {
  final List<String> p = key.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// The cards first read on each day, as far as what each day dealt can say:
/// a card dealt on a day and read is read on the first day it was dealt.
/// For a phone that read before the app wrote reading down by day.
Map<String, List<String>> readDaysFrom(
  Map<String, List<String>> deckHistory,
  Set<String> seen,
) {
  final out = <String, List<String>>{};
  final placed = <String>{};
  for (final String day in deckHistory.keys.toList()..sort()) {
    for (final String id in deckHistory[day]!) {
      if (seen.contains(id) && placed.add(id)) {
        out.putIfAbsent(day, () => []).add(id);
      }
    }
  }
  return out;
}

/// One week of the journey: from [first] to [last], both date keys, the
/// last being today for the week in hand.
class JourneyWeek {
  const JourneyWeek(this.first, this.last, {required this.current});
  final String first;
  final String last;
  final bool current;
}

/// How a run of answers went: how many, and how many right.
class Tally {
  const Tally(this.right, this.of);
  final int right;
  final int of;
  double? get share => of == 0 ? null : right / of;
}

/// Where the reader stood on one day, worked out again from the dated record.
class _Stood {
  const _Stood(this.held, this.moves, this.movesSet);
  final int held;
  final int moves;
  final Set<Principle> movesSet;
}

/// The record, ready to be asked about any day of it.
class JourneyRecord {
  JourneyRecord({
    required this.today,
    required this.seen,
    required this.readDays,
    required this.dayLog,
    required this.judgements,
    required this.answers,
    required this.completedDates,
    required this.cards,
    required this.liveScore,
    this.otherDays = const [],
  });

  final DateTime today;
  final Set<String> seen;
  final Map<String, List<String>> readDays;
  final Map<String, List<int>> dayLog;
  final List<Judgement> judgements;
  final Map<String, Answer> answers;
  final List<String> completedDates;

  /// The bank, by id.
  final Map<String, Pill> cards;

  /// Today's score as it stands.
  final int liveScore;

  /// Other dates the app wrote down, such as the day each rung was reached:
  /// they can only move the start earlier.
  final Iterable<String> otherDays;

  String get todayKey => dateKey(today);

  /// Today at midnight UTC, for counting days.
  DateTime get _day => DateTime.utc(today.year, today.month, today.day);

  /// The date key [n] days before today.
  String daysBefore(int n) => dateKey(_day.subtract(Duration(days: n)));

  /// The Monday of this week, at midnight UTC.
  DateTime get monday => _day.subtract(Duration(days: _day.weekday - 1));

  /// The first day the app has anything dated for, today if none.
  late final String start = () {
    String first = todayKey;
    void see(String? d) {
      if (d != null && d.length == 10 && d.compareTo(first) < 0) first = d;
    }

    for (final d in readDays.keys) {
      if (readDays[d]!.isNotEmpty) see(d);
    }
    dayLog.keys.forEach(see);
    completedDates.forEach(see);
    for (final j in judgements) {
      see(j.on);
    }
    otherDays.forEach(see);
    return first;
  }();

  /// Days from the start to today, both counted.
  int get daysIn =>
      _day.difference(dayOfKey(start)).inDays.clamp(0, 1 << 20) + 1;

  /// Cards read before the app wrote reading down by day.
  late final Set<String> _undated = () {
    final dated = <String>{for (final ids in readDays.values) ...ids};
    return seen.difference(dated);
  }();

  /// The day each dated card was first read.
  late final Map<String, String> _readOn = () {
    final out = <String, String>{};
    for (final d in readDays.keys.toList()..sort()) {
      for (final id in readDays[d]!) {
        if (seen.contains(id)) out.putIfAbsent(id, () => d);
      }
    }
    return out;
  }();

  /// The cards first read on [day].
  List<String> readOnDay(String day) => [
    for (final id in readDays[day] ?? const <String>[])
      if (_readOn[id] == day) id,
  ];

  /// Every card read by the end of [day]: the dated ones up to it, and the
  /// undated, which are older than all of them.
  Iterable<String> readBy(String day) sync* {
    yield* _undated;
    for (final e in _readOn.entries) {
      if (e.value.compareTo(day) <= 0) yield e.key;
    }
  }

  /// The cards first read from [first] to [last], both date keys.
  Iterable<String> readBetween(String first, String last) sync* {
    for (final e in _readOn.entries) {
      if (e.value.compareTo(first) >= 0 && e.value.compareTo(last) <= 0) {
        yield e.key;
      }
    }
  }

  /// The days anything was read or the five were finished.
  late final Set<String> activeDays = {
    for (final e in readDays.entries)
      if (e.value.isNotEmpty) e.key,
    ...completedDates,
  };

  /// Weeks from the start, seven days each, the last one today's. At most
  /// [most], the latest.
  List<JourneyWeek> weeks({int most = 26}) {
    final DateTime first = dayOfKey(start);
    final int n = _day.difference(first).inDays ~/ 7 + 1;
    final out = <JourneyWeek>[
      for (var i = 0; i < n; i++)
        JourneyWeek(
          dateKey(first.add(Duration(days: 7 * i))),
          i == n - 1 ? todayKey : dateKey(first.add(Duration(days: 7 * i + 6))),
          current: i == n - 1,
        ),
    ];
    return out.length > most ? out.sublist(out.length - most) : out;
  }

  // ── The score ─────────────────────────────────────────────────────────

  /// The graded cards with a dated answer: the ones the replay can follow.
  late final Set<String> _datedCards = {
    for (final j in judgements)
      if (j.pillId != null && j.on != null) j.pillId!,
  };

  /// Cards held and moves spotted as they stood at the end of [day], from
  /// the dated answers in order. A card nothing dated speaks for was
  /// answered before the app dated answers, so it counts as it stands now.
  _Stood _stoodOn(String day) {
    final stage = <String, int>{};
    final right = <String, bool>{};
    for (final j in judgements) {
      final String? id = j.pillId;
      if (id == null || j.on == null || j.on!.compareTo(day) > 0) continue;
      stage[id] = j.correct ? (stage[id] ?? 0) + 1 : 0;
      right[id] = j.correct;
    }
    for (final e in answers.entries) {
      if (_datedCards.contains(e.key)) continue;
      final Pill? pill = cards[e.key];
      if (pill == null || !pill.isGraded) continue;
      stage[e.key] = e.value.stage;
      right[e.key] = pill.challenge.accepts(e.value.response);
    }
    final met = <Principle, int>{};
    final got = <Principle, int>{};
    for (final e in right.entries) {
      final Principle? p = cards[e.key]?.principle;
      if (p == null || !p.isReal) continue;
      met[p] = (met[p] ?? 0) + 1;
      if (e.value) got[p] = (got[p] ?? 0) + 1;
    }
    final moves = <Principle>{
      for (final e in met.entries)
        if (e.value >= 2 && (got[e.key] ?? 0) / e.value >= 0.5) e.key,
    };
    return _Stood(
      stage.values.where((s) => s >= kHeldFromStage).length,
      moves.length,
      moves,
    );
  }

  final Map<String, int> _scores = {};

  /// The score at the end of [day]: today's as it stands, a day the app
  /// wrote down as it was, and an earlier one counted again from the dated
  /// record — the same four parts, as they stood then.
  int scoreOn(String day) {
    if (day.compareTo(todayKey) >= 0) return liveScore;
    return _scores[day] ??= () {
      String? logged;
      for (final d in dayLog.keys) {
        if (d.compareTo(day) <= 0 &&
            (logged == null || d.compareTo(logged) > 0)) {
          logged = d;
        }
      }
      final List<int>? entry = logged == null ? null : dayLog[logged];
      if (entry != null && entry.isNotEmpty) return entry[kLogScore];
      final _Stood stood = _stoodOn(day);
      final completed = <String>{
        for (final d in completedDates)
          if (d.compareTo(day) <= 0) d,
      };
      return Score(
        read: readBy(day).length,
        held: stood.held,
        moves: stood.moves,
        weeks: weeksKept(completed, dayOfKey(day)),
      ).total;
    }();
  }

  /// What a week added to the score, never less than nothing.
  int earnedIn(JourneyWeek week) {
    final String before = dateKey(
      dayOfKey(week.first).subtract(const Duration(days: 1)),
    );
    final int was = before.compareTo(start) < 0 ? 0 : scoreOn(before);
    final int gain = scoreOn(week.last) - was;
    return gain < 0 ? 0 : gain;
  }

  /// What the score has gained in the last [days] days.
  int gainedIn(int days) {
    final String then = daysBefore(days);
    final int was = then.compareTo(start) < 0 ? 0 : scoreOn(then);
    return liveScore - was;
  }

  /// Moves spotted at the end of [day].
  int movesOn(String day) => _stoodOn(day).moves;

  /// The move the reader has had for the shortest time, of the ones they
  /// have now: the one whose dated answers carried it over the line last.
  Principle? newestMove(Set<Principle> now) {
    final days = <String>{
      for (final j in judgements)
        if (j.on != null) j.on!,
    }.toList()..sort();
    final since = <Principle, String>{};
    Set<Principle> before = {};
    for (final d in days) {
      final Set<Principle> on = _stoodOn(d).movesSet;
      for (final p in on.difference(before)) {
        since[p] = d;
      }
      for (final p in before.difference(on)) {
        since.remove(p);
      }
      before = on;
    }
    Principle? newest;
    for (final p in now) {
      final String? d = since[p];
      if (d == null) continue;
      if (newest == null || d.compareTo(since[newest]!) > 0) newest = p;
    }
    return newest;
  }

  // ── Answers ───────────────────────────────────────────────────────────

  /// The answers made by the end of [day], the undated among them.
  Iterable<Judgement> judgedBy(String day) =>
      judgements.where((j) => j.on == null || j.on!.compareTo(day) <= 0);

  /// How often the reader was right when they said they were sure, by the
  /// end of [day].
  Tally sureBy(String day) {
    final sure = judgedBy(day).where((j) => j.confidence >= kSureFrom);
    return Tally(sure.where((j) => j.correct).length, sure.length);
  }

  /// How often the reader was right when they said they were sure, over
  /// the answers dated from [first] to [last].
  Tally sureBetween(String first, String last) {
    final sure = judgements.where(
      (j) =>
          j.confidence >= kSureFrom &&
          j.on != null &&
          j.on!.compareTo(first) >= 0 &&
          j.on!.compareTo(last) <= 0,
    );
    return Tally(sure.where((j) => j.correct).length, sure.length);
  }

  /// The date key [n] days before [day].
  static String before(String day, int n) =>
      dateKey(dayOfKey(day).subtract(Duration(days: n)));

  /// How the cards went when they came back after the [wait]th step of
  /// [kReviewLadder] — two days after a miss, a week after the first
  /// right answer, three weeks after the second — counting the answers
  /// made by the end of [by], or all of them.
  Tally recall(int wait, {String? by}) {
    final run = <String, int>{};
    var right = 0;
    var of = 0;
    for (final j in judgements) {
      final String? id = j.pillId;
      if (id == null) continue;
      // Null the first time a card is answered: that is not a return.
      final int? climbed = run[id];
      final bool counts =
          by == null || j.on == null || j.on!.compareTo(by) <= 0;
      if (climbed == wait && counts) {
        of++;
        if (j.correct) right++;
      }
      run[id] = j.correct ? (climbed ?? 0) + 1 : 0;
    }
    return Tally(right, of);
  }

  // ── The days ──────────────────────────────────────────────────────────

  /// Seconds spent on cards from [first] to [last], as far as the app
  /// timed them.
  int secondsBetween(String first, String last) {
    var s = 0;
    for (final e in dayLog.entries) {
      if (e.key.compareTo(first) < 0 || e.key.compareTo(last) > 0) continue;
      if (e.value.length > kLogSeconds) s += e.value[kLogSeconds];
    }
    return s;
  }

  /// Whether any day was timed, and the first one that was.
  String? get firstTimed {
    String? first;
    for (final e in dayLog.entries) {
      if (e.value.length > kLogSeconds && e.value[kLogSeconds] > 0) {
        if (first == null || e.key.compareTo(first) < 0) first = e.key;
      }
    }
    return first;
  }

  /// The part of the day most cards were read in, once there are enough to
  /// say; null before.
  DayPart? mostlyIn({int atLeast = 10}) {
    final counts = List<int>.filled(DayPart.values.length, 0);
    for (final e in dayLog.values) {
      for (var i = 0; i < DayPart.values.length; i++) {
        if (e.length > kLogParts + i) counts[i] += e[kLogParts + i];
      }
    }
    final int total = counts.fold(0, (a, b) => a + b);
    if (total < atLeast) return null;
    var best = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] > counts[best]) best = i;
    }
    return DayPart.values[best];
  }
}
