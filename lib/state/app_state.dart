import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/card_catalog.dart';
import '../data/pills_repository.dart';
import '../data/taste.dart';
import '../data/topics.dart';
import '../models/pill.dart';
import '../sync/card_feed.dart';
import '../sync/reader_snapshot.dart';
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
  static const _kPushAsked = 'knowit.pushAsked';
  static const _kPushTokens = 'knowit.pushTokens';
  static const _kTaste = 'knowit.taste';

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

  /// True once the Astuto+ second set has been unlocked today.
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

  /// What the app has learned about what this reader likes, from what they
  /// did with the cards they were given. The mix above is its prior.
  ReaderTaste taste = ReaderTaste();

  /// When the card on screen was put there.
  ///
  /// The one behavioural signal the app cannot get any other way: a card
  /// swiped past in two seconds was not read, and a card that held someone
  /// for half a minute was. Everything else — saving, answering, asking for
  /// the hint — is a button, and buttons are pressed by the minority who
  /// press buttons.
  DateTime _cardOpenedAt = DateTime.now();
  bool notificationsOn = true;
  String notifyTime = '08:30';

  /// Astuto+ — gates the archive, image export and the topic mix.
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

    // Before anything is dealt, so a day is dealt from everything the phone
    // knows about rather than only from what shipped inside it. Reads a file,
    // touches no network, and a cache that will not read is simply not there.
    await CardFeed.loadCache(_prefs);

    // Stored state is read defensively. A value written by an older build,
    // or corrupted on disk, must not leave the app stuck on the splash: it
    // is better to start fresh than never to start.
    try {
      await _restore();
    } catch (error, stack) {
      debugPrint('Astuto: could not restore stored state, starting fresh');
      debugPrintStack(stackTrace: stack, label: '$error');
      await _startNewDay();
    }

    ready = true;
    notifyListeners();

    // And then go and look for more, behind the reader rather than in front
    // of them. Anything new applies from tomorrow: today's deck is already
    // dealt and re-dealing it would drop whatever they are part-way through.
    unawaited(_catchUp());
  }

  Future<void> _catchUp() async {
    final held = await CardFeed.refresh(_prefs);
    if (held != null) notifyListeners();
  }

  /// How many of the cards on hand were written after this build shipped.
  /// Shown in the debug section, where "is the generator running" is
  /// otherwise unanswerable from a phone.
  int get writtenCards => CardCatalog.writtenCount;

  Future<void> _restore() async {
    taste = ReaderTaste.fromJson(_decodeJson(_prefs.getString(_kTaste)));
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
    // The mix is the taste model's prior, so it has to be in place before
    // anything is scored — including on a day that was restored rather than
    // dealt, where the profile still reads the model to say what it thinks.
    taste.declare(topicWeights);
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
    pushAsked = _prefs.getBool(_kPushAsked) ?? false;
    pushTokens = _prefs.getStringList(_kPushTokens) ?? [];
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
    // What was shown yesterday matters less than what is shown today, so a
    // subject rested for a few days becomes available again.
    taste.ageOneDay();
    taste.declare(topicWeights);
    _cardOpenedAt = DateTime.now();

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
      taste: taste,
      successByLevel: successByLevel,
      weakMoves: weakMoves,
      exclude: {...seenIds, ...reviews.map((p) => p.id)},
      count: size - reviews.length,
    );
    todaysDeck = [...reviews, ...todaysDeck];
    todaysDeck.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
    todayIndex = 0;

    // Dealing is what tires a subject out, not liking it: a card the reader
    // loved and one they skipped both mean they have just had one of those.
    for (final card in todaysDeck) {
      taste.noteDealt(card);
    }
    await _saveTaste();
    await _prefs.setString(_kTodayDate, dateKey(today));
    await _prefs.setInt(_kTodayIndex, 0);
    await _prefs.setStringList(_kDeckIds, todaysDeck.map((p) => p.id).toList());
  }

  Future<void> _saveTaste() =>
      _prefs.setString(_kTaste, jsonEncode(taste.toJson()));

  /// How often the reader gets a card of each difficulty right.
  ///
  /// What the deck needs in order to pitch a card where it can be won. Only
  /// levels they have actually answered at appear: a guess at a level nobody
  /// has met is not better than the assumption the ranker already makes.
  Map<Difficulty, double> get successByLevel {
    final met = <Difficulty, int>{};
    final right = <Difficulty, int>{};
    for (final e in _graded) {
      final level = e.key.difficulty;
      met[level] = (met[level] ?? 0) + 1;
      if (e.key.challenge.accepts(e.value.response)) {
        right[level] = (right[level] ?? 0) + 1;
      }
    }
    return {
      for (final level in met.keys)
        if (met[level]! >= 3) level: (right[level] ?? 0) / met[level]!,
    };
  }

  /// The moves the reader keeps missing, for the deck to bring back.
  ///
  /// This is the term that stops the ranking being a preference engine.
  /// Everything else in the score asks what the reader wants; this one asks
  /// what they need, and the profile already names it out loud — showing
  /// someone their worst move and then never dealing it again would be the
  /// app telling them about a gap it has no intention of closing.
  Set<Principle> get weakMoves => {
    for (final m in masteryByWeakness)
      if (m.isWeak) m.principle,
  };

  /// Records what the reader did with the card in front of them.
  ///
  /// Every one of these is something they did rather than something they
  /// said. See [Signal].
  Future<void> noteSignal(Pill card, Signal signal) async {
    taste.learn(card, signal);
    await _saveTaste();
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
    final card = todaysDeck[todayIndex];

    // Read, or moved past. The floor is a share of how long the card claims
    // to take, so a one-line fact is not counted as skipped for being read
    // quickly and a worked problem is not counted as read for being glanced
    // at. Bounded at both ends: nothing counts as read under three seconds,
    // and nothing has to be held for more than twenty.
    final spent = DateTime.now().difference(_cardOpenedAt).inMilliseconds / 1000;
    final floor = (card.seconds * 0.3).clamp(3.0, 20.0);
    taste.learn(card, spent >= floor ? Signal.read : Signal.skipped);
    await _saveTaste();
    _cardOpenedAt = DateTime.now();

    seenIds.add(card.id);
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
      final pill = CardCatalog.cards.where((p) => p.id == e.key).firstOrNull;
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

    final pill = CardCatalog.cards.where((p) => p.id == pillId).firstOrNull;
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

    // Committing to an answer rather than tapping through is engagement, and
    // it is not scored on whether the answer was right: being wrong about
    // something is not evidence of disliking it, and treating it that way
    // would quietly steer every reader toward what they already know.
    if (pill != null) {
      taste.learn(pill, Signal.answered);
      await _saveTaste();
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
      final original = CardCatalog.cards.where((p) => p.id == e.key).firstOrNull;
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

    final siblings = CardCatalog.cards
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
    final total = CardCatalog.cards.where((p) => p.principle == principle).length;
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
    final keeping = !savedIds.contains(pillId);
    if (keeping) {
      savedIds.insert(0, pillId);
    } else {
      savedIds.remove(pillId);
    }
    await _prefs.setStringList(_kSavedIds, savedIds);

    final card = CardCatalog.cards.where((p) => p.id == pillId).firstOrNull;
    if (card != null) {
      await noteSignal(card, keeping ? Signal.saved : Signal.unsaved);
    }
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
    // Changing the mix moves the prior, not the evidence. Somebody who has
    // used the app for months has facts about themselves on record, and a
    // slider is not a reason to throw them away — it is a reason to weigh
    // them differently.
    taste.declare(topicWeights);
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

  /// Unlocks the Astuto+ screens locally. No billing is wired up, so this
  /// only flips a stored flag — the paywall says as much when it calls it.
  Future<void> startPlusTrial() async {
    isPlus = true;
    await _prefs.setBool(_kPlus, true);
    notifyListeners();
  }

  /// True when the reader is on Astuto+, has finished the day and has a
  /// second set still waiting.
  bool get canOpenExtraSet => isPlus && todayCompleted && !extraSetOpen;

  /// Unlocks the second set of the day — the "5 extra pills" Astuto+ perk.
  Future<void> openExtraSet() async {
    if (!canOpenExtraSet) return;
    extraSetOpen = true;
    await _prefs.setString(_kExtraOpen, dateKey(today));

    // Ranked the same way the first five were. A second set that ignored
    // everything the app knows about the reader would be the one part of the
    // product they paid for being the least personal thing in it.
    final extra = pillsForDate(
      today,
      topics: pickedTopics,
      weights: topicWeights,
      taste: taste,
      successByLevel: successByLevel,
      weakMoves: weakMoves,
      exclude: {...seenIds, ...todaysDeck.map((p) => p.id)},
      count: kPillsPerDay,
    );
    for (final card in extra) {
      taste.noteDealt(card);
    }
    await _saveTaste();
    todaysDeck = [...todaysDeck, ...extra];
    await _prefs.setStringList(_kDeckIds, todaysDeck.map((p) => p.id).toList());
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
    await CardFeed.clear(_prefs);
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
    pushAsked = false;
    pushTokens = [];
    extraSetOpen = false;
    reviewIdsToday = {};
    answers = {};
    judgements = [];
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
    seenIds: seenIds.toList(),
    pillsRead: pillsRead,
    answers: Map<String, Answer>.from(answers),
    judgements: List<Judgement>.from(judgements),
    pickedTopics: pickedTopics.toList(),
    topicWeights: Map<String, double>.from(topicWeights),
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
    seenIds = s.seenIds.toSet();
    pillsRead = s.pillsRead;
    answers = Map<String, Answer>.from(s.answers);
    judgements = List<Judgement>.from(s.judgements);
    if (s.pickedTopics.isNotEmpty) pickedTopics = s.pickedTopics.toSet();
    topicWeights = Map<String, double>.from(s.topicWeights);
    pushTokens = List<String>.from(s.pushTokens);

    await _prefs.setString(_kName, name);
    await _prefs.setInt(_kStreak, streak);
    await _prefs.setInt(_kBestStreak, bestStreak);
    if (lastCompletionDate != null) {
      await _prefs.setString(_kLastCompletion, lastCompletionDate!);
    }
    await _prefs.setStringList(_kCompletedDates, completedDates);
    await _prefs.setStringList(_kSavedIds, savedIds);
    await _prefs.setStringList(_kSeenIds, seenIds.toList());
    await _prefs.setInt(_kPillsRead, pillsRead);
    await _prefs.setStringList(_kTopics, pickedTopics.toList());
    await _prefs.setString(_kTopicWeights, jsonEncode(topicWeights));
    await _prefs.setStringList(_kPushTokens, pushTokens);
    await _saveAnswers();
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
