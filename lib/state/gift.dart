/// The new reader's gift of Astute+ (`trial.reverse`): all of it for
/// fourteen days, held on the phone, with nothing bought, no card asked for
/// and nothing to cancel. What Astute+ adds is only understood by using it
/// for days, and the first run's offer of the store's trial asked for it
/// after one card; the gift gives the days first and asks after them.
///
/// The rules, all here, where the tests hold them:
///
/// - **Who.** A new reader, in the first run, where the first run would
///   offer the trial after its one card ([giftDue]): the switch on for
///   them, Astute+ not theirs already, the store never having held it for
///   them (a trial or a plan, running or over), and neither this reader's
///   account nor this phone having given a gift before. The web's preview
///   is not a phone, and gives none.
/// - **How long.** [AppState.kGiftDays] days from the first run's day: the
///   fifteenth is the free plan's ([AppState.giftEndsOn]). Held to that
///   date on every phone the reader signs in on: the account keeps the
///   first day (ReaderSnapshot.giftFrom), a merge keeps the earlier, and a
///   new phone neither starts another nor moves its end. A sign-out takes
///   the gift with the reader, and the phone remembers it gave one.
/// - **Never against the store.** It is not a purchase and the store knows
///   nothing of it. A reader who buys in it has the plan and the store's
///   own free days ([AppState.paidPlus]); the gift's end is then not said.
///   The paywall sells to a reader in their gift as to any other.
/// - **The last two days.** One quiet line, on the finished day's shelf
///   ([AppState.giftDaysLeft]), and on the thirteenth, for a reader with the
///   nudge on, that morning's nudge says it.
/// - **The end.** The first morning after it, before the five are begun,
///   once, within [kGiftEndLastDays] of it: what the fourteen days came to,
///   in the reader's own numbers, and what goes back to the free plan; then
///   the paywall ([giftEndDue], lib/screens/gift_pages.dart).
library;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../data/daily.dart' show ownCardsFor, isSunday;
import '../data/pill_bank.dart' show PillBank;
import '../data/pills_repository.dart' show dateKey, daysBetween, kPillsPerDay;
import '../models/pill.dart';
import '../sync/subscription.dart';
import 'app_state.dart';

/// The days after the gift in which its end can still be said: a reader
/// back after a month is not told about a fortnight long gone.
const int kGiftEndLastDays = 14;

/// Whether the first run gives the gift now, where it would offer the
/// store's trial. See the library's own words for who.
bool giftDue(AppState app, {Subscription? store, bool web = kIsWeb}) {
  final Subscription s = store ?? Subscription.instance;
  return !web &&
      app.reverseTrialOn &&
      !app.onboarded &&
      app.giftFrom == null &&
      !app.giftGiven &&
      !app.paidPlus &&
      !s.isPlus &&
      !(s.ready && s.everHeldPlus);
}

/// Whether the gift's end is to be said now: the gift is over and never
/// became a plan, the end not said yet, within [kGiftEndLastDays] of it,
/// and today's five not begun — the morning the plan changes, before the
/// day it changes. Only once the store has answered, where there is one,
/// so a plan bought on another phone is heard of first.
bool giftEndDue(AppState app, {Subscription? store}) {
  final Subscription s = store ?? Subscription.instance;
  final DateTime? ends = app.giftEndsOn;
  if (ends == null || app.giftEndShownOn != null) return false;
  if (app.onGift || app.paidPlus || s.isPlus) return false;
  if (s.hasStore && !s.ready) return false;
  final int since = daysBetween(ends, app.today);
  if (since < 0 || since >= kGiftEndLastDays) return false;
  return app.onboarded && app.todayIndex == 0 && !app.dayClosed;
}

/// What the gift came to, in the reader's own numbers, and what the free
/// plan deals in its place: what the page at its end says.
class GiftNumbers {
  const GiftNumbers({
    required this.days,
    required this.of,
    required this.cards,
    required this.backRight,
    required this.random,
    this.gapWas,
    this.gap,
  });

  /// Days the five were finished in the gift's days, of its [of].
  final int days;
  final int of;

  /// Cards first read in the gift's days, wherever they were read.
  final int cards;

  /// How far off the reader's sureness ran, in points, the first day of the
  /// gift it could be said and at its end; null under the floor.
  final double? gapWas;
  final double? gap;

  /// Moves missed and then got right when they came back, in its days.
  final int backRight;

  /// How many of the five the free plan deals at random, today.
  final int random;

  /// Whether the gap moved from the first measure to the last, in whole
  /// points: only then is it said as from one to the other.
  bool get gapMoved =>
      gapWas != null && gap != null && gapWas!.round() != gap!.round();

  /// [app]'s reader's numbers, from what the app already keeps.
  factory GiftNumbers.of(AppState app) {
    final DateTime? from = _dayOf(app.giftFrom);
    final List<String> days = from == null
        ? const []
        : [
            for (int i = 0; i < AppState.kGiftDays; i++)
              dateKey(DateTime(from.year, from.month, from.day + i)),
          ];
    final Set<String> inGift = days.toSet();
    double? was;
    for (final String day in days) {
      was = app.confidenceGapOn(day);
      if (was != null) break;
    }
    return GiftNumbers(
      days: app.completedDates.where(inGift.contains).toSet().length,
      of: AppState.kGiftDays,
      cards: <String>{for (final String day in days) ...?app.readDays[day]}
          .length,
      gapWas: was,
      gap: days.isEmpty ? null : app.confidenceGapOn(days.last),
      backRight: backRightIn(app.judgements, inGift),
      random:
          kPillsPerDay -
          ownCardsFor(
            plus: false,
            streak: app.liveStreak,
            sunday: isSunday(app.today),
          ),
    );
  }

  /// Numbers to look at the page with, from the developer tools and the
  /// camera: a fortnight read most days.
  factory GiftNumbers.sample() => const GiftNumbers(
    days: 12,
    of: AppState.kGiftDays,
    cards: 62,
    gapWas: 17,
    gap: 12,
    backRight: 7,
    random: 3,
  );

  /// The moves missed in [days] and got right later in them, once each: a
  /// card that came back is often another card of the same move, so they
  /// are counted by the move, and by the card where it trains none.
  static int backRightIn(List<Judgement> judgements, Set<String> days) {
    final Map<String, String> missedOn = {};
    final Set<String> back = {};
    for (final Judgement j in judgements) {
      final String? on = j.on;
      final String? id = j.pillId;
      if (on == null || id == null || !days.contains(on)) continue;
      final Principle principle =
          PillBank.byId(id)?.principle ?? Principle.none;
      final String move = principle.isReal ? principle.name : id;
      if (!j.correct) {
        missedOn.putIfAbsent(move, () => on);
      } else if ((missedOn[move]?.compareTo(on) ?? 0) < 0) {
        back.add(move);
      }
    }
    return back.length;
  }

  static DateTime? _dayOf(String? key) {
    if (key == null) return null;
    final List<int?> parts = key.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return null;
    return DateTime(parts[0]!, parts[1]!, parts[2]!);
  }
}
