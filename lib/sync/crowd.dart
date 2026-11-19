import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../cloud.dart';

/// Today's three across readers: for each day, how many readers came to
/// each score, in tens of points, and nothing about who.
///
/// A reader adds their score once a day, in one batch: a mark under their
/// own id in the day's `readers`, which cannot be there already and is never
/// changed or taken away, and one more on their score's count, which
/// firestore.rules (`crowd`) lets move only together with that mark. So a
/// day's counts add up to the readers who played it, each once.
abstract class CrowdStore {
  /// Adds this phone's reader to [day]'s count for [bucket] (0 to 30: the
  /// score in tens of points).
  Future<void> add(String day, int bucket);

  /// [day]'s counts, by bucket, as they change: other readers' scores come
  /// in while the result is on screen.
  Stream<Map<int, int>> watch(String day);
}

/// The counts as stored: `n` holds one number per bucket, `b0` to `b30`;
/// `k` names the bucket the last write added to, which is how the rules can
/// hold every write to one bucket, plus one.
class FirestoreCrowdStore implements CrowdStore {
  FirestoreCrowdStore(this.uid, [FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  /// The reader the mark is filed under: their own id, as the rules ask.
  final String uid;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _day(String day) =>
      _db.collection('crowd').doc(day);

  @override
  Future<void> add(String day, int bucket) {
    final String k = 'b$bucket';
    final WriteBatch batch = _db.batch()
      ..set(_day(day).collection('readers').doc(uid), {'k': k})
      ..set(_day(day), {
        'k': k,
        'n': {k: FieldValue.increment(1)},
      }, SetOptions(merge: true));
    return batch.commit();
  }

  @override
  Stream<Map<int, int>> watch(String day) =>
      _day(day).snapshots().map((s) => bucketsOf(s.data()?['n']));
}

/// A day's counts as stored, keeping only what is a count of a bucket.
Map<int, int> bucketsOf(Object? raw) {
  if (raw is! Map) return const {};
  final Map<int, int> out = {};
  for (final MapEntry<Object?, Object?> e in raw.entries) {
    final Object? key = e.key;
    final Object? value = e.value;
    if (key is! String || !key.startsWith('b') || value is! num) continue;
    final int? bucket = int.tryParse(key.substring(1));
    if (bucket == null || bucket < 0 || bucket > 30 || value <= 0) continue;
    out[bucket] = value.round();
  }
  return out;
}

/// Counts kept in memory: for tests, and the camera that photographs the
/// app without a project.
class MemoryCrowdStore implements CrowdStore {
  MemoryCrowdStore([Map<String, Map<int, int>>? days]) : _days = days ?? {};

  final Map<String, Map<int, int>> _days;
  final Map<String, StreamController<Map<int, int>>> _out = {};

  /// What was added, for a test to read.
  final List<(String, int)> added = [];

  @override
  Future<void> add(String day, int bucket) async {
    added.add((day, bucket));
    final Map<int, int> counts = _days.putIfAbsent(day, () => {});
    counts[bucket] = (counts[bucket] ?? 0) + 1;
    _out[day]?.add(Map.of(counts));
  }

  @override
  Stream<Map<int, int>> watch(String day) {
    final StreamController<Map<int, int>> c = _out.putIfAbsent(
      day,
      StreamController<Map<int, int>>.broadcast,
    );
    return Stream<Map<int, int>>.multi((sink) {
      sink.add(Map.of(_days[day] ?? const {}));
      final StreamSubscription<Map<int, int>> s = c.stream.listen(sink.add);
      sink.onCancel = s.cancel;
    });
  }
}

/// Where today's three is counted: the server's when the phone is signed in
/// to it, otherwise nowhere, and the result says nothing of other readers.
class Crowd {
  Crowd._();

  static CrowdStore? _override;

  /// A store in place of the server's, for tests and the camera.
  @visibleForTesting
  static void useForTest(CrowdStore? store) => _override = store;

  /// The store, or null when there is none to count in.
  static CrowdStore? get store {
    if (_override != null) return _override;
    if (!Cloud.ready) return null;
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirestoreCrowdStore(user.uid);
  }

  /// Where [score] stands in [counts]: how many readers played, and the
  /// share of them, in whole per cent, who scored less.
  static ({int readers, int beaten}) place(Map<int, int> counts, int score) {
    final int bucket = (score ~/ 10).clamp(0, 30);
    int readers = 0;
    int below = 0;
    counts.forEach((b, n) {
      readers += n;
      if (b < bucket) below += n;
    });
    return (
      readers: readers,
      beaten: readers == 0 ? 0 : (100 * below / readers).round(),
    );
  }
}
