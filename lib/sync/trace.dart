import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cloud.dart';

/// What the reader does, written down for the reader's own sake.
///
/// Every app that feels like it knows you — the feed that learns, the playlist
/// made for Monday — is built on one thing: a record of what you did, kept
/// where the thing that decides can read it. Astute measures the reader
/// already (`Analytics`), but that record goes to PostHog, where it says how
/// the app is doing and never comes back to change what the reader is dealt.
/// This is the copy that comes back. The same gestures, compacted, land at
/// `readers/{uid}/activity/{UTC day}` in the reader's own account, and the
/// server reads them to work out what to deal them next (`functions/`).
///
/// It is the reader's, so the rules let nobody else read it, it is deleted
/// with the account, and it carries no prose: card ids, kinds, durations,
/// numbers and enums, never a name, an email, a reason written on a card or
/// a search typed.
///
/// It is batched. A phone that wrote one document per tap would spend a
/// write on every gesture and drain the battery keeping a socket warm; this
/// one keeps events in memory, flushes after [batch] of them or [settle]
/// after the first, and again when the app leaves the screen. Offline the
/// batch waits: the queue is kept on the phone until the store takes it, and
/// Firestore's own offline queue carries the write when the network is back.
///
/// It is fed from [Analytics.capture], which every gesture already passes
/// through with its facts attached — a second call at eighty call sites
/// would drift from the first within a month. [note] keeps the events it
/// wants and shortens their names and fields; everything else falls through.
class Trace extends ChangeNotifier {
  Trace({this.storeOverride, this.uidOverride, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// One trace for the app, replaced under test.
  static Trace instance = Trace();

  @visibleForTesting
  static void useForTest(Trace value) => instance = value;

  /// Stands in for Firestore in the tests. Null in the app.
  final TraceStore? storeOverride;

  /// Stands in for the signed-in reader in the tests. Null in the app.
  final String? uidOverride;

  final DateTime Function() _clock;

  /// Flush after this many events, or [settle] after the first one queued.
  static const int batch = 25;
  static const Duration settle = Duration(seconds: 20);

  /// Never more than this many waiting: a phone that cannot reach the store
  /// for a month keeps the last month's shape, not an unbounded list.
  static const int cap = 600;

  /// Where the queue waits between launches.
  static const String _kQueue = 'knowit.trace';

  final List<Map<String, Object?>> _queue = [];
  Timer? _pending;
  Future<void>? _flushing;
  Future<void>? _loading;
  bool _loaded = false;

  /// What has been written since the trace started, for the debug section.
  int written = 0;

  /// Whether the reader holds Astute+, as the phone knows it: the server
  /// deals five of their own on it. Said with the presence; a phone that
  /// lied would get four more of its own cards and nothing else.
  bool plus = false;

  /// The events kept, and the short name each goes out under. Everything
  /// not here is measurement only.
  static const Map<String, String> kept = {
    'app started': 'app',
    'app paused': 'pause',
    'card flipped': 'flip',
    'hint shown': 'hint',
    'explore scrolled': 'xd',
    'day started': 'day',
    'day completed': 'done',
    'card viewed': 'view',
    'card advanced': 'next',
    'card answered': 'ans',
    'pill liked': 'like',
    'pill unliked': 'unlike',
    'pill saved': 'save',
    'pill unsaved': 'unsave',
    'pill disliked': 'skip',
    'pill dislike undone': 'unskip',
    'pill said': 'said',
    'pill shared': 'share',
    'pill opened': 'open',
    'card read elsewhere': 'read',
    'card shown': 'seen',
    'tab opened': 'tab',
    'explore filtered': 'xf',
    'explore searched': 'xs',
    'explore top opened': 'xo',
    'explore loved opened': 'xo',
    'onboarding completed': 'onb',
    'mix set': 'mix',
    'genres set': 'genres',
    'plan changed': 'plan',
  };

  /// The fields kept, and the short name each goes out under. Card tags are
  /// not among them: the server has the bank and reads them off the id.
  static const Map<String, String> _fields = {
    'pill_id': 'c',
    'ms_on_card': 'ms',
    'ms_to_answer': 'ms',
    'ms_to_flip': 'ms',
    'ms_in_app': 'ms',
    'response_index': 'a',
    'response_value': 'v',
    'hint_available': 'h',
    'depth': 'd',
    'correct': 'ok',
    'confidence': 'cf',
    'review': 'rv',
    'review_stage': 'st',
    'slot': 's',
    'shelf': 'sh',
    'rank': 'r',
    'window': 'w',
    'subject': 'sub',
    'tab': 'tab',
    'by': 'by',
    'own': 'own',
    'welcome': 'wel',
    'streak_days': 'streak',
    'is_plus': 'plus',
    'cards': 'n',
    'reviews': 'rvs',
    'answered_right': 'right',
    'answered_wrong': 'wrong',
    'resumed': 'res',
    'topics': 'topics',
    'shape': 'shape',
    'claimed': 'claimed',
    'graded': 'g',
    'gave_reason': 'why',
    'saved': 'sv',
    'liked': 'lk',
    'answered': 'an',
    'to': 'to',
    'length': 'len',
    'found': 'found',
  };

  /// Writes an event down, if it is one the trace keeps.
  void note(String event, Map<String, Object?> properties) {
    final String? code = kept[event];
    if (code == null) return;
    final Map<String, Object?> compact = {
      't': _clock().millisecondsSinceEpoch,
      'e': code,
    };
    for (final MapEntry<String, Object?> e in properties.entries) {
      final String? key = _fields[e.key];
      final Object? value = e.value;
      if (key == null || value == null) continue;
      // Numbers, flags and short enums only. Anything longer is prose or a
      // list, and neither belongs in the reader's account.
      if (value is num || value is bool) {
        compact[key] = value;
      } else if (value is String && value.length <= 64) {
        compact[key] = value;
      }
    }
    _queue.add(compact);
    if (_queue.length > cap) _queue.removeRange(0, _queue.length - cap);
    // Nowhere to write yet — no account, a test — and nothing is armed: the
    // events wait in memory for the next note that finds a store, or for
    // the flush the app makes when it leaves the screen.
    if (_store == null) return;
    // What the last launch left comes in first; until it has, this launch's
    // events are not written down over it.
    unawaited(_load().then((_) => _persist()));
    if (_queue.length >= batch) {
      unawaited(flush());
    } else {
      _pending ??= Timer(settle, () {
        _pending = null;
        unawaited(flush());
      });
    }
  }

  /// Signed in, even anonymously, and Firebase up, or nothing.
  TraceStore? get _store {
    if (storeOverride != null) return storeOverride;
    if (!Cloud.ready || FirebaseAuth.instance.currentUser == null) return null;
    return FirestoreTraceStore();
  }

  String? get _uid =>
      uidOverride ??
      (Cloud.ready ? FirebaseAuth.instance.currentUser?.uid : null);

  /// Writes what is waiting, now. Two flushes in a row share one trip.
  Future<void> flush() =>
      _flushing ??= _flush().whenComplete(() => _flushing = null);

  Future<void> _flush() async {
    _pending?.cancel();
    _pending = null;
    await _load();
    final TraceStore? store = _store;
    final String? uid = _uid;
    if (store == null || uid == null || _queue.isEmpty) return;
    // By the UTC day each event fell on, like the counts: one document a day
    // per reader, and the server reads the days it wants.
    final Map<String, List<Map<String, Object?>>> byDay = {};
    for (final Map<String, Object?> e in _queue) {
      final int t = e['t'] as int;
      byDay
          .putIfAbsent(
            _day(DateTime.fromMillisecondsSinceEpoch(t, isUtc: true)),
            () => [],
          )
          .add(e);
    }
    final List<Map<String, Object?>> sent = List.of(_queue);
    try {
      for (final MapEntry<String, List<Map<String, Object?>>> e
          in byDay.entries) {
        await store.append(uid, e.key, e.value);
      }
      await store.presence(uid, {
        'tz': _clock().timeZoneOffset.inMinutes,
        'lastSeen': _clock().millisecondsSinceEpoch,
        'plus': plus,
      });
    } catch (error) {
      // Kept for the next flush: the phone is offline, or the rules are not
      // published yet. Nothing about the day depends on this landing.
      debugPrint('Could not write the trace: $error');
      return;
    }
    _queue.removeWhere(sent.contains);
    written += sent.length;
    await _persist();
    notifyListeners();
  }

  /// How many events are waiting to be written.
  int get waiting => _queue.length;

  static String _day(DateTime utc) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}-${two(utc.month)}-${two(utc.day)}';
  }

