import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cloud.dart';
import '../data/card_json.dart';
import '../models/pill.dart';

/// What the server dealt and assembled, as the phone reads it.
///
/// The phone dealt its own day from the bank it carried and read Explore
/// off the same bank. Now the server does both (`functions/`): it reads
/// what the reader did, deals the day from that, and writes it to
/// `readers/{uid}/days/{date}` with every card whole, so the morning is one
/// document; it assembles Explore for everybody at `explore/latest` and the
/// shelf that is one reader's at `readers/{uid}/explore/current`. This is
/// the reading side, and the fallbacks around it.
///
/// The phone still knows how to deal. A day the server has not dealt — a
/// first morning without signal, a project not yet on the plan that runs
/// functions, an outage — is dealt on the phone as it always was, from the
/// same calendar, and the reader never sees the difference except that it
/// knows them a little less well. Nothing the reader does waits on a
/// server: the request for a day is bounded, the evening asks for tomorrow
/// ahead of the morning, and what came back is kept on the phone.
class Served extends ChangeNotifier {
  Served({this.storeOverride, this.uidOverride, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static Served instance = Served();

  @visibleForTesting
  static void useForTest(Served value) => instance = value;

  final ServedStore? storeOverride;
  final String? uidOverride;
  final DateTime Function() _clock;

  /// How long the morning waits for the server before dealing on the phone.
  /// The document is usually there already, dealt the evening before or by
  /// the nightly pass, and read from the phone's own cache in milliseconds.
  static const Duration morningWait = Duration(seconds: 4);

  /// How long asking the server to deal a day may take, when the document
  /// is not there: a cold function and the profile's reads.
  static const Duration dealWait = Duration(seconds: 8);

  /// Explore as last read stands this long before it is asked for again.
  static const Duration exploreFresh = Duration(minutes: 10);

  static const String _kDay = 'knowit.servedDay';

  ServedStore? get _store {
    if (storeOverride != null) return storeOverride;
    if (!Cloud.ready || FirebaseAuth.instance.currentUser == null) return null;
    return FirestoreServedStore();
  }

  String? get _uid =>
      uidOverride ??
      (Cloud.ready ? FirebaseAuth.instance.currentUser?.uid : null);

  /// Whether a server can be asked at all from this phone.
  bool get available => _store != null && _uid != null;

  /// The reader's day for [date], as the server dealt it, or null to deal
  /// on the phone: what the phone kept from the evening's ask, then the
  /// document, then the server asked to deal it now, each within its wait.
  Future<ServedDay?> dayFor(DateTime date) async {
    final String key = _dateKey(date);
    final ServedDay? kept = await _keptDay(key);
    if (kept != null) return kept;
    final ServedStore? store = _store;
    final String? uid = _uid;
    if (store == null || uid == null) return null;
    try {
      final ServedDay? had = await store.day(uid, key).timeout(morningWait);
      if (had != null) {
        await _keep(had);
        return had;
      }
      final ServedDay? dealt = await store
          .askDay(uid, key, tz: _clock().timeZoneOffset.inMinutes)
          .timeout(dealWait);
      if (dealt != null) await _keep(dealt);
      return dealt;
    } catch (error) {
      debugPrint('The server did not deal $key; dealing here: $error');
      return null;
    }
  }

  /// Asks the server for [date] ahead of time and keeps the answer, so the
  /// morning finds it. Nothing waits on this.
  Future<ServedDay?> prefetch(DateTime date) async {
    final ServedStore? store = _store;
    final String? uid = _uid;
    if (store == null || uid == null) return null;
    final String key = _dateKey(date);
    try {
      final ServedDay? dealt = await store
          .askDay(uid, key, tz: _clock().timeZoneOffset.inMinutes)
          .timeout(dealWait);
      if (dealt != null) {
        await _keep(dealt);
        notifyListeners();
      }
      return dealt;
    } catch (error) {
      debugPrint('Could not fetch $key ahead: $error');
      return null;
    }
  }

  /// A day kept on the phone, for [date] only — an old one is a stale deal.
  Future<ServedDay?> keptDay(DateTime date) => _keptDay(_dateKey(date));

  Future<ServedDay?> _keptDay(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kDay);
      if (raw == null) return null;
      final ServedDay? day = ServedDay.parse(jsonDecode(raw));
      return day != null && day.date == key ? day : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _keep(ServedDay day) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDay, jsonEncode(day.toJson()));
    } catch (_) {}
  }

  ServedExplore? _explore;
  DateTime? _exploreAt;
  Future<ServedExplore?>? _exploring;

  /// Explore as the server assembled it, or null to assemble on the phone.
  /// What was read stands ten minutes; [force] reads again.
  Future<ServedExplore?> explore({bool force = false}) {
    final DateTime? at = _exploreAt;
    if (!force && at != null && _clock().difference(at) < exploreFresh) {
      return Future.value(_explore);
    }
    return _exploring ??= _readExplore().whenComplete(() => _exploring = null);
  }

  /// The last Explore read, without asking.
  ServedExplore? get lastExplore => _explore;

  Future<ServedExplore?> _readExplore() async {
    final ServedStore? store = _store;
    final String? uid = _uid;
    if (store == null || uid == null) return null;
    try {
      final ServedExplore? got = await store.explore(uid).timeout(morningWait);
      if (got != null) {
        _explore = got;
        _exploreAt = _clock();
        notifyListeners();
      }
      return got ?? _explore;
    } catch (error) {
      debugPrint('Could not read Explore from the server: $error');
      return _explore;
    }
  }

  /// The pool asked a question, on the server; null when it cannot be.
  Future<List<Pill>?> search(String query) async {
    final ServedStore? store = _store;
    if (store == null || _uid == null) return null;
    try {
      return await store.search(query).timeout(dealWait);
    } catch (error) {
      debugPrint('The server did not answer the search: $error');
      return null;
    }
  }

  /// Forgets what was read: a sign-out, the end of a test.
  Future<void> reset() async {
    _explore = null;
    _exploreAt = null;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kDay);
    } catch (_) {}
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// A day as the server dealt it: the cards whole, and which are the
/// reader's own.
class ServedDay {
  const ServedDay({
    required this.date,
    required this.cards,
    required this.own,
    required this.reviews,
    this.welcome = false,
    this.fromCache = false,
  });

