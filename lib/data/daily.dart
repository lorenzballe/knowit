/// The question of the day: one card that asks, the same for everybody.
///
/// A day is five cards, four of them the reader's own — dealt from their
/// mix, what they said they know, what came due for review — and one that
/// every reader in the world meets on the same day. That one is the
/// question of the day. It is the card a friend can be asked about ("did
/// you get it?"), the one the morning notification can quote a fortnight
/// ahead, and the one square in the shared grid that means the same thing
/// on every phone. It costs the mix nothing: every card that asks and can
/// be marked lives under Thinking, and Thinking was never off anybody's
/// deck.
library;

import 'dart:math';

import '../models/pill.dart';
import 'pills_data.dart';
import 'pills_repository.dart';

/// The day the calendar began. Edition 1.
final DateTime kEpoch = DateTime(2026, 9, 1);

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

/// The question of the day for [date].
Pill questionOfTheDay(DateTime date) => questionOfEdition(editionOf(date));

/// The question of the day for an edition.
///
/// Chained: each edition keeps clear of what the editions before it asked,
/// for three quarters of a lap of the cards that can be marked, so the same
/// question does not come round again for months. The chain runs from the
/// first edition on every phone that holds the same pool, which is what
/// makes it the same question everywhere — and when the pool grows the
/// chain is re-dealt from the start, which is why the archive keeps a note
/// of what was actually dealt rather than trusting this to say.
Pill questionOfEdition(int edition) {
  final cached = _questions[edition];
  if (cached != null) return cached;
  // Everything before the calendar is dealt on its own, chained to nothing:
  // it is an archive that was never really shared.
  final int start = edition < 1 ? edition : 1;
  for (var e = start; e <= edition; e++) {
    _questions[e] ??= _ask(e);
  }
  return _questions[edition]!;
}

Pill _ask(int edition) {
  final pool = kPillPool.where((p) => p.asksSomething && p.isGraded).toList();
  if (pool.isEmpty) return kPillPool.first;
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

/// A day: the question of the day, and four cards of the reader's own.
///
/// The two asking slots go first to the question of the day and then to a
/// card that came due for review, if one did; only when none did does the
/// second go to a fresh question from the mix. The three reading slots are
/// the mix's entirely. Then the day is arranged rather than sorted.
List<Pill> dealDay({
  required DateTime date,
  Set<String>? topics,
  Map<String, double> weights = const {},
  Map<String, int> levels = const {},
  Set<String> exclude = const {},
  List<Pill> reviews = const [],
  int count = kPillsPerDay,
}) {
  final Pill question = questionOfTheDay(date);
  final int asks = asksInADay(count);
  final review = reviews
      .where((p) => p.id != question.id)
      .take(max(0, asks - 1))
      .toList();
  final int personalAsks = max(0, asks - 1 - review.length);
  final rest = pillsForDate(
    date,
    topics: topics,
    weights: weights,
    levels: levels,
    exclude: {...exclude, question.id, ...review.map((p) => p.id)},
    count: count - 1 - review.length,
    asking: personalAsks,
  );
  return arrangeDay([question, ...review, ...rest]);
}

/// Forgets every deal. For tests that change what the pool holds.
void resetCalendar() => _questions.clear();