  Future<void> _load() => _loading ??= _loadOnce();

  Future<void> _loadOnce() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kQueue);
      if (raw == null) return;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final List<Map<String, Object?>> kept = [
        for (final Object? e in decoded)
          if (e is Map && e['t'] is int && e['e'] is String)
            {
              for (final MapEntry<Object?, Object?> f in e.entries)
                '${f.key}': f.value,
            },
      ];
      // What this launch already noted comes after what the last one left.
      _queue.insertAll(0, kept);
      if (_queue.length > cap) _queue.removeRange(0, _queue.length - cap);
    } catch (_) {
    } finally {
      _loaded = true;
    }
  }

  Future<void> _persist() async {
    // Only where a store could take it: a test, or a phone with an account.
    if (!_loaded || (storeOverride == null && !Cloud.ready)) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kQueue, jsonEncode(_queue));
    } catch (_) {}
  }

  /// Forgets the queue and the count: a sign-out, or the end of a test.
  Future<void> reset() async {
    _pending?.cancel();
    _pending = null;
    await _load();
    _queue.clear();
    written = 0;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kQueue);
    } catch (_) {}
  }
}

/// Where the trace goes. An interface so the app can be driven in a test
/// without a project or a network.
abstract class TraceStore {
  /// Adds [events] to the reader's record for [day] (UTC, `yyyy-mm-dd`).
  Future<void> append(
    String uid,
    String day,
    List<Map<String, Object?>> events,
  );

