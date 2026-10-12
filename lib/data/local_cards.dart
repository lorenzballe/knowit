/// The cards about where a reader lives: which of them reach the reader,
/// nearest first, the one a day deals, and the shelf of them in Explore.
///
/// A card about a place goes to the readers who live there and nowhere
/// else (docs/PLACES.md §5). The bank keeps such cards out of everything
/// it deals to everybody ([PillBank.cards]); this is the one road they
/// take, and it starts from the reader's own place. The server deals them
/// the same way (`localCard` in functions/src/deal.ts, `whereYouLive` in
/// explore.ts), and the fit both sides use is lib/models/place.dart's,
/// held to the same cases.
library;

import 'dart:math';

import '../models/pill.dart';
import '../models/place.dart';
import 'pill_bank.dart';
import 'pills_repository.dart';
import 'topics.dart';

/// Whether [pill] may be put in front of a reader who lives at [home]: a
/// card for everybody always, a card about a place only where they live.
bool reachesReader(Pill pill, Place? home) {
  final CardPlace? place = pill.place;
  return place == null || placeFit(place, home) != PlaceFit.none;
}

/// The cards about where the reader lives, each with how it fits, nearest
/// first: their city's, then their region's, then their country's, in the
/// bank's order inside each. Nothing without a place, and never a card
/// whose place the reader is not in. [on] leaves out a card past its
/// expiry on that day.
List<({Pill pill, PlaceFit fit})> placeCardsFor(
  Place? home, {
  Iterable<Pill>? from,
  DateTime? on,
}) {
  if (home == null) return const [];
  final Map<PlaceFit, List<Pill>> byFit = {
    for (final PlaceFit fit in PlaceFit.values) fit: <Pill>[],
  };
  for (final Pill p in from ?? PillBank.placeCards) {
    final CardPlace? place = p.place;
    if (place == null || (on != null && !dealableOn(p, on))) continue;
    byFit[placeFit(place, home)]!.add(p);
  }
  return [
    for (final PlaceFit fit in const [
      PlaceFit.city,
      PlaceFit.region,
      PlaceFit.country,
    ])
      for (final Pill p in byFit[fit]!) (pill: p, fit: fit),
  ];
}

/// The day's card about where the reader lives, or null for an ordinary
/// day: no place, or nothing left for it.
///
/// The nearest there is — a card about their city before one about their
/// region, and that before one about their country — and never one in
/// [exclude], which holds what they have read. Inside the nearest fit, a
/// card on the mix and ready before one waiting for a card it builds on,
/// before one under a genre turned off, before one off the subjects
/// altogether. Among equals, the date and the reading history decide, as
/// they do for the cards at random ([pillsAtRandom]): the same morning
/// dealt twice is the same morning.
Pill? localCardFor(
  DateTime date, {
  required Place? home,
  Set<String> exclude = const {},
  Set<String>? topics,
  Set<String> genresOff = const {},
  Set<String> strandsOff = const {},
  Iterable<Pill>? from,
}) {
  final fitting = [
    for (final c in placeCardsFor(home, from: from, on: date))
      if (!exclude.contains(c.pill.id)) c,
  ];
  if (fitting.isEmpty) return null;
  // Summed rather than chained, so the order the history is held in cannot
  // change the seed.
  var seed = stableHash('local:${dateKey(date)}');
  for (final String id in exclude) {
    seed = (seed + stableHash(id)) & 0x1FFFFFFF;
  }
  final Random rng = Random(seed);

  final Set<String> wanted = {
    for (final key in topics ?? const <String>{}) ?kTopics[key]?.name,
  };
  bool onTopic(Pill p) => wanted.isEmpty || wanted.contains(p.topic);
  bool strandOn(String strand) =>
      !strandsOff.contains(strand) &&
      !genresOff.contains(strand.substring(0, strand.lastIndexOf('.')));
  bool onMix(Pill p) =>
      onTopic(p) && (p.strands.isEmpty || p.strands.any(strandOn));
  bool ready(Pill p) => p.buildsOn.every(exclude.contains);
  int tierOf(Pill p) {
    if (onMix(p)) return ready(p) ? 0 : 1;
    return onTopic(p) ? 2 : 3;
  }

  final ranked = [
    for (final c in fitting)
      (
        pill: c.pill,
        near: c.fit.index,
        tier: tierOf(c.pill),
        u: rng.nextDouble(),
      ),
  ];
  ranked.sort((a, b) {
    final int nearer = b.near.compareTo(a.near);
    if (nearer != 0) return nearer;
    final int kept = a.tier.compareTo(b.tier);
    return kept != 0 ? kept : a.u.compareTo(b.u);
  });
  return ranked.first.pill;
}

/// How many cards Explore's "Where you live" holds.
const int kWhereYouLiveShelf = 12;

/// Explore's "Where you live": the cards about the reader's place, nearest
/// first — their city's, then their region's, then their country's — and
/// inside each the ones not yet [read] before the ones read, in [seed]'s
/// order, which turns over with the month. Read ones stay, marked: the
/// shelf is the reader's home, not a list of finds. Empty without a place
/// and before any card is written for it. The server's shelf, card for
/// card (`whereYouLive` in functions/src/explore.ts).
List<Pill> whereYouLive(
  Place? home, {
  Set<String> read = const {},
  required String seed,
  int count = kWhereYouLiveShelf,
  Iterable<Pill>? from,
}) {
  final ranked = [
    for (final c in placeCardsFor(home, from: from))
      (
        pill: c.pill,
        near: c.fit.index,
        read: read.contains(c.pill.id) ? 1 : 0,
        key: stableHash('$seed${c.pill.id}'),
      ),
  ];
  ranked.sort((a, b) {
    final int nearer = b.near.compareTo(a.near);
    if (nearer != 0) return nearer;
    final int unread = a.read.compareTo(b.read);
    if (unread != 0) return unread;
    final int byKey = a.key.compareTo(b.key);
    return byKey != 0 ? byKey : a.pill.id.compareTo(b.pill.id);
  });
  return [for (final r in ranked.take(count)) r.pill];
}