  final String date;
  final List<Pill> cards;
  final Set<String> own;
  final Set<String> reviews;
  final bool welcome;

  /// Read from the phone's own copy of the store rather than the server:
  /// what it was when the phone last had signal.
  final bool fromCache;

  /// Reads the document at readers/{uid}/days/{date}. Null when it is not a
  /// day the app can deal: a card it cannot draw refuses the whole day, and
  /// the phone deals its own instead.
  static ServedDay? parse(Object? raw, {bool fromCache = false}) {
    if (raw is! Map) return null;
    final String? date = raw['date'] is String ? raw['date'] as String : null;
    final Object? rawCards = raw['cards'];
    if (date == null || rawCards is! List || rawCards.isEmpty) return null;
    try {
      final cards = <Pill>[
        for (final c in rawCards)
          if (c is Map) cardFromJson(Map<String, Object?>.from(c)),
      ];
      if (cards.length != rawCards.length) return null;
      List<String> strings(Object? v) =>
          v is List ? v.whereType<String>().toList() : const [];
      return ServedDay(
        date: date,
        cards: cards,
        own: strings(raw['own']).toSet(),
        reviews: strings(raw['reviews']).toSet(),
        welcome: raw['welcome'] == true,
        fromCache: fromCache,
      );
    } catch (error) {
      debugPrint('A served day the app could not draw: $error');
      return null;
    }
  }

  Map<String, Object?> toJson() => {
    'date': date,
    'cards': [for (final p in cards) cardToJson(p)],
    'own': own.toList(),
    'reviews': reviews.toList(),
    'welcome': welcome,
  };
}

/// One place on a served list.
class ServedRank {
  const ServedRank(this.pill, this.readers);
  final Pill pill;
  final int readers;
}

/// Explore as the server assembled it: for everybody, and for this reader.
class ServedExplore {
  const ServedExplore({
    required this.day,
    required this.today,
    required this.asking,
    required this.topWeek,
    required this.topMonth,
    required this.loved,
    required this.bySubject,
    this.because,
    this.mine = const [],
    this.forYou = const [],
    this.fromCache = false,
  });

  /// The UTC day the shelves were assembled for.
  final String day;
  final List<Pill> today;
  final List<Pill> asking;
  final List<ServedRank> topWeek;
  final List<ServedRank> topMonth;
  final List<ServedRank> loved;

  /// Per subject key: the ids on its week, month and loved lists, with their
  /// counts, so the subject row narrows without another read.
  final Map<
    String,
    ({
      List<(String, int)> week,
      List<(String, int)> month,
      List<(String, int)> loved,
    })
  >
  bySubject;

  final String? because;
  final List<Pill> mine;
  final List<Pill> forYou;
  final bool fromCache;

