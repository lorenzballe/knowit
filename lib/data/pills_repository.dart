import 'dart:math';
import 'dart:math' as math;

import '../models/pill.dart';
import 'pills_data.dart';
import 'topics.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// How many pills a free day holds. Astuto+ unlocks a second set of the same
/// size once the first is done.
const int kPillsPerDay = 5;

/// How much of a day should ask something of the reader rather than tell.
///
/// Reading facts has no evidence behind it as reasoning training — the
/// large review of brain training found gains only on the exact task
/// practised (Simons et al., 2016). What does transfer is answering, being
/// wrong, and being told which move you missed (Morewedge et al., 2015).
///
/// So a day is mostly asking. One fact opens it: a fact is a reason to come
/// and it opens up a subject, which is worth one card in five and not four.
const double kAskShare = 0.8;

/// The first five anybody ever sees, chosen rather than dealt.
///
/// A generated first day is a gamble on the worst possible occasion. These
/// five are picked to be the app arguing for itself: something startling that
/// costs nothing to read, the trap almost everybody falls into, a survivorship
/// case from a kitchen drawer, an arithmetic catch that lands in a second, and
/// an argument with two real sides to close on.
///
/// It is also the answer to personalising a first session. A questionnaire
/// cannot help here — four cards in five have to ask something and everything
/// that asks is one subject — so the honest way to make the opening feel
/// chosen is to choose it.
const List<String> kOpeningDeck = [
  'science-4',
  'thinking-1',
  'thinking-5',
  'thinking-9',
  'thinking-d6',
];

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

  /// How much of each subject the reader asked for, 0..1 by topic key. When
  /// this is empty the deck spreads evenly, which is what it always did.
  Map<String, double> weights = const {},
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

  // With a mix to honour, order by it. Without one, spread the topics out so
  // a day never opens with two of the same subject running together.
  final byName = {
    for (final entry in kTopics.entries)
      entry.value.name: weights[entry.key] ?? 0.0,
  };
  final ordered = weights.isEmpty
      ? [for (final tier in tiers) ..._oneTopicFirst(tier)]
      : [
          for (final tier in tiers)
            ..._weightedOrder(tier, byName, Random(seed)),
        ];

  // Fill the asking slots first, then top the day up with reading. Both
  // fall back to whatever is left, so a reader who has turned every asking
  // topic off still gets a full day.
  final wantAsks = (count * kAskShare).round();

  // At most one debate a day. A debate is ungraded on purpose, so it feeds
  // nothing back into calibration — and now that the pool holds twenty of
  // them, a day picked purely at random can come out as four opinions in a
  // row and measure nothing at all.
  const maxDebates = 1;
  var debates = 0;
  final asks = <Pill>[];
  for (final p in ordered.where((p) => p.asksSomething)) {
    if (asks.length >= wantAsks) break;
    final isDebate = p.challenge is TakeASide;
    if (isDebate) {
      if (debates >= maxDebates) continue;
      debates++;
    }
    asks.add(p);
  }
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

/// Orders pills so each subject turns up about as often as it was asked for.
///
/// This is the exponential race: draw a key of -ln(u) / w for each item and
/// sort ascending, which samples without replacement in proportion to the
/// weights. Seeded, so a day does not reshuffle under the reader.
List<Pill> _weightedOrder(
  List<Pill> pills,
  Map<String, double> byName,
  Random rng,
) {
  if (pills.isEmpty) return pills;
  final keyed = <(double, Pill)>[];
  for (final pill in pills) {
    final w = byName[pill.topic] ?? 0.0;
    // A subject pushed all the way in still exists — it just goes last,
    // which is what keeps a day full when the mix is narrow.
    final weight = w <= 0 ? 1e-6 : w;
    final u = rng.nextDouble().clamp(1e-12, 1.0);
    keyed.add((-math.log(u) / weight, pill));
  }
  keyed.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final entry in keyed) entry.$2];
}
