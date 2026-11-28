/// Sunday's week: on Sunday, once the five are read, a reader on the free
/// plan is shown what the week came to — the cards read, the right answers,
/// how sure against how right, the days in a row, the subject they did best
/// in — with one figure of Astute+'s blurred under them and, to a reader
/// without an account, the account in one line (lib/widgets/your_week_sheet.dart
/// is the sheet). A reader who missed Sunday is shown the week gone by on
/// Monday morning instead. Behind `week.sunday`, off as built.
///
/// A reason to come back that is the reader's own, as the first week's page
/// is (lib/state/first_offers.dart), and the plainest showcase of what
/// Astute+ keeps: everything on it is worked out from what the app already
/// writes down, and a figure there is too little to say is left out rather
/// than shown as a dash.
///
/// The rules, all here, where the tests hold them ([yourWeekDue]):
///
/// - **On Sunday, once the five are read**, the week from Monday to today;
///   **on Monday before noon**, the week gone by, for a reader who did not
///   see it on Sunday. Never later: by Monday afternoon a new week is under
///   way, and last week's numbers are old news.
/// - **Once a week**, kept for the phone ([AppState.weekShownFor]).
/// - **Only on the free plan**, never on Astute+, which has all of it in
///   Your journey; never on the reader's first day, which has its own; and
///   only for a week with a card read in it.
/// - **One moment an evening**: not on the evening the first week's page or
///   the first month's rose, the first run offered the trial, or a level
///   rose (main.dart asks the level), nor on the reminder sheet's or the
///   store's rating sheet's. The shell puts it after the reminder, the
///   consent and the account's own sheet, and in a sitting nothing else has
///   asked in (main.dart).
library;

import '../data/pills_repository.dart' show dateKey;
import '../models/pill.dart';
import 'app_state.dart';
import 'first_offers.dart' show FirstOfferNumbers;
import 'journey_record.dart' show Tally;
import 'progress.dart' show kEarlyReadingFrom, mondayOf;

/// Until what hour of the phone's clock on Monday the week gone by is shown
/// to a reader who missed it on Sunday.
const int kWeekMondayUntil = 12;

/// Answers in a subject in the week before it can be the week's best.
const int kWeekSubjectFloor = 3;

/// What a week came to, from Monday to Sunday, or to today.
class YourWeek {
  const YourWeek({
    required this.monday,
    required this.cards,
    required this.days,
    required this.answered,
    required this.streak,
    this.sure,
    this.best,
  });

  /// The Monday the week starts on.
  final DateTime monday;

  /// Cards first read in the week, wherever they were read.
  final int cards;

  /// Days the five were finished in it.
  final int days;

  /// The answers given in it, and the right ones.
  final Tally answered;

  /// Days in a row, as the streak stands now.
  final int streak;

  /// How sure the reader said they were on average, in percent, and how
  /// often they were right, of the [n] answers in the week said how sure;
  /// null under [kEarlyReadingFrom] of them.
  final ({int sure, int right, int n})? sure;

  /// The subject answered best in the week, by key, and how it went; null
  /// while no subject has [kWeekSubjectFloor] answers in it.
  final ({String key, Tally tally})? best;

  /// The Sunday it ends on.
  DateTime get sunday => DateTime(monday.year, monday.month, monday.day + 6);

  /// [app]'s reader's week from [monday].
  factory YourWeek.of(AppState app, DateTime monday) {
    final String from = dateKey(monday);
    final String to = dateKey(
      DateTime(monday.year, monday.month, monday.day + 6),
    );
    bool inWeek(String? day) =>
        day != null && day.compareTo(from) >= 0 && day.compareTo(to) <= 0;
    final List<Judgement> week = [
      for (final Judgement j in app.judgements)
        if (inWeek(j.on)) j,
    ];
    final List<Judgement> said = [
      for (final Judgement j in week)
        if (j.confidence != null) j,
    ];
    final int claimed = said.fold<int>(0, (a, j) => a + j.confidence!);
    final int saidRight = said.where((j) => j.correct).length;
    return YourWeek(
      monday: monday,
      cards: app.record.readBetween(from, to).length,
      days: {
        for (final String d in app.completedDates)
          if (inWeek(d)) d,
      }.length,
      answered: Tally(week.where((j) => j.correct).length, week.length),
      streak: app.liveStreak,
      sure: said.length < kEarlyReadingFrom
          ? null
          : (
              sure: (claimed / said.length).round(),
              right: (saidRight * 100 / said.length).round(),
              n: said.length,
            ),
      best: FirstOfferNumbers.strongestOf(week, floor: kWeekSubjectFloor),
    );
  }
}

/// The Monday of the week due to be shown to [app]'s reader now, if one is;
/// see the library's own words for the rules. [now] is the phone's clock,
/// for Monday's morning; [levelRoseToday] whether a level rose on screen
/// today.
DateTime? yourWeekDue(
  AppState app, {
  DateTime? now,
  bool levelRoseToday = false,
}) {
  if (!app.ready || !app.onboarded || app.isPlus || !app.sundayWeekOn) {
    return null;
  }
  final DateTime today = app.today;
  final DateTime clock = now ?? DateTime.now();
  final DateTime monday;
  if (today.weekday == DateTime.sunday) {
    // Sunday's own: once the five are read, so the day counts in it.
    if (!app.dayClosed) return null;
    monday = mondayOf(today);
  } else if (today.weekday == DateTime.monday &&
      clock.hour < kWeekMondayUntil) {
    final DateTime last = mondayOf(today);
    monday = DateTime(last.year, last.month, last.day - 7, 12);
  } else {
    return null;
  }
  if (app.weekShownFor == dateKey(monday)) return null;
  // Never on the first day the reader ever read: it has its own.
  if (app.completedDates.toSet().length < 2) return null;
  // One moment an evening.
  if (levelRoseToday || app.trialOfferedToday || app.firstOfferRoseToday) {
    return null;
  }
  if (app.shouldAskForPush ||
      app.shouldAskForReview ||
      app.reviewAskedOn == dateKey(today)) {
    return null;
  }
  if (YourWeek.of(app, monday).cards == 0) return null;
  return monday;
}

/// Whether the week's sheet offers the account in its one line, to a
/// reader who has none: three weeks at most, never again once the sheet it
/// opens was closed without one, and never while the server holds the
/// account's offer back. [signedIn] and [canSignIn] are the account's.
bool weekOffersAccount(
  AppState app, {
  required bool signedIn,
  required bool canSignIn,
}) =>
    !signedIn &&
    canSignIn &&
    !app.weekAccountDeclined &&
    app.weekAccountShown < kWeekAccountTimes &&
    app.accountOfferOn;

/// How many weeks the account's line is offered at most.
const int kWeekAccountTimes = 3;
