import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../cloud.dart';
import 'served.dart' show kFunctionsRegion;

/// How everybody played one of the day's games — Today's five, or a
/// subject's three — counted on the server (functions/src/daily.ts) and
/// nothing about who: how many played, how many came to each score, and
/// for each card how many got it right, which option each picked or, for a
/// share, where the guesses fell.
///
/// A phone sends its play once it is over; the server judges every answer
/// by the card's own test and adds it once, keeping a mark under the
/// reader's own record that only stops a play being counted twice. The
/// counts are a document every signed-in phone may read
/// (`daily/{key}`, firestore.rules) and none may write.
@immutable
class DailyCounts {
  const DailyCounts({
    required this.players,
    required this.scores,
    required this.items,
  });

  /// How many played.
  final int players;

  /// How many came to each score, in tens of points: [0] for nought to
  /// nine, up to the most the game scores.
  final List<int> scores;

  /// By card.
  final Map<String, DailyItemCounts> items;

  /// The counts as the server writes them; null when they are not counts.
  static DailyCounts? parse(Object? raw) {
    if (raw is! Map) return null;
    final Object? players = raw['players'];
    if (players is! num || players < 0) return null;
    final Map<String, DailyItemCounts> items = {};
    final Object? rawItems = raw['items'];
    if (rawItems is Map) {
      for (final MapEntry<Object?, Object?> e in rawItems.entries) {
        if (e.key is! String) continue;
        final DailyItemCounts? item = DailyItemCounts.parse(e.value);
        if (item != null) items[e.key as String] = item;
      }
    }
    return DailyCounts(
      players: players.round(),
      scores: _counts(raw['scores']),
      items: items,
    );
  }

  /// Where [score] stands: how many played, and the share of them, in whole
  /// per cent, who scored less — counted by tens, as the scores are kept.
  ({int players, int beaten}) place(int score) {
    final int bucket = score ~/ 10;
    int all = 0;
    int below = 0;
    for (int b = 0; b < scores.length; b++) {
      all += scores[b];
      if (b < bucket) below += scores[b];
    }
    return (players: all, beaten: all == 0 ? 0 : (100 * below / all).round());
  }
}

/// How everybody did on one card of a game.
@immutable
class DailyItemCounts {
  const DailyItemCounts({
    required this.n,
    required this.right,
    this.picks = const [],
    this.guesses = const [],
    this.sum = 0,
  });

  /// How many answered it.
  final int n;

  /// How many of them got it right, by the card's own test.
  final int right;

  /// On a pick: how many picked each option, in the card's order.
  final List<int> picks;

  /// On a share: how many guessed in each ten, 0–9% to 100%.
  final List<int> guesses;

  /// On a share: every guess added up, for the average.
  final double sum;

  /// The share who got it right, 0 to 1.
  double get rightShare => n == 0 ? 0 : (right / n).clamp(0, 1).toDouble();

  /// On a share, the average guess; null without guesses.
  double? get meanGuess =>
      n == 0 || guesses.isEmpty ? null : (sum / n).clamp(0, 100).toDouble();

  static DailyItemCounts? parse(Object? raw) {
    if (raw is! Map) return null;
    final Object? n = raw['n'], right = raw['right'], sum = raw['sum'];
    if (n is! num || right is! num || n < 0 || right < 0) return null;
    return DailyItemCounts(
      n: n.round(),
      right: right.round().clamp(0, n.round()),
      picks: _counts(raw['picks']),
      guesses: _counts(raw['guesses']),
      sum: sum is num && sum >= 0 ? sum.toDouble() : 0,
    );
  }
}

/// Counts by place — by score in tens, by option, by ten of the guess — as a
/// list in place order. The server keeps them as a map from the place,
/// `'0'` up, to how many, as only what is there can be added to; a list in
/// place order is read too.
List<int> _counts(Object? raw) {
  if (raw is List) {
    return [for (final Object? v in raw) v is num && v > 0 ? v.round() : 0];
  }
  if (raw is! Map) return const [];
  final Map<int, int> at = {};
  for (final MapEntry<Object?, Object?> e in raw.entries) {
    final int? place = int.tryParse('${e.key}');
    final Object? v = e.value;
    // No game scores past a few hundred: a place past that is no count.
    if (place == null || place < 0 || place > 100 || v is! num || v <= 0) {
      continue;
    }
    at[place] = v.round();
  }
  if (at.isEmpty) return const [];
  final int last = at.keys.reduce((a, b) => a > b ? a : b);
  return [for (int i = 0; i <= last; i++) at[i] ?? 0];
}