  /// Reads explore/latest, and the reader's own shelf when there is one.
  static ServedExplore? parse(
    Object? global,
    Object? personal, {
    bool fromCache = false,
  }) {
    if (global is! Map) return null;
    try {
      List<Pill> pills(Object? v) => [
        for (final c in (v is List ? v : const []))
          if (c is Map) cardFromJson(Map<String, Object?>.from(c)),
      ];
      List<ServedRank> ranked(Object? v) => [
        for (final r in (v is List ? v : const []))
          if (r is Map && r['card'] is Map && r['readers'] is num)
            ServedRank(
              cardFromJson(Map<String, Object?>.from(r['card'] as Map)),
              (r['readers'] as num).round(),
            ),
      ];
      List<(String, int)> ids(Object? v) => [
        for (final r in (v is List ? v : const []))
          if (r is Map && r['id'] is String && r['readers'] is num)
            (r['id'] as String, (r['readers'] as num).round()),
      ];
      final by =
          <
            String,
            ({
              List<(String, int)> week,
              List<(String, int)> month,
              List<(String, int)> loved,
            })
          >{};
      final rawBy = global['bySubject'];
      if (rawBy is Map) {
        for (final e in rawBy.entries) {
          if (e.key is String && e.value is Map) {
            final Map v = e.value as Map;
            by[e.key as String] = (
              week: ids(v['week']),
              month: ids(v['month']),
              loved: ids(v['loved']),
            );
          }
        }
      }
      final Map? p = personal is Map ? personal : null;
      return ServedExplore(
        day: global['day'] is String ? global['day'] as String : '',
        today: pills(global['today']),
        asking: pills(global['asking']),
        topWeek: ranked(global['topWeek']),
        topMonth: ranked(global['topMonth']),
        loved: ranked(global['loved']),
        bySubject: by,
        because: p?['because'] is String ? p!['because'] as String : null,
        mine: pills(p?['mine']),
        forYou: pills(p?['forYou']),
        fromCache: fromCache,
      );
    } catch (error) {
      debugPrint('An Explore the app could not draw: $error');
      return null;
    }
  }
}

/// Where the served things come from. An interface so the app can be
/// driven in a test without a project or a network.
abstract class ServedStore {
  /// The day already dealt, or null when it is not there.
  Future<ServedDay?> day(String uid, String date);

  /// The server asked to deal [date] now, and the day it dealt.
  Future<ServedDay?> askDay(String uid, String date, {required int tz});

  Future<ServedExplore?> explore(String uid);

  Future<List<Pill>> search(String query);
}

/// The region the functions live in: europe-west1, where the readers are.
const String kFunctionsRegion = 'europe-west1';

class FirestoreServedStore implements ServedStore {
  FirestoreServedStore([
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  ]) : _db = firestore ?? FirebaseFirestore.instance,
       _fn =
           functions ?? FirebaseFunctions.instanceFor(region: kFunctionsRegion);

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  @override
  Future<ServedDay?> day(String uid, String date) async {
    final snap = await _db
        .collection('readers')
        .doc(uid)
        .collection('days')
        .doc(date)
        .get();
    if (!snap.exists) return null;
    return ServedDay.parse(snap.data(), fromCache: snap.metadata.isFromCache);
  }

  @override
  Future<ServedDay?> askDay(String uid, String date, {required int tz}) async {
    final result = await _fn
        .httpsCallable(
          'dealDay',
          options: HttpsCallableOptions(timeout: Served.dealWait),
        )
        .call<Object?>({'date': date, 'tz': tz});
    return ServedDay.parse(result.data);
  }

  @override
  Future<ServedExplore?> explore(String uid) async {
    final results = await Future.wait([
      _db.collection('explore').doc('latest').get(),
      _db
          .collection('readers')
          .doc(uid)
          .collection('explore')
          .doc('current')
          .get(),
    ]);
    final global = results[0];
    if (!global.exists) return null;
    return ServedExplore.parse(
      global.data(),
      results[1].exists ? results[1].data() : null,
      fromCache: global.metadata.isFromCache,
    );
  }

  @override
  Future<List<Pill>> search(String query) async {
    final result = await _fn
        .httpsCallable(
          'search',
          options: HttpsCallableOptions(timeout: Served.dealWait),
        )
        .call<Object?>({'q': query});
    final Object? data = result.data;
    final Object? cards = data is Map ? data['cards'] : null;
    return [
      for (final c in (cards is List ? cards : const []))
        if (c is Map) cardFromJson(Map<String, Object?>.from(c)),
    ];
  }
}

/// Keeps what the server would serve in memory. Used by the tests.
class MemoryServedStore implements ServedStore {
  final Map<String, ServedDay> days = {};
  ServedExplore? shelves;
  List<Pill> hits = const [];
  bool refusing = false;
  int asked = 0;

  /// What [askDay] deals when asked, keyed by date; a date not here is refused.
  final Map<String, ServedDay> onAsk = {};

  @override
  Future<ServedDay?> day(String uid, String date) async {
    if (refusing) throw StateError('unavailable');
    return days['$uid:$date'];
  }

  @override
  Future<ServedDay?> askDay(String uid, String date, {required int tz}) async {
    asked += 1;
    if (refusing) throw StateError('unavailable');
    final ServedDay? dealt = onAsk[date];
    if (dealt != null) days['$uid:$date'] = dealt;
    return dealt;
  }

  @override
  Future<ServedExplore?> explore(String uid) async {
    if (refusing) throw StateError('unavailable');
    return shelves;
  }

  @override
  Future<List<Pill>> search(String query) async {
    if (refusing) throw StateError('unavailable');
    return hits;
  }
}
