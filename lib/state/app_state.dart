import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart'
    show Color, ThemeMode, basicLocaleListResolution;
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/date_symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics.dart';
import '../data/daily.dart';
import '../data/genres.dart';
import '../data/pill_bank.dart';
import '../data/pills_repository.dart';
import '../data/topics.dart';
import '../l10n/app_localizations.dart';
import '../models/pill.dart';
import '../models/reminder.dart';
import '../sync/board.dart';
import '../sync/reader_snapshot.dart';
import '../sync/tally.dart';
import '../utils/home_widget.dart';
import '../utils/reminders.dart';
import 'progress.dart';

/// Which paid plan the paywall has selected. Purchases are not wired up.
enum Plan { month, year }

/// How the reminder is asked about and armed. Function-typed so a test can
/// stand in for the platform, which has no notification centre.
typedef PermissionProbe = Future<bool> Function();
typedef ReminderArmer = Future<void> Function(List<Reminder> plan);
typedef HomeWidgetPusher = Future<void> Function(Map<String, Object?> data);

class AppState extends ChangeNotifier {
  AppState({
    PermissionProbe? hasPermission,
    PermissionProbe? askPermission,
    ReminderArmer? arm,
    Future<void> Function()? disarm,
    HomeWidgetPusher? pushWidget,
  }) : _hasPermission = hasPermission ?? hasReminderPermission,
       _askPermission = askPermission ?? ensureReminderPermission,
       _arm = arm ?? armReminders,
       _disarm = disarm ?? disarmReminders,
       _pushWidget = pushWidget ?? pushHomeWidget;

  final PermissionProbe _hasPermission;
  final PermissionProbe _askPermission;
  final ReminderArmer _arm;
  final Future<void> Function() _disarm;
  final HomeWidgetPusher _pushWidget;

  static const _kStreak = 'knowit.streak';
  static const _kBestStreak = 'knowit.bestStreak';
  static const _kLastCompletion = 'knowit.lastCompletionDate';
  static const _kFreezes = 'knowit.freezes';
  static const _kFrozeOn = 'knowit.frozeOn';
  static const _kCompletedDates = 'knowit.completedDates';
  static const _kSavedIds = 'knowit.savedIds';
  static const _kLikedIds = 'knowit.likedIds';
  static const _kDislikedIds = 'knowit.dislikedIds';
  static const _kFriendCodes = 'knowit.friendCodes';
  static const _kTodayDate = 'knowit.todayDate';
  static const _kTodayIndex = 'knowit.todayIndex';
  static const _kOnboarded = 'knowit.onboarded';
  static const _kTopics = 'knowit.topics';
  static const _kTopicWeights = 'knowit.topicWeights';
  static const _kTopicLevels = 'knowit.topicLevels';
  static const _kGenresOff = 'knowit.genresOff';
  static const _kStrandsOff = 'knowit.strandsOff';
  static const _kNotifications = 'knowit.notifications';
  static const _kNotifyHour = 'knowit.notifyHour';
  static const _kPillsRead = 'knowit.pillsRead';
  static const _kComebackSeen = 'knowit.comebackSeenDate';
  static const _kName = 'knowit.name';
  static const _kPlus = 'knowit.plus';
  static const _kSeenIds = 'knowit.seenIds';
  static const _kDeckIds = 'knowit.todayDeckIds';
  static const _kDeckHistory = 'knowit.deckHistory';
  static const _kDayStartRung = 'knowit.dayStartRung';
  static const _kDayStartScore = 'knowit.dayStartScore';
  static const _kRungDates = 'knowit.rungDates';
  static const _kSaidIds = 'knowit.saidIds';
  static const _kOwnIds = 'knowit.todayOwnIds';
  static const _kAnswers = 'knowit.answersJson';
  static const _kJudgements = 'knowit.judgements';
  static const _kTheme = 'knowit.theme';
  static const _kPushAsked = 'knowit.pushAsked';
  static const _kPushTokens = 'knowit.pushTokens';

  late SharedPreferences _prefs;
  bool ready = false;

  int streak = 0;
  int bestStreak = 0;
  String? lastCompletionDate;

  /// Days the reader can miss without losing the streak. Earned by keeping
  /// one, not only bought — a protection you can only pay for is a threat.
  int freezes = 0;

  /// The day a freeze was spent, so it can be said out loud once.
  String? frozeOn;
  List<String> completedDates = [];

  /// Saved pill ids, most recently kept first. A bookmark: the cards the
  /// reader wants to find again.
  List<String> savedIds = [];

  /// Liked pill ids, most recently liked first. A card held down. What the
  /// reader liked is what the app deals more of, where it deals anything
  /// of its own — and a shelf of its own on the profile.
  List<String> likedIds = [];

  /// Cards thrown down: less of this. Quiet, and only a lean on the deal.
  List<String> dislikedIds = [];

  /// The friends whose boards the reader looks at, by code.
  List<String> friendCodes = [];
  int todayIndex = 0;
  int pillsRead = 0;

  /// Every pill id already read, so later days open on something new.
  Set<String> seenIds = {};

  /// Which of today's cards are the reader's own — dealt from their mix
  /// rather than from the edition everybody gets. Two of five on the free
  /// plan, and every one of them on Astute+.
  Set<String> ownIdsToday = {};

  /// Which of today's cards the reader has already answered once — the
  /// calendar can deal a card round again, and a card met before shows
  /// what was said the first time.
  Set<String> reviewIdsToday = {};

  /// What each day actually dealt, by date key, for the last few weeks.
  ///
  /// The calendar is re-dealt from the start whenever the pool grows, so
  /// asking it what last Tuesday held can get a different answer from the
  /// one last Tuesday gave. This is the one that was given.
  Map<String, List<String>> deckHistory = {};

  /// The rung the reader stood on when today was dealt, so the end of the
  /// day can say whether they climbed.
  int rungAtDayStart = 0;

  /// And what the score stood at, so the day can say what it was worth.
  int scoreAtDayStart = 0;

  /// The day each rung was first reached, by rung id — the dates on the
  /// journey. Written the moment a rung is cleared and never moved.
  Map<String, String> rungDates = {};

  /// Cards the reader has said out loud to somebody. The one thing the app
  /// cannot check and the only one that proves the card left the phone.
  List<String> saidIds = [];

  /// Card id -> what the reader last committed to, and when it comes back.
  Map<String, Answer> answers = {};

  /// Every judgement ever made, oldest first. Calibration is a track record,
  /// so this is appended to and never rewritten.
  List<Judgement> judgements = [];

  bool onboarded = false;
  Set<String> pickedTopics = kTopicOrder.toSet();

  /// How much of each subject the reader asked for, 0..1 by topic key. Empty
  /// means they never said, and every subject is dealt evenly.
  Map<String, double> topicWeights = {};

  /// What the reader says they already know of each subject: 0 curious,
  /// 1 some, 2 solid, by topic key. Only the subjects they were asked about
  /// are here; the rest count as 1.
  Map<String, int> topicLevels = {};

  /// The genres, and the strands under them, the reader turned off.
  ///
  /// Off rather than on, so that everything starts in and a reader who walks
  /// past the screen has turned nothing down — and so that a genre added in a
  /// later build reaches everybody instead of being hidden from every reader
  /// who chose before it existed.
  Set<String> genresOff = {};
  Set<String> strandsOff = {};
  bool notificationsOn = true;
  String notifyTime = '08:30';

  /// Astute+ — every card of the day the reader's own, the map of what
  /// they know, and the whole archive.
  bool isPlus = false;
  String name = 'You';
  Plan plan = Plan.year;

  /// Light, dark, or whatever the phone is set to. One choice for the whole
  /// app — it does not change from screen to screen.
  ThemeMode themeMode = ThemeMode.dark;

  /// Whether the reader has been asked about notifications. iOS gives one
  /// prompt and no second chance, so this is asked once and remembered.
  bool pushAsked = false;

  /// Every address the account can be reached at, this phone's included.
  /// Kept whole rather than reduced to this device, so backing up does not
  /// quietly unsubscribe the reader's other phone.
  List<String> pushTokens = [];

  late DateTime today;
  late List<Pill> todaysDeck;

  bool get todayCompleted => todayIndex >= todaysDeck.length;

  /// True once today's five have been finished, whether or not a second set
  /// was dealt after them.
  bool get dayClosed => lastCompletionDate == dateKey(today);

  /// Which day this is, counted along the streak. A streak counts finished
  /// days, so the day being read is one past it: the sixth day kept is
  /// "Day 6" from the moment it opens, not only once it is done.
  int get dayNumber => liveStreak + (dayClosed ? 0 : 1);

  /// How many of today's cards the reader liked.
  int get likedToday => todaysDeck.where((p) => likedIds.contains(p.id)).length;

  /// Initials for the profile avatar.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'KW';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (parts.first[0] + parts.elementAt(1)[0]).toUpperCase();
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // The newest bank the last run downloaded, before a card is dealt from
    // the one built in. Adopting later, mid-day, would re-deal the table.
    PillBank.restore(_prefs);
    today = DateTime.now();

    // Stored state is read defensively. A value written by an older build,
    // or corrupted on disk, must not leave the app stuck on the splash: it
    // is better to start fresh than never to start.
    try {
      await _restore();
    } catch (error, stack) {
      debugPrint('Astute: could not restore stored state, starting fresh');
      debugPrintStack(stackTrace: stack, label: '$error');
      await _startNewDay();
    }

