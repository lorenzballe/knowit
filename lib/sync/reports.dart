import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics.dart';
import '../cloud.dart';

/// Why a reader says a card is wrong. The names are what is stored, and
/// what firestore.rules and the server's scorecard know them by.
enum ReportReason {
  fact('fact'),
  answer('answer'),
  source('source'),
  unclear('unclear'),
  typo('typo'),
  other('other');

  const ReportReason(this.wire);

  /// The name it is stored under.
  final String wire;

  /// A claim that the card says something untrue. Enough readers making
  /// one takes the card out of the deal until somebody has looked.
  bool get factual => this == fact || this == answer || this == source;

  static ReportReason? fromWire(Object? name) {
    for (final ReportReason r in values) {
      if (r.wire == name) return r;
    }
    return null;
  }
}

/// What a reader said about one card.
@immutable
class CardReport {
  const CardReport({required this.card, required this.reason, this.note = ''});

  final String card;
  final ReportReason reason;

  /// What they wrote, if anything. Kept with their account and read by the
  /// people who fix cards; never sent to measurement.
  final String note;

  /// The most a note may say, here and in firestore.rules.
  static const int noteLimit = 500;
}

/// Where reports go. An interface so the card can be driven in a test
/// without a project or a network.
abstract class ReportStore {
  /// Writes [fields] as the reader's report on the card they name, over any
  /// earlier one: a reader says one thing about a card, the last thing.
  Future<void> send(String uid, Map<String, Object?> fields);
}

/// One document per reader per card at readers/{uid}/reports/{card},
/// matching firestore.rules. Under the reader, so it goes when they do.
class FirestoreReportStore implements ReportStore {
  FirestoreReportStore([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> send(String uid, Map<String, Object?> fields) => _db
      .collection('readers')
      .doc(uid)
      .collection('reports')
      .doc(fields['card']! as String)
      .set({...fields, 'at': FieldValue.serverTimestamp()});
}

/// Keeps reports in memory. Used by the tests, and by nothing else.
class MemoryReportStore implements ReportStore {
  /// Reader, then card, then what was written.
  final Map<String, Map<String, Map<String, Object?>>> sent = {};

  /// Refuses every write while true, as Firestore does offline.
  bool refusing = false;

  @override
  Future<void> send(String uid, Map<String, Object?> fields) async {
    if (refusing) throw StateError('unavailable');
    sent.putIfAbsent(uid, () => {})[fields['card']! as String] = Map.of(fields);
  }
}

/// "Report a problem", from the back of a card.
///
/// A bank of five thousand cards written with a model's help will have
/// mistakes in it, and the readers are the only ones who read all of it.
/// This is how they say so: a reason from a short list, a line if they
/// want, and the card it is about. It is written with the reader's account,
/// where the server's nightly scorecard finds it (functions/src/scorecard.ts):
/// a card enough readers say is wrong stops being dealt until a person has
/// checked it.
///
/// A report waits on the phone until it is written — no account yet, no
/// signal — and goes with the next report or the next launch. The phone
/// remembers which cards it reported, so the card says "reported" instead
/// of asking again.
class Reports extends ChangeNotifier {
  Reports({this.storeOverride, this.uidOverride});

  /// One for the app, replaced under test.
  static Reports instance = Reports();

  @visibleForTesting
  static void useForTest(Reports value) => instance = value;

  /// Stands in for Firestore in the tests. Null in the app.
  final ReportStore? storeOverride;

  /// Stands in for the signed-in reader in the tests. Null in the app.
  final String? uidOverride;

  static const String _kReported = 'knowit.reported';
  static const String _kWaiting = 'knowit.reportsWaiting';

  final Set<String> _reported = {};
  final List<Map<String, Object?>> _waiting = [];
  Future<void>? _loading;
  Future<void>? _sending;

  /// Whether this phone has reported [cardId].
  bool has(String cardId) => _reported.contains(cardId);

  /// How many reports are waiting to be written.
  int get waiting => _waiting.length;

  /// Reads what the last launch left. Safe to call any number of times.
  Future<void> load() => _loading ??= _loadOnce();

  Future<void> _loadOnce() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _reported.addAll(prefs.getStringList(_kReported) ?? const []);
      final Object? decoded = jsonDecode(prefs.getString(_kWaiting) ?? '[]');
      if (decoded is List) {
        for (final Object? e in decoded) {
          if (e is Map && e['card'] is String) {
            _waiting.add({
              for (final MapEntry<Object?, Object?> f in e.entries)
                '${f.key}': f.value,
            });
          }
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Files [report]: marked on this phone at once, measured without the
  /// note, and written with the account as soon as there is one.
  Future<void> send(
    CardReport report, {
    String? topic,
    String? locale,
    int? bank,
  }) async {
    await load();
    final String note = report.note.trim();
    _reported.add(report.card);
    _waiting
      ..removeWhere((e) => e['card'] == report.card)
      ..add({
        'card': report.card,
        'reason': report.reason.wire,
        // By code point, so a cut never splits an emoji in two.
        'note': String.fromCharCodes(note.runes.take(CardReport.noteLimit)),
        'locale': ?locale,
        'bank': ?bank,
        'os': defaultTargetPlatform.name,
      });
    notifyListeners();
    // That a card was reported and why is measured, like a like; what the
    // reader wrote is not.
    Analytics.capture('card reported', {
      'pill_id': report.card,
      'topic': topic,
      'report_reason': report.reason.wire,
      'with_note': note.isNotEmpty,
    });
    await _persist();
    await flush();
  }

  /// Writes what is waiting. Two calls in a row share one trip.
  Future<void> flush() =>
      _sending ??= _flush().whenComplete(() => _sending = null);

  Future<void> _flush() async {
    await load();
    final ReportStore? store = _store;
    final String? uid = _uid;
    if (store == null || uid == null || _waiting.isEmpty) return;
    for (final Map<String, Object?> report in List.of(_waiting)) {
      try {
        await store.send(uid, report);
      } catch (error) {
        // Kept for the next time: offline, or the rules not published yet.
        debugPrint('Could not send the report on ${report['card']}: $error');
        break;
      }
      _waiting.remove(report);
    }
    await _persist();
  }

  ReportStore? get _store {
    if (storeOverride != null) return storeOverride;
    if (!Cloud.ready || FirebaseAuth.instance.currentUser == null) return null;
    return FirestoreReportStore();
  }

  String? get _uid =>
      uidOverride ??
      (Cloud.ready ? FirebaseAuth.instance.currentUser?.uid : null);

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kReported, _reported.toList());
      // Only where a store could ever take them: on the site there is no
      // account, and a report there is the measured event and nothing more.
      if (storeOverride != null || Cloud.ready) {
        await prefs.setString(_kWaiting, jsonEncode(_waiting));
      }
    } catch (_) {}
  }

  /// Forgets everything: a sign-out, or the end of a test.
  Future<void> reset() async {
    await load();
    _reported.clear();
    _waiting.clear();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kReported);
      await prefs.remove(_kWaiting);
    } catch (_) {}
    notifyListeners();
  }
}
