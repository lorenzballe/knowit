/// The first week's page, and the first month's: a reader on the free plan,
/// at the end of their seventh day of reading, or of a day a month after
/// the install, is shown what the week or the month came to in their own
/// numbers, and offered the year's free days under them. Once each, and
/// never again (lib/screens/first_offer.dart is the page).
///
/// Readers of an app like this one start many of their trials late, a
/// quarter of them a month or more after the install; a moment that is the
/// reader's own, at the end of a first week, says more than a locked door.
/// So the page says nothing the app does not know, and asks for nothing the
/// reader did not come for: it rises after the five, never during them,
/// and "Not now" is as plain as the trial.
///
/// The rules, all here, where the tests hold them ([firstOfferDue]):
///
/// - **The week** comes at the end of the seventh day the five are
///   finished: seven days, not seven in a row. A missed Tuesday does not
///   make a week less read, the streak is the crueller number, and the
///   store's rating prompt already waits for a week in a row. An evening
///   taken by something else moves it to the next day finished, up to the
///   tenth ([kFirstWeekLastDays]); after that it is gone.
/// - **The month** comes at the end of a day finished thirty days or more
///   after the install, up to the forty-fourth, to a reader with seven days
///   of reading at least, and two weeks at least after the week's page.
/// - **Only on the free plan, to a reader who never had a trial.** Never on
///   Astute+, never to a reader the store has ever held Astute+ for — a
///   trial or a plan, running or over — and never unless the store sells
///   the year with free days to this reader. The page is an offer of free
///   days: a reader the store will not give them to is not shown it at all,
///   rather than shown a price to pay today at the end of their first week.
/// - **Once each**, kept for the phone ([AppState.firstWeekOfferedOn]).
/// - **One full-screen moment a day**: not on a day the first run offered
///   the trial, a level rose, or the other page rose. On the evening a level
///   and the page are both due, the level wins: it is the reader's, the page
///   is the app's, and the page can come on the next day finished.
/// - **One question an evening**: not on the evening the reminder sheet or
///   the store's rating sheet has; and on the evening it rises, the
///   account's, the place's and the widget's sheets wait for another
///   (AppState.firstOfferRoseToday).
/// - **Right after the five**: the day finished in this sitting, the shelf
///   landed (TodayScreen).
library;

import '../data/pill_bank.dart' show PillBank;
import '../data/pills_repository.dart' show dateKey, daysBetween;
import '../data/topics.dart' show kTopics;
import '../models/pill.dart';
import '../sync/subscription.dart';
import 'app_state.dart';
import 'journey_record.dart' show Tally, dayOfKey, kSureFrom;

/// The two pages.
enum FirstOffer {
  week('first week'),
  month('first month');

  const FirstOffer(this.source);

  /// Its name where it is counted: the screen's, and the door the paywall's
  /// numbers say a trial started from.
  final String source;
}

/// The days the five are finished on which the first week's page comes,
/// the first and the last.
const int kFirstWeekDays = 7;
const int kFirstWeekLastDays = 10;

/// The days since the install on which the first month's page comes, the
/// first and the last, and the days of reading it needs at least.
const int kFirstMonthDays = 30;
const int kFirstMonthLastDays = 44;
const int kFirstMonthReadDays = 7;

/// The least time between the two pages, in days.
const int kFirstOffersApart = 14;

/// Answers said 80% sure or more before the page says how often they were
/// right: one sure answer, wrong, is not "right 0% of the time".
const int kOfferSureFloor = 3;

/// Answers in a subject before it can be called the strongest: a week has
/// fewer to go on than the journey's six, a month has the journey's. Of
/// each subject, the latest [kOfferSubjectSample] are counted, as the
/// journey counts them.
const int kOfferSubjectFloorWeek = 4;
const int kOfferSubjectFloorMonth = 6;
const int kOfferSubjectSample = 20;

/// Why a card is the best of the week or the month: the most the reader did
/// with it, in this order.
enum BestCardWhy { said, liked, saved, changed }

