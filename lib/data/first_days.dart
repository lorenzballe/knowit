/// The first three days: the cards a new reader meets first, chosen by hand.
///
/// A new reader's first mornings used to be dealt like any other: the hooks
/// sharpened, drawn cards weighed eight times, and the rest left to chance.
/// Chance put an encyclopaedia question with a weak drawing on the first
/// card of a first morning, and three cards of words beside it. And the
/// first day was dealt before the onboarding had been answered, so every
/// new reader of a date got the same five whatever they had chosen.
///
/// These are the best cards the bank has for a first impression, judged
/// against docs/cards/SCOPO.md and CRITERI.md: a question that stops you in
/// two seconds, a big drawing that fills the card on both sides, one thing
/// to do with it, a real source, nothing dark. Fifteen make the opening a
/// reader who leaned nowhere is dealt, five a day in the order read; the
/// others are the best of a subject, for a reader who held that subject
/// above the rest.
///
/// Dealt to readers whose first run is on a build that has this
/// (`AppState.firstDays`), on their first [kOpeningDays] days, counted by
/// the days finished before. A reader's own subjects come first; a subject
/// they turned off never comes at all; anything read is not dealt again;
/// and what the opening cannot fill — a mix that keeps few of these
/// subjects — the reader's own dealer fills, as on any day.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/pill.dart';
import '../models/place.dart';
import 'daily.dart';
import 'local_cards.dart';
import 'pill_bank.dart';
import 'pills_repository.dart';
import 'topics.dart';

/// How many of a reader's days open on these cards: the first three.
const int kOpeningDays = 3;

/// One card of the opening, and why it is there.
@immutable
class FirstCard {
  const FirstCard(this.id, {required this.day, required this.why, this.twin});

  /// The card's id in the bank.
  final String id;

  /// The day of the opening it is dealt on to a reader who leaned nowhere,
  /// 1 to 3; 0 for a subject's own, dealt to a reader who held that subject
  /// highest.
  final int day;

  /// Why this card, in a line.
  final String why;

  /// A card telling the same story another way: a reader meets one of the
  /// two, never both.
  final String? twin;
}

