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

/// A launch's worth of readers under the real ones.
///
/// A top list is only worth having once people have held on to things, and
/// on the first day nobody has: the list opened as three numbered empty
/// places, on every phone, for weeks. So until the real counts are enough
/// to stand alone, the list is seeded — a steady, believable crowd laid
/// under whatever real readers add, and the real ones rank on top of it.
///
/// Deterministic: the same card on the same day always gets the same
/// number on every phone, so two friends see the same list. About one card
/// in seven is ever seeded, enough for a subject's own list to fill,
/// heavy-tailed the way real lists are (a few cards far ahead, a long run
/// behind), and turning over month by month so the month list is not the
/// week's forever. [appeal] tilts it towards what readers
/// actually keep — questions over facts, a debate over both — and away from
/// nothing.
///
/// To retire it, construct [Tallies.instance] without a seed in `main.dart`.
class TopSeed {
  TopSeed({required this.ids, double Function(String id)? appeal})
    : appeal = appeal ?? _flat;

  /// Every card that may be seeded: the live bank.
  final Iterable<String> Function() ids;

  /// How much readers take to a card, around 1.
  final double Function(String id) appeal;

  static double _flat(String _) => 1;

  final Map<String, Map<String, int>> _days = {};

  /// A number in [0, 1) from [text], the same everywhere.
  static double unit(String text) {
    var h = 0x811c9dc5;
    for (final int c in text.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
    }
    // FNV alone leaves ids that differ by a digit close together; the
    // murmur finaliser spreads them over the whole range.
    h ^= h >> 16;
    h = (h * 0x85ebca6b) & 0xFFFFFFFF;
    h ^= h >> 13;
    h = (h * 0xc2b2ae35) & 0xFFFFFFFF;
    h ^= h >> 16;
    return h / 0x100000000;
  }

  /// How many readers a card has on an ordinary day: nothing for most, and
  /// from a third of a reader to about five for about one card in seven.
  static double popularity(String id) {
    final double u = unit('seed:$id');
    if (u < 0.85) return 0;
    return 0.3 + 4.5 * math.pow((u - 0.85) / 0.15, 2.5);
  }

  /// The seeded counts for [day] (`yyyy-mm-dd`).
  Map<String, int> on(String day) => _days.putIfAbsent(day, () {
    final String month = day.substring(0, 7);
    final Map<String, int> out = {};
    for (final String id in ids()) {
      final double p = popularity(id);
      if (p == 0) continue;
      final double season = 0.4 + 1.2 * unit('$month:$id');
      final double today = 0.5 + unit('$day:$id');
      final int n = (p * season * today * appeal(id)).floor();
      if (n > 0) out[id] = n;
    }
    return out;
  });
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
  Tallies({this.storeOverride, this.seed, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// The launch crowd under the real counts, or null for real counts only.
  /// See [TopSeed].
  final TopSeed? seed;

  /// True when the list has something to show: the counts have been read,
  /// or there is a seed to show until they are.
  bool get ready => answered || seed != null;

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

  /// True once the counts have been read. Until then Explore ranks nothing:
  /// it shows the list's places empty rather than guess at what is on them.
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
      final Map<String, int>? real = _days[day];
      final Map<String, int>? seeded = seed?.on(day);
      final Map<String, int>? counts = seeded == null
          ? real
          : real == null
          ? seeded
          : {
              ...seeded,
              for (final e in real.entries)
                e.key: (seeded[e.key] ?? 0) + e.value,
            };
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