/// What a page says: the reader's own numbers, from what the app already
/// keeps, or a sample for the developer tools' preview.
class FirstOfferNumbers {
  const FirstOfferNumbers({
    required this.days,
    required this.cards,
    required this.streak,
    this.sure,
    this.strongest,
    this.best,
    this.bestWhy,
  });

  /// Days the five were finished.
  final int days;

  /// Cards read, wherever they were read.
  final int cards;

  /// Days in a row, as the streak stands tonight.
  final int streak;

  /// How often right when said 80% sure or more; null under
  /// [kOfferSureFloor].
  final Tally? sure;

  /// The subject answered best, by its key, and how its latest answers
  /// went; null while no subject has enough answers to say it.
  final ({String key, Tally tally})? strongest;

  /// The best card, and why it is; null when the reader did nothing more
  /// with any card than read it.
  final Pill? best;
  final BestCardWhy? bestWhy;

  /// [app]'s reader's numbers, everything so far: the page comes at the end
  /// of the first week or the first month, so so far is that week or month.
  factory FirstOfferNumbers.of(AppState app, FirstOffer which) {
    final Iterable<Judgement> sure = app.judgements.where(
      (j) => (j.confidence ?? 0) >= kSureFrom,
    );
    final Tally sureTally = Tally(
      sure.where((j) => j.correct).length,
      sure.length,
    );
    final (Pill, BestCardWhy)? best = bestCardOf(app);
    return FirstOfferNumbers(
      days: app.completedDates.toSet().length,
      cards: app.seenIds.length,
      streak: app.liveStreak,
      sure: sureTally.of >= kOfferSureFloor ? sureTally : null,
      strongest: strongestOf(
        app.judgements,
        floor: which == FirstOffer.week
            ? kOfferSubjectFloorWeek
            : kOfferSubjectFloorMonth,
      ),
      best: best?.$1,
      bestWhy: best?.$2,
    );
  }

  /// Numbers to look at the page with, from the developer tools: a week
  /// read every day, or a month read most days, and a real card of the bank
  /// as the best.
  factory FirstOfferNumbers.sample(FirstOffer which) {
    final Pill? card = PillBank.cards
        .where((p) => p.question.trim().isNotEmpty && p.isGraded)
        .elementAtOrNull(which == FirstOffer.week ? 3 : 11);
    return switch (which) {
      FirstOffer.week => FirstOfferNumbers(
        days: 7,
        cards: 35,
        streak: 7,
        sure: const Tally(8, 10),
        strongest: (key: 'history', tally: const Tally(5, 6)),
        best: card,
        bestWhy: card == null ? null : BestCardWhy.said,
      ),
      FirstOffer.month => FirstOfferNumbers(
        days: 22,
        cards: 113,
        streak: 9,
        sure: const Tally(31, 40),
        strongest: (key: 'psychology', tally: const Tally(15, 18)),
        best: card,
        bestWhy: card == null ? null : BestCardWhy.liked,
      ),
    };
  }

  /// The subject [judgements] say the reader is strongest in: of the latest
  /// [kOfferSubjectSample] answers in each subject with [floor] or more, the
  /// most often right, the more answers breaking a tie. Null when none has
  /// enough.
  static ({String key, Tally tally})? strongestOf(
    List<Judgement> judgements, {
    required int floor,
  }) {
    final Map<String, String> keyOf = {
      for (final e in kTopics.entries) e.value.name: e.key,
    };
    final Map<String, List<bool>> byKey = {};
    for (final Judgement j in judgements) {
      final String? id = j.pillId;
      final String? key = id == null ? null : keyOf[PillBank.byId(id)?.topic];
      if (key == null) continue;
      byKey.putIfAbsent(key, () => []).add(j.correct);
    }
    ({String key, Tally tally})? best;
    for (final MapEntry<String, List<bool>> e in byKey.entries) {
      if (e.value.length < floor) continue;
      final List<bool> latest = e.value.reversed
          .take(kOfferSubjectSample)
          .toList();
      final Tally t = Tally(latest.where((c) => c).length, latest.length);
      final Tally? b = best?.tally;
      if (b == null ||
          t.share! > b.share! ||
          (t.share == b.share && t.of > b.of)) {
        best = (key: e.key, tally: t);
      }
    }
    return best;
  }

