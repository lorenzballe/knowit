import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pills_data.dart';
import '../data/pills_repository.dart';
import '../data/topics.dart';
import '../models/pill.dart';
import '../utils/reminders.dart';

/// Which paid plan the paywall has selected. Purchases are not wired up.
enum Plan { month, year }

class AppState extends ChangeNotifier {
  static const _kStreak = 'knowit.streak';
  static const _kBestStreak = 'knowit.bestStreak';
  static const _kLastCompletion = 'knowit.lastCompletionDate';
  static const _kFreezes = 'knowit.freezes';
  static const _kFrozeOn = 'knowit.frozeOn';
  static const _kCompletedDates = 'knowit.completedDates';
  static const _kSavedIds = 'knowit.savedIds';
  static const _kTodayDate = 'knowit.todayDate';
  static const _kTodayIndex = 'knowit.todayIndex';
  static const _kOnboarded = 'knowit.onboarded';
  static const _kTopics = 'knowit.topics';
  static const _kTopicWeights = 'knowit.topicWeights';
  static const _kNotifications = 'knowit.notifications';
  static const _kNotifyHour = 'knowit.notifyHour';
  static const _kPillsRead = 'knowit.pillsRead';
  static const _kComebackSeen = 'knowit.comebackSeenDate';
  static const _kName = 'knowit.name';
  static const _kPlus = 'knowit.plus';
  static const _kSeenIds = 'knowit.seenIds';
  static const _kDeckIds = 'knowit.todayDeckIds';
  static const _kExtraOpen = 'knowit.extraSetDate';
  static const _kAnswers = 'knowit.answersJson';
  static const _kJudgements = 'knowit.judgements';
  static const _kTheme = 'knowit.theme';

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

  /// Saved pill ids, most recently kept first.
  List<String> savedIds = [];
  int todayIndex = 0;
  int pillsRead = 0;

  /// Every pill id already read, so later days open on something new.
  Set<String> seenIds = {};

  /// True once the Knowit+ second set has been unlocked today.
  bool extraSetOpen = false;

  /// Which of today's cards are here because they came back.
  Set<String> reviewIdsToday = {};

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
  bool notificationsOn = true;
  String notifyTime = '08:30';

  /// Knowit+ — gates the archive, image export and the topic mix.
  bool isPlus = false;
  String name = 'You';
  Plan plan = Plan.year;

  /// Light, dark, or whatever the phone is set to. One choice for the whole
  /// app — it does not change from screen to screen.
  ThemeMode themeMode = ThemeMode.dark;

  late DateTime today;
  late List<Pill> todaysDeck;

  bool get todayCompleted => todayIndex >= todaysDeck.length;

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
    today = DateTime.now();

    // Stored state is read defensively. A value written by an older build,
    // or corrupted on disk, must not leave the app stuck on the splash: it
    // is better to start fresh than never to start.
    try {
      await _restore();
    } catch (error, stack) {
      debugPrint('Knowit: could not restore stored state, starting fresh');
      debugPrintStack(stackTrace: stack, label: '$error');
      await _startNewDay();
    }

