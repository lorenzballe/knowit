import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pills_data.dart';
import '../data/pills_repository.dart';
import '../data/topics.dart';
import '../models/pill.dart';

/// Which paid plan the paywall has selected. Purchases are not wired up.
enum Plan { month, year }

class AppState extends ChangeNotifier {
  static const _kStreak = 'knowit.streak';
  static const _kBestStreak = 'knowit.bestStreak';
  static const _kLastCompletion = 'knowit.lastCompletionDate';
  static const _kCompletedDates = 'knowit.completedDates';
  static const _kSavedIds = 'knowit.savedIds';
  static const _kTodayDate = 'knowit.todayDate';
  static const _kTodayIndex = 'knowit.todayIndex';
  static const _kOnboarded = 'knowit.onboarded';
  static const _kTopics = 'knowit.topics';
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
    completedDates = _prefs.getStringList(_kCompletedDates) ?? [];
    savedIds = _prefs.getStringList(_kSavedIds) ?? [];
    pillsRead = _prefs.getInt(_kPillsRead) ?? 0;

    onboarded = _prefs.getBool(_kOnboarded) ?? false;
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
      await _startNewDay();
    }
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
    final size = extraSetOpen ? kPillsPerDay * 2 : kPillsPerDay;
    final reviews = dueReviews.take(kReviewsPerDay).toList();
    reviewIdsToday = reviews.map((p) => p.id).toSet();

    todaysDeck = pillsForDate(
      today,
      topics: pickedTopics,
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
  }) async {
    final existing = answers[pillId];
    if (existing != null && !isDueForReview(pillId)) return;

    final pill = kPillPool.where((p) => p.id == pillId).firstOrNull;
    final graded = pill?.isGraded ?? false;
    final right = graded && (pill?.challenge.accepts(response) ?? false);

    answers[pillId] = _scheduled(
      Answer(response, confidence: confidence),
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

  /// The cards waiting to come back, oldest due first.
  List<Pill> get dueReviews {
    final due = <MapEntry<String, Pill>>[];
    for (final e in answers.entries) {
      if (!isDueForReview(e.key)) continue;
      final pill = kPillPool.where((p) => p.id == e.key).firstOrNull;
      if (pill != null) due.add(MapEntry(e.value.dueOn!, pill));
    }
    due.sort((a, b) => a.key.compareTo(b.key));
    return [for (final e in due) e.value];
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

  Future<void> setNotifications(bool on) async {
    notificationsOn = on;
    await _prefs.setBool(_kNotifications, on);
    notifyListeners();
  }

  Future<void> setNotifyTime(String time) async {
    notifyTime = time;
    await _prefs.setString(_kNotifyHour, time);
    notifyListeners();
  }

  Future<void> setName(String value) async {
    name = value.trim().isEmpty ? 'You' : value.trim();
    await _prefs.setString(_kName, name);
    notifyListeners();
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
