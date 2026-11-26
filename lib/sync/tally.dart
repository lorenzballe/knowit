import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cloud.dart';

/// The day a count is filed under: a UTC day, so a card liked in Tokyo and
/// one liked in Milan at the same moment land on the same one.
String tallyDay(DateTime at) {
  final DateTime utc = at.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)}';
}

/// A day's counts as stored, keeping only what is a count.
Map<String, int> countsOf(Object? raw) {
  if (raw is! Map) return {};
  return {
    for (final MapEntry<Object?, Object?> e in raw.entries)
      if (e.key is String && e.value is num && (e.value as num) > 0)
        e.key as String: (e.value as num).round(),
  };
}

/// Where the counts live. An interface so Explore can be driven in a test,
/// and photographed, without a project or a network.
abstract class TallyStore {
  /// Adds one to [pillId] on [day].
  Future<void> add(String day, String pillId);

  /// The counts on each of [days] that has any: day, then card, then how
  /// many readers.
  Future<Map<String, Map<String, int>>> read(List<String> days);

  /// Adds one to [pillId]'s count for good.
  Future<void> addTotal(String pillId);

  /// Every card's count for good: card, then how many readers.
  Future<Map<String, int>> readTotals();
}

/// Where a card's count for good is kept: the part of its id before the
/// first dash, so a shard holds one subject's cards and stays small.
String totalShard(String pillId) {
  final int dash = pillId.indexOf('-');
  return dash < 0 ? pillId : pillId.substring(0, dash);
}

/// One document per day at tallies/{day}: a count per card, and `k`, the
/// card the last write added to — which is how firestore.rules can hold
/// every write to one card, plus one.
class FirestoreTallyStore implements TallyStore {
  FirestoreTallyStore([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _days =>
      _db.collection('tallies');

  @override
  Future<void> add(String day, String pillId) => _days.doc(day).set({
    'k': pillId,
    'n': {pillId: FieldValue.increment(1)},
  }, SetOptions(merge: true));

  CollectionReference<Map<String, dynamic>> get _totals =>
      _db.collection('totals');

  @override
  Future<void> addTotal(String pillId) => _totals.doc(totalShard(pillId)).set({
    'k': pillId,
    'n': {pillId: FieldValue.increment(1)},
  }, SetOptions(merge: true));

  @override
  Future<Map<String, int>> readTotals() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _totals.get();
    return {for (final doc in snap.docs) ...countsOf(doc.data()['n'])};
  }

  @override
  Future<Map<String, Map<String, int>>> read(List<String> days) async {
    final Map<String, Map<String, int>> out = {};
    // Ten at a time: the most an `in` query took for years.
    for (var i = 0; i < days.length; i += 10) {
      final List<String> some = days.sublist(i, math.min(i + 10, days.length));
      final QuerySnapshot<Map<String, dynamic>> snap = await _days
          .where(FieldPath.documentId, whereIn: some)
          .get();
      for (final doc in snap.docs) {
        out[doc.id] = countsOf(doc.data()['n']);
      }
    }
    return out;
  }
}

/// Keeps the counts in memory. Used by the tests and the camera, and by
/// nothing else.
class MemoryTallyStore implements TallyStore {
  MemoryTallyStore([Map<String, Map<String, int>> seed = const {}])
    : days = {
        for (final MapEntry<String, Map<String, int>> e in seed.entries)
          e.key: Map<String, int>.from(e.value),
      };

  final Map<String, Map<String, int>> days;

  /// The counts for good.
  final Map<String, int> totals = {};

  /// Every set of days asked for, in order, so a test can see what was read.
  final List<List<String>> asked = [];

  @override
  Future<void> add(String day, String pillId) async {
    final Map<String, int> counts = days.putIfAbsent(day, () => {});
    counts[pillId] = (counts[pillId] ?? 0) + 1;
  }

  @override
  Future<void> addTotal(String pillId) async =>
      totals[pillId] = (totals[pillId] ?? 0) + 1;

  @override
  Future<Map<String, int>> readTotals() async => Map.of(totals);

  @override
  Future<Map<String, Map<String, int>>> read(List<String> wanted) async {
    asked.add(List.of(wanted));
    return {
      for (final String day in wanted)
        if (days[day] != null) day: Map<String, int>.from(days[day]!),
    };
  }
}

/// One place on the list: a card, and how many readers held on to it.
@immutable
class Ranked {
  const Ranked(this.id, this.readers);

