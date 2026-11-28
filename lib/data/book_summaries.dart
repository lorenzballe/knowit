/// Books' summaries on the phone: where each comes from, and where the
/// reader is in it.
///
/// A summary travels the way a free card's page does (lib/data/
/// card_pages.dart): the bank names it with the hash of its bytes
/// (`"summaries": {"<book>": {"file": "summaries/<book>.json?v=<hash>"}}`,
/// tool/cards/bundle.py), and the phone fetches it from the site when the
/// book is opened and keeps it. The books that ship with the app have theirs
/// built in ([kEmbeddedSummaries]), so they open on a phone that has never
/// been online; a summary revised since the build is fetched, and the copy
/// built in is read while the network is away.
///
/// Where the reader is, in each, is kept between starts ([SummaryShelf]):
/// the part, how far into it, which parts are read, and whether the book
/// has been read to the end. Reading and listening keep the same place: a
/// part heard is a part read, and the reader opens where the voice stopped.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_summary.dart';
import 'card_page_store.dart';
import 'card_pages.dart' show CardPages, kCardsBase;
import 'embedded_summaries.dart';

/// What a fetch of a summary returns: the body on 200, null on anything
/// else. Replaceable, so tests never touch the network.
typedef SummaryFetcher = Future<String?> Function(Uri url);

/// The summaries in hand, and where to get the rest.
class BookSummaries {
  BookSummaries({
    SummaryFetcher? fetch,
    PageStore? store,
    Map<String, String>? builtIn,
  }) : fetch = fetch ?? _overHttp,
       store = store ?? summaryStoreOnThisPhone(),
       builtIn = builtIn ?? kEmbeddedSummaries;

  /// The app's summaries. Tests replace it.
  static BookSummaries instance = BookSummaries();

  /// How a summary is fetched from the site.
  SummaryFetcher fetch;

  /// Where the summaries fetched are kept between runs.
  final PageStore store;

  /// The summaries built into the app, by the name the bank gives each.
  final Map<String, String> builtIn;

  final Map<String, BookSummary> _held = {};
  final Map<String, Future<BookSummary>> _coming = {};
  final Map<String, DateTime> _failedAt = {};

  /// The summary [ref] names, at once, when it is built in or already in
  /// hand; null when it has to be fetched.
  BookSummary? inHand(SummaryRef ref) {
    final BookSummary? held = _held[ref.file];
    if (held != null) return held;
    final String? text = builtIn[ref.file];
    if (text == null) return null;
    try {
      return _held[ref.file] = BookSummary.parse(text);
    } on FormatException {
      return null;
    }
  }

  /// The summary [ref] names: the one in hand or built in, the one kept on
  /// the phone, or the site's. A summary that cannot be had is the copy
  /// built in for the same book, if there is one, older or not; otherwise
  /// this throws, and the reader says the book needs the network once.
  Future<BookSummary> of(SummaryRef ref) {
    final BookSummary? now = inHand(ref);
    if (now != null) return Future.value(now);
    return _coming[ref.file] ??= _load(ref).whenComplete(() {
      _coming.remove(ref.file);
    });
  }

  /// Starts fetching [ref]'s summary, so it is there by the time the reader
  /// opens it. Never throws; after a fetch that failed, waits a minute
  /// before trying again, however often a page that shows the book is
  /// rebuilt.
  void warm(SummaryRef ref) {
    if (inHand(ref) != null) return;
    final DateTime? failed = _failedAt[ref.file];
    if (failed != null &&
        DateTime.now().difference(failed) < const Duration(minutes: 1)) {
      return;
    }
    unawaited(
      of(ref).then<void>(
        (_) {},
        onError: (Object _) => _failedAt[ref.file] = DateTime.now(),
      ),
    );
  }

  /// Forgets what is held in memory. What is kept on the phone stays.
  @visibleForTesting
  void forget() => _held.clear();

  Future<BookSummary> _load(SummaryRef ref) async {
    try {
      final String? kept = await store.read(ref.file);
      if (kept != null) return _held[ref.file] = BookSummary.parse(kept);
    } catch (_) {}
    try {
      final String? body = await fetch(Uri.parse(kCardsBase).resolve(ref.file));
      if (body == null || body.trim().isEmpty) {
        throw StateError('the site has no ${ref.file}');
      }
      final BookSummary summary = BookSummary.parse(body);
      // Kept only when it is the one its name promises.
      if (CardPages.matches(ref.file, body)) {
        unawaited(store.write(ref.file, body).catchError((Object _) {}));
      }
      return _held[ref.file] = summary;
    } catch (error) {
      final BookSummary? older = _builtInOf(ref.book);
      if (older != null) return older;
      rethrow;
    }
  }

