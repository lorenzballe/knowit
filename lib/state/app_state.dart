import 'dart:convert';

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

  /// Card id -> what the reader committed to, and how sure they were.
  Map<String, Answer> answers = {};

  bool onboarded = false;
  Set<String> pickedTopics = kTopicOrder.toSet();
  bool notificationsOn = true;
  String notifyTime = '08:30';

  /// Knowit+ — gates the archive, image export and the topic mix.
  bool isPlus = false;
  String name = 'You';
  Plan plan = Plan.year;

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
    seenIds = (_prefs.getStringList(_kSeenIds) ?? []).toSet();
    extraSetOpen = _prefs.getString(_kExtraOpen) == dateKey(today);
    answers = _decodeAnswers(_prefs.getString(_kAnswers));

    final storedDay = _prefs.getString(_kTodayDate);
    final storedDeck = _prefs.getStringList(_kDeckIds) ?? [];
    if (storedDay == dateKey(today) && storedDeck.isNotEmpty) {
      // Restore the exact deck this day started with: recomputing it would
      // shuffle under the reader as their history grows.
      todaysDeck = pillsByIds(storedDeck);
      todayIndex = _prefs.getInt(_kTodayIndex) ?? 0;
      if (todaysDeck.isEmpty) await _startNewDay();
    } else {
      await _startNewDay();
    }
  }

  /// Deals a fresh day and records it, so a restart resumes the same deck.
  Future<void> _startNewDay() async {
    todaysDeck = pillsForDate(
      today,
      topics: pickedTopics,
      exclude: seenIds,
      count: extraSetOpen ? kPillsPerDay * 2 : kPillsPerDay,
    );
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
    if (raw == null || raw.isEmpty) return {};
    Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } on FormatException {
      return {};
    }
    if (parsed is! Map) return {};
    final out = <String, Answer>{};
    for (final entry in parsed.entries) {
      final answer = Answer.fromJson(entry.value);
      if (answer != null) out['${entry.key}'] = answer;
    }
    return out;
  }

  Future<void> _saveAnswers() async {
    await _prefs.setString(
      _kAnswers,
      jsonEncode({for (final e in answers.entries) e.key: e.value.toJson()}),
    );
  }

  /// What the reader committed to on this card, or null if they have not.
  Answer? answerFor(String pillId) => answers[pillId];

  /// Only cards that can be right or wrong count. A debate card asks for an
  /// opinion, and an opinion is not a score.
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

  /// Records a commitment. The first answer is the one that stands — meeting
  /// a card again should not let the score be retaken.
  Future<void> recordAnswer(
    String pillId,
    String response, {
    int? confidence,
  }) async {
    if (answers.containsKey(pillId)) return;
    answers[pillId] = Answer(response, confidence: confidence);
    await _saveAnswers();
    notifyListeners();
  }

  // ── Calibration ───────────────────────────────────────────────────────

  /// One confidence level, and how it actually went.
  Iterable<CalibrationBucket> get calibration sync* {
    for (final level in kConfidenceLevels) {
      var count = 0;
      var right = 0;
      for (final e in _graded) {
        if (e.value.confidence != level) continue;
        count++;
        if (e.key.challenge.accepts(e.value.response)) right++;
      }
      if (count > 0) yield CalibrationBucket(level, count, right);
    }
  }

  int get calibratedAnswers =>
      _graded.where((e) => e.value.confidence != null).length;

  /// How far the reader's confidence sits from their accuracy, in points.
  /// Positive means overconfident — the usual direction.
  double? get overconfidence {
    var claimed = 0.0;
    var right = 0;
    var count = 0;
    for (final e in _graded) {
      final said = e.value.confidence;
      if (said == null) continue;
      claimed += said;
      if (e.key.challenge.accepts(e.value.response)) right++;
      count++;
    }
    if (count == 0) return null;
    return (claimed / count) - (right / count * 100);
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
    seenIds = {};
    extraSetOpen = false;
    answers = {};
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