/// One play as it is sent: the day, the game, and every card with what was
/// said on it, in the order played, in the form the card keeps an answer.
@immutable
class DailyPlay {
  const DailyPlay({
    required this.day,
    required this.game,
    required this.said,
    required this.tz,
  });

  /// `yyyy-mm-dd` on the phone's calendar.
  final String day;

  /// `five` or `three`.
  final String game;

  /// Card id and what was said, in the order played.
  final List<(String, String)> said;

  /// The phone's offset from UTC, in minutes: what tells the server that
  /// [day] is today somewhere.
  final int tz;

  Map<String, Object?> toJson() => {
    'date': day,
    'game': game,
    'cards': [
      for (final (String id, String s) in said) {'id': id, 'said': s},
    ],
    'tz': tz,
  };
}

/// Where the day's games are counted.
abstract class DailyStore {
  /// Counts [play] once; the game's counts after it. A play counted
  /// already is not counted again, and the counts come back all the same.
  Future<DailyCounts?> play(DailyPlay play);

  /// The counts kept under [key] (DailyGame.keyFor), as they change: other
  /// readers' plays come in while the result is on screen. Null while
  /// nobody has played.
  Stream<DailyCounts?> watch(String key);
}

/// The server's: the play sent to `playDaily`, the counts read from
/// `daily/{key}`.
class FirebaseDailyStore implements DailyStore {
  FirebaseDailyStore([FirebaseFirestore? firestore, FirebaseFunctions? fn])
    : _db = firestore ?? FirebaseFirestore.instance,
      _fn = fn ?? FirebaseFunctions.instanceFor(region: kFunctionsRegion);

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  /// How long a play may take to be counted: a cold function and one
  /// transaction. Nothing waits on it but the line about the crowd.
  static const Duration wait = Duration(seconds: 10);

  @override
  Future<DailyCounts?> play(DailyPlay play) async {
    final HttpsCallableResult<Object?> result = await _fn
        .httpsCallable(
          'playDaily',
          options: HttpsCallableOptions(timeout: wait),
        )
        .call<Object?>(play.toJson());
    final Object? data = result.data;
    return DailyCounts.parse(data is Map ? data['counts'] : null);
  }

  @override
  Stream<DailyCounts?> watch(String key) => _db
      .collection('daily')
      .doc(key)
      .snapshots()
      .map((s) => s.exists ? DailyCounts.parse(s.data()) : null);
}

/// Counts kept in memory, judged as the server judges them: for tests, and
/// the camera that photographs the app without a project.
class MemoryDailyStore implements DailyStore {
  MemoryDailyStore({
    Map<String, DailyCounts>? counts,
    this.judge,
    this.max = const {'five': 500, 'three': 300},
  }) : _counts = counts ?? {};

  final Map<String, DailyCounts> _counts;
  final Map<String, StreamController<DailyCounts?>> _out = {};

  /// How a card's answer is judged, as the server would: right or not, the
  /// points, and on a share the guess. Without it, every play is only
  /// noted and nothing is added.
  final ({bool right, int points, int? pick, double? guess}) Function(
    String id,
    String said,
  )?
  judge;

  /// The most each game scores.
  final Map<String, int> max;

  /// What was sent, for a test to read.
  final List<DailyPlay> sent = [];

  /// Whether the next plays fail, as a server that cannot be reached does.
  bool failing = false;

  /// The game's key for [play]: the server's, from the day, the game and
  /// the cards.
  static String keyOf(DailyPlay play) =>
      '${play.day}~${play.game}~'
      '${([for (final (String id, _) in play.said) id]..sort()).join(',')}';