  /// The copy built in for [book], whatever its version.
  BookSummary? _builtInOf(String book) {
    for (final MapEntry<String, String> e in builtIn.entries) {
      if (Uri.parse(e.key).path == 'summaries/$book.json') {
        try {
          return BookSummary.parse(e.value);
        } on FormatException {
          return null;
        }
      }
    }
    return null;
  }

  static Future<String?> _overHttp(Uri url) async {
    final http.Response response = await http
        .get(url)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return null;
    return utf8.decode(response.bodyBytes);
  }
}

/// Where a reader is in a book's summary.
@immutable
class SummaryPlace {
  const SummaryPlace({
    this.part = 0,
    this.through = 0,
    this.read = const {},
    this.finished = false,
  });

  /// The part open, from 0.
  final int part;

  /// How far into it, from 0 to 1.
  final double through;

  /// The parts read, or heard, to their end.
  final Set<int> read;

  /// Whether the summary has been read to its end, once at least.
  final bool finished;

  /// Started, and not yet read to the end: the book's page offers to
  /// continue.
  bool get underway =>
      !finished && (part > 0 || through > 0.02 || read.isNotEmpty);

  SummaryPlace copyWith({
    int? part,
    double? through,
    Set<int>? read,
    bool? finished,
  }) => SummaryPlace(
    part: part ?? this.part,
    through: through ?? this.through,
    read: read ?? this.read,
    finished: finished ?? this.finished,
  );

  Map<String, Object?> toJson() => {
    'p': part,
    't': double.parse(through.toStringAsFixed(3)),
    'r': (read.toList()..sort()),
    if (finished) 'f': true,
  };

  static SummaryPlace? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? part = raw['p'], through = raw['t'], read = raw['r'];
    return SummaryPlace(
      part: part is int && part >= 0 ? part : 0,
      through: through is num ? through.toDouble().clamp(0.0, 1.0) : 0,
      read: {
        if (read is List)
          for (final Object? r in read)
            if (r is int) r,
      },
      finished: raw['f'] == true,
    );
  }
}

/// Where the reader is in every summary, kept on the phone between starts.
class SummaryShelf extends ChangeNotifier {
  static const String _kPlaces = 'knowit.summaries';

  SharedPreferences? _prefs;
  Map<String, SummaryPlace> _places = {};

  /// Where the reader is in [book]'s summary; null when it was never opened.
  SummaryPlace? placeOf(String book) => _places[book];

  /// Whether [book]'s summary has been read to the end.
  bool finished(String book) => _places[book]?.finished ?? false;

  /// Reads what the last run kept. Something unreadable is let go: a fresh
  /// start beats a stuck one.
  void restore(SharedPreferences prefs) {
    _prefs = prefs;
    _places = {};
    try {
      final String? raw = prefs.getString(_kPlaces);
      final Object? doc = raw == null ? null : jsonDecode(raw);
      if (doc is Map) {
        for (final MapEntry<Object?, Object?> e in doc.entries) {
          final SummaryPlace? place = SummaryPlace.fromJson(e.value);
          if (e.key is String && place != null) {
            _places[e.key as String] = place;
          }
        }
      }
    } catch (_) {
      _places = {};
    }
  }

  /// Keeps where the reader is in [book]. [notify] tells whoever shows it
  /// (a book's page): not on every line scrolled, only when a part changes.
  Future<void> keep(String book, SummaryPlace place, {bool notify = true}) {
    _places[book] = place;
    if (notify) _notifySoon();
    return _write();
  }

  bool _notifying = false;

  /// Tells whoever shows a place, once the frame in hand is built: a place
  /// is often kept while a page is being laid out (the reader opening, the
  /// reader closing), and a page told then would be told mid-build.
  void _notifySoon() {
    if (_notifying) return;
    _notifying = true;
    scheduleMicrotask(() {
      _notifying = false;
      notifyListeners();
    });
  }

  /// Marks part [part] of [book] read (or heard) to its end.
  Future<void> markRead(String book, int part) {
    final SummaryPlace place = _places[book] ?? const SummaryPlace();
    if (place.read.contains(part)) return Future.value();
    return keep(book, place.copyWith(read: {...place.read, part}));
  }

  /// Marks [book]'s summary read to the end. The next opening starts from
  /// its first part again.
  Future<void> finish(String book) {
    final SummaryPlace place = _places[book] ?? const SummaryPlace();
    _places[book] = place.copyWith(finished: true, part: 0, through: 0);
    _notifySoon();
    return _write();
  }

  /// Forgets every place: a sign-out, a reset.
  void forget() {
    _places = {};
    _notifySoon();
    unawaited(_prefs?.remove(_kPlaces));
  }

  Future<void> _write() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _kPlaces,
      jsonEncode({
        for (final MapEntry<String, SummaryPlace> e in _places.entries)
          e.key: e.value.toJson(),
      }),
    );
  }
}
