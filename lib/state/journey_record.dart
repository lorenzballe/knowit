/// The reader twice: two weeks in, and today — what the top of Your journey
/// sets side by side (artboard 134b).
///
/// "Two weeks in" is the fourteenth day from the first one the app knew of,
/// and the comparison is only offered once that day is a week behind the
/// reader: set against yesterday, it says nothing. Everything in it is
/// counted from what the app wrote down with a date — the day each rung was
/// reached, every answer with how sure, and the day's counts — and what was
/// not written down then is not worked out now: it is left empty, and the
/// screen shows a dash.
library;

import '../data/pills_repository.dart' show dateKey;
import '../models/pill.dart';
import 'app_state.dart';
import 'progress.dart';

/// Sure, as the journey counts it: the top two of the five steps.
const int kSureFrom = 80;

/// Two weeks in is the fourteenth day, thirteen after the first.
const int kTwoWeeksIn = 13;

/// How long after two weeks in before the comparison is offered.
const int kCompareAfter = 7;

/// Where the reader stood on one day.
class RecordAt {
  const RecordAt({
    required this.level,
    this.sureRight,
    this.gap,
    this.moves,
    this.held,
    this.read,
    this.curve = const [],
  });

  /// The rung, as an index into [kRungs].
  final int level;

  /// How often the reader was right when they said they were sure, as a
  /// percentage; null with no sure answer yet.
  final double? sureRight;

  /// How far their confidence was from their results, in points; null
  /// until there are enough answers to say ([kCalibrationFloor]).
  final double? gap;

  /// Moves they could spot, cards still with them, and cards read. Null
  /// when nothing was written down that day to say.
  final int? moves;
  final int? held;
  final int? read;

  /// How sure they said, against how often they were right, level by level.
  final List<CalibrationBucket> curve;
}

/// Each confidence level, and how it went, over [judgements].
List<CalibrationBucket> bucketsOf(Iterable<Judgement> judgements) => [
  for (final int level in kConfidenceLevels)
    if (judgements.any((j) => j.confidence == level))
      CalibrationBucket(
        level,
        judgements.where((j) => j.confidence == level).length,
        judgements.where((j) => j.confidence == level && j.correct).length,
      ),
];

/// Points off, as [AppState.confidenceGap] counts them.
double? gapOf(List<CalibrationBucket> buckets) {
  final int n = buckets.fold<int>(0, (a, b) => a + b.count);
  if (n < kCalibrationFloor) return null;
  return buckets.fold<double>(0, (a, b) => a + b.gap.abs() * b.count) / n;
}

/// How often the reader was right when they said they were sure.
double? sureRightOf(Iterable<Judgement> judgements) {
  final sure = judgements.where((j) => j.confidence >= kSureFrom).toList();
  if (sure.isEmpty) return null;
  return sure.where((j) => j.correct).length / sure.length * 100;
}

DateTime _day(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// The first day the app knew the reader, as a date key: the earliest of
/// the first rung's date and the days read.
String? journeyStart(
  Map<String, String> rungDates,
  List<String> completedDates,
) {
  final keys = [?rungDates[kRungs.first.id], ...completedDates]
    ..removeWhere((k) => !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(k));
  if (keys.isEmpty) return null;
  keys.sort();
  return keys.first;
}

/// Two weeks in, as a date key.
String twoWeeksIn(String start) =>
    dateKey(_day(start).add(const Duration(days: kTwoWeeksIn)));

/// Whether two weeks in is far enough behind [today] to set beside it.
bool canCompare(String start, DateTime today) {
  final DateTime then = _day(twoWeeksIn(start));
  final DateTime now = DateTime(today.year, today.month, today.day);
  return now.difference(then).inDays >= kCompareAfter;
}

/// Which day of the journey [today] is: the first day is day one.
int dayOf(String start, DateTime today) {
  final DateTime now = DateTime(today.year, today.month, today.day);
  return now.difference(_day(start)).inDays + 1;
}

/// The reader as they stood at the end of [on].
RecordAt recordOn(AppState app, String on) {
  var level = 0;
  for (var i = 0; i < kRungs.length; i++) {
    final String? reached = app.rungDates[kRungs[i].id];
    if (reached != null && reached.compareTo(on) <= 0) level = i;
  }
  // Answers from before the app dated them cannot be placed, so they are
  // left out of the past and only counted today.
  final dated = app.judgements
      .where((j) => j.on != null && j.on!.compareTo(on) <= 0)
      .toList();
  final List<CalibrationBucket> curve = bucketsOf(dated);
  // The counts as written down on the last day there was anything to
  // write: nothing moved in between.
  final List<String> days =
      app.recordDays.keys.where((k) => k.compareTo(on) <= 0).toList()..sort();
  final List<int>? counts = days.isEmpty ? null : app.recordDays[days.last];
  return RecordAt(
    level: level,
    sureRight: sureRightOf(dated),
    gap: gapOf(curve),
    read: counts != null && counts.isNotEmpty ? counts[0] : null,
    held: counts != null && counts.length > 1 ? counts[1] : null,
    moves: counts != null && counts.length > 2 ? counts[2] : null,
    curve: curve,
  );
}

/// The reader today.
RecordAt recordNow(AppState app) => RecordAt(
  level: app.standing.at,
  sureRight: sureRightOf(app.judgements),
  gap: app.confidenceGap,
  moves: app.movesDown,
  held: app.heldCards,
  read: app.seenIds.length,
  curve: app.calibration.toList(),
);
