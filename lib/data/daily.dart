/// The day: what is the reader's own in it, and what is everybody's.
///
/// A day is five cards. On the free plan two of them are the reader's own —
/// dealt from their mix, at the level they said they were — and three are
/// everybody's: the question of the day, and two more that every free
/// reader in the world meets on the same day. The day after a full week
/// kept, three are the reader's own and two are everybody's.
///
/// With Astute+ all five are the reader's own: from the strands they keep
/// on, at the level the app has measured rather than the one they said,
/// never a card already read, with a card that came due for review, and
/// leaned by what they held and what they threw down.
///
/// The question of the day is the one card a friend can be asked about
/// ("did you get it?"), the one the morning notification can quote a
/// fortnight ahead, and the one square in the shared grid that means the
/// same thing on every phone. It costs the mix nothing: it is always one of
/// Thinking's, and Thinking was never off anybody's deck. The subjects ask
/// questions of their own too, and those are dealt from the mix.
library;

import 'dart:math';

import '../models/pill.dart';
import 'pill_bank.dart';
import 'pills_repository.dart';
import 'topics.dart';

/// The day the calendar began. Edition 1.
final DateTime kEpoch = DateTime(2026, 9, 1);

/// How many of a free day's five are the reader's own: one, beside the
/// question of the day and three of the edition's. Astute+ makes it five.
const int kOwnCardsFree = 1;

/// How many are the reader's own the day after a full week kept: the
/// streak's own reward, and the thing Astute+ has more of, tasted once a
/// week by a reader who has not paid for it.
const int kOwnCardsRewarded = 2;

/// How many of a day's [kPillsPerDay] are the reader's own.
///
/// All of them on Astute+. On the free plan [kOwnCardsFree], or
/// [kOwnCardsRewarded] on the morning after the streak reaches a multiple
/// of seven — nothing to redeem and nothing to press: the deck simply has
/// one more.
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

/// The question of the day for [date].
Pill questionOfTheDay(DateTime date) => questionOfEdition(editionOf(date));

/// The question of the day for an edition.
///
/// The bank carries a calendar — edition to card id — frozen when it was
/// built and extended a year ahead every night, so the same question is
/// asked on every phone whatever else the bank did in between. Past the end
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
  // Thinking's, as the calendar the bundler writes is: the question is
  // everybody's, and Thinking is the one subject on every deck. The
  // subjects' own questions are dealt from the mix instead.
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

/// How many cards an edition holds in common besides its question: the three
/// a free day deals, and two spares for a reader who has already read one.
const int kCommonSpares = 5;

/// The cards that are everybody's on an edition, besides the question of
/// the day, in the order a free day takes them.
///
/// Cards that tell rather than ask, from the whole bank rather than any
/// mix — that is what makes them everybody's — each edition chained clear
/// of the ones before it, so the same card does not come round for weeks,
/// and never two of one subject in the same edition. A free day takes the
/// first [kOwnCardsFree]-ish it has not already read, so two readers who
/// have read different things still mostly share the same three.
List<Pill> commonOfEdition(int edition) {
  _followTheBank();
  final cached = _commons[edition];
  if (cached != null) return cached;
  final int start = edition < 1 ? edition : 1;
  for (var e = start; e <= edition; e++) {
    _commons[e] ??= _tell(e);
  }
  return _commons[edition]!;
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
  const Deal({required this.cards, required this.own, this.question});

  final List<Pill> cards;

  /// The ids of the cards dealt from the reader's mix — the ones a free
  /// day marks, and the ones Astute+ makes all five of.
  final Set<String> own;

  /// The question of the day, when the day carries it. A day that is all
  /// the reader's own does not.
  final Pill? question;
}

/// A day: [own] cards of the reader's own, and the rest everybody's.
///
/// Every card the reader's own when [own] reaches [count]: the asking
/// slots go first to a card that came due for review, if one did, and then
/// to a fresh question from the mix, and the reading slots are the mix's
/// entirely. Otherwise the question of the day takes the first asking slot
/// and the edition's common cards fill what the reader's own leave, which
/// puts the day's second question among the reader's own. Then the day is
/// arranged rather than sorted.
Deal dealDay({
  required DateTime date,
  Set<String>? topics,
  Map<String, double> weights = const {},
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
  final bool whole = own >= count;
  final Pill? question = whole ? null : questionOfTheDay(date);
  // A review is the reader's own, coming back. One at most, so a day
  // always has one question it has never asked.
  final review = reviews
      .where((p) => p.id != question?.id)
      .take(max(0, asks - 1))
      .toList();

  final taken = <String>{...exclude, ?question?.id, ...review.map((p) => p.id)};
  final common = <Pill>[];
  if (!whole) {
    final int wanted = max(0, count - 1 - own);
    for (final p in commonOfEdition(editionOf(date))) {
      if (common.length >= wanted) break;
      if (!taken.add(p.id)) continue;
      common.add(p);
    }
  }

  final int dealt = (question == null ? 0 : 1) + common.length;
  final int ownAsks = max(0, asks - (question == null ? 0 : 1));
  final rest = pillsForDate(
    date,
    topics: topics,
    weights: weights,
    levels: levels,
    taste: taste,
    genresOff: genresOff,
    strandsOff: strandsOff,
    strandsDealt: {
      for (final p in [?question, ...common, ...review])
        if (p.strand.isNotEmpty) p.strand,
    },
    exclude: taken,
    count: max(0, count - dealt - review.length),
    asking: max(0, ownAsks - review.length),
  );
  final mine = [...review, ...rest];
  return Deal(
    cards: arrangeDay([?question, ...common, ...mine]),
    own: {for (final p in mine) p.id},
    question: question,
  );
}

/// Forgets every deal: for tests that change what the pool holds, and for
/// the bank when a newer bundle is adopted.
void resetCalendar() {
  _questions.clear();
  _commons.clear();
}
