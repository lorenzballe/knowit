import 'dart:math' as math;

import '../models/pill.dart';

/// Everything about a reader that should survive a new phone.
///
/// Deliberately not in here: the theme, the reminder time, today's deck and
/// how far through it they are, and whether the onboarding is done. Those
/// describe a device rather than a person, and copying them across would
/// mean a phone picking up half of another phone's day.
///
/// Also not in here: the plan. A subscription the client can write to itself
/// is not an entitlement, it is a wish — that comes from the store, through
/// RevenueCat, and until then it stays on the device that granted it.
class ReaderSnapshot {
  const ReaderSnapshot({
    this.name = 'You',
    this.streak = 0,
    this.bestStreak = 0,
    this.lastCompletionDate,
    this.completedDates = const [],
    this.savedIds = const [],
    this.seenIds = const [],
    this.pillsRead = 0,
    this.answers = const {},
    this.judgements = const [],
    this.pickedTopics = const [],
    this.topicWeights = const {},
    this.pushTokens = const [],
  });

  final String name;
  final int streak;
  final int bestStreak;
  final String? lastCompletionDate;
  final List<String> completedDates;
  final List<String> savedIds;
  final List<String> seenIds;
  final int pillsRead;
  final Map<String, Answer> answers;
  final List<Judgement> judgements;
  final List<String> pickedTopics;
  final Map<String, double> topicWeights;

  /// Where to send a notification, one entry per phone the reader uses.
  final List<String> pushTokens;

  bool get isEmpty =>
      streak == 0 &&
      pillsRead == 0 &&
      answers.isEmpty &&
      judgements.isEmpty &&
      savedIds.isEmpty &&
      completedDates.isEmpty;

  Map<String, dynamic> toJson() => {
    'name': name,
    'streak': streak,
    'bestStreak': bestStreak,
    'lastCompletionDate': lastCompletionDate,
    'completedDates': completedDates,
    'savedIds': savedIds,
    'seenIds': seenIds,
    'pillsRead': pillsRead,
    'answers': answers.map((k, v) => MapEntry(k, v.toJson())),
    'judgements': judgements.map((j) => j.toJson()).toList(),
    'pickedTopics': pickedTopics,
    'topicWeights': topicWeights,
    'pushTokens': pushTokens,
  };

  static ReaderSnapshot fromJson(Map<String, dynamic>? raw) {
    if (raw == null) return const ReaderSnapshot();

    List<String> strings(Object? v) =>
        v is List ? v.whereType<String>().toList() : const [];

    final answersRaw = raw['answers'];
    final answers = <String, Answer>{};
    if (answersRaw is Map) {
      for (final entry in answersRaw.entries) {
        final key = entry.key;
        final value = Answer.fromJson(entry.value);
        if (key is String && value != null) answers[key] = value;
      }
    }

    final judgementsRaw = raw['judgements'];
    final judgements = judgementsRaw is List
        ? judgementsRaw.map(Judgement.fromJson).whereType<Judgement>().toList()
        : <Judgement>[];

    final weightsRaw = raw['topicWeights'];
    final weights = <String, double>{};
    if (weightsRaw is Map) {
      for (final entry in weightsRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is num) weights[key] = value.toDouble();
      }
    }

    return ReaderSnapshot(
      name: raw['name'] is String ? raw['name'] as String : 'You',
      streak: raw['streak'] is int ? raw['streak'] as int : 0,
      bestStreak: raw['bestStreak'] is int ? raw['bestStreak'] as int : 0,
      lastCompletionDate: raw['lastCompletionDate'] is String
          ? raw['lastCompletionDate'] as String
          : null,
      completedDates: strings(raw['completedDates']),
      savedIds: strings(raw['savedIds']),
      seenIds: strings(raw['seenIds']),
      pillsRead: raw['pillsRead'] is int ? raw['pillsRead'] as int : 0,
      answers: answers,
      judgements: judgements,
      pickedTopics: strings(raw['pickedTopics']),
      topicWeights: weights,
      pushTokens: strings(raw['pushTokens']),
    );
  }
}

/// Folds what is on this phone into what the account already holds.
///
/// Signing in is not a restore and not a backup: it happens after the reader
/// has already used the app, so both sides are real and neither may be
/// thrown away. Every rule below is chosen so that no work disappears.
ReaderSnapshot mergeSnapshots(ReaderSnapshot local, ReaderSnapshot remote) {
  // Counts and streaks: the better of the two. A streak lost because the
  // other phone was idle would be the app punishing someone for owning two.
  final int streak = math.max(local.streak, remote.streak);
  final int bestStreak = math.max(
    math.max(local.bestStreak, remote.bestStreak),
    streak,
  );

  List<String> union(List<String> a, List<String> b) =>
      <String>{...a, ...b}.toList();

  String? latest(String? a, String? b) {
    if (a == null) return b;
    if (b == null) return a;
    // Date keys are yyyy-mm-dd, so they compare as strings.
    return a.compareTo(b) >= 0 ? a : b;
  }

  // Answers: the first answer stands, which is the app's own rule, so a card
  // both sides know keeps the one that has climbed further up the ladder —
  // that is the side with the longer history of it.
  final Map<String, Answer> answers = {...remote.answers};
  for (final entry in local.answers.entries) {
    final Answer? theirs = answers[entry.key];
    if (theirs == null || entry.value.stage > theirs.stage) {
      answers[entry.key] = entry.value;
    }
  }

  // Judgements carry no id and no time, so two lists cannot be interleaved
  // without inventing history. On one device the list only ever grows, so
  // the longer one is the more complete record — and it is never rewritten,
  // which is the promise the profile makes about calibration.
  final List<Judgement> judgements =
      local.judgements.length >= remote.judgements.length
      ? local.judgements
      : remote.judgements;

  // The mix is a decision, not a score: the one made most recently wins, and
  // this phone is where the reader just was.
  final bool localChoseMix = local.topicWeights.isNotEmpty;

  return ReaderSnapshot(
    name: local.name != 'You' ? local.name : remote.name,
    streak: streak,
    bestStreak: bestStreak,
    lastCompletionDate: latest(
      local.lastCompletionDate,
      remote.lastCompletionDate,
    ),
    // A day either was completed or was not, so the union is the truth.
    completedDates: union(local.completedDates, remote.completedDates),
    savedIds: union(local.savedIds, remote.savedIds),
    seenIds: union(local.seenIds, remote.seenIds),
    pillsRead: math.max(local.pillsRead, remote.pillsRead),
    answers: answers,
    judgements: judgements,
    pickedTopics: localChoseMix
        ? local.pickedTopics
        : union(local.pickedTopics, remote.pickedTopics),
    topicWeights: localChoseMix ? local.topicWeights : remote.topicWeights,
    // A reader with two phones should be reachable on both.
    pushTokens: union(local.pushTokens, remote.pushTokens),
  );
}
