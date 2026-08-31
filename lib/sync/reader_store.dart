import 'package:cloud_firestore/cloud_firestore.dart';

import 'reader_snapshot.dart';

/// Where a reader's snapshot lives when it is not on this phone.
///
/// An interface rather than a direct Firestore call so the sign-in path can
/// be tested without a project, a network or a signed-in user.
abstract class ReaderStore {
  Future<ReaderSnapshot?> read(String uid);

  Future<void> write(String uid, ReaderSnapshot snapshot);
}

/// One document per reader, at readers/{uid}, matching firestore.rules.
class FirestoreReaderStore implements ReaderStore {
  FirestoreReaderStore([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('readers').doc(uid);

  @override
  Future<ReaderSnapshot?> read(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return ReaderSnapshot.fromJson(snap.data());
  }

  @override
  Future<void> write(String uid, ReaderSnapshot snapshot) =>
      _doc(uid).set(snapshot.toJson());
}

/// Keeps a snapshot in memory. Used by the tests, and by nothing else.
class MemoryReaderStore implements ReaderStore {
  MemoryReaderStore([Map<String, ReaderSnapshot> seed = const {}])
    : _store = Map<String, ReaderSnapshot>.from(seed);

  final Map<String, ReaderSnapshot> _store;

  int writes = 0;

  @override
  Future<ReaderSnapshot?> read(String uid) async => _store[uid];

  @override
  Future<void> write(String uid, ReaderSnapshot snapshot) async {
    writes += 1;
    _store[uid] = snapshot;
  }
}
