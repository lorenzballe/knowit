/// The day: what is the reader's own in it, and what is dealt at random.
///
/// A day is five cards. With Astute+ all five are the reader's own: from
/// the strands they keep on, at the level the app has measured rather than
/// the one they said, never a card already read, with a card that came due
/// for review, and leaned by what they held and what they threw down.
///
/// On the free plan two of the five are the reader's own and three are
/// dealt at random from the subjects they kept on, from the first morning.
/// The morning after a full week kept, three are their own.
///
/// Nothing in a day is everybody's any more. The question of the day and
/// the edition's cards are still kept in the calendar the bank carries, for
/// the site, for the widget that has not heard from the app, and for
/// whatever Explore makes of them, but no day deals them.
library;

import 'dart:math';

import '../models/pill.dart';
import 'pill_bank.dart';
import 'pills_repository.dart';
import 'topics.dart';

/// The day the calendar began. Edition 1.
final DateTime kEpoch = DateTime(2026, 9, 1);

/// How many of a free day's five are the reader's own: two, beside three
/// dealt at random. Astute+ makes it five.
const int kOwnCardsFree = 2;

/// How many are the reader's own the day after a full week kept: the
/// streak's own reward, and the thing Astute+ has more of, tasted once a
/// week by a reader who has not paid for it.
const int kOwnCardsRewarded = 3;

/// How many of a day's [kPillsPerDay] are the reader's own.
///
/// All of them on Astute+. On the free plan [kOwnCardsFree] from the first
/// day, or [kOwnCardsRewarded] on the morning after the streak reaches a
/// multiple of seven: nothing to redeem and nothing to press, the deck
/// simply has one more.
///
/// The first days read used to be a welcome, four of the five the reader's
/// own with no card asked for. Beside Astute+'s free trial it was a second
/// free thing, and two free things read as one too many: the one way to
/// try all five is now the trial, and the free day is the same from the
/// first morning, so what Astute+ adds is there to see from the start.
int ownCardsFor({required bool plus, required int streak}) {
  if (plus) return kPillsPerDay;
  return streak > 0 && streak % 7 == 0 ? kOwnCardsRewarded : kOwnCardsFree;
}

/// Which edition a date is: the first day is 1, and every day after it one
/// more. Days before the calendar started come out at zero and below, and
/// still deal — there is an archive to reconstruct.
int editionOf(DateTime date) =>
    DateTime(date.year, date.month, date.day).difference(kEpoch).inDays + 1;

/// The date an edition falls on.
DateTime dateOfEdition(int edition) =>
    DateTime(kEpoch.year, kEpoch.month, kEpoch.day + edition - 1);

/// How many of a day's cards ask something. Two of five: a card that asks
/// takes a minute and a decision, a card that tells takes a breath — and a
/// day that is four decisions long is a day that gets skipped. Two is still
/// two judgements a day, which is what the calibration record is made of.
int asksInADay(int count) => (count * kAskShare).round();

final Map<int, Pill> _questions = {};
final Map<int, List<Pill>> _commons = {};

/// Which bank the chains above were dealt from. A newer bundle brings its
/// own calendar, and a chain dealt from the old one would contradict it.
BankBundle? _dealtFrom;

void _followTheBank() {
  if (identical(_dealtFrom, PillBank.current)) return;
  _questions.clear();
  _commons.clear();
  _dealtFrom = PillBank.current;
}

/// The question of the day for [date]: the calendar's, which no day deals
/// any more. The site shows it, and so does the widget until the app has
/// told it the reader's own.
Pill questionOfTheDay(DateTime date) => questionOfEdition(editionOf(date));

/// The question of the day for an edition.
///
/// The bank carries a calendar — edition to card id — frozen when it was
/// built and extended a year ahead every night, so an edition names the same
/// question on every phone and on the site whatever else the bank did in
/// between. Past the end
/// of the calendar, or on a phone that never updates, the chain below takes
/// over: each edition keeps clear of what the editions before it asked, for
/// three quarters of a lap of Thinking's cards that can be marked, so the same
/// question does not come round again for months. The archive still keeps a
/// note of what was actually dealt rather than trusting either to say.
Pill questionOfEdition(int edition) {
  _followTheBank();
  final cached = _questions[edition];
  if (cached != null) return cached;
  // Everything before the calendar is dealt on its own, chained to nothing:
  // it is an archive that was never really shared.
  final int start = edition < 1 ? edition : 1;
  for (var e = start; e <= edition; e++) {
    _questions[e] ??= _frozen(e) ?? _ask(e);
  }
  return _questions[edition]!;
}

Pill? _frozen(int edition) {
  final id = PillBank.editions[edition];
  if (id == null) return null;
  final pill = PillBank.byId(id);
  return (pill != null && pill.asksSomething && pill.isGraded) ? pill : null;
}

Pill _ask(int edition) {
  final graded = PillBank.cards
      .where((p) => p.asksSomething && p.isGraded)
      .toList();
  if (graded.isEmpty) return PillBank.cards.first;
  // Thinking's, as the calendar the bundler writes is: Thinking is the one
  // subject on every mix.
  final thinking = graded
      .where((p) => p.topic == kTopics['thinking']!.name)
      .toList();
  final pool = thinking.isEmpty ? graded : thinking;
  final int window = max(0, (pool.length * 0.75).floor());
  final recent = <String>{
    for (var e = edition - window; e < edition; e++) ?_questions[e]?.id,
  };
  final rng = Random(edition * 7919 + 104729);
  final fresh = pool.where((p) => !recent.contains(p.id)).toList()
    ..shuffle(rng);
  if (fresh.isNotEmpty) return fresh.first;
  final stale = List<Pill>.from(pool)..shuffle(rng);
  return stale.first;
}

