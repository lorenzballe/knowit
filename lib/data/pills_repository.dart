import 'dart:math';

import '../models/pill.dart';
import 'pills_data.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Deterministic "5 pills for today" — same date always yields the same set
/// and order, so the deck doesn't reshuffle mid-day or across devices.
List<Pill> pillsForDate(DateTime date) {
  final seed = date.year * 10000 + date.month * 100 + date.day;
  final pool = List<Pill>.from(kPillPool);
  pool.shuffle(Random(seed));

  final byTopic = <String, Pill>{};
  final rest = <Pill>[];
  for (final p in pool) {
    if (!byTopic.containsKey(p.topic)) {
      byTopic[p.topic] = p;
    } else {
      rest.add(p);
    }
  }
  final ordered = [...byTopic.values, ...rest];
  return ordered.take(5).toList();
}
