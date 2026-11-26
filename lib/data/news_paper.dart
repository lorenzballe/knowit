/// The news, reasoned: the paper the server made this morning
/// (functions/src/news.ts), the world's most important stories and a few
/// for the subjects, each a story page and a news card, for every reader.
///
/// Asked for at start and at every return to the app, at most every
/// [NewsPaper.every], and kept, so a phone offline still has the morning's
/// paper. The cards are bank cards in all but where they come from:
/// [PillBank.byId] finds them while the paper holds them, so a deck that was
/// dealt one opens it and its reading counts. A card past its expiry
/// ([NewsScene.expires]) is never dealt.
///
/// Explore shows the newest paper's front page for every subject
/// ([NewsPaper.front]) and, on a subject's page, the subject's own stories
/// of the week ([NewsPaper.ofSubject]); no story, no section.
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
  static Set<String> _world = const {};
  static DateTime? _asked;

  /// How the app asks: the callable function. Tests replace it.
  static NewsCall call = _callable;

  /// What time it is, for how old a story is and which paper is today's.
  /// Tests and the camera set it.
  static DateTime Function() clock = DateTime.now;

  /// Where the paper files a story no subject fits (functions/src/news.ts,
  /// WORLD): politics, diplomacy, a conflict, a disaster. The front page has
  /// it, no subject's page does. A build before it leaves such a card out.
  static const String worldDesk = 'world';

  /// The topic a story of the world desk is read under, since a card needs
  /// one: Thinking, the app's own voice, which is no subject. It is never
  /// shown as the story's subject ([isWorld]).
  static const String _standIn = 'thinking';

  /// Whether [p] is a story of no subject: the world desk's.
  static bool isWorld(Pill p) => _world.contains(p.id);

  /// Stories on the front page, at most (FRONT in functions/src/news.ts).
  static const int frontSize = 5;

  /// How old the newest paper may be for Explore to show it as the latest
  /// news: today's, or yesterday's while today's is not out.
  static const int frontDays = 2;

  /// The paper's day, yyyy-mm-dd, or null when there is none yet.
  static String? get date => _date;

  /// The paper's cards that are still current on [day], in the paper's order.
  static List<Pill> on(DateTime day) => [
    for (final Pill p in _cards)
      if (dealableOn(p, day)) p,
  ];

  /// How far back a subject's latest news reaches: the stories of the week,
  /// not only the morning's (NEWS_LATEST_DAYS in functions/src/news.ts). A
  /// story still told there may be past the days it is dealt in a reader's
  /// five.
  static const int latestDays = 7;

  /// Explore's latest news for every subject: the newest paper's front
  /// page, its world stories in the paper's order, [limit] at most. A paper
  /// made before there was a front page gives its stories in its order.
  /// Nothing when the newest paper is older than [frontDays]: last week's
  /// news is no front page.
  static List<Pill> front({int limit = frontSize}) {
    final DateTime? newest = _newestPaper();
    if (newest == null || _daysBefore(newest) >= frontDays) return const [];
    final List<Pill> day = _ranked([
      for (final Pill p in _cards)
        if (_paperOf(p) == newest) p,
    ]);
    final List<Pill> world = [
      for (final Pill p in day)
        if ((p.scene as NewsScene).world) p,
    ];
    return (world.isEmpty ? day : world).take(limit).toList();
  }

  /// A subject's latest news: its own stories of the week, the newest
  /// paper first and each paper's in its order, [limit] at most. The world
  /// desk's are on no subject's page.
  static List<Pill> ofSubject(String subject, {int limit = 4}) {
    final List<Pill> out = [
      for (final Pill p in _cards)
        if (p.topic == subject && !isWorld(p))
          if (_paperOf(p) case final DateTime d
              when _daysBefore(d) < latestDays)
            p,
    ];
    out.sort((a, b) {
      final int byDay = _paperOf(b)!.compareTo(_paperOf(a)!);
      return byDay != 0 ? byDay : _rankOf(a).compareTo(_rankOf(b));
    });
    return out.take(limit).toList();
  }

  /// The day of the paper [p] came in, or null for a card that is no news.
  static DateTime? _paperOf(Pill p) {
    final scene = p.scene;
    return scene is NewsScene ? scene.date : null;
  }

  static DateTime? _newestPaper() {
    DateTime? newest;
    for (final Pill p in _cards) {
      final DateTime? d = _paperOf(p);
      if (d != null && (newest == null || d.isAfter(newest))) newest = d;
    }
    return newest;
  }

  /// Whole days from [day] to the clock's today.
  static int _daysBefore(DateTime day) {
    final DateTime now = clock();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(day.year, day.month, day.day)).inDays;
  }

  /// Where [p] stands in its paper: its rank, or its place when unranked.
  static int _rankOf(Pill p) {
    final int rank = (p.scene as NewsScene).rank;
    return rank > 0 ? rank : 1000 + _cards.indexOf(p);
  }

  static List<Pill> _ranked(List<Pill> cards) =>
      [...cards]..sort((a, b) => _rankOf(a).compareTo(_rankOf(b)));

  /// A card of the paper by id, current or not.
  static Pill? byId(String id) => _byId[id];

  /// Takes up a paper: the cards this build can read, each once; a story of
  /// the world desk under a stand-in topic. Returns whether anything changed.
  static bool adopt(String? date, List<Object?> raw) {
    final cards = <Pill>[];
    final seen = <String>{};
    final world = <String>{};
    for (final Object? c in raw) {
      if (c is! Map) continue;
      try {
        final Map<String, Object?> card = Map<String, Object?>.from(c);
        final bool desk = card['topic'] == worldDesk;
        if (desk) card['topic'] = _standIn;
        final Pill p = cardFromJson(card);
        if (seen.add(p.id)) {
          cards.add(p);
          if (desk) world.add(p.id);
        }
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
    _world = world;
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
    _world = const {};
    _asked = null;
    call = _callable;
    clock = DateTime.now;
  }
}