    ready = true;
    notifyListeners();
    // Not awaited: the splash must not wait on the notification centre, and
    // this never prompts — it only re-arms what is already permitted.
    unawaited(refreshDailyReminder());
    unawaited(refreshHomeWidget());
    // Nor on the bank: whatever it downloads is for tomorrow's start.
    unawaited(PillBank.refresh(_prefs));
  }

  Future<void> _restore() async {
    streak = _prefs.getInt(_kStreak) ?? 0;
    bestStreak = _prefs.getInt(_kBestStreak) ?? 0;
    lastCompletionDate = _prefs.getString(_kLastCompletion);
    freezes = _prefs.getInt(_kFreezes) ?? 1;
    frozeOn = _prefs.getString(_kFrozeOn);
    completedDates = _prefs.getStringList(_kCompletedDates) ?? [];
    savedIds = _prefs.getStringList(_kSavedIds) ?? [];
    likedIds = _prefs.getStringList(_kLikedIds) ?? [];
    dislikedIds = _prefs.getStringList(_kDislikedIds) ?? [];
    friendCodes = _prefs.getStringList(_kFriendCodes) ?? [];
    pillsRead = _prefs.getInt(_kPillsRead) ?? 0;

    onboarded = _prefs.getBool(_kOnboarded) ?? false;
    topicWeights = _decodeWeights(_prefs.getString(_kTopicWeights));
    topicLevels = _decodeLevels(_prefs.getString(_kTopicLevels));
    genresOff = (_prefs.getStringList(_kGenresOff) ?? []).toSet();
    strandsOff = (_prefs.getStringList(_kStrandsOff) ?? []).toSet();
    final storedTopics = _prefs.getStringList(_kTopics);
    if (storedTopics != null && storedTopics.isNotEmpty) {
      pickedTopics = storedTopics.toSet();
    }
    notificationsOn = _prefs.getBool(_kNotifications) ?? true;
    notifyTime = _prefs.getString(_kNotifyHour) ?? '08:30';
    name = _prefs.getString(_kName) ?? 'You';
    isPlus = _prefs.getBool(_kPlus) ?? false;
    themeMode = _decodeTheme(_prefs.getString(_kTheme));
    seenIds = (_prefs.getStringList(_kSeenIds) ?? []).toSet();
    ownIdsToday = (_prefs.getStringList(_kOwnIds) ?? []).toSet();
    answers = _decodeAnswers(_prefs.getString(_kAnswers));
    pushAsked = _prefs.getBool(_kPushAsked) ?? false;
    pushTokens = _prefs.getStringList(_kPushTokens) ?? [];
    judgements = _decodeJudgements(_prefs.getString(_kJudgements));
    deckHistory = _decodeHistory(_prefs.getString(_kDeckHistory));
    rungDates = _decodeDates(_prefs.getString(_kRungDates));
    saidIds = _prefs.getStringList(_kSaidIds) ?? [];
    // Absent on an install that started the day on an older build: the
    // reader is where they are now, and today reports no climb.
    rungAtDayStart = _prefs.getInt(_kDayStartRung) ?? standing.at;
    scoreAtDayStart = _prefs.getInt(_kDayStartScore) ?? score.total;
    await _noteClimb();

    final storedDay = _prefs.getString(_kTodayDate);
    final storedDeck = _prefs.getStringList(_kDeckIds) ?? [];
    if (storedDay == dateKey(today) && storedDeck.isNotEmpty) {
      // Restore the exact deck this day started with: recomputing it would
      // shuffle under the reader as their history grows.
      todaysDeck = pillsByIds(storedDeck);
      todayIndex = _prefs.getInt(_kTodayIndex) ?? 0;
      reviewIdsToday = {
        for (final p in todaysDeck)
          if (answers.containsKey(p.id)) p.id,
      };
      if (todaysDeck.isEmpty) {
        await _startNewDay();
      } else {
        _sayCardUp(resumed: true);
      }
    } else {
      await _spendFreezeIfMissed();
      await _sayStreakBroken();
      await _startNewDay();
    }
  }

  static const _kBrokenSaid = 'knowit.streakBrokenSaid';

  /// A streak the freezes could not cover is gone, and that is said once —
  /// not on every morning of the lapse. The last day kept marks which
  /// streak it was.
  Future<void> _sayStreakBroken() async {
    final String? last = lastCompletionDate;
    if (last == null || streak < 1 || missedDays < 1) return;
    if (_prefs.getString(_kBrokenSaid) == last) return;
    await _prefs.setString(_kBrokenSaid, last);
    Analytics.capture('streak broken', {
      'streak_lost': streak,
      'best_streak': bestStreak,
      'days_missed': missedDays,
      'freezes_left': freezes,
      'is_plus': isPlus,
    });
  }

  /// How many freezes can be held at once.
  ///
  /// One on the free plan is enough to cover the evening somebody falls
  /// asleep early. Three is the difference between a streak that survives a
  /// weekend away and one that does not, and that is worth paying for.
  int get freezeCapacity => isPlus ? 3 : 1;

  /// Covers a gap, if the whole gap can be covered.
  ///
  /// Partial cover would be the worst of both: the freezes are gone and the
  /// streak breaks anyway. So it is all or nothing, and the freezes stay in
  /// the bank when they cannot save it.
  Future<void> _spendFreezeIfMissed() async {
    final missed = missedDays;
    if (missed < 1 || streak < 1) return;
    if (freezes < missed) return;

    freezes -= missed;
    lastCompletionDate = dateKey(today.subtract(const Duration(days: 1)));
    frozeOn = dateKey(today);
    await _prefs.setInt(_kFreezes, freezes);
    await _prefs.setString(_kLastCompletion, lastCompletionDate!);
    await _prefs.setString(_kFrozeOn, frozeOn!);
    Analytics.capture('streak frozen', {
      'days_covered': missed,
      'freezes_left': freezes,
      'streak_days': streak,
    });
  }

  /// True when a freeze saved the streak today and it has not been said yet.
  bool get streakWasFrozen => frozeOn == dateKey(today);

  /// Earns a freeze every seventh day kept, up to what can be held. The
  /// streak pays for its own insurance.
  Future<void> _earnFreeze() async {
    if (streak % 7 != 0) return;
    if (freezes >= freezeCapacity) return;
    freezes++;
    await _prefs.setInt(_kFreezes, freezes);
    Analytics.capture('freeze earned', {
      'freezes': freezes,
      'streak_days': streak,
    });
  }

  /// How many of a day's cards are the reader's own: all five on Astute+;
  /// two on the free plan, and three on the morning after a full week
  /// kept — the streak's own reward, tasted once a week.
  int get ownCardsToday => ownCardsFor(plus: isPlus, streak: liveStreak);

  /// Deals a day for this reader. See [dealDay] for what a day is.
  ///
  /// On Astute+ the cards are dealt at the level the app has measured,
  /// leaned by what the reader held and threw down, with a card that came
  /// due for review. On the free plan they are dealt at the level the
  /// reader said, from the subjects and strands they kept on — the mix is
  /// everybody's — and what came due waits after the day instead.
  Deal _deal(
    DateTime date, {
    required Set<String> exclude,
    required List<Pill> reviews,
    required int own,
  }) => dealDay(
    date: date,
    topics: pickedTopics,
    weights: leanedWeights,
    levels: isPlus ? measuredLevels : topicLevels,
    taste: isPlus ? taste : const {},
    genresOff: genresOff,
    strandsOff: strandsOff,
    exclude: exclude,
    reviews: isPlus ? reviews : const [],
    own: own,
  );

  /// Deals a fresh day and records it, so a restart resumes the same deck.
  ///
  /// An app that never re-asks what you got wrong is not teaching, it is
  /// entertaining: on Astute+ a card that came due takes an asking slot
  /// before any fresh question does.
  Future<void> _startNewDay() async {
    final reviews = dueReviews;
    final Deal deal = _deal(
      today,
      exclude: seenIds,
      reviews: reviews,
      own: ownCardsToday,
    );
    todaysDeck = deal.cards;
    ownIdsToday = deal.own;
    final dealtReviews = reviews.map((p) => p.id).toSet();
    reviewIdsToday = {
      for (final p in todaysDeck)
        if (dealtReviews.contains(p.id) || answers.containsKey(p.id)) p.id,
    };
    todayIndex = 0;
    rungAtDayStart = standing.at;
    scoreAtDayStart = score.total;
    await _prefs.setString(_kTodayDate, dateKey(today));
    await _prefs.setInt(_kTodayIndex, 0);
    await _prefs.setInt(_kDayStartRung, rungAtDayStart);
    await _prefs.setInt(_kDayStartScore, scoreAtDayStart);
    await _prefs.setStringList(_kDeckIds, todaysDeck.map((p) => p.id).toList());
    await _prefs.setStringList(_kOwnIds, ownIdsToday.toList());
    await _noteDealt(today, todaysDeck);
    Analytics.capture('day started', {
      'cards': todaysDeck.length,
      // How much of the day is the reader's own, and how much of it is a
      // re-asking. The whole claim of the plan is the first number; the
      // whole claim of the review ladder is the second.
      'own': ownIdsToday.length,
      'reviews': reviewIdsToday.length,
      'topics': pickedTopics.length,
      'streak_days': streak,
      'rung': standing.at,
      'is_plus': isPlus,
      // Which of the day's cards are which, in order.
      'slots': [for (final p in todaysDeck) cardFacts(p.id)['slot']].join(','),
      'challenges': [for (final p in todaysDeck) challengeKind(p.challenge)]
          .join(','),
      'question_of_day': todaysDeck.any(
        (p) => p.id == questionOfTheDay(today).id,
      ),
    });
    _sayCardUp();
  }

  /// Writes down what a day was dealt, and forgets what is older than the
  /// archive shows.
  Future<void> _noteDealt(DateTime day, List<Pill> deck) async {
    deckHistory[dateKey(day)] = deck.map((p) => p.id).toList();
    final keys = deckHistory.keys.toList()..sort();
    while (keys.length > 60) {
      deckHistory.remove(keys.removeAt(0));
    }
    await _prefs.setString(_kDeckHistory, jsonEncode(deckHistory));
  }

  static Map<String, List<String>> _decodeHistory(String? raw) {
    final parsed = _decodeJson(raw);
    if (parsed is! Map) return {};
    return {
      for (final e in parsed.entries)
        if (e.value is List)
          '${e.key}': (e.value as List).whereType<String>().toList(),
    };
  }

  /// What a past day was dealt: what this phone wrote down, or failing
  /// that the day dealt again from the same date and mix — which is what
  /// it was, less the review and the history, and closer to the truth than
  /// showing nothing.
  List<Pill> deckOn(DateTime day) {
    if (dateKey(day) == dateKey(today)) return todaysDeck;
    final noted = deckHistory[dateKey(day)];
    if (noted != null && noted.isNotEmpty) return pillsByIds(noted);
    return _deal(
      day,
      exclude: const {},
      reviews: const [],
      own: ownCardsFor(plus: isPlus, streak: 0),
    ).cards;
  }

  /// True when today's five carried the reader up a rung.
  bool get climbedToday => standing.at > rungAtDayStart;

  /// The record as one number, and what today has added to it.
  Score get score => Score(
    read: seenIds.length,
    held: heldCards,
    moves: movesDown,
    weeks: keptWeeks,
  );

  int get pointsToday => (score.total - scoreAtDayStart).clamp(0, 1 << 30);

  /// Today's five as a row of squares, with nothing in it a friend could
  /// not be shown: which cards asked, and of those which went right — never
  /// what was asked or what was said.
  DaySummary get daySummary {
    final squares = StringBuffer();
    var asked = 0;
    var right = 0;
    for (final p in todaysDeck.take(kPillsPerDay)) {
      if (!p.asksSomething) {
        squares.write(DaySummary.readSquare);
        continue;
      }
      final Answer? given = answers[p.id];
      if (given == null) {
        squares.write(DaySummary.passedSquare);
      } else if (!p.isGraded) {
        squares.write(DaySummary.sidedSquare);
      } else {
        asked++;
        final bool ok = p.challenge.accepts(given.response);
        if (ok) right++;
        squares.write(ok ? DaySummary.rightSquare : DaySummary.wrongSquare);
      }
    }
    final todays = judgements.where((j) => j.on == dateKey(today)).toList();
    final double? sure = todays.isEmpty
        ? null
        : todays.fold<int>(0, (a, j) => a + j.confidence) / todays.length;

    // The question of the day, on its own: the one square a friend's grid
    // has in the same place.
    final Pill question = questionOfTheDay(today);
    final Answer? said = todaysDeck.any((p) => p.id == question.id)
        ? answers[question.id]
        : null;
    return DaySummary(
      edition: editionOf(today),
      squares: squares.toString(),
      asked: asked,
      right: right,
      sure: sure,
      streak: liveStreak,
      questionRight: said == null
          ? null
          : question.challenge.accepts(said.response),
      questionSure: said?.confidence,
    );
  }

  // ── Streak ────────────────────────────────────────────────────────────

  /// The streak as it stands right now. A stored streak only still counts if
  /// the last completed day was today or yesterday; otherwise it has lapsed.
  int get liveStreak {
    if (lastCompletionDate == null) return 0;
    final todayK = dateKey(today);
    final yesterdayK = dateKey(today.subtract(const Duration(days: 1)));
    if (lastCompletionDate == todayK || lastCompletionDate == yesterdayK) {
      return streak;
    }
    return 0;
  }

  /// Whole days missed since the last completed day, 0 when up to date.
  int get missedDays {
    if (lastCompletionDate == null) return 0;
    final parts = lastCompletionDate!.split('-').map(int.parse).toList();
    final last = DateTime(parts[0], parts[1], parts[2]);
    final t = DateTime(today.year, today.month, today.day);
    final gap = t.difference(last).inDays;
    return gap > 1 ? gap - 1 : 0;
  }

  /// True when a streak lapsed and the come-back screen has not been shown
  /// yet today.
  bool get shouldShowComeback {
    if (missedDays < 1 || streak < 1) return false;
    return _prefs.getString(_kComebackSeen) != dateKey(today);
  }

  Future<void> dismissComeback() async {
    await _prefs.setString(_kComebackSeen, dateKey(today));
    notifyListeners();
  }

  // ── What a card is, for measurement ──────────────────────────────────

  /// A card as every event about it describes it: what kind of card it is,
  /// from its own tags, and — when it is one of today's — where it sits in
  /// the day and why it was dealt. Never the card's text, and never what
  /// the reader wrote about it.
  Map<String, Object?> cardFacts(String pillId) {
    final Pill? p = pillById(pillId);
    String? tag(String? value) =>
        value == null || value.trim().isEmpty ? null : value;
    final int at = todaysDeck.indexWhere((c) => c.id == pillId);
    final String? slot = at < 0
        ? null
        : reviewIdsToday.contains(pillId)
        ? 'review'
        : questionOfTheDay(today).id == pillId
        ? 'question_of_day'
        : ownIdsToday.contains(pillId)
        ? 'own'
        : 'common';
    return {
      'pill_id': pillId,
      'topic': p?.topic,
      'genre': tag(p?.genre),
      'strand': tag(p?.strand),
      'principle': p == null || !p.principle.isReal ? null : p.principle.name,
      'difficulty': p?.difficulty.name,
      'challenge': p == null ? null : challengeKind(p.challenge),
      'graded': p?.isGraded,
      'era': tag(p?.era),
      'region': tag(p?.region),
      'hook': tag(p?.hook),
      'mood': tag(p?.mood),
      'numeracy': p?.numeracy,
      'abstraction': tag(p?.abstraction),
      'shelf_life': tag(p?.shelfLife),
      'has_figure': p?.figure.trim().isNotEmpty,
      'position': at < 0 ? null : at + 1,
      'of': at < 0 ? null : todaysDeck.length,
      'slot': slot,
      'edition': editionOf(today),
      'is_plus': isPlus,
    };
  }

  /// The kind of question a card asks, as a word an event can carry.
  static String challengeKind(Challenge challenge) => switch (challenge) {
    NoChallenge() => 'fact',
    PickOne() => 'pick_one',
    TypeNumber() => 'type_number',
    Estimate() => 'estimate',
    TakeASide() => 'take_a_side',
  };

  /// When the card in front of the reader came up, for how long they
  /// stayed on it.
  DateTime? _cardUpAt;

  /// The card now in front of the reader, said as seen. [resumed] when the
  /// app opened on a day already under way.
  void _sayCardUp({bool resumed = false}) {
    if (todayIndex >= todaysDeck.length) {
      _cardUpAt = null;
      return;
    }
    _cardUpAt = DateTime.now();
    Analytics.capture('card viewed', {
      ...cardFacts(todaysDeck[todayIndex].id),
      'resumed': resumed ? true : null,
    });
  }

  // ── Reading ───────────────────────────────────────────────────────────

  Future<void> advance() async {
    if (todayCompleted) return;
    final Pill card = todaysDeck[todayIndex];
    final DateTime? upAt = _cardUpAt;
    Analytics.capture('card advanced', {
      // Which of the day's cards this was, so the drop-off inside a day can
      // be read as a curve rather than as a single completion rate — and
      // what kind of card it was, and how long it held the reader.
      ...cardFacts(card.id),
      'review': reviewIdsToday.contains(card.id),
      'ms_on_card': upAt == null
          ? null
          : DateTime.now().difference(upAt).inMilliseconds,
    });
    seenIds.add(card.id);
    todayIndex += 1;
    pillsRead += 1;
    await _prefs.setInt(_kTodayIndex, todayIndex);
    await _prefs.setInt(_kPillsRead, pillsRead);
    await _prefs.setStringList(_kSeenIds, seenIds.toList());
    if (todayCompleted) await _completeToday();
    _sayCardUp();
    // After every card, not only the last: the five widget counts them.
    unawaited(refreshHomeWidget());
    await _noteClimb();
    notifyListeners();
  }

  /// Dates every rung the reader now stands on or above, once. A rung
  /// reached on an install that predates the dating gets today, which is
  /// the day the app first knew.
  Future<void> _noteClimb() async {
    var changed = false;
    final int at = standing.at;
    // Whether this is the first climb of a fresh install — which dates every
    // rung under the reader at once — or one step taken now. Only the second
    // is a moment worth an event apiece.
    final bool firstEver = rungDates.isEmpty;
    for (var i = 0; i <= at && i < kRungs.length; i++) {
      if (rungDates.containsKey(kRungs[i].id)) continue;
      rungDates[kRungs[i].id] = dateKey(today);
      changed = true;
      if (!firstEver) {
        Analytics.capture('rung reached', {
          'rung': kRungs[i].id,
          'rung_index': i,
          'days_in': completedDates.length,
          'pills_read': pillsRead,
        });
      }
    }
    if (changed) {
      await _prefs.setString(_kRungDates, jsonEncode(rungDates));
      Analytics.register('rung', at);
    }
  }

  static Map<String, String> _decodeDates(String? raw) {
    final parsed = _decodeJson(raw);
    if (parsed is! Map) return {};
    return {
      for (final e in parsed.entries)
        if (e.value is String) '${e.key}': e.value as String,
    };
  }

  Future<void> _completeToday() async {
    final key = dateKey(today);
    if (lastCompletionDate == key) return;

    final yesterday = dateKey(today.subtract(const Duration(days: 1)));
    final int bestBefore = bestStreak;
    streak = (lastCompletionDate == yesterday) ? streak + 1 : 1;
    lastCompletionDate = key;
    if (streak > bestStreak) bestStreak = streak;

    completedDates = [...completedDates, key];
    if (completedDates.length > 30) {
      completedDates = completedDates.sublist(completedDates.length - 30);
    }

    await _prefs.setInt(_kStreak, streak);
    await _prefs.setInt(_kBestStreak, bestStreak);
    await _prefs.setString(_kLastCompletion, lastCompletionDate!);
    await _prefs.setStringList(_kCompletedDates, completedDates);
    Analytics.capture('day completed', {
      'streak_days': streak,
      'best_streak': bestStreak,
      'cards': todaysDeck.length,
      'days_completed': completedDates.length,
      'rung': standing.at,
      // What the day was worth, rather than what the reader now holds: the
      // second number is the same on a day they did nothing.
      'score_gained': score.total - scoreAtDayStart,
      'rungs_climbed': standing.at - rungAtDayStart,
      'is_plus': isPlus,
      // How the day went: the questions got right and got wrong today.
      'answered_right': judgements
          .where((j) => j.on == key && j.correct)
          .length,
      'answered_wrong': judgements
          .where((j) => j.on == key && !j.correct)
          .length,
      'reviews': reviewIdsToday.length,
      'own': ownIdsToday.length,
    });
    // The streaks worth a moment of their own, and the day a record falls.
    if (const {3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 365}.contains(streak)) {
      Analytics.capture('streak milestone', {
        'streak_days': streak,
        'is_plus': isPlus,
      });
    }
    if (streak > bestBefore && bestBefore > 0) {
      Analytics.capture('best streak beaten', {
        'streak_days': streak,
        'previous_best': bestBefore,
      });
    }
    await _earnFreeze();
  }

  // ── Answers ───────────────────────────────────────────────────────────

  static Map<String, Answer> _decodeAnswers(String? raw) {
    final parsed = _decodeJson(raw);
    if (parsed is! Map) return {};
    final out = <String, Answer>{};
    for (final entry in parsed.entries) {
      final answer = Answer.fromJson(entry.value);
      if (answer != null) out['${entry.key}'] = answer;
    }
    return out;
  }

  static List<Judgement> _decodeJudgements(String? raw) {
    final parsed = _decodeJson(raw);
    if (parsed is! List) return [];
    return [for (final item in parsed) ?Judgement.fromJson(item)];
  }

  static Object? _decodeJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> _saveAnswers() async {
    await _prefs.setString(
      _kAnswers,
      jsonEncode({for (final e in answers.entries) e.key: e.value.toJson()}),
    );
    await _prefs.setString(
      _kJudgements,
      jsonEncode([for (final j in judgements) j.toJson()]),
    );
  }

  /// What the reader last committed to on this card, or null if never.
  Answer? answerFor(String pillId) => answers[pillId];

  /// Cards answered, paired with the pill, for the ones that can be marked.
  Iterable<MapEntry<Pill, Answer>> get _graded sync* {
    for (final e in answers.entries) {
      final pill = PillBank.cards.where((p) => p.id == e.key).firstOrNull;
      if (pill != null && pill.isGraded) yield MapEntry(pill, e.value);
    }
  }

  int get puzzlesAnswered => _graded.length;

  int get puzzlesRight {
    var right = 0;
    for (final e in _graded) {
      // Grading belongs to the challenge, not here: a new kind of card
      // brings its own rule and this stays untouched.
      if (e.key.challenge.accepts(e.value.response)) right++;
    }
    return right;
  }

  /// Share of challenges the reader got right, 0 when none answered yet.
  double get puzzleAccuracy =>
      puzzlesAnswered == 0 ? 0 : puzzlesRight / puzzlesAnswered;

  // ── What it adds up to ────────────────────────────────────────────────

  /// Cards that came back and stuck: got right often enough that the app
  /// has stopped asking for a while.
  int get heldCards =>
      answers.values.where((a) => a.stage >= kHeldFromStage).length;

  /// How far off the reader's confidence is, in points, whichever way.
  ///
  /// Averaged over the levels rather than over the whole run, so being
  /// right about being unsure counts as much as being right about being
  /// sure: two errors in opposite directions are two errors, not none.
  /// Null until there is enough of a record to draw a line through.
  double? get confidenceGap {
    final buckets = calibration.toList();
    final int n = buckets.fold<int>(0, (a, b) => a + b.count);
    if (n < kCalibrationFloor) return null;
    return buckets.fold<double>(0, (a, b) => a + b.gap.abs() * b.count) / n;
  }

  /// Where the reader stands on the ladder, and what the next step is.
  Standing get standing => Standing(
    read: seenIds.length,
    answered: answers.length,
    judged: judgements.length,
    held: heldCards,
    gap: confidenceGap,
  );

  /// Weeks kept in a row, a week being five days out of seven.
  int get keptWeeks => weeksKept(completedDates.toSet(), today);

  /// The cards the reader was sure about and wrong about, newest first.
  List<Miss> get misses => missesFrom(judgements);

  /// What this week came to.
  WeekReport get thisWeek => weekReport(
    judgements: judgements,
    completedDates: completedDates,
    today: today,
  );

  /// The mix as the personal deals see it: what the reader asked for,
  /// leaned by what they liked and threw down. The five of the day never
  /// look at this; the second set and the swaps do.
  Map<String, double> get leanedWeights {
    if (likedIds.isEmpty && dislikedIds.isEmpty) return topicWeights;
    final keyOf = {for (final e in kTopics.entries) e.value.name: e.key};
    final byId = {for (final p in PillBank.cards) p.id: p};
    final lean = <String, double>{};
    void nudge(Iterable<String> ids, double by) {
      for (final id in ids) {
        final String? key = keyOf[byId[id]?.topic];
        if (key != null) lean[key] = (lean[key] ?? 0) + by;
      }
    }

    nudge(likedIds, kLean);
    nudge(dislikedIds, -kLean);
    final base = topicWeights.isEmpty
        ? {for (final key in kTopicOrder) key: 1.0}
        : topicWeights;
    return {
      for (final e in base.entries)
        e.key: (e.value * (1 + (lean[e.key] ?? 0))).clamp(0.05, 3.0),
    };
  }

  /// How much one like, or one throw, moves its subject's weight.
  static const double kLean = 0.15;

  /// How much one like, or one throw, moves each of a card's traits. A card
  /// carries about eight, so a card sharing everything with a liked one
  /// comes out at roughly kLean more than the like did for its subject.
  static const double kTasteLean = 0.08;

  /// The reader's lean on every tag value, from what they held and what
  /// they threw down: `genre:space.the_moon` to a signed amount, and the
  /// same for the strand, the era, the hook, the mood and the rest. The
  /// dealer reads it through [leanOf]; nothing here ever leaves the phone.
  Map<String, double> get taste {
    if (likedIds.isEmpty && dislikedIds.isEmpty) return const {};
    final lean = <String, double>{};
    void nudge(Iterable<String> ids, double by) {
      for (final id in ids) {
        for (final trait in PillBank.byId(id)?.traits ?? const <String>[]) {
          lean[trait] = (lean[trait] ?? 0) + by;
        }
      }
    }

    nudge(likedIds, kTasteLean);
    nudge(dislikedIds, -kTasteLean);
    return lean;
  }

  /// How many of a subject's most recent judgements decide its level, and
  /// how many there have to be before they decide anything.
  static const int kLevelSample = 8;
  static const int kLevelFloor = 4;

  /// What the reader knows of each subject, measured rather than asked.
  ///
  /// The onboarding once asked the reader to rate themselves before they
  /// had seen a card, and nothing ever updated the answer. This does: the
  /// last [kLevelSample] judgements on a subject, once there are
  /// [kLevelFloor] of them, set its level — three in four right is solid,
  /// two in five or fewer is curious, between is some — over whatever the
  /// reader said. A subject they have not been asked about keeps what they
  /// said, or the middle.
  Map<String, int> get measuredLevels {
    final out = Map<String, int>.from(topicLevels);
    final keyOf = {for (final e in kTopics.entries) e.value.name: e.key};
    final recent = <String, List<bool>>{};
    for (final j in judgements.reversed) {
      final String? id = j.pillId;
      if (id == null) continue;
      final String? key = keyOf[PillBank.byId(id)?.topic];
      if (key == null) continue;
      final list = recent.putIfAbsent(key, () => []);
      if (list.length < kLevelSample) list.add(j.correct);
    }
    for (final e in recent.entries) {
      if (e.value.length < kLevelFloor) continue;
      final double share = e.value.where((c) => c).length / e.value.length;
      out[e.key] = share >= 0.75
          ? 2
          : share <= 0.4
          ? 0
          : 1;
    }
    return out;
  }

  /// Records a commitment.
  ///
  /// A card can be answered again only when it has come back for review —
  /// otherwise the first answer stands, so a score cannot be retaken by
  /// reopening a card from the archive.
  Future<void> recordAnswer(
    String pillId,
    String response, {
    int? confidence,
    String? reason,
  }) async {
    final existing = answers[pillId];
    if (existing != null && !isDueForReview(pillId)) return;

    final pill = pillById(pillId);
    final graded = pill?.isGraded ?? false;
    final right = graded && (pill?.challenge.accepts(response) ?? false);

    answers[pillId] = _scheduled(
      Answer(response, confidence: confidence, reason: reason),
      graded: graded,
      right: right,
      previous: existing,
    );

    if (graded && confidence != null) {
      judgements.add(
        Judgement(
          confidence,
          correct: right,
          pillId: pillId,
          on: dateKey(today),
        ),
      );
    }

    await _saveAnswers();
    Analytics.capture('card answered', {
      ...cardFacts(pillId),
      'graded': graded,
      'ms_to_answer': _cardUpAt == null
          ? null
          : DateTime.now().difference(_cardUpAt!).inMilliseconds,
      // Only meaningful on a graded card; an ungraded one has nothing to be
      // right about, and the property is left off rather than sent as false.
      'correct': graded ? right : null,
      // How sure they said they were. The number, never the reason they
      // wrote beside it — that is prose, and prose stays on the phone.
      'confidence': confidence,
      'gave_reason': reason != null && reason.trim().isNotEmpty,
      'review': existing != null,
      'review_stage': existing?.stage,
    });
    await _noteClimb();
    notifyListeners();
  }

  // ── Review ────────────────────────────────────────────────────────────

  /// Works out when this card should come back.
  ///
  /// Wrong knocks it to the bottom of the ladder; right moves it up one, and
  /// past the top it retires. Ungraded cards never come back: there is
  /// nothing to get right.
  Answer _scheduled(
    Answer answer, {
    required bool graded,
    required bool right,
    Answer? previous,
  }) {
    if (!graded) return answer;

    final stage = right ? (previous?.stage ?? 0) + 1 : 0;
    if (stage >= kReviewLadder.length) {
      return answer.copyWith(stage: stage, clearDue: true);
    }
    final due = today.add(Duration(days: kReviewLadder[stage]));
    return answer.copyWith(stage: stage, dueOn: dateKey(due));
  }

  bool isDueForReview(String pillId) => _dueBy(pillId, today);

  bool _dueBy(String pillId, DateTime on) {
    final due = answers[pillId]?.dueOn;
    if (due == null) return false;
    return due.compareTo(dateKey(on)) <= 0;
  }

  /// The cards to bring back, oldest due first.
  ///
  /// A card that came due is returned as a *different instance of the same
  /// principle* wherever one exists. Meeting the identical card again tests
  /// whether you remember that card; meeting base-rate neglect in a context
  /// you have not seen tests whether you learned base rates — and only the
  /// second is what transfer means.
  List<Pill> get dueReviews => _reviewsDue(today);

  /// The cards that came due and found no room in the five: what waits
  /// after the day, to be answered again.
  List<Pill> get reviewsWaiting {
    final dealt = todaysDeck.map((p) => p.id).toSet();
    return dueReviews.where((p) => !dealt.contains(p.id)).toList();
  }

  /// The same, for a day that has not started: what [on] will bring back.
  List<Pill> _reviewsDue(DateTime on) {
    final due = <MapEntry<String, Pill>>[];
    final claimed = <String>{};

    final entries = answers.entries.where((e) => _dueBy(e.key, on)).toList()
      ..sort((a, b) => a.value.dueOn!.compareTo(b.value.dueOn!));

    for (final e in entries) {
      final original = PillBank.cards.where((p) => p.id == e.key).firstOrNull;
      if (original == null) continue;
      final pick = _freshInstanceOf(original, claimed, on);
      claimed.add(pick.id);
      due.add(MapEntry(e.value.dueOn!, pick));
    }
    return [for (final entry in due) entry.value];
  }

  /// Tomorrow's cards, dealt the way tomorrow will deal them.
  ///
  /// The dealer is deterministic in the date and the reading history, and
  /// once a day is done the history is exactly what tomorrow will see — so
  /// tonight can say what opens the morning and the morning will agree.
  List<Pill> get tomorrowsDeck {
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    return _deal(
      tomorrow,
      exclude: {...seenIds, ...todaysDeck.map((p) => p.id)},
      reviews: _reviewsDue(tomorrow),
      own: ownCardsFor(plus: isPlus, streak: liveStreak),
    ).cards;
  }

  /// True when tomorrow is the morning after a full week kept, and so has
  /// three cards of the reader's own instead of two. Astute+ has five every
  /// day, so there it is nothing to say.
  bool get tomorrowIsRewarded =>
      !isPlus && liveStreak > 0 && liveStreak % 7 == 0;

  /// The card a morning opens on — for the reminder that quotes it and the
  /// widget that shows it. The question of the day on the free plan, where
  /// it is dealt; on Astute+ the first of the reader's own that asks, dealt
  /// the way that morning will deal it for a reader who has been away since
  /// tonight, which is the reader a reminder is for.
  Pill leadOn(DateTime day) {
    if (!isPlus) return questionOfTheDay(day);
    final List<Pill> deck = dateKey(day) == dateKey(today)
        ? todaysDeck
        : _deal(
            day,
            exclude: {...seenIds, ...todaysDeck.map((p) => p.id)},
            reviews: _reviewsDue(day),
            own: kPillsPerDay,
          ).cards;
    if (deck.isEmpty) return questionOfTheDay(day);
    return deck.firstWhere((p) => p.asksSomething, orElse: () => deck.first);
  }

  /// Another card teaching the same principle that the reader has not met,
  /// or the original when the principle has only the one instance.
  Pill _freshInstanceOf(Pill original, Set<String> claimed, DateTime on) {
    if (!original.principle.isReal) return original;

    final siblings = PillBank.cards
        .where(
          (p) =>
              p.principle == original.principle &&
              p.id != original.id &&
              !claimed.contains(p.id) &&
              !answers.containsKey(p.id),
        )
        .toList();
    if (siblings.isEmpty) return original;

    // Deterministic per day, so the deck does not shuffle under the reader.
    siblings.sort((a, b) => a.id.compareTo(b.id));
    final seed = dateKey(on).hashCode.abs() + original.id.hashCode.abs();
    return siblings[seed % siblings.length];
  }

  // ── Mastery ───────────────────────────────────────────────────────────

  /// How the reader is doing on one principle, across every context of it
  /// they have met.
  Mastery masteryOf(Principle principle) {
    var met = 0;
    var right = 0;
    for (final e in _graded) {
      if (e.key.principle != principle) continue;
      met++;
      if (e.key.challenge.accepts(e.value.response)) right++;
    }
    final total = PillBank.cards.where((p) => p.principle == principle).length;
    return Mastery(principle, met: met, right: right, contexts: total);
  }

  /// Every principle the reader has met, weakest first — the ones worth
  /// putting in front of them again.
  List<Mastery> get masteryByWeakness {
    final out = [
      for (final principle in Principle.values)
        if (principle.isReal) masteryOf(principle),
    ]..removeWhere((m) => m.met == 0);
    out.sort((a, b) => a.share.compareTo(b.share));
    return out;
  }

  // ── Calibration ───────────────────────────────────────────────────────

  /// One confidence level, and how it actually went.
  Iterable<CalibrationBucket> get calibration sync* {
    for (final level in kConfidenceLevels) {
      var count = 0;
      var right = 0;
      for (final j in judgements) {
        if (j.confidence != level) continue;
        count++;
        if (j.correct) right++;
      }
      if (count > 0) yield CalibrationBucket(level, count, right);
    }
  }

  int get calibratedAnswers => judgements.length;

  /// How the gap between confidence and accuracy has moved across the run.
  ///
  /// Judgements are append-only and kept in order, so the earliest window and
  /// the most recent one can be compared without storing a date against each
  /// answer. Null until there are two full windows: before that, a "trend" is
  /// just the last few answers wearing a serious word.
  Trend? get trend {
    const window = 10;
    if (judgements.length < window * 2) return null;
    return Trend(
      early: _gapOver(judgements.take(window)),
      recent: _gapOver(judgements.skip(judgements.length - window)),
      window: window,
    );
  }

  static double _gapOver(Iterable<Judgement> run) {
    var claimed = 0.0;
    var right = 0;
    var n = 0;
    for (final j in run) {
      claimed += j.confidence;
      if (j.correct) right++;
      n++;
    }
    if (n == 0) return 0;
    return claimed / n - right * 100 / n;
  }

  /// How far the reader's confidence sits from their accuracy, in points.
  /// Positive means overconfident — the usual direction.
  double? get overconfidence {
    if (judgements.isEmpty) return null;
    var claimed = 0.0;
    var right = 0;
    for (final j in judgements) {
      claimed += j.confidence;
      if (j.correct) right++;
    }
    final n = judgements.length;
    return (claimed / n) - (right / n * 100);
  }

  bool isSaved(String pillId) => savedIds.contains(pillId);

  Future<void> toggleSaved(String pillId) async {
    final bool had = savedIds.contains(pillId);
    if (had) {
      savedIds.remove(pillId);
    } else {
      savedIds.insert(0, pillId);
      unawaited(Tallies.instance.held(pillId));
    }
    await _prefs.setStringList(_kSavedIds, savedIds);
    Analytics.capture(had ? 'pill unsaved' : 'pill saved', {
      ...cardFacts(pillId),
      'shelf_size': savedIds.length,
    });
    notifyListeners();
  }

  /// Puts a pill back where it was — the undo behind the "removed" message.
  Future<void> restoreSaved(String pillId, int at) async {
    if (savedIds.contains(pillId)) return;
    savedIds.insert(at.clamp(0, savedIds.length), pillId);
    await _prefs.setStringList(_kSavedIds, savedIds);
    Analytics.capture('pill unsave undone', cardFacts(pillId));
    notifyListeners();
  }

  bool isLiked(String pillId) => likedIds.contains(pillId);

  /// A card held down. Liking one that was thrown down takes the throw
  /// back: the reader has changed their mind, and the newer word stands.
  Future<void> toggleLiked(String pillId) async {
    final bool had = likedIds.contains(pillId);
    if (had) {
      likedIds.remove(pillId);
    } else {
      likedIds.insert(0, pillId);
      unawaited(Tallies.instance.held(pillId));
      dislikedIds.remove(pillId);
      await _prefs.setStringList(_kDislikedIds, dislikedIds);
    }
    await _prefs.setStringList(_kLikedIds, likedIds);
    Analytics.capture(had ? 'pill unliked' : 'pill liked', {
      ...cardFacts(pillId),
      'shelf_size': likedIds.length,
    });
    notifyListeners();
  }

  Future<void> restoreLiked(String pillId, int at) async {
    if (likedIds.contains(pillId)) return;
    likedIds.insert(at.clamp(0, likedIds.length), pillId);
    await _prefs.setStringList(_kLikedIds, likedIds);
    Analytics.capture('pill unlike undone', cardFacts(pillId));
    notifyListeners();
  }

  bool hasSaid(String pillId) => saidIds.contains(pillId);

  /// Marks a card as said out loud. Newest first, and never unsaid: it
  /// either left the phone or it did not.
  Future<void> markSaid(String pillId) async {
    if (saidIds.contains(pillId)) return;
    saidIds.insert(0, pillId);
    unawaited(Tallies.instance.held(pillId));
    await _prefs.setStringList(_kSaidIds, saidIds);
    // The one thing the app is actually for: a card that left the phone and
    // was said to somebody. If any number here is the north star, it is this.
    Analytics.capture('pill said', {
      ...cardFacts(pillId),
      'said_total': saidIds.length,
    });
    notifyListeners();
  }

  /// The moves the reader has down: a principle met in at least two
  /// contexts and got right more often than not. What "something you can
  /// explain" means here, counted rather than claimed.
  int get movesDown =>
      masteryByWeakness.where((m) => m.isSettled && m.share >= 0.5).length;

  bool isDisliked(String pillId) => dislikedIds.contains(pillId);

  /// A card thrown down: less of this. It leaves the liked shelf if it
  /// was on it, for the same reason a like takes a throw back.
  Future<void> dislike(String pillId) async {
    if (dislikedIds.contains(pillId)) return;
    dislikedIds.insert(0, pillId);
    likedIds.remove(pillId);
    await _prefs.setStringList(_kDislikedIds, dislikedIds);
    await _prefs.setStringList(_kLikedIds, likedIds);
    Analytics.capture('pill disliked', {
      ...cardFacts(pillId),
      'disliked_total': dislikedIds.length,
    });
    notifyListeners();
  }

  /// The undo behind "less like this".
  Future<void> undislike(String pillId) async {
    if (!dislikedIds.remove(pillId)) return;
    await _prefs.setStringList(_kDislikedIds, dislikedIds);
    Analytics.capture('pill dislike undone', cardFacts(pillId));
    notifyListeners();
  }

  // ── Friends ───────────────────────────────────────────────────────────

  Future<void> addFriend(String code) async {
    if (friendCodes.contains(code)) return;
    friendCodes = [...friendCodes, code];
    await _prefs.setStringList(_kFriendCodes, friendCodes);
    // The count, never the codes. A friend code names a person.
    Analytics.capture('friend added', {'friends': friendCodes.length});
    notifyListeners();
  }

  Future<void> removeFriend(String code) async {
    if (!friendCodes.contains(code)) return;
    friendCodes = friendCodes.where((c) => c != code).toList();
    await _prefs.setStringList(_kFriendCodes, friendCodes);
    Analytics.capture('friend removed', {'friends': friendCodes.length});
    notifyListeners();
  }

  /// What a friend gets to see of this reader. The squares only once the
  /// day is done: half a grid says the wrong thing.
  Board board(String uid) {
    final DaySummary d = daySummary;
    return Board(
      uid: uid,
      code: friendCodeOf(uid),
      name: name,
      streak: liveStreak,
      weeks: keptWeeks,
      days: thisWeek.days,
      gap: confidenceGap,
      edition: d.edition,
      squares: dayClosed ? d.squares : '',
      right: d.right,
      asked: d.asked,
      questionRight: d.questionRight,
      questionSure: d.questionSure,
      updated: dateKey(today),
    );
  }

  // ── Onboarding & settings ─────────────────────────────────────────────

  Future<void> setTopics(Set<String> topics) async {
    pickedTopics = topics;
    await _prefs.setStringList(_kTopics, topics.toList());
    // The mix only takes effect on pills not yet dealt: re-dealing a day in
    // progress would drop what the reader is part-way through. Leave today's
    // remaining cards alone and let tomorrow follow the new mix.
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboarded = true;
    await _prefs.setBool(_kOnboarded, true);
    Analytics.capture('onboarding completed', {'topics': pickedTopics.length});
    notifyListeners();
  }

  static ThemeMode _decodeTheme(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _prefs.setString(_kTheme, mode.name);
    Analytics.capture('theme set', {'theme': mode.name});
    notifyListeners();
  }

  /// True once the reader turned the nudge on and the system agreed to it.
  /// The switch reflects what will actually happen rather than what was
  /// asked for — a toggle that says on while nothing is scheduled is worse
  /// than no toggle.
  bool remindersLive = false;

  Future<void> setNotifications(bool on) async {
    notificationsOn = on;
    await _prefs.setBool(_kNotifications, on);
    Analytics.capture('reminder switched', {'on': on, 'at': notifyTime});
    // The switch shows the setting, not the platform's response time. Told
    // only after the notification centre answered, it sat on its old value
    // for as long as that took — and a second tap then flipped it back.
    notifyListeners();
    await _applyReminder();
    notifyListeners();
  }

  Future<void> setNotifyTime(String time) async {
    notifyTime = time;
    await _prefs.setString(_kNotifyHour, time);
    // The hour a reader picks is the hour the content pipeline has to be
    // ready by, so it is worth knowing what they actually pick.
    Analytics.capture('reminder time set', {'at': time});
    notifyListeners();
    await _applyReminder();
    notifyListeners();
  }

  /// Puts the daily reminder in step with the settings, whichever way they
  /// moved. Called from both setters so the two can never disagree. This is
  /// the one path that may prompt for permission, because it runs when the
  /// reader has just touched the switch.
  Future<void> _applyReminder() async {
    if (!remindersSupported) {
      remindersLive = false;
      return;
    }
    // A host with no notification implementation behind the plugin — a
    // desktop, a test — throws on the first call. Losing the reminder is a
    // small thing; losing the settings screen with it is not.
    try {
      if (!notificationsOn) {
        await _disarm();
        remindersLive = false;
        return;
      }
      final granted = await _askPermission();
      if (!granted) {
        remindersLive = false;
        return;
      }
      await _armNow();
    } catch (_) {
      remindersLive = false;
    }
  }

  /// Re-arms the reminder without ever asking for anything.
  ///
  /// Run at every launch and every return to the foreground. The switch was
  /// the only thing that ever scheduled, so a fresh install with the switch
  /// on never scheduled at all — and a reminder armed once carries the
  /// streak it was armed with, which is stale by the next morning. This
  /// keeps it both present and current, and stays silent where permission
  /// has not been given: that prompt belongs to a moment the reader chose.
  Future<void> refreshDailyReminder() async {
    if (!remindersSupported || !notificationsOn) return;
    try {
      // No patience timer on this path. It is never awaited by anything
      // that shows on screen, so a centre that never answers costs nothing
      // here — and the timer itself outlived every widget test as a
      // pending timer, which is a worse fault than the one it guarded.
      if (!await _hasPermission()) {
        remindersLive = false;
        return;
      }
      await _armNow();
    } catch (_) {
      remindersLive = false;
    }
  }

  Future<void> _armNow() async {
    await _arm(reminderPlan());
    remindersLive = true;
  }

  /// How many days ahead the notifications are planned.
  static const int kPlannedDays = 14;

  /// The fortnight of notifications, each carrying the question of the
  /// day it lands on.
  ///
  /// One a day at the reader's hour, and never "we miss you": a message
  /// about the app's feelings is not worth the interruption. On the days a
  /// lapse reaches, it says something about the reader instead — that the
  /// freeze is holding, the card they were sure and wrong about, what two
  /// weeks came to — and after a fortnight it stops. Re-planned at every
  /// launch, so a reader who comes back is never told they were away.
  List<Reminder> reminderPlan({DateTime? now}) {
    final l = _strings;
    final parts = notifyTime.split(':');
    final int hour = int.tryParse(parts.first) ?? 8;
    final int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 30) : 30;
    final DateTime clock = now ?? DateTime.now();
    final DateTime? lastDone = dayClosed
        ? DateTime(today.year, today.month, today.day)
        : _dateOf(lastCompletionDate);

    final plan = <Reminder>[];
    for (var i = 0; i <= kPlannedDays; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final at = DateTime(day.year, day.month, day.day, hour, minute);
      if (!at.isAfter(clock)) continue;
      if (i == 0 && todayCompleted) continue;
      final Pill lead = leadOn(day);

      // How long the reader will have been away when this one lands.
      final int gap = lastDone == null ? 0 : day.difference(lastDone).inDays;
      String title = l.nudgeTitle;
      String body = lead.question;
      if (gap == 2 && freezes > 0) {
        title = l.nudgeFreezeTitle;
        body = l.nudgeFreezeBody(lead.question);
      } else if (gap == 7 && misses.isNotEmpty) {
        final Miss miss = misses.first;
        title = l.nudgeSureTitle;
        body = l.nudgeSureBody(miss.pill.question, miss.confidence);
      } else if (gap == 14) {
        final double? off = confidenceGap;
        title = l.nudgeTwoWeeksTitle(seenIds.length);
        body = off == null
            ? l.nudgeTwoWeeksBodyNoGap(answers.length, lead.question)
            : l.nudgeTwoWeeksBody(off.round(), lead.question);
      }
      plan.add(Reminder(id: i + 1, when: at, title: title, body: body));
    }
    return plan;
  }

  /// What the home-screen widget shows, handed over whenever it could
  /// have changed: at launch, on coming back, and when the day is done.
  ///
  /// The card the morning opens on and the streak, and the same for each of
  /// the next fourteen mornings, so the widget turns over at midnight on
  /// its own. The question of the day on the free plan; on Astute+ one of
  /// the reader's own. Nothing about the reader beyond the streak: the
  /// widget is on the home screen, where anyone can read it.
  /// Everything the home-screen widget will need, handed over whole.
  ///
  /// The widget draws the card the way the app does — the subject's colour
  /// for a ground, the subject as an eyebrow, the question set large — so it
  /// is given the colour and the ink of each morning's card, not only its
  /// question, and the three lines of its foot already in the reader's
  /// language, since the widget has no translations of its own.
  Map<String, Object?> homeWidgetData() {
    final ahead = <String, String>{};
    final aheadTopic = <String, String>{};
    final aheadColor = <String, String>{};
    final aheadInk = <String, String>{};
    for (var i = 0; i <= kPlannedDays; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final Pill lead = leadOn(day);
      final String key = dateKey(day);
      ahead[key] = lead.question;
      aheadTopic[key] = lead.topic;
      aheadColor[key] = hexOf(lead.color);
      aheadInk[key] = hexOf(lead.ink);
    }
    final Pill lead = leadOn(today);
    final AppLocalizations l = _strings;

    // The streak widget's week: the last seven days, oldest first, as a
    // row of 1s and 0s for read through or not, and each day's initial in
    // the reader's language. Initials repeat every seven days, so a widget
    // that has not heard from the app for a while can still roll them on.
    final Set<String> readThrough = completedDates.toSet();
    final Map<dynamic, dynamic> symbols = dateTimeSymbolMap();
    final List<String> initials =
        (symbols[l.localeName] as DateSymbols? ?? symbols['en'] as DateSymbols)
            .NARROWWEEKDAYS;
    final week = StringBuffer();
    final weekLabels = <String>[];
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day - i);
      week.write(readThrough.contains(dateKey(day)) ? '1' : '0');
      weekLabels.add(initials[day.weekday % 7]);
    }

    // Today's five in the order they are read, and tomorrow's, so the five
    // widget has the new day's colours at midnight without the app.
    List<Map<String, Object>> five(List<Pill> deck, int read) => [
      for (final (int i, Pill p) in deck.indexed)
        {
          'topic': p.topic,
          'color': hexOf(p.color),
          'ink': hexOf(p.ink),
          'read': i < read,
        },
    ];
    final int readToday = todayIndex.clamp(0, todaysDeck.length);

    return {
      'edition': editionOf(today),
      'date': dateKey(today),
      'question': lead.question,
      'topic': lead.topic,
      'color': hexOf(lead.color),
      'ink': hexOf(lead.ink),
      'streak': liveStreak,
      'done': dayClosed,
      'footPlain': l.widgetFootPlain,
      'footStreak': l.widgetFootStreak(liveStreak),
      'footDone': l.widgetFootDone,
      'ahead': ahead,
      'aheadTopic': aheadTopic,
      'aheadColor': aheadColor,
      'aheadInk': aheadInk,
      'streakCaption': l.dayStreakCaps,
      'streakText': l.streakDays(liveStreak),
      'streakStart': l.widgetStreakStart,
      'weekDone': week.toString(),
      'weekLabels': jsonEncode(weekLabels),
      'fiveJson': jsonEncode(five(todaysDeck, readToday)),
      'fiveTomorrowJson': jsonEncode(five(tomorrowsDeck, 0)),
      'fiveRead': readToday,
      'fiveTitle': l.widgetFiveTitle,
      'fiveReadText': l.widgetFiveRead(readToday),
      'fiveDone': l.widgetFiveDone,
      'fiveWaiting': l.widgetFiveWaiting,
    };
  }

  /// The reader as PostHog's profile holds them: the slow-moving facts
  /// worth cutting every chart by. Counts and enums, like every event.
  Map<String, Object> get analyticsProfile => {
    'is_plus': isPlus,
    'rung': standing.at,
    'streak_days': streak,
    'best_streak': bestStreak,
    'days_completed': completedDates.length,
    'weeks_kept': keptWeeks,
    'topics_count': pickedTopics.length,
    'genres_off': genresOff.length,
    'strands_off': strandsOff.length,
    'saved_count': savedIds.length,
    'liked_count': likedIds.length,
    'disliked_count': dislikedIds.length,
    'friends_count': friendCodes.length,
    'reminders_on': notificationsOn,
    'reminder_hour': int.tryParse(notifyTime.split(':').first) ?? -1,
    'theme': themeMode.name,
    'app_language': _strings.localeName,
    'onboarded': onboarded,
    'freezes': freezes,
  };

  /// The facts every event carries as well, so a funnel can be cut by them
  /// without a join.
  static const List<String> _everyEvent = [
    'is_plus',
    'rung',
    'streak_days',
    'days_completed',
    'topics_count',
    'reminders_on',
    'theme',
    'app_language',
  ];

  Map<String, Object>? _profileSent;

  /// Keeps PostHog's picture of the reader current. Sent only when something
  /// in it moved, so reading a card is not a profile update.
  void _syncAnalytics() {
    if (!ready || !Analytics.ready) return;
    final Map<String, Object> profile = analyticsProfile;
    if (mapEquals(profile, _profileSent)) return;
    _profileSent = profile;
    for (final String key in _everyEvent) {
      final Object? value = profile[key];
      if (value != null) Analytics.register(key, value);
    }
    Analytics.person(set: profile);
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _syncAnalytics();
  }

  /// A colour as the widgets read it: `#RRGGBB`, opaque.
  static String hexOf(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Future<void> refreshHomeWidget() async {
    try {
      await _pushWidget(homeWidgetData());
    } catch (_) {
      // The widget is a convenience; the app never fails for it.
    }
  }

  static DateTime? _dateOf(String? key) {
    if (key == null) return null;
    final parts = key.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return null;
    return DateTime(parts[0]!, parts[1]!, parts[2]!);
  }

  /// The strings, in the phone's language, for what is said with no screen
  /// to say it on.
  AppLocalizations get _strings => lookupAppLocalizations(
    basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    ),
  );

  Future<void> setName(String value) async {
    name = value.trim().isEmpty ? 'You' : value.trim();
    await _prefs.setString(_kName, name);
    notifyListeners();
  }

  /// Records the mix the reader dragged into shape.
  ///
  /// The weights and the picked set are two views of one answer, so they are
  /// written together and never separately.
  /// Keeps what the reader says they know. The whole answer at once: the
  /// screen that asks is the only writer, and it always writes all of it.
  /// What the reader turned off one layer under the mix.
  ///
  /// Taken whole rather than a toggle at a time: the screen is one decision
  /// made across a scrolling list, and writing to disk on every tap of a chip
  /// would be a write per tap for a choice that is not final until they leave.
  Future<void> setGenresOff(Set<String> genres, Set<String> strands) async {
    genresOff = {...genres};
    strandsOff = {...strands};
    await _prefs.setStringList(_kGenresOff, genresOff.toList());
    await _prefs.setStringList(_kStrandsOff, strandsOff.toList());
    Analytics.capture('genres set', {
      'genres_off': genresOff.length,
      'strands_off': strandsOff.length,
      'genres_on': kAllGenres.length - genresOff.length,
    });
    notifyListeners();
  }

  /// Whether this genre is dealt from. Everything is, until turned off.
  bool genreIsOn(String id) => !genresOff.contains(id);

  bool strandIsOn(String id) =>
      !strandsOff.contains(id) && genreIsOn(genreIdOf(id));

  Future<void> setTopicLevels(Map<String, int> levels) async {
    topicLevels = {...levels};
    await _prefs.setString(_kTopicLevels, jsonEncode(levels));
    Analytics.capture('levels set', {'subjects_rated': levels.length});
    notifyListeners();
  }

  static Map<String, int> _decodeLevels(String? raw) {
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (e.value is num) e.key.toString(): (e.value as num).round(),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> setTopicMix(Map<String, double> weights) async {
    topicWeights = {...weights};
    // Thinking is never on the wheel and never off the deck: every card that
    // asks something lives there, and those are the training.
    pickedTopics = {...weights.keys, 'thinking'};
    await _prefs.setString(
      _kTopicWeights,
      jsonEncode(weights.map((k, v) => MapEntry(k, v))),
    );
    await _prefs.setStringList(_kTopics, pickedTopics.toList());
    // Which subjects the wheel ended on, and how leaned it is. The names
    // decide what the pipeline writes next.
    Analytics.capture('mix set', {
      'topics': pickedTopics.length,
      'leaned_to': [
        for (final e
            in (weights.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .take(3))
          e.key,
      ].join(','),
    });
    notifyListeners();
  }

  static Map<String, double> _decodeWeights(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, double>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is num) out[key] = value.toDouble();
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  void setPlan(Plan value) {
    plan = value;
    notifyListeners();
  }

  /// Unlocks the Astute+ screens locally. No billing is wired up, so this
  /// only flips a stored flag — the paywall says as much when it calls it.
  Future<void> startPlusTrial() async {
    isPlus = true;
    await _prefs.setBool(_kPlus, true);
    Analytics.capture('trial started');
    Analytics.register('is_plus', true);
    notifyListeners();
  }

  /// What the store says the reader is entitled to.
  ///
  /// Kept in prefs so a launch with no network still opens on the right side
  /// of the paywall: the store is the truth, this is the last thing it said.
  Future<void> applyEntitlement(bool active) async {
    if (isPlus == active) return;
    isPlus = active;
    await _prefs.setBool(_kPlus, active);
    // What the store said, not what a screen hoped: this is the one place
    // the plan actually changes, so it is the one place it is counted.
    Analytics.capture('plan changed', {'is_plus': active});
    Analytics.register('is_plus', active);
    notifyListeners();
  }

  Future<void> endPlus() async {
    isPlus = false;
    await _prefs.setBool(_kPlus, false);
    Analytics.register('is_plus', false);
    notifyListeners();
  }

  /// Wipes local state — used by "Sign out" on the profile.
  Future<void> signOut() async {
    // Said before the wipe, while there is still a streak to report losing.
    Analytics.capture('signed out', {
      'streak_days': streak,
      'days_completed': completedDates.length,
      'pills_read': pillsRead,
    });
    await _prefs.clear();
    // The clear above took the reader's own answer to "measure this?" with
    // it. An opt-out a sign-out quietly undoes is not a choice, it is a
    // delay — so it goes back down before anything else is written.
    unawaited(Analytics.persistChoice());
    // And this phone is no longer that reader. What the next person does
    // here is theirs, counted as somebody new.
    unawaited(Analytics.reset());
    streak = 0;
    bestStreak = 0;
    lastCompletionDate = null;
    completedDates = [];
    savedIds = [];
    likedIds = [];
    dislikedIds = [];
    friendCodes = [];
    rungDates = {};
    saidIds = [];
    todayIndex = 0;
    pillsRead = 0;
    onboarded = false;
    pickedTopics = kTopicOrder.toSet();
    notificationsOn = true;
    notifyTime = '08:30';
    freezes = 1;
    frozeOn = null;
    name = 'You';
    isPlus = false;
    themeMode = ThemeMode.dark;
    seenIds = {};
    pushAsked = false;
    pushTokens = [];
    ownIdsToday = {};
    reviewIdsToday = {};
    answers = {};
    judgements = [];
    topicWeights = {};
    topicLevels = {};
    genresOff = {};
    strandsOff = {};
    deckHistory = {};
    await _startNewDay();
    notifyListeners();
  }

  /// True once there is a day behind the reader and they have not been asked
  /// about notifications yet. Asking before that spends the single prompt
  /// iOS allows on someone who does not yet know what the app is.
  bool get shouldAskForPush => !pushAsked && completedDates.isNotEmpty;

  /// Records the answer to that question, whatever it was. A refusal is
  /// remembered as firmly as a yes: asking twice is not possible anyway.
  Future<void> notedPushAnswer({String? token}) async {
    pushAsked = true;
    await _prefs.setBool(_kPushAsked, true);
    if (token != null && !pushTokens.contains(token)) {
      pushTokens = [...pushTokens, token];
      await _prefs.setStringList(_kPushTokens, pushTokens);
    }
    notifyListeners();
    // The reader has just answered the system's notification prompt. If they
    // said yes, the daily nudge can be armed now rather than at the next
    // launch.
    await refreshDailyReminder();
  }

  /// A token can be reissued by the system; one that changed is one the
  /// server can no longer reach.
  Future<void> rememberPushToken(String token) async {
    if (pushTokens.contains(token)) return;
    pushTokens = [...pushTokens, token];
    await _prefs.setStringList(_kPushTokens, pushTokens);
    notifyListeners();
  }

  /// What this phone knows about the reader, for the account to hold.
  ReaderSnapshot snapshot() => ReaderSnapshot(
    name: name,
    streak: streak,
    bestStreak: bestStreak,
    lastCompletionDate: lastCompletionDate,
    completedDates: List<String>.from(completedDates),
    savedIds: List<String>.from(savedIds),
    likedIds: List<String>.from(likedIds),
    dislikedIds: List<String>.from(dislikedIds),
    friendCodes: List<String>.from(friendCodes),
    rungDates: Map<String, String>.from(rungDates),
    saidIds: List<String>.from(saidIds),
    seenIds: seenIds.toList(),
    pillsRead: pillsRead,
    answers: Map<String, Answer>.from(answers),
    judgements: List<Judgement>.from(judgements),
    pickedTopics: pickedTopics.toList(),
    topicWeights: Map<String, double>.from(topicWeights),
    topicLevels: Map<String, int>.from(topicLevels),
    genresOff: genresOff.toList(),
    strandsOff: strandsOff.toList(),
    pushTokens: List<String>.from(pushTokens),
  );

  /// Takes on a snapshot that has already been merged, and stores it.
  ///
  /// Today's deck is deliberately left alone. The reader is part-way through
  /// five cards; re-dealing under them because a sign-in finished would lose
  /// the one thing they were actually doing.
  Future<void> adopt(ReaderSnapshot s) async {
    name = s.name;
    streak = s.streak;
    bestStreak = s.bestStreak;
    lastCompletionDate = s.lastCompletionDate;
    completedDates = List<String>.from(s.completedDates);
    savedIds = List<String>.from(s.savedIds);
    likedIds = List<String>.from(s.likedIds);
    dislikedIds = List<String>.from(s.dislikedIds);
    friendCodes = List<String>.from(s.friendCodes);
    rungDates = Map<String, String>.from(s.rungDates);
    saidIds = List<String>.from(s.saidIds);
    seenIds = s.seenIds.toSet();
    pillsRead = s.pillsRead;
    answers = Map<String, Answer>.from(s.answers);
    judgements = List<Judgement>.from(s.judgements);
    if (s.pickedTopics.isNotEmpty) pickedTopics = s.pickedTopics.toSet();
    topicWeights = Map<String, double>.from(s.topicWeights);
    topicLevels = Map<String, int>.from(s.topicLevels);
    genresOff = s.genresOff.toSet();
    strandsOff = s.strandsOff.toSet();
    pushTokens = List<String>.from(s.pushTokens);

    await _prefs.setString(_kName, name);
    await _prefs.setInt(_kStreak, streak);
    await _prefs.setInt(_kBestStreak, bestStreak);
    if (lastCompletionDate != null) {
      await _prefs.setString(_kLastCompletion, lastCompletionDate!);
    }
    await _prefs.setStringList(_kCompletedDates, completedDates);
    await _prefs.setStringList(_kSavedIds, savedIds);
    await _prefs.setStringList(_kLikedIds, likedIds);
    await _prefs.setStringList(_kDislikedIds, dislikedIds);
    await _prefs.setStringList(_kFriendCodes, friendCodes);
    await _prefs.setString(_kRungDates, jsonEncode(rungDates));
    await _prefs.setStringList(_kSaidIds, saidIds);
    await _prefs.setStringList(_kSeenIds, seenIds.toList());
    await _prefs.setInt(_kPillsRead, pillsRead);
    await _prefs.setStringList(_kTopics, pickedTopics.toList());
    await _prefs.setString(_kTopicWeights, jsonEncode(topicWeights));
    await _prefs.setString(_kTopicLevels, jsonEncode(topicLevels));
    await _prefs.setStringList(_kPushTokens, pushTokens);
    await _saveAnswers();
    await _noteClimb();
    notifyListeners();
  }

  /// True/false for the last 7 calendar days, oldest first.
  List<bool> weekCompletion() {
    final set = completedDates.toSet();
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return set.contains(dateKey(d));
    });
  }
}

