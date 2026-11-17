/// The news, reasoned: the paper the server made this morning
/// (functions/src/news.ts), a few of the day's stories, each explained in a
/// news card, for every reader.
///
/// Asked for at start and at every return to the app, at most every
/// [NewsPaper.every], and kept, so a phone offline still has the morning's
/// paper. The cards are bank cards in all but where they come from:
/// [PillBank.byId] finds them while the paper holds them, so a deck that was
/// dealt one opens it and its reading counts. A card past its expiry
/// ([NewsScene.expires]) is never shown.
library;

import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cloud.dart';
import '../models/pill.dart';
import '../sync/served.dart' show kFunctionsRegion;
import 'card_json.dart';
import 'pills_repository.dart' show dealableOn;

/// The newest paper as the server sends it: its day, and its cards in the
/// bank's own shape. Null when it could not be asked.
typedef NewsCall = Future<Map<String, Object?>?> Function();

abstract final class NewsPaper {
  static const _kKept = 'knowit.news.v1';

  /// How often the paper is asked for while the app runs.
  static const Duration every = Duration(hours: 2);

  static String? _date;
  static List<Pill> _cards = const [];
  static Map<String, Pill> _byId = const {};
  static DateTime? _asked;

  /// How the app asks: the callable function. Tests replace it.
  static NewsCall call = _callable;

  /// The paper's day, yyyy-mm-dd, or null when there is none yet.
  static String? get date => _date;

  /// The paper's cards that are still current on [day], in the paper's order.
  static List<Pill> on(DateTime day) => [
    for (final Pill p in _cards)
      if (dealableOn(p, day)) p,
  ];

  /// A card of the paper by id, current or not.
  static Pill? byId(String id) => _byId[id];

  /// Takes up a paper: the cards this build can read, each once. Returns
  /// whether anything changed.
  static bool adopt(String? date, List<Object?> raw) {
    final cards = <Pill>[];
    final seen = <String>{};
    for (final Object? c in raw) {
      if (c is! Map) continue;
      try {
        final Pill p = cardFromJson(Map<String, Object?>.from(c));
        if (seen.add(p.id)) cards.add(p);
      } catch (_) {
        // A card this build cannot read is left out, not the paper.
      }
    }
    final bool same =
        date == _date &&
        cards.length == _cards.length &&
        [for (final p in cards) p.id].join() ==
            [for (final p in _cards) p.id].join();
    _date = date;
    _cards = List.unmodifiable(cards);
    _byId = {for (final p in cards) p.id: p};
    return !same;
  }

  /// The paper the last run kept. Called once at start.
  static void restore(SharedPreferences prefs) {
    final String? kept = prefs.getString(_kKept);
    if (kept == null) return;
    try {
      final Object? doc = jsonDecode(kept);
      if (doc is Map && doc['cards'] is List) {
        adopt(doc['date'] as String?, doc['cards'] as List<Object?>);
      }
    } catch (_) {
      // A paper that cannot be read is no paper; the next ask brings one.
    }
  }

  /// Asks for the newest paper, at most every [every] unless [force]d, and
  /// keeps it. Returns whether the paper changed.
  static Future<bool> refresh(
    SharedPreferences prefs, {
    DateTime? now,
    bool force = false,
  }) async {
    final DateTime at = now ?? DateTime.now();
    final DateTime? asked = _asked;
    if (!force && asked != null && at.difference(asked) < every) return false;
    _asked = at;
    final Map<String, Object?>? doc = await call();
    final Object? cards = doc?['cards'];
    if (doc == null || cards is! List) return false;
    final Object? date = doc['date'];
    // Through JSON and back: what the platform channel hands over is maps
    // of anything, and a card is read from maps of strings, all the way in.
    final String text = jsonEncode({
      'date': date is String ? date : null,
      'cards': cards,
    });
    final Map<String, Object?> clean = jsonDecode(text) as Map<String, Object?>;
    final bool changed = adopt(
      clean['date'] as String?,
      clean['cards'] as List<Object?>,
    );
    if (changed) await prefs.setString(_kKept, text);
    return changed;
  }

  static Future<Map<String, Object?>?> _callable() async {
    if (!Cloud.ready) return null;
    try {
      final result =
          await FirebaseFunctions.instanceFor(region: kFunctionsRegion)
              .httpsCallable(
                'newsToday',
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 20),
                ),
              )
              .call<Object?>();
      final Object? data = result.data;
      return data is Map ? Map<String, Object?>.from(data) : null;
    } catch (_) {
      return null;
    }
  }

  /// No paper, and asked never. Tests, and nothing else.
  @visibleForTesting
  static void reset() {
    _date = null;
    _cards = const [];
    _byId = const {};
    _asked = null;
    call = _callable;
  }
}
