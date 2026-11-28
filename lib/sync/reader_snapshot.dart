import 'dart:math' as math;

import '../models/pill.dart';
import '../models/place.dart';
import '../state/card_notes.dart';
import '../state/reading_log.dart';

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
    this.likedIds = const [],
    this.dislikedIds = const [],
    this.friendCodes = const [],
    this.rungDates = const {},
    this.readDays = const {},
    this.dayLog = const {},
    this.saidIds = const [],
    this.seenIds = const [],
    this.pillsRead = 0,
    this.answers = const {},
    this.judgements = const [],
    this.readingLog = const [],
    this.notes = const {},
    this.reactions = const {},
    this.pickedTopics = const [],
    this.topicWeights = const {},
    this.topicLevels = const {},
    this.genresOff = const [],
    this.strandsOff = const [],
    this.lovedTopics = const [],
    this.pushTokens = const [],
    this.place,
    this.placeRemovedAt,
    this.giftFrom,
    this.giftEndSaid,
  });

  final String name;
  final int streak;
  final int bestStreak;
  final String? lastCompletionDate;
  final List<String> completedDates;
  final List<String> savedIds;

  /// Held down, and thrown down. Both are the reader's word on a card,
  /// and both lean what the app deals of its own.
  final List<String> likedIds;
  final List<String> dislikedIds;

  /// The friend codes the reader added while the app had friends. Nothing
  /// reads them any more; the backup carries them as they were.
  final List<String> friendCodes;

  /// The day each rung of the ladder was first reached, by rung id.
  final Map<String, String> rungDates;

  /// The cards first read on each day, by date key.
  final Map<String, List<String>> readDays;

  /// What each day came to — the score at its end, the seconds on its cards
  /// and the cards read in each part of it — by date key.
  final Map<String, List<int>> dayLog;

  /// Cards the reader has said out loud to somebody.
  final List<String> saidIds;
  final List<String> seenIds;
  final int pillsRead;
  final Map<String, Answer> answers;
  final List<Judgement> judgements;

  /// Every read of a card, the last ReadingLog.keep (reading_log.dart): how
  /// the reader reads, which the app learns their taste from.
  final List<CardReadEntry> readingLog;

  /// The reader's notes on cards, a note taken away kept as an empty one
  /// with its time, so a merge does not bring it back (card_notes.dart).
  final Map<String, CardNote> notes;

  /// What the cards that ask did for the reader: a card's id to its
  /// reaction's key (AppState.reactions). Strings only, so the backup holds
  /// no array inside an array.
  final Map<String, String> reactions;
  final List<String> pickedTopics;
  final Map<String, double> topicWeights;

  /// What the reader said they already know of each subject, by key.
  final Map<String, int> topicLevels;

  /// The genres and strands the reader turned off, said in the same breath as
  /// the mix. Off rather than on, so a build that adds a genre gives it to
  /// everybody instead of hiding it from every reader who chose before it
  /// existed.
  final List<String> genresOff;
  final List<String> strandsOff;

  /// The subjects the reader loves, in the order picked, at most three:
  /// the first run's question asked in the positive, part of the mix.
  final List<String> lovedTopics;

  /// Where to send a notification, one entry per phone the reader uses.
  final List<String> pushTokens;

  /// Where the reader lives: a person's, not a phone's, so it travels. Kept
  /// at `readers/{uid}.place`, which is where the server reads it to deal
  /// cards about it — and, like every field here, gone from the document
  /// with the first write after it is removed, since a write replaces the
  /// whole of it.
  final Place? place;

  /// When the reader removed their place, if they did and have not set one
  /// since: the word a merge weighs against an older place, so that one
  /// phone's removal is not undone by another phone's copy.
  final DateTime? placeRemovedAt;

  /// The first day of the new reader's gift of Astute+, as a date key, or
  /// null for a reader who never had one: the reader's, so a new phone
  /// keeps the days the first one gave and gives no others. Not the plan:
  /// the gift is given once and never bought, and it is held to its date.
  final String? giftFrom;

  /// The day the gift's end was said, so it is said once whichever phone
  /// says it.
  final String? giftEndSaid;

  bool get isEmpty =>
      streak == 0 &&
      pillsRead == 0 &&
      answers.isEmpty &&
      judgements.isEmpty &&
      readingLog.isEmpty &&
      notes.isEmpty &&
      reactions.isEmpty &&
      savedIds.isEmpty &&
      completedDates.isEmpty;

  Map<String, dynamic> toJson() => {
    'name': name,
    'streak': streak,
    'bestStreak': bestStreak,
    'lastCompletionDate': lastCompletionDate,
    'completedDates': completedDates,
    'savedIds': savedIds,
    'likedIds': likedIds,
    'dislikedIds': dislikedIds,
    'friendCodes': friendCodes,
    'rungDates': rungDates,
    'readDays': readDays,
    'dayLog': dayLog,
    'saidIds': saidIds,
    'seenIds': seenIds,
    'pillsRead': pillsRead,
    'answers': answers.map((k, v) => MapEntry(k, v.toJson())),
    'judgements': judgements.map((j) => j.toJson()).toList(),
    // As one string: Firestore takes no array inside an array, and the iOS
    // SDK does not refuse one, it throws — the app closed on every backup
    // that carried a read (TestFlight build 63).
    'readingLog': ReadingLog.encode(readingLog),
    'notes': CardNotes.toJson(notes),
    'reactions': reactions,
    'pickedTopics': pickedTopics,
    'topicWeights': topicWeights,
    'topicLevels': topicLevels,
    'genresOff': genresOff,
    'strandsOff': strandsOff,
    'lovedTopics': lovedTopics,
    'pushTokens': pushTokens,
    'place': ?place?.toJson(),
    if (placeRemovedAt != null)
      'placeRemovedAt': placeRemovedAt!.toUtc().toIso8601String(),
    'giftFrom': ?giftFrom,
    'giftEndSaid': ?giftEndSaid,
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

    final reactionsRaw = raw['reactions'];
    final Map<String, String> reactions = {
      if (reactionsRaw is Map)
        for (final e in reactionsRaw.entries)
          if (e.key is String && Reaction.of(e.value) != null)
            e.key as String: e.value as String,
    };

    final notes = CardNotes.fromJson(raw['notes']);

    final readingRaw = raw['readingLog'];
    final readingLog = readingRaw is String
        ? ReadingLog.decode(readingRaw)
        : readingRaw is List
        ? readingRaw
              .map(CardReadEntry.fromJson)
              .whereType<CardReadEntry>()
              .toList()
        : <CardReadEntry>[];

    final weightsRaw = raw['topicWeights'];
    final weights = <String, double>{};
    if (weightsRaw is Map) {
      for (final entry in weightsRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is num) weights[key] = value.toDouble();
      }
    }

    final datesRaw = raw['rungDates'];
    final dates = <String, String>{};
    if (datesRaw is Map) {
      for (final entry in datesRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is String) dates[key] = value;
      }
    }

    final readRaw = raw['readDays'];
    final readDays = <String, List<String>>{};
    if (readRaw is Map) {
      for (final entry in readRaw.entries) {
        final key = entry.key;
        if (key is String) readDays[key] = strings(entry.value);
      }
    }

    final logRaw = raw['dayLog'];
    final dayLog = <String, List<int>>{};
    if (logRaw is Map) {
      for (final entry in logRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is List) {
          dayLog[key] = [
            for (final Object? n in value)
              if (n is num) n.round(),
          ];
        }
      }
    }

    final levelsRaw = raw['topicLevels'];
    final levels = <String, int>{};
    if (levelsRaw is Map) {
      for (final entry in levelsRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is num) levels[key] = value.round();
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
      likedIds: strings(raw['likedIds']),
      dislikedIds: strings(raw['dislikedIds']),
      friendCodes: strings(raw['friendCodes']),
      rungDates: dates,
      readDays: readDays,
      dayLog: dayLog,
      saidIds: strings(raw['saidIds']),
      seenIds: strings(raw['seenIds']),
      pillsRead: raw['pillsRead'] is int ? raw['pillsRead'] as int : 0,
      answers: answers,
      judgements: judgements,
      reactions: reactions,
      readingLog: readingLog,
      notes: notes,
      pickedTopics: strings(raw['pickedTopics']),
      topicWeights: weights,
      topicLevels: levels,
      genresOff: strings(raw['genresOff']),
      strandsOff: strings(raw['strandsOff']),
      lovedTopics: strings(raw['lovedTopics']),
      pushTokens: strings(raw['pushTokens']),
      place: Place.fromJson(raw['place']),
      placeRemovedAt: raw['placeRemovedAt'] is String
          ? DateTime.tryParse(raw['placeRemovedAt'] as String)
          : null,
      giftFrom: _dayKey(raw['giftFrom']),
      giftEndSaid: _dayKey(raw['giftEndSaid']),
    );
  }
}