/// A day, said without spoiling it.
class DaySummary {
  const DaySummary({
    required this.edition,
    required this.squares,
    required this.asked,
    required this.right,
    required this.sure,
    required this.streak,
    this.questionRight,
    this.questionSure,
  });

  /// One square a card: read, right, wrong, a side taken, or passed.
  static const String readSquare = '\u2b1c';
  static const String rightSquare = '\u{1f7e9}';
  static const String wrongSquare = '\u{1f7e5}';
  static const String sidedSquare = '\u{1f7e8}';
  static const String passedSquare = '\u2b1b';

  final int edition;
  final String squares;

  /// Cards that could be marked and were answered, and how many went right.
  final int asked;
  final int right;

  /// The confidence the reader put on today's answers, averaged, or null
  /// when nothing today carried one.
  final double? sure;
  final int streak;

  /// How the question of the day went — null until it was answered — and
  /// how sure the reader said they were.
  final bool? questionRight;
  final int? questionSure;
}

/// One confidence level and how it actually turned out.
class CalibrationBucket {
  /// What the reader claimed, as a percentage.
  final int said;
  final int count;
  final int right;

  const CalibrationBucket(this.said, this.count, this.right);

  /// What actually happened, as a percentage.
  double get actual => count == 0 ? 0 : right / count * 100;

  /// Positive when the reader was more sure than they should have been.
  double get gap => said - actual;
}

/// How one principle is going, across every context of it the reader has met.
class Mastery {
  final Principle principle;

  /// Contexts met, and of those how many were got right.
  final int met;
  final int right;

  /// How many contexts of this principle exist at all.
  final int contexts;

  const Mastery(
    this.principle, {
    required this.met,
    required this.right,
    required this.contexts,
  });

  double get share => met == 0 ? 0 : right / met;

  /// One instance proves nothing either way; the label waits for a second.
  bool get isSettled => met >= 2;

  bool get isWeak => isSettled && share < 0.5;
}

/// Two windows of the same run, so the reader can see whether the distance
/// between how sure they were and how right they were is actually closing.
class Trend {
  /// Signed gaps in points; positive means overconfident.
  final double early;
  final double recent;
  final int window;

  const Trend({
    required this.early,
    required this.recent,
    required this.window,
  });

  /// Positive means the gap has narrowed, whichever side it started on.
  double get closedBy => early.abs() - recent.abs();

  /// A couple of points either way is noise, not progress.
  bool get isMoving => closedBy.abs() >= 3;

  bool get isImproving => isMoving && closedBy > 0;
}