/// The opening, in the order it is dealt.
///
/// Each day is three cards to read and two that ask, one of those with a
/// right answer, five subjects, read in this order: a drawing first, then
/// a question, by turns. The subjects' own close the list. Every one was
/// clear in tool/cards/card_check.cjs on three phones when chosen; a card
/// whose drawing is redone should be looked at again before it stays.
const List<FirstCard> kFirstDays = [
  // Day 1.
  FirstCard(
    'nature-half-mountain-tsunami',
    day: 1,
    why:
        'The opener: a question nobody scrolls past, drawn to the owner\'s '
        'own bar (ESEMPI, lesson 6); one tap and the far coast is hit.',
  ),
  FirstCard(
    'food-estimated-weight-mark',
    day: 1,
    why:
        'The ℮ on a packet in every kitchen: a question with a right answer, '
        'then sixty packs weighed. A sum the reader can check in a shop.',
  ),
  FirstCard(
    'thinking-hidden-popcorn',
    day: 1,
    why:
        'A myth about the reader, tried on the reader: the flash as short as '
        'Vicary claimed. Pratkanis and Karremans on the back.',
  ),
  FirstCard(
    'psychology-stroop-other-way',
    day: 1,
    why:
        'An experiment done on yourself before answering, then Stroop\'s own '
        '1935 numbers: reading runs by itself.',
  ),
  FirstCard(
    'technology-hoover-dam-blocks',
    day: 1,
    why:
        'A why with a picture: concrete cools from the outside in, so the '
        'dam was cut into blocks. Pour it each way and watch the heat.',
  ),
  // Day 2.
  FirstCard(
    'nature-longest-straw',
    day: 2,
    why:
        'Nobody sucks a drink up a straw: the air pushes, and gives up at '
        '10.3 m; trees pull. Hand-inked, the style the owner approved.',
  ),
  FirstCard(
    'science-bermuda-gas-myth',
    day: 2,
    why:
        'A famous mystery undone by one date from the US Geological Survey; '
        'what to keep is a way of thinking.',
  ),
  FirstCard(
    'medicine-mri-field-strength',
    day: 2,
    why:
        'An MRI counted in Earths, ten more at every tap: one of the drawings '
        'the owner named as the level.',
  ),
  FirstCard(
    'life-jerks-dont-climb',
    day: 2,
    why:
        'A bet on people at work, settled by a 14-year study (PNAS, 2020) '
        'with its limits said.',
  ),
  FirstCard(
    'thinking-two-four-seven',
    day: 2,
    why:
        'A game: the rule a doubling guess can never crack. Confirmation bias '
        'felt before it is named.',
  ),
  // Day 3.
  FirstCard(
    'science-bradyseism-breathing-ground',
    day: 3,
    why:
        'The owner\'s ideal drawing (ESEMPI, lesson 5): a coast that rises '
        'and sinks over centuries, run with one finger.',
    twin: 'history-baia-sunken-city',
  ),
  FirstCard(
    'space-bones-in-orbit',
    day: 3,
    why:
        'Space through the body: the guess dragged into a bone, then 1–2% a '
        'month, ten times osteoporosis.',
  ),
  FirstCard(
    'maths-knot-tricolorability',
    day: 3,
    why:
        'Maths as play: a three-colour test that tells two knots apart, on a '
        'big red knot that fills the card.',
  ),
  FirstCard(
    'thinking-fukushima-radiation-toll',
    day: 3,
    why:
        'A guess against the record: one death from radiation, over 15,000 '
        'from the wave. What we fear is not what kills.',
  ),
  FirstCard(
    'technology-induction-magnetic-field',
    day: 3,
    why:
        'The hob in the kitchen, explained: the pot is the heater. A bold '
        'pot and coil that fill the card.',
  ),
  // The subjects' own, for a reader who held these highest.
  FirstCard(
    'space-frozen-horizon-light',
    day: 0,
    why:
        'Space: drop things into a black hole and watch them freeze at its '
        'edge. Redrawn to the house style.',
  ),
  FirstCard(
    'history-baia-sunken-city',
    day: 0,
    why:
        'History: the Roman town under the sea, bold and full width; the '
        'same story as the bradyseism card, so never with it.',
    twin: 'science-bradyseism-breathing-ground',
  ),
  FirstCard(
    'history-weighing-the-air',
    day: 0,
    why:
        'History: Pascal\'s bet that air has weight, climbed in 1648; the '
        'guess dragged up the tube, Périer\'s own numbers on the back.',
  ),
  FirstCard(
    'history-glass-that-fell',
    day: 0,
    why:
        'History read in a rock: trinitite\'s two faces say the sand melted '
        'in the air. Eby et al. (2010) on the back.',
  ),
  FirstCard(
    'human_body-alcohol-heat-loss',
    day: 0,
    why:
        'The body: a drink warms the skin and cools the core; one more drink '
        'at a tap, both thermometers moving.',
  ),
  FirstCard(
    'psychology-effort-means-learning',
    day: 0,
    why:
        'The mind: the video that felt harder taught more, which is how '
        'Astute means to teach.',
  ),
  FirstCard(
    'weird_facts-marble-football-fields',
    day: 0,
    why:
        'The strange: a city clad in marble, and why 692 football fields is '
        'a square only 26 a side.',
  ),
  FirstCard(
    'sport-ancient-2',
    day: 0,
    why:
        'Sport: Olympic long jumpers who jumped with stones in their hands, '
        'tested in Nature (2002). Its subject\'s only drawn card.',
  ),
  FirstCard(
    'pop_culture-denim-6',
    day: 0,
    why:
        'Pop culture: denim leaves the dye yellow-green and turns blue in '
        'the air, held up by the reader.',
  ),
];

/// The two of a pair, each way round.
final Map<String, String> _twins = {
  for (final FirstCard c in kFirstDays)
    if (c.twin case final String t) ...{c.id: t, t: c.id},
};

/// Whether [p] may be dealt to anybody today, as the bank's own list has
/// it, and still carries the drawing it was chosen for.
bool _showable(Pill p, DateTime date) =>
    !PillBank.isRetired(p.id) &&
    !p.isAboutAPlace &&
    !p.needsLaterKit &&
    p.book == null &&
    p.hasPage &&
    dealableOn(p, date);