/// [raw] when it is a day as the app files one, yyyy-mm-dd; null otherwise.
String? _dayKey(Object? raw) =>
    raw is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw) ? raw : null;

/// The earlier of two days kept as date keys, either of them missing.
String? _earlier(String? a, String? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.compareTo(b) <= 0 ? a : b;
}

/// Where the reader lives, of two records of it: whichever phone heard
/// last. A place is weighed by when its phone read it (`at`), a removal by
/// when it was made, and the newer of all of them stands — so a place set
/// on one phone reaches the other, and a removal made on one is not undone
/// by the other's older copy. Equal or undated, this phone's word wins.
({Place? place, DateTime? removedAt}) _newerPlace(
  ReaderSnapshot local,
  ReaderSnapshot remote,
) {
  DateTime when(Place? place, DateTime? removedAt) =>
      place?.at ??
      removedAt ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final bool localSaid = local.place != null || local.placeRemovedAt != null;
  final bool remoteSaid = remote.place != null || remote.placeRemovedAt != null;
  final bool remoteIsNewer =
      remoteSaid &&
      (!localSaid ||
          when(
            remote.place,
            remote.placeRemovedAt,
          ).isAfter(when(local.place, local.placeRemovedAt)));
  final ReaderSnapshot from = remoteIsNewer ? remote : local;
  return (
    place: from.place,
    removedAt: from.place == null ? from.placeRemovedAt : null,
  );
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
  // The reads, the same way: each phone's log only grows (to its cap), so
  // the longer is the fuller record.
  final List<CardReadEntry> readingLog =
      local.readingLog.length >= remote.readingLog.length
      ? local.readingLog
      : remote.readingLog;

  // Notes: for each card, the word written last, a note taken away
  // included.
  final Map<String, CardNote> notes = CardNotes.merged(
    remote.notes,
    local.notes,
  );

  // A rung was first reached on whichever phone reached it first: the
  // earlier date is the true one.
  final Map<String, String> rungDates = {...remote.rungDates};
  for (final entry in local.rungDates.entries) {
    final String? theirs = rungDates[entry.key];
    if (theirs == null || entry.value.compareTo(theirs) < 0) {
      rungDates[entry.key] = entry.value;
    }
  }

  // A card was first read on whichever phone read it first.
  final Map<String, String> firstRead = {};
  for (final days in [remote.readDays, local.readDays]) {
    for (final entry in days.entries) {
      for (final id in entry.value) {
        final String? theirs = firstRead[id];
        if (theirs == null || entry.key.compareTo(theirs) < 0) {
          firstRead[id] = entry.key;
        }
      }
    }
  }
  final Map<String, List<String>> readDays = {};
  for (final entry in firstRead.entries) {
    readDays.putIfAbsent(entry.value, () => []).add(entry.key);
  }

  // A day's counts only ever grow on the phone that wrote them, so where
  // both phones wrote the same day, the larger of each is the truer.
  final Map<String, List<int>> dayLog = {...remote.dayLog};
  for (final entry in local.dayLog.entries) {
    final List<int>? theirs = dayLog[entry.key];
    dayLog[entry.key] = theirs == null
        ? entry.value
        : [
            for (
              var i = 0;
              i < math.max(theirs.length, entry.value.length);
              i++
            )
              math.max(
                i < theirs.length ? theirs[i] : 0,
                i < entry.value.length ? entry.value[i] : 0,
              ),
          ];
  }

  // The mix is a decision, not a score: the one made most recently wins, and
  // this phone is where the reader just was.
  final bool localChoseMix = local.topicWeights.isNotEmpty;

  // Where the reader lives: the newer word, a removal included.
  final ({Place? place, DateTime? removedAt}) home = _newerPlace(local, remote);

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
    likedIds: union(local.likedIds, remote.likedIds),
    dislikedIds: union(local.dislikedIds, remote.dislikedIds),
    friendCodes: union(local.friendCodes, remote.friendCodes),
    rungDates: rungDates,
    readDays: readDays,
    dayLog: dayLog,
    saidIds: union(local.saidIds, remote.saidIds),
    seenIds: union(local.seenIds, remote.seenIds),
    pillsRead: math.max(local.pillsRead, remote.pillsRead),
    answers: answers,
    judgements: judgements,
    readingLog: readingLog,
    notes: notes,
    // A card's latest word stands, and this phone's is the latest it knows.
    reactions: {...remote.reactions, ...local.reactions},
    pickedTopics: localChoseMix
        ? local.pickedTopics
        : union(local.pickedTopics, remote.pickedTopics),
    topicWeights: localChoseMix ? local.topicWeights : remote.topicWeights,
    // Said in the same breath as the mix, so it travels with it.
    topicLevels: localChoseMix ? local.topicLevels : remote.topicLevels,
    // And so do the genres under it, for the same reason and by the same
    // rule: a union would quietly resurrect a genre this phone turned off.
    genresOff: localChoseMix ? local.genresOff : remote.genresOff,
    strandsOff: localChoseMix ? local.strandsOff : remote.strandsOff,
    // The loves too, which a reader can give with the mix walked past.
    lovedTopics: localChoseMix || local.lovedTopics.isNotEmpty
        ? local.lovedTopics
        : remote.lovedTopics,
    // A reader with two phones should be reachable on both.
    pushTokens: union(local.pushTokens, remote.pushTokens),
    place: home.place,
    placeRemovedAt: home.removedAt,
    // A gift was given on whichever phone gave it first, and runs from that
    // day: a second phone neither starts another nor moves its end.
    giftFrom: _earlier(local.giftFrom, remote.giftFrom),
    giftEndSaid: _earlier(local.giftEndSaid, remote.giftEndSaid),
  );
}