  /// The card the reader did the most with: one they said to somebody, then
  /// one they liked, one they saved, one that changed their mind — the
  /// latest of the first kind there is. Null when there is none.
  static (Pill, BestCardWhy)? bestCardOf(AppState app) {
    Pill? card(String id) {
      final Pill? p = PillBank.byId(id);
      return p != null && p.question.trim().isNotEmpty ? p : null;
    }

    for (final String id in app.saidIds) {
      if (card(id) case final Pill p) return (p, BestCardWhy.said);
    }
    for (final String id in app.likedIds) {
      if (card(id) case final Pill p) return (p, BestCardWhy.liked);
    }
    for (final String id in app.savedIds) {
      if (card(id) case final Pill p) return (p, BestCardWhy.saved);
    }
    for (final MapEntry<String, String> e
        in app.reactions.entries.toList().reversed) {
      if (e.value != Reaction.changed.key) continue;
      if (card(e.key) case final Pill p) return (p, BestCardWhy.changed);
    }
    return null;
  }
}

/// Which page the days have reached for [app]'s reader, if one: the week's
/// between the seventh and the tenth day finished, in the first month; the
/// month's between the thirtieth and the forty-fourth day since the
/// install, with a week of reading in it, two weeks at least after the
/// week's. Each only while the server has it on, and only if it has never
/// gone up on this phone.
FirstOffer? firstOfferWindow(AppState app) {
  final int read = app.completedDates.toSet().length;
  final int since = app.daysSinceInstall;
  if (since >= kFirstMonthDays) {
    if (since > kFirstMonthLastDays || read < kFirstMonthReadDays) return null;
    if (!app.firstMonthOfferOn || app.firstMonthOfferedOn != null) return null;
    final String? week = app.firstWeekOfferedOn;
    if (week != null &&
        daysBetween(dayOfKey(week), app.today) < kFirstOffersApart) {
      return null;
    }
    return FirstOffer.month;
  }
  if (read < kFirstWeekDays || read > kFirstWeekLastDays) return null;
  if (!app.firstWeekOfferOn || app.firstWeekOfferedOn != null) return null;
  return FirstOffer.week;
}

/// Whether the store lets a page go up: it has answered, the reader has no
/// Astute+ with it and never had, and it sells the year with free days to
/// this reader. No year on sale from the store, no page: a price or a trial
/// written into the app never stands in for the store's.
bool firstOfferStoreAllows(Subscription store) =>
    store.ready &&
    !store.isPlus &&
    !store.everHeldPlus &&
    store.yearly != null &&
    store.trialDays != null;

/// The page due now for [app]'s reader, at the end of today's five, if
/// one is; see the library's own words for the rules. [levelRoseToday]
/// says whether a level rose on screen today (LevelMemory.roseOn).
FirstOffer? firstOfferDue(
  AppState app, {
  Subscription? store,
  bool levelRoseToday = false,
}) {
  // Right after the five: today's are finished, the deck read to its end.
  if (!app.dayClosed || !app.todayCompleted) return null;
  final FirstOffer? which = firstOfferWindow(app);
  if (which == null) return null;
  if (app.isPlus || !firstOfferStoreAllows(store ?? Subscription.instance)) {
    return null;
  }
  // One full-screen moment a day.
  if (app.trialOfferedToday || app.firstOfferRoseToday || levelRoseToday) {
    return null;
  }
  // One question an evening: the reminder sheet's evening, or the store's
  // rating sheet's, is theirs.
  if (app.shouldAskForPush ||
      app.shouldAskForReview ||
      app.reviewAskedOn == dateKey(app.today)) {
    return null;
  }
  return which;
}
