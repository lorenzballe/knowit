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

  /// Every set of days asked for, in order, so a test can see what was read.
  final List<List<String>> asked = [];

  @override
  Future<void> add(String day, String pillId) async {
    final Map<String, int> counts = days.putIfAbsent(day, () => {});
    counts[pillId] = (counts[pillId] ?? 0) + 1;
  }

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

  /// True once the counts have been read. Until then Explore leaves the list
  /// out, rather than show an empty one that may not be empty — and a phone
  /// that cannot read them, offline or on rules not yet published, never
  /// shows a list that could never fill.
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
      for (var i = 0; i < monthDays; i++)
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

  /// The list for the last [days] days: most readers first; then the card
  /// counted most recently, so a card that is rising beats one that was;
  /// then by id, so the order never shuffles between two readings of the
  /// same numbers. [where] narrows it — to cards the app has, and to a
  /// subject.
  List<Ranked> top(
    int days, {
    bool Function(String id)? where,
    int limit = 10,
  }) {
    final DateTime now = _clock();
    final Map<String, int> readers = {};
    final Map<String, int> latest = {};
    for (var i = 0; i < days; i++) {
      final Map<String, int>? counts =
          _days[tallyDay(now.subtract(Duration(days: i)))];
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