  @override
  Future<DailyCounts?> play(DailyPlay play) async {
    if (failing) throw StateError('unavailable');
    sent.add(play);
    final String key = keyOf(play);
    final ({bool right, int points, int? pick, double? guess}) Function(
      String,
      String,
    )?
    judged = judge;
    if (judged == null) return _counts[key];
    final DailyCounts before =
        _counts[key] ??
        DailyCounts(
          players: 0,
          scores: List.filled((max[play.game] ?? 500) ~/ 10 + 1, 0),
          items: const {},
        );
    int total = 0;
    final Map<String, DailyItemCounts> items = {...before.items};
    for (final (String id, String said) in play.said) {
      final j = judged(id, said);
      total += j.points;
      final DailyItemCounts had =
          items[id] ?? const DailyItemCounts(n: 0, right: 0);
      List<int> plus(List<int> list, int? at, int length) {
        final List<int> out = [...list];
        while (out.length < length) {
          out.add(0);
        }
        if (at != null && at >= 0 && at < out.length) out[at]++;
        return out;
      }

      items[id] = DailyItemCounts(
        n: had.n + 1,
        right: had.right + (j.right ? 1 : 0),
        picks: j.pick == null
            ? had.picks
            : plus(had.picks, j.pick, j.pick! + 1),
        guesses: j.guess == null
            ? had.guesses
            : plus(had.guesses, (j.guess! / 10).floor().clamp(0, 10), 11),
        sum: had.sum + (j.guess ?? 0),
      );
    }
    final List<int> scores = [...before.scores];
    final int bucket = (total ~/ 10).clamp(0, scores.length - 1);
    scores[bucket]++;
    final DailyCounts after = DailyCounts(
      players: before.players + 1,
      scores: scores,
      items: items,
    );
    _counts[key] = after;
    _out[key]?.add(after);
    return after;
  }

  /// Adds somebody else's counts to [key], as other readers' plays come in.
  void put(String key, DailyCounts counts) {
    _counts[key] = counts;
    _out[key]?.add(counts);
  }

  @override
  Stream<DailyCounts?> watch(String key) {
    final StreamController<DailyCounts?> c = _out.putIfAbsent(
      key,
      StreamController<DailyCounts?>.broadcast,
    );
    return Stream<DailyCounts?>.multi((sink) {
      sink.add(_counts[key]);
      final StreamSubscription<DailyCounts?> s = c.stream.listen(sink.add);
      sink.onCancel = s.cancel;
    });
  }
}

/// Where the day's games are counted: the server's when the phone is
/// signed in to it, otherwise nowhere, and the result says so.
class DailyCrowd {
  DailyCrowd._();

  static DailyStore? _override;
  static bool _overridden = false;

  /// A store in place of the server's, for tests and the camera; null for
  /// none at all. [on] false goes back to the server's.
  @visibleForTesting
  static void useForTest(DailyStore? store, {bool on = true}) {
    _override = store;
    _overridden = on;
    _counted.clear();
    _tried.clear();
    _sending.clear();
  }

  /// Told whenever a play has been sent and has come back, counted or not.
  static Listenable get revision => _revision;
  static final _Told _revision = _Told();

  /// The games whose play is on its way.
  static final Set<String> _sending = {};

  /// Whether [key]'s play is on its way to be counted.
  static bool isSending(String key) => _sending.contains(key);

  /// The store, or null when there is none to count in.
  static DailyStore? get store {
    if (_overridden) return _override;
    if (!Cloud.ready) return null;
    if (FirebaseAuth.instance.currentUser == null) return null;
    return FirebaseDailyStore();
  }

  /// The counts each play came back with, by game key: what the result
  /// shows at once, and still shows if the document cannot be read.
  static final Map<String, DailyCounts> _counted = {};

  /// The games a play was sent for in this run, so one the server could not
  /// take is tried again once a run, not at every redraw.
  static final Set<String> _tried = {};

  /// The counts [key]'s play came back with, if it did in this run.
  static DailyCounts? countedWith(String key) => _counted[key];

  /// Sends [play] to be counted, once a run for [key]; [onCounted] is told
  /// when it was. Never throws: a play not counted is a line on the result,
  /// not an error.
  static Future<void> send(
    String key,
    DailyPlay play, {
    VoidCallback? onCounted,
    void Function(Object error)? onError,
  }) async {
    final DailyStore? s = store;
    if (s == null || !_tried.add(key)) return;
    _sending.add(key);
    _revision.tell();
    try {
      final DailyCounts? counts = await s.play(play);
      if (counts != null) _counted[key] = counts;
      onCounted?.call();
    } catch (error) {
      onError?.call(error);
    } finally {
      _sending.remove(key);
      _revision.tell();
    }
  }
}

/// A listenable that is told from outside.
class _Told extends ChangeNotifier {
  void tell() => notifyListeners();
}
