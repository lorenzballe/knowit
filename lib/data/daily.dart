/// The five of the day, the same five for everybody.
///
/// A deck dealt from a reader's own mix and history was five cards nobody
/// else had, which meant nobody could talk about them. This is the other
/// thing: one calendar, one edition a day, and every reader in the world
/// opens the same five — so a grid can be shared without spoiling anything,
/// a friend can be asked "did you get the third one", and the morning
/// notification can quote the exact question everyone else is about to
/// meet. Nothing personal enters: the mix, the levels and the history shape
/// what sits *around* the five, never the five.
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

final Map<int, List<Pill>> _dealt = {};

/// The five for [date].
List<Pill> sharedDeckFor(DateTime date) => sharedDeckOfEdition(editionOf(date));

/// The five for an edition.
///
/// Chained: each edition keeps clear of what the editions just before it
/// dealt, for as long as the pool allows, so the same card does not come
/// round again a week later. The chain runs from the first edition, so
/// every phone that holds the same pool deals the same calendar — and when
/// the pool grows, the calendar is re-dealt from the start, which is why
/// the archive keeps a note of what was actually dealt rather than
/// trusting this to say.
List<Pill> sharedDeckOfEdition(int edition) {
  final cached = _dealt[edition];
  if (cached != null) return cached;
  // Everything before the calendar is dealt on its own, chained to nothing:
  // it is an archive that was never really shared.
  final int start = edition < 1 ? edition : 1;
  for (var e = start; e <= edition; e++) {
    _dealt[e] ??= _deal(e);
  }
  return _dealt[edition]!;
}

/// How many editions back a card is kept out of the deal — three quarters
/// of a lap of its kind of the pool, so there is always a real choice left.
int _window(int kind, int perDay) {
  if (perDay == 0) return 0;
  return max(0, (kind / perDay * 0.75).floor());
}

List<Pill> _deal(int edition) {
  final asks = kPillPool.where((p) => p.asksSomething).toList();
  final reads = kPillPool.where((p) => !p.asksSomething).toList();
  final int wantAsks = min(asksInADay(kPillsPerDay), asks.length);
  final int wantReads = min(kPillsPerDay - wantAsks, reads.length);

  final recentAsks = _recent(edition, _window(asks.length, wantAsks));
  final recentReads = _recent(edition, _window(reads.length, wantReads));

  final rng = Random(edition * 7919 + 104729);
  final askOrder = _order(asks, rng, avoid: recentAsks);
  final readOrder = _order(reads, rng, avoid: recentReads);

  final deck = <Pill>[];
  final subjects = <String>{};

  // Asking first: at most one debate, and at least one card that can be
  // marked, because a debate is ungraded and a day of opinions measures
  // nothing. The debate, when there is one, is what closes the day.
  var debates = 0;
  for (final p in askOrder) {
    if (deck.length >= wantAsks) break;
    final bool debate = p.challenge is TakeASide;
    if (debate && (debates >= 1 || wantAsks - deck.length == 1 && !_hasGraded(deck))) {
      continue;
    }
    if (debate) debates++;
    deck.add(p);
    subjects.add(p.topic);
  }
  _top(deck, askOrder, wantAsks);

  // Then reading, one subject each while there are subjects to spread over:
  // three facts from one shelf is not a day, it is a chapter.
  final taken = deck.length;
  for (final p in readOrder) {
    if (deck.length >= taken + wantReads) break;
    if (subjects.contains(p.topic)) continue;
    deck.add(p);
    subjects.add(p.topic);
  }
  _top(deck, readOrder, taken + wantReads);
  _top(deck, [...readOrder, ...askOrder], kPillsPerDay);

  return arrangeDay(deck);
}

bool _hasGraded(List<Pill> deck) => deck.any((p) => p.isGraded);

/// Fills [deck] up to [count] from [from], in order, skipping what is in it.
void _top(List<Pill> deck, List<Pill> from, int count) {
  for (final p in from) {
    if (deck.length >= count) return;
    if (!deck.contains(p)) deck.add(p);
  }
}

/// The ids dealt in the [back] editions before [edition].
Set<String> _recent(int edition, int back) {
  final out = <String>{};
  for (var e = edition - back; e < edition; e++) {
    final past = _dealt[e];
    if (past == null) continue;
    for (final p in past) {
      out.add(p.id);
    }
  }
  return out;
}

/// A seeded order with the recently dealt pushed to the back rather than
/// cut: a small pool must still deal a full day.
List<Pill> _order(List<Pill> pills, Random rng, {required Set<String> avoid}) {
  final fresh = <Pill>[];
  final stale = <Pill>[];
  for (final p in pills) {
    (avoid.contains(p.id) ? stale : fresh).add(p);
  }
  fresh.shuffle(rng);
  stale.shuffle(rng);
  return [...fresh, ...stale];
}

/// Forgets every deal. For tests that change what the pool holds.
void resetSharedDecks() => _dealt.clear();
