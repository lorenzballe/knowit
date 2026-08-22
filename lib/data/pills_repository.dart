import 'dart:math';

import '../models/pill.dart';
import 'pills_data.dart';
import 'topics.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Deterministic "5 pills for today" — same date always yields the same set
/// and order, so the deck doesn't reshuffle mid-day or across devices.
///
/// [topics] restricts the mix to the topic keys the reader picked. When fewer
/// than five pills match, the rest of the pool tops the deck back up so the
/// day is never short.
List<Pill> pillsForDate(DateTime date, {Set<String>? topics}) {
  final seed = date.year * 10000 + date.month * 100 + date.day;
  final pool = List<Pill>.from(kPillPool);
  pool.shuffle(Random(seed));

  final wanted = <String>{};
  for (final key in topics ?? const <String>{}) {
    final style = kTopics[key];
    if (style != null) wanted.add(style.name);
  }

  final preferred = wanted.isEmpty
      ? pool
      : pool.where((p) => wanted.contains(p.topic)).toList();
  final fallback = pool.where((p) => !preferred.contains(p)).toList();

  final ordered = [..._oneTopicFirst(preferred), ..._oneTopicFirst(fallback)];
  return ordered.take(5).toList();
}

/// Front-loads one pill per topic so a day never opens with two in a row from
/// the same subject.
List<Pill> _oneTopicFirst(List<Pill> pills) {
  final byTopic = <String, Pill>{};
  final rest = <Pill>[];
  for (final p in pills) {
    if (!byTopic.containsKey(p.topic)) {
      byTopic[p.topic] = p;
    } else {
      rest.add(p);
    }
  }
  return [...byTopic.values, ...rest];
}

/// Free-text search across the whole pool — question, answer and topic.
List<Pill> searchPills(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List<Pill>.from(kPillPool);
  return kPillPool.where((p) {
    final hay = '${p.question} ${p.answer} ${p.topic} ${p.barMove}';
    return hay.toLowerCase().contains(q);
  }).toList();
}
