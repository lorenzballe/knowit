import 'dart:math';

import '../models/pill.dart';
import 'pills_data.dart';
import 'topics.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// How many pills a free day holds. Knowit+ unlocks a second set of the same
/// size once the first is done.
const int kPillsPerDay = 5;

/// How much of a day should ask something of the reader rather than tell.
///
/// Without a floor the mix collapses: everything that asks lives under one
/// topic, and a deck that takes one card per topic then deals four facts and
/// a single puzzle. An app that trains reasoning cannot be four fifths
/// reading.
const double kAskShare = 0.4;

/// Deterministic pills for a day — the same date, topic mix and reading
/// history always yield the same set and order, so the deck doesn't reshuffle
/// mid-day or across devices.
///
/// [topics] restricts the mix to the topic keys the reader picked. [exclude]
/// holds the ids already read on earlier days, which are kept out until the
/// pool runs dry. When too few pills match, the rest of the pool tops the deck
/// back up so a day is never short.
List<Pill> pillsForDate(
  DateTime date, {
  Set<String>? topics,
  Set<String> exclude = const {},
  int count = kPillsPerDay,
}) {
  final seed = date.year * 10000 + date.month * 100 + date.day;
  final pool = List<Pill>.from(kPillPool);
  pool.shuffle(Random(seed));

  final wanted = <String>{};
  for (final key in topics ?? const <String>{}) {
    final style = kTopics[key];
    if (style != null) wanted.add(style.name);
  }

  bool onTopic(Pill p) => wanted.isEmpty || wanted.contains(p.topic);

  // Best to worst: unread and on-topic, unread anything, then read again once
  // the pool cannot cover a fresh day.
  final tiers = [
    pool.where((p) => onTopic(p) && !exclude.contains(p.id)).toList(),
    pool.where((p) => !onTopic(p) && !exclude.contains(p.id)).toList(),
    pool.where((p) => onTopic(p) && exclude.contains(p.id)).toList(),
    pool.where((p) => !onTopic(p) && exclude.contains(p.id)).toList(),
  ];

  final ordered = [for (final tier in tiers) ..._oneTopicFirst(tier)];

  // Fill the asking slots first, then top the day up with reading. Both
  // fall back to whatever is left, so a reader who has turned every asking
  // topic off still gets a full day.
  final wantAsks = (count * kAskShare).round();
  final asks = ordered.where((p) => p.asksSomething).take(wantAsks).toList();
  final reads = ordered
      .where((p) => !p.asksSomething)
      .take(count - asks.length)
      .toList();

  final deck = [...asks, ...reads];
  if (deck.length < count) {
    deck.addAll(
      ordered.where((p) => !deck.contains(p)).take(count - deck.length),
    );
  }
  return arrangeDay(deck);
}

/// Gives a day a shape rather than a sort order.
///
/// Sorting by difficulty looked sensible and was not: facts are easy and
/// anything that asks is not, so every day came out as all the reading first
/// and then a pile of work at the end, when attention is lowest.
///
/// Instead: reading and answering alternate, the hardest card lands early
/// while there is attention to spend on it, and a debate closes — it is the
/// one card meant to be carried away rather than finished.
List<Pill> arrangeDay(List<Pill> cards) {
  if (cards.length < 3) return cards;

  int byEase(Pill a, Pill b) =>
      a.difficulty.index.compareTo(b.difficulty.index);

  final reads = [...cards.where((c) => !c.asksSomething)]..sort(byEase);
  final asks = [...cards.where((c) => c.asksSomething)]..sort(byEase);

  Pill? closer;
  final debate = asks.indexWhere((c) => c.challenge is TakeASide);
  if (debate >= 0) closer = asks.removeAt(debate);

  // The hardest of what is left goes near the front, not at the back.
  if (asks.length > 1) asks.insert(0, asks.removeLast());

  final out = <Pill>[];
  var wantRead = true;
  while (reads.isNotEmpty || asks.isNotEmpty) {
    final pool = wantRead
        ? (reads.isNotEmpty ? reads : asks)
        : (asks.isNotEmpty ? asks : reads);
    out.add(pool.removeAt(0));
    wantRead = !wantRead;
  }
  if (closer != null) out.add(closer);
  return out;
}

/// Looks pills back up by id — used to restore a day's deck across restarts.
List<Pill> pillsByIds(List<String> ids) {
  final byId = {for (final p in kPillPool) p.id: p};
  return [
    for (final id in ids)
      if (byId[id] != null) byId[id]!,
  ];
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