/// The opening's cards this reader may still be dealt, in the order they
/// come: the ones in a subject the reader claimed first, the subject held
/// highest first, then the opening as it is listed.
///
/// Never a card already read ([exclude]), the twin of one, a subject the
/// reader turned off ([topics], by key; Thinking is always on), a card
/// whose every strand is off, or a card the bank no longer deals or
/// draws.
List<Pill> openingFor(
  DateTime date, {
  Set<String>? topics,
  Set<String> claimed = const {},
  Map<String, double> mix = const {},
  Set<String> genresOff = const {},
  Set<String> strandsOff = const {},
  Set<String> exclude = const {},
}) {
  final Set<String> wanted = {
    for (final String key in topics ?? const <String>{}) ?kTopics[key]?.name,
  };
  final Map<String, String> keyOf = {
    for (final e in kTopics.entries) e.value.name: e.key,
  };
  bool strandOn(String strand) =>
      !strandsOff.contains(strand) &&
      !genresOff.contains(strand.substring(0, strand.lastIndexOf('.')));
  final List<(int, Pill)> found = [];
  for (var i = 0; i < kFirstDays.length; i++) {
    final String id = kFirstDays[i].id;
    final Pill? p = PillBank.byId(id);
    if (p == null || !_showable(p, date)) continue;
    if (exclude.contains(id) || exclude.contains(_twins[id])) continue;
    if (wanted.isNotEmpty && !wanted.contains(p.topic)) continue;
    if (p.strands.isNotEmpty && !p.strands.any(strandOn)) continue;
    found.add((i, p));
  }
  double held(Pill p) {
    final String? key = keyOf[p.topic];
    return key != null && claimed.contains(key) ? (mix[key] ?? 1) : -1;
  }

  found.sort((a, b) {
    final int byClaim = held(b.$2).compareTo(held(a.$2));
    return byClaim != 0 ? byClaim : a.$1.compareTo(b.$1);
  });
  return [for (final (_, p) in found) p];
}