  /// Notes that the reader was here: their clock's offset and the moment,
  /// which is what the nightly dealer uses to know when their tomorrow is.
  Future<void> presence(String uid, Map<String, Object?> data);
}

/// One document per reader per UTC day at readers/{uid}/activity/{day}, and
/// the reader's presence at presence/{uid}, matching firestore.rules.
class FirestoreTraceStore implements TraceStore {
  FirestoreTraceStore([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> append(
    String uid,
    String day,
    List<Map<String, Object?>> events,
  ) => _db.collection('readers').doc(uid).collection('activity').doc(day).set({
    'ev': FieldValue.arrayUnion(events),
    'n': FieldValue.increment(events.length),
    'at': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  @override
  Future<void> presence(String uid, Map<String, Object?> data) =>
      _db.collection('presence').doc(uid).set({
        ...data,
        'uid': uid,
        'at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}

/// Keeps the trace in memory. Used by the tests, and by nothing else.
class MemoryTraceStore implements TraceStore {
  final Map<String, Map<String, List<Map<String, Object?>>>> days = {};
  final Map<String, Map<String, Object?>> presences = {};
  int appends = 0;

  /// Refuses every write while true, as Firestore does offline.
  bool refusing = false;

  @override
  Future<void> append(
    String uid,
    String day,
    List<Map<String, Object?>> events,
  ) async {
    if (refusing) throw StateError('unavailable');
    appends += 1;
    days.putIfAbsent(uid, () => {}).putIfAbsent(day, () => []).addAll(events);
  }

  @override
  Future<void> presence(String uid, Map<String, Object?> data) async {
    if (refusing) throw StateError('unavailable');
    presences[uid] = data;
  }
}