/// How many cards an edition keeps besides its question: eight, of eight
/// subjects out of eighteen.
const int kCommonSpares = 8;

/// The cards the calendar keeps for an edition besides its question.
///
/// Cards that tell rather than ask, from the whole bank rather than any
/// mix, frozen in the bank's calendar by `bundle.py`, and past its end
/// chained clear of the ones before, so the same card does not come round
/// for weeks, and never two of one subject in the same edition. No day
/// deals them any more: a free day's cards that are not the reader's own
/// are dealt at random (see [dealDay]). The calendar keeps them, the same
/// on the phone and the server, for whatever is made of them next.
List<Pill> commonOfEdition(int edition) {
  _followTheBank();
  final cached = _commons[edition];
  if (cached != null) return cached;
  final int start = edition < 1 ? edition : 1;
  for (var e = start; e <= edition; e++) {
    _commons[e] ??= _frozenCommons(e) ?? _tell(e);
  }
  return _commons[edition]!;
}

/// The edition's cards as the bank froze them, or null past the end of the
/// calendar or on a bank from before they were frozen. Frozen, like the
/// question, so the phone and the server (see `functions/`) read the same
/// calendar.
List<Pill>? _frozenCommons(int edition) {
  final List<String>? ids = PillBank.commons[edition];
  if (ids == null) return null;
  final List<Pill> cards = [
    for (final id in ids)
      if (PillBank.byId(id) case final Pill p when !p.asksSomething) p,
  ];
  return cards.isEmpty ? null : cards;
}

List<Pill> _tell(int edition) {
  final pool = PillBank.cards.where((p) => !p.asksSomething).toList();
  if (pool.isEmpty) return const [];
  // A lap of the reading cards, at five an edition, keeps a card out for
  // as long as the pool allows; on a bank of a few hundred that is weeks,
  // and the bank grows every night.
  final int window = max(0, (pool.length * 0.75).floor() ~/ kCommonSpares);
  final recent = <String>{
    for (var e = edition - window; e < edition; e++)
      ...?_commons[e]?.map((p) => p.id),
  };
  final rng = Random(edition * 6007 + 91);
  final fresh = pool.where((p) => !recent.contains(p.id)).toList()
    ..shuffle(rng);
  final stale = pool.where(recent.contains).toList()..shuffle(rng);
  final picked = <Pill>[];
  final topics = <String>{};
  for (final p in [...fresh, ...stale]) {
    if (picked.length >= kCommonSpares) break;
    if (!topics.add(p.topic)) continue;
    picked.add(p);
  }
  return picked;
}

/// A day, dealt: the cards in the order they are read, and which of them
/// are the reader's own.
class Deal {
  const Deal({required this.cards, required this.own});

  final List<Pill> cards;

  /// The ids of the cards dealt from the reader's mix: the ones a free day
  /// marks, and the ones Astute+ makes all five of.
  final Set<String> own;
}

/// A day: [own] cards of the reader's own, and the rest at random.
///
/// The reader's own come first, and the asking slots are theirs before
/// they are chance's: a question at the reader's level trains, and one
/// drawn at random only quizzes. A card that came due for review takes an
/// asking slot before any fresh question does, then fresh questions from
/// the mix, then reads. What the reader's own leave is dealt at random
/// ([pillsAtRandom]) from the subjects they kept on, as much of each as
/// [mix] asks for, and nothing else about them. Then the day is arranged
/// rather than sorted.
///
/// [weights] is the mix the reader's own are dealt from, leaned and
/// sharpened as the reading of the reader says; [mix] is the mix as they
/// set it, for the part dealt at random. Without [mix], [weights] serves
/// both.
Deal dealDay({
  required DateTime date,
  Set<String>? topics,
  Map<String, double> weights = const {},
  Map<String, double>? mix,
  Map<String, int> levels = const {},
  Map<String, double> taste = const {},
  Set<String> genresOff = const {},
  Set<String> strandsOff = const {},
  Set<String> exclude = const {},
  List<Pill> reviews = const [],
  int count = kPillsPerDay,
  int own = kOwnCardsFree,
}) {
  final int asks = asksInADay(count);
  final int ownCount = own.clamp(0, count);
  // A review is the reader's own, coming back. One at most, so a day
  // always has one question it has never asked.
  final review = reviews.take(min(ownCount, max(0, asks - 1))).toList();
  final taken = <String>{...exclude, ...review.map((p) => p.id)};

  final int ownAsks = min(asks, ownCount);
  final rest = pillsForDate(
    date,
    topics: topics,
    weights: weights,
    levels: levels,
    taste: taste,
    genresOff: genresOff,
    strandsOff: strandsOff,
    strandsDealt: {
      for (final p in review)
        if (p.strand.isNotEmpty) p.strand,
    },
    exclude: taken,
    count: max(0, ownCount - review.length),
    asking: max(0, ownAsks - review.length),
  );
  final mine = [...review, ...rest];

  final chance = pillsAtRandom(
    date,
    count: max(0, count - mine.length),
    asking: max(0, asks - mine.where((p) => p.asksSomething).length),
    topics: topics,
    weights: mix ?? weights,
    genresOff: genresOff,
    strandsOff: strandsOff,
    exclude: {...taken, ...mine.map((p) => p.id)},
    topicsDealt: {for (final p in mine) p.topic},
    strandsDealt: {
      for (final p in mine)
        if (p.strand.isNotEmpty) p.strand,
    },
  );
  return Deal(
    cards: arrangeDay([...mine, ...chance]),
    own: {for (final p in mine) p.id},
  );
}

/// Forgets every deal: for tests that change what the pool holds, and for
/// the bank when a newer bundle is adopted.
void resetCalendar() {
  _questions.clear();
  _commons.clear();
}