/// A day of the reader's opening: the opening's cards first ([openingFor]),
/// then what the reader's own dealer gives for the slots they leave. Null
/// when not one of the opening's cards is left for this reader, and the day
/// is dealt as any other ([dealDay]).
///
/// The shape of the day is the shape of every day: [asksInADay] of the five
/// ask, one of them with a right answer when the opening has one; a card
/// that came due for review takes an asking slot first, on Astute+ (pass
/// [reviews] only there); a card about where the reader lives takes a slot
/// as it does on any day; at most one debate. The first [own] are the
/// reader's own, the asking ones first, as a free day marks them.
///
/// The five are as varied as the reader's mix allows: one card of a
/// subject before any subject has two, and never three.
///
/// [weights], [levels] and [taste] are the reader's own dealer's, as
/// [dealDay] takes them, for the slots the opening leaves.
Deal? dealOpening({
  required DateTime date,
  Set<String>? topics,
  Set<String> claimed = const {},
  Map<String, double> mix = const {},
  Map<String, double> weights = const {},
  Map<String, int> levels = const {},
  Map<String, double> taste = const {},
  Set<String> genresOff = const {},
  Set<String> strandsOff = const {},
  Set<String> exclude = const {},
  List<Pill> reviews = const [],
  int count = kPillsPerDay,
  int own = kOwnCardsFree,
  Place? home,
}) {
  final int asks = asksInADay(count);
  final int ownCount = own.clamp(0, count);
  // As on any day: a review is the reader's own coming back, one at most.
  final List<Pill> review = reviews
      .where((p) => dealableOn(p, date))
      .take(min(ownCount, max(0, asks - 1)))
      .toList();
  final Set<String> taken = {...exclude, ...review.map((p) => p.id)};
  final List<Pill> pool = openingFor(
    date,
    topics: topics,
    claimed: claimed,
    mix: mix,
    genresOff: genresOff,
    strandsOff: strandsOff,
    exclude: taken,
  );
  if (pool.isEmpty) return null;

  final Pill? local = localCardFor(
    date,
    home: home,
    exclude: taken,
    topics: topics,
    genresOff: genresOff,
    strandsOff: strandsOff,
  );
  final int slots = count - review.length - (local == null ? 0 : 1);
  final int askSlots = min(
    slots,
    max(0, asks - review.length - (local?.asksSomething ?? false ? 1 : 0)),
  );

  final List<Pill> picked = [];
  final Map<String, int> bySubject = {
    for (final Pill p in [...review, ?local]) p.topic: 1,
  };
  int asking() => picked.where((p) => p.asksSomething).length;
  bool gradedIn(Iterable<Pill> cards) =>
      cards.any((p) => p.asksSomething && p.isGraded);
  final bool gradedLeft = gradedIn(pool) && !gradedIn(review);
  // One card of a subject first, then a second, and an asking slot kept
  // for a card with a right answer until nothing else can fill it.
  for (final (int cap, bool keepGraded) in [(1, true), (2, true), (2, false)]) {
    for (final Pill p in pool) {
      if (picked.length >= slots) break;
      if (picked.contains(p) || (bySubject[p.topic] ?? 0) >= cap) continue;
      if (picked.any((q) => _twins[q.id] == p.id)) continue;
      if (p.asksSomething) {
        final bool reserve =
            keepGraded && gradedLeft && !p.isGraded && !gradedIn(picked);
        if (asking() >= askSlots - (reserve ? 1 : 0)) continue;
      } else if (picked.length - asking() >= slots - askSlots) {
        continue;
      }
      picked.add(p);
      bySubject[p.topic] = (bySubject[p.topic] ?? 0) + 1;
    }
  }
  // Read in the opening's order, whichever round took them.
  picked.sort((a, b) => pool.indexOf(a).compareTo(pool.indexOf(b)));

  // What the opening left, from the reader's own dealer: never a card the
  // bank marks dark or for adults on a first day, and the drawings weighed
  // as on any day rather than as the first week weighs them — the
  // opening's own are the drawings a first day is shown, and most of the
  // rest are still waiting to be drawn again (ESEMPI, lesson 6).
  final int missing = slots - picked.length;
  final List<Pill> more = [];
  if (missing > 0) {
    final Set<String> held = {...taken, ...picked.map((p) => p.id), ?local?.id};
    bool unfit(Pill p) => p.mature || p.mood == 'dark';
    more.addAll(
      pillsForDate(
        date,
        topics: topics,
        weights: weights,
        levels: levels,
        taste: taste,
        genresOff: genresOff,
        strandsOff: strandsOff,
        strandsDealt: {
          for (final Pill p in [...review, ...picked, ?local])
            if (p.strand.isNotEmpty) p.strand,
        },
        exclude: {
          ...held,
          for (final Pill p in PillBank.cards)
            if (unfit(p)) p.id,
        },
        count: missing,
        asking: max(0, askSlots - asking()),
        debatesDealt: local?.challenge is TakeASide ? 1 : 0,
      ).where((p) => !held.contains(p.id) && !unfit(p)),
    );
    // A bank too small to fill the day is no bank to open on.
    if (more.length < missing) return null;
  }

  List<Pill> asksOf(Iterable<Pill> cards) => [
    for (final Pill p in cards)
      if (p.asksSomething) p,
  ];
  List<Pill> readsOf(Iterable<Pill> cards) => [
    for (final Pill p in cards)
      if (!p.asksSomething) p,
  ];
  final List<Pill> mine = [
    ...review,
    ...asksOf(picked),
    ...asksOf(more),
    ...readsOf(picked),
    ...readsOf(more),
  ];
  return Deal(
    cards: arrangeOpening([
      ...readsOf(picked),
      ...readsOf(more),
      ...asksOf(picked),
      ...asksOf(more),
      ...review,
      ?local,
    ]),
    own: {for (final Pill p in mine.take(ownCount)) p.id},
    local: local,
  );
}

/// The day's shape, as [arrangeDay] gives every day, but in the opening's
/// order rather than by how hard each card is: a card to read first, then
/// one that asks, by turns, and a debate, if the day has one, to close.
/// Each kind keeps the order [cards] has it in.
List<Pill> arrangeOpening(List<Pill> cards) {
  final List<Pill> reads = [
    for (final Pill p in cards)
      if (!p.asksSomething) p,
  ];
  final List<Pill> asks = [
    for (final Pill p in cards)
      if (p.asksSomething && p.challenge is! TakeASide) p,
  ];
  final List<Pill> debates = [
    for (final Pill p in cards)
      if (p.challenge is TakeASide) p,
  ];
  final List<Pill> out = [];
  var wantRead = true;
  while (reads.isNotEmpty || asks.isNotEmpty) {
    final List<Pill> from = wantRead
        ? (reads.isNotEmpty ? reads : asks)
        : (asks.isNotEmpty ? asks : reads);
    out.add(from.removeAt(0));
    wantRead = !wantRead;
  }
  return [...out, ...debates];
}