    ready = true;
    notifyListeners();
  }

  Future<void> _restore() async {
    streak = _prefs.getInt(_kStreak) ?? 0;
    bestStreak = _prefs.getInt(_kBestStreak) ?? 0;
    lastCompletionDate = _prefs.getString(_kLastCompletion);
    freezes = _prefs.getInt(_kFreezes) ?? 1;
    frozeOn = _prefs.getString(_kFrozeOn);
    completedDates = _prefs.getStringList(_kCompletedDates) ?? [];
    savedIds = _prefs.getStringList(_kSavedIds) ?? [];
    pillsRead = _prefs.getInt(_kPillsRead) ?? 0;

    onboarded = _prefs.getBool(_kOnboarded) ?? false;
    topicWeights = _decodeWeights(_prefs.getString(_kTopicWeights));
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
    extraSetOpen = _prefs.getString(_kExtraOpen) == dateKey(today);
    answers = _decodeAnswers(_prefs.getString(_kAnswers));
    judgements = _decodeJudgements(_prefs.getString(_kJudgements));

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
      if (todaysDeck.isEmpty) await _startNewDay();
    } else {
      await _spendFreezeIfMissed();
      await _startNewDay();
    }
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
  }

  /// How much of a day is given over to cards coming back. Two out of five
  /// keeps the day feeling new while still closing the loop on mistakes.
  static const int kReviewsPerDay = 2;

  /// Deals a fresh day and records it, so a restart resumes the same deck.
  ///
  /// Cards that have come round again take the first slots, and fresh ones
  /// fill the rest — an app that never re-asks what you got wrong is not
  /// teaching, it is entertaining.
  Future<void> _startNewDay() async {
    // Nobody has read anything yet, so this is the only first impression
    // there will be. It is chosen, not dealt.
    if (seenIds.isEmpty && answers.isEmpty && !extraSetOpen) {
      final opening = pillsByIds(kOpeningDeck);
      if (opening.length == kOpeningDeck.length) {
        todaysDeck = opening;
        reviewIdsToday = {};
        todayIndex = 0;
        await _prefs.setString(_kTodayDate, dateKey(today));
        await _prefs.setInt(_kTodayIndex, 0);
        await _prefs.setStringList(_kDeckIds, kOpeningDeck);
        return;
      }
    }

    final size = extraSetOpen ? kPillsPerDay * 2 : kPillsPerDay;
    final reviews = dueReviews.take(kReviewsPerDay).toList();
    reviewIdsToday = reviews.map((p) => p.id).toSet();

    todaysDeck = pillsForDate(
      today,
      topics: pickedTopics,
      weights: topicWeights,
      exclude: {...seenIds, ...reviews.map((p) => p.id)},
      count: size - reviews.length,
    );
    todaysDeck = [...reviews, ...todaysDeck];
    todaysDeck.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
    todayIndex = 0;
    await _prefs.setString(_kTodayDate, dateKey(today));
    await _prefs.setInt(_kTodayIndex, 0);
    await _prefs.setStringList(_kDeckIds, todaysDeck.map((p) => p.id).toList());
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

  // ── Reading ───────────────────────────────────────────────────────────

  Future<void> advance() async {
    if (todayCompleted) return;
    seenIds.add(todaysDeck[todayIndex].id);
    todayIndex += 1;
    pillsRead += 1;
    await _prefs.setInt(_kTodayIndex, todayIndex);
    await _prefs.setInt(_kPillsRead, pillsRead);
    await _prefs.setStringList(_kSeenIds, seenIds.toList());
    if (todayCompleted) {
      await _completeToday();
    }
    notifyListeners();
  }

  Future<void> _completeToday() async {
    final key = dateKey(today);
    if (lastCompletionDate == key) return;

    final yesterday = dateKey(today.subtract(const Duration(days: 1)));
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
      final pill = kPillPool.where((p) => p.id == e.key).firstOrNull;
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

    final pill = kPillPool.where((p) => p.id == pillId).firstOrNull;
    final graded = pill?.isGraded ?? false;
    final right = graded && (pill?.challenge.accepts(response) ?? false);

    answers[pillId] = _scheduled(
      Answer(response, confidence: confidence, reason: reason),
      graded: graded,
      right: right,
      previous: existing,
    );

    if (graded && confidence != null) {
      judgements.add(Judgement(confidence, correct: right));
    }

    await _saveAnswers();
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

  bool isDueForReview(String pillId) {
    final due = answers[pillId]?.dueOn;
    if (due == null) return false;
    return due.compareTo(dateKey(today)) <= 0;
  }

  /// The cards to bring back, oldest due first.
  ///
  /// A card that came due is returned as a *different instance of the same
  /// principle* wherever one exists. Meeting the identical card again tests
  /// whether you remember that card; meeting base-rate neglect in a context
  /// you have not seen tests whether you learned base rates — and only the
  /// second is what transfer means.
  List<Pill> get dueReviews {
    final due = <MapEntry<String, Pill>>[];
    final claimed = <String>{};

    final entries = answers.entries.where((e) => isDueForReview(e.key)).toList()
      ..sort((a, b) => a.value.dueOn!.compareTo(b.value.dueOn!));

    for (final e in entries) {
      final original = kPillPool.where((p) => p.id == e.key).firstOrNull;
      if (original == null) continue;
      final pick = _freshInstanceOf(original, claimed);
      claimed.add(pick.id);
      due.add(MapEntry(e.value.dueOn!, pick));
    }
    return [for (final entry in due) entry.value];
  }

  /// Another card teaching the same principle that the reader has not met,
  /// or the original when the principle has only the one instance.
  Pill _freshInstanceOf(Pill original, Set<String> claimed) {
    if (!original.principle.isReal) return original;

    final siblings = kPillPool
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
    final seed = dateKey(today).hashCode.abs() + original.id.hashCode.abs();
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
    final total = kPillPool.where((p) => p.principle == principle).length;
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
    if (savedIds.contains(pillId)) {
      savedIds.remove(pillId);
    } else {
      savedIds.insert(0, pillId);
    }
    await _prefs.setStringList(_kSavedIds, savedIds);
    notifyListeners();
  }

  /// Puts a pill back where it was — the undo behind the "removed" message.
  Future<void> restoreSaved(String pillId, int at) async {
    if (savedIds.contains(pillId)) return;
    savedIds.insert(at.clamp(0, savedIds.length), pillId);
    await _prefs.setStringList(_kSavedIds, savedIds);
    notifyListeners();
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
    await _applyReminder();
    notifyListeners();
  }

  Future<void> setNotifyTime(String time) async {
    notifyTime = time;
    await _prefs.setString(_kNotifyHour, time);
    await _applyReminder();
    notifyListeners();
  }

  /// Puts the daily reminder in step with the settings, whichever way they
  /// moved. Called from both setters so the two can never disagree.
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
        await cancelDailyReminder();
        remindersLive = false;
        return;
      }
      final granted = await ensureReminderPermission();
      if (!granted) {
        remindersLive = false;
        return;
      }
      final parts = notifyTime.split(':');
      await scheduleDailyReminder(
        hour: int.tryParse(parts.first) ?? 8,
        minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 30) : 30,
        title: 'Your five are ready',
        body: streak > 0
            ? '$streak days in a row. Keep it.'
            : 'Five cards, two minutes.',
      );
      remindersLive = true;
    } catch (_) {
      remindersLive = false;
    }
  }

  Future<void> setName(String value) async {
    name = value.trim().isEmpty ? 'You' : value.trim();
    await _prefs.setString(_kName, name);
    notifyListeners();
  }

  /// Records the mix the reader dragged into shape.
  ///
  /// The weights and the picked set are two views of one answer, so they are
  /// written together and never separately.
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

  /// Unlocks the Knowit+ screens locally. No billing is wired up, so this
  /// only flips a stored flag — the paywall says as much when it calls it.
  Future<void> startPlusTrial() async {
    isPlus = true;
    await _prefs.setBool(_kPlus, true);
    notifyListeners();
  }

  /// True when the reader is on Knowit+, has finished the day and has a
  /// second set still waiting.
  bool get canOpenExtraSet => isPlus && todayCompleted && !extraSetOpen;

  /// Unlocks the second set of the day — the "5 extra pills" Knowit+ perk.
  Future<void> openExtraSet() async {
    if (!canOpenExtraSet) return;
    extraSetOpen = true;
    await _prefs.setString(_kExtraOpen, dateKey(today));

    final extra = pillsForDate(
      today,
      topics: pickedTopics,
      weights: topicWeights,
      exclude: {...seenIds, ...todaysDeck.map((p) => p.id)},
      count: kPillsPerDay,
    );
    todaysDeck = [...todaysDeck, ...extra];
    await _prefs.setStringList(_kDeckIds, todaysDeck.map((p) => p.id).toList());
    notifyListeners();
  }

  Future<void> endPlus() async {
    isPlus = false;
    await _prefs.setBool(_kPlus, false);
    notifyListeners();
  }

  /// Wipes local state — used by "Sign out" on the profile.
  Future<void> signOut() async {
    await _prefs.clear();
    streak = 0;
    bestStreak = 0;
    lastCompletionDate = null;
    completedDates = [];
    savedIds = [];
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
    extraSetOpen = false;
    reviewIdsToday = {};
    answers = {};
    judgements = [];
    await _startNewDay();
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