  final String id;
  final int readers;
}

/// What readers across the app held on to — the cards they liked, saved or
/// said — counted by day. Explore's top of the week and top of the month
/// are read off it.
///
/// A count is all there is: one number per card per day, and nothing about
/// who. No account, no device, not the hour. A phone adds one to a card the
/// first time its reader likes, saves or says it, and never again, so a
/// number is a number of readers — and liking, unliking and liking again is
/// not a way up the list.
///
/// And the counts are only ever real ones. The list once had a launch crowd
/// under it, a made-up following so it was never empty; a list that says it
/// is what readers liked cannot be partly invented, however small the part.
/// Until real readers make a list worth showing ([worthShowing]) there is
/// none, and Explore says plainly what stands in its place.
class Tallies extends ChangeNotifier {
  Tallies({this.storeOverride, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// A singleton for the same reason the store's subscription is one: the
  /// app has one list, and tests replace it rather than thread it through
  /// six screens.
  static Tallies instance = Tallies();

  @visibleForTesting
  static void useForTest(Tallies value) => instance = value;

  /// Stands in for Firestore in the tests and the camera. Null in the app.
  final TallyStore? storeOverride;
  final DateTime Function() _clock;

  /// The cards this phone has already added one to.
  static const _kCounted = 'knowit.tallied';

  /// Settled days, as they were read, so they are only ever read once.
  static const _kSettled = 'knowit.tallyDays';

  static const int weekDays = 7;
  static const int monthDays = 30;

  /// Today, yesterday and the day before can still be added to — the rules
  /// allow for phones whose clocks sit either side of midnight — so they are
  /// read every time. Anything older is settled.
  static const int _openDays = 3;

  /// How long a reading stands before Explore asks again.
  static const Duration _fresh = Duration(minutes: 10);

  final Map<String, Map<String, int>> _days = {};
  final Map<String, int> _totals = {};
  bool _answered = false;
  DateTime? _readAt;
  Future<void>? _reading;

  /// Signed in, even anonymously, or nothing: the rules let nobody else read
  /// or add.
  TallyStore? get _store {
    if (storeOverride != null) return storeOverride;
    if (!Cloud.ready || FirebaseAuth.instance.currentUser == null) return null;
    return FirestoreTallyStore();
  }

  /// True once the counts have been read. Until then Explore ranks nothing:
  /// Astute's own picks stand in the list's place, said to be Astute's,
  /// rather than a guess at what readers kept.
  bool get answered => _answered;

  /// Counts [pillId] for this phone's reader: once per card, ever.
  Future<void> held(String pillId) async {
    final TallyStore? store = _store;
    if (store == null) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> counted = prefs.getStringList(_kCounted) ?? const [];
    if (counted.contains(pillId)) return;
    await prefs.setStringList(_kCounted, [...counted, pillId]);

    // On the list at once on this phone. The write goes when the network
    // lets it, and the next reading brings back everyone's.
    final String day = tallyDay(_clock());
    final Map<String, int> counts = _days.putIfAbsent(day, () => {});
    counts[pillId] = (counts[pillId] ?? 0) + 1;
    notifyListeners();
    unawaited(
      store.add(day, pillId).catchError((Object error) {
        debugPrint('Could not count $pillId: $error');
      }),
    );
    unawaited(
      store.addTotal(pillId).catchError((Object error) {
        debugPrint('Could not count $pillId for good: $error');
      }),
    );
  }

  /// Reads the last month's counts. Two readings in a row share one trip,
  /// and a reading stands for ten minutes unless [force]d.
  Future<void> refresh({bool force = false}) =>
      _reading ??= _read(force).whenComplete(() => _reading = null);

  Future<void> _read(bool force) async {
    final TallyStore? store = _store;
    if (store == null) return;
    final DateTime now = _clock();
    final DateTime? readAt = _readAt;
    if (!force && readAt != null && now.difference(readAt) < _fresh) return;

    final List<String> month = [
      for (var i = 0; i < closedAfter + monthDays; i++)
        tallyDay(now.subtract(Duration(days: i))),
    ];
    final List<String> open = month.take(_openDays).toList();
    final List<String> settled = month.skip(_openDays).toList();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, Map<String, int>> kept = _decode(
      prefs.getString(_kSettled),
    );
    final List<String> wanted = [
      ...open,
      for (final String day in settled)
        if (!kept.containsKey(day)) day,
    ];

    final Map<String, Map<String, int>> fetched;
    try {
      fetched = await store.read(wanted);
    } catch (error) {
      debugPrint('Could not read the counts: $error');
      return;
    }
    // The totals are a nicety on top of the list: when they cannot be read
    // the week and the month still stand.
    try {
      final Map<String, int> totals = await store.readTotals();
      _totals
        ..clear()
        ..addAll(totals);
    } catch (error) {
      debugPrint('Could not read the totals: $error');
    }

    _days
      ..clear()
      ..addAll({
        for (final String day in settled)
          if (kept[day] != null) day: kept[day]!,
      })
      ..addAll(fetched);
    // Every settled day in the month, empty ones too, so none is asked for
    // twice; days that fell out of the month fall out of the store.
    await prefs.setString(
      _kSettled,
      jsonEncode({
        for (final String day in settled) day: _days[day] ?? const {},
      }),
    );
    _answered = true;
    _readAt = now;
    notifyListeners();
  }

  /// How many of the most recent UTC days are left out of the list because
  /// they can still be added to. The rules take a count for a day until two
  /// days after it began (`isRecentDay`), so from midnight UTC the day
  /// before yesterday is closed: its numbers are final, and the same on
  /// every phone that reads them.
  static const int closedAfter = 2;

  /// How few readers a card can have and still be on a list for everybody.
  /// A count is of readers, and under three it is one person's taste, or a
  /// household's, not what readers kept. The server's `LIST_READERS`
  /// (functions/src/explore.ts).
  static const int listReaders = 3;

  /// How few cards make a list worth showing: a top of one or two is not a
  /// top. The server's `LIST_CARDS`.
  static const int listCards = 5;

  /// [ranked] as it may be shown to everybody: the cards fewer than
  /// [listReaders] readers held left off, and nothing at all while fewer
  /// than [listCards] are left — then Explore shows Astute's own picks in
  /// the list's place, under their own name, rather than a list too thin to
  /// mean anything. The server holds its lists to the same two numbers
  /// (`worthShowing`), card for card.
  static List<Ranked> worthShowing(List<Ranked> ranked) {
    final List<Ranked> held = [
      for (final Ranked r in ranked)
        if (r.readers >= listReaders) r,
    ];
    return held.length >= listCards ? held : const [];
  }

  /// The list for the [days] days that closed most recently: most readers
  /// first; then the card counted most recently, so a card that is rising
  /// beats one that was; then by id, so the order never shuffles between
  /// two readings of the same numbers. [where] narrows it — to cards the app
  /// has, and to a subject.
  ///
  /// Closed days only, so the list is one list: identical on every phone,
  /// and fixed from one midnight UTC to the next. A list that counted today
  /// would move under the reader all day, and differently on each phone —
  /// a phone sees its own like at once and everybody else's ten minutes
  /// later. The price is two days of lag, which a top of the week can pay.
  List<Ranked> top(
    int days, {
    bool Function(String id)? where,
    int limit = 10,
  }) {
    final DateTime now = _clock();
    final Map<String, int> readers = {};
    final Map<String, int> latest = {};
    for (var i = closedAfter; i < closedAfter + days; i++) {
      final String day = tallyDay(now.subtract(Duration(days: i)));
      final Map<String, int>? counts = _days[day];
      if (counts == null) continue;
      counts.forEach((id, n) {
        if (where != null && !where(id)) return;
        readers[id] = (readers[id] ?? 0) + n;
        latest.putIfAbsent(id, () => i);
      });
    }
    final List<MapEntry<String, int>> order = readers.entries.toList()
      ..sort((a, b) {
        final int most = b.value.compareTo(a.value);
        if (most != 0) return most;
        final int newest = latest[a.key]!.compareTo(latest[b.key]!);
        if (newest != 0) return newest;
        return a.key.compareTo(b.key);
      });
    return [for (final e in order.take(limit)) Ranked(e.key, e.value)];
  }

  /// The cards readers held on to most since the start: the counts for
  /// good. Live rather than closed — it is a shelf for finding what you
  /// missed, not a ranking to quote, and it moves too slowly for a day's
  /// likes to show. [where] narrows it.
  List<Ranked> allTime({bool Function(String id)? where, int limit = 40}) {
    final Map<String, int> readers = {
      for (final MapEntry<String, int> e in _totals.entries)
        if (e.value > 0 && (where == null || where(e.key))) e.key: e.value,
    };
    final List<MapEntry<String, int>> order = readers.entries.toList()
      ..sort((a, b) {
        final int most = b.value.compareTo(a.value);
        return most != 0 ? most : a.key.compareTo(b.key);
      });
    return [for (final e in order.take(limit)) Ranked(e.key, e.value)];
  }

  static Map<String, Map<String, int>> _decode(String? raw) {
    if (raw == null) return {};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final MapEntry<Object?, Object?> e in decoded.entries)
          if (e.key is String) e.key as String: countsOf(e.value),
      };
    } catch (_) {
      return {};
    }
  }
}
