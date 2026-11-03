/// A free card's page, fetched when its card is about to be shown.
///
/// The bank every phone downloads names each page and leaves it out
/// (`"page": "pages/<id>.html?v=<hash>"`, tool/cards/bundle.py): a page is a
/// file of its own on the site, fetched the moment its card is near the top
/// of the deck and kept on the phone, the way a feed fetches a picture. So
/// the bank stays small however many pages there are, a new card's page is
/// on the phone the first time somebody meets the card, and a page met once
/// opens again without the network.
///
/// The name carries the hash of what is in the page, so a changed page is a
/// new name: nothing kept on a phone ever outlives the page it copied.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/pill.dart';
import 'card_page_store.dart';

/// Where the bank's files are published: a page's name is read from here.
const String kCardsBase = 'https://astutetheapp.com/cards/';

/// What a fetch of a page returns: the body on 200, null on anything else.
/// Replaceable, so tests never touch the network.
typedef PageFetcher = Future<String?> Function(Uri url);

/// The pages of the bank's free cards: the ones in hand, the ones on the
/// way, and where to get the rest.
class CardPages {
  CardPages({PageFetcher? fetch, PageStore? store})
    : fetch = fetch ?? _overHttp,
      store = store ?? pageStoreOnThisPhone();

  /// The app's pages. Tests replace it.
  static CardPages instance = CardPages();

  /// How a page is fetched from the site.
  PageFetcher fetch;

  /// Where the pages fetched are kept between runs.
  final PageStore store;

  /// How many cards ahead of the deck's two live pages are fetched before
  /// the reader reaches them.
  static const int ahead = 4;

  /// How many pages are held in memory, the most recently wanted first.
  static const int held = 16;

  final LinkedHashMap<String, String> _held = LinkedHashMap();
  final Map<String, Future<String>> _coming = {};

  /// The page of [face]: the one inside it, the one in memory, the one kept
  /// on the phone, or the site's. Throws when none can be had: a page never
  /// met, on a phone with no signal. The card is then drawn natively.
  Future<String> html(WebFace face) {
    final String? inline = face.html;
    if (inline != null) return Future.value(inline);
    final String ref = face.page!;
    final String? hit = _held.remove(ref);
    if (hit != null) {
      _held[ref] = hit;
      return Future.value(hit);
    }
    // The block, not an arrow: an arrow would return the removed future,
    // and whenComplete would wait for itself.
    return _coming[ref] ??= _load(ref).whenComplete(() {
      _coming.remove(ref);
    });
  }

  /// Whether the page of [face] is in hand, so its card can be drawn
  /// without waiting for anything.
  bool inHand(WebFace face) =>
      face.html != null || _held.containsKey(face.page);

  /// Starts fetching the pages of [cards], the next few a reader will meet,
  /// so each is on the phone before its card is on top. Never throws.
  void warm(Iterable<Pill> cards) {
    for (final Pill p in cards) {
      final WebFace? face = p.web;
      if (face == null || !p.hasPage || inHand(face)) continue;
      unawaited(html(face).then<void>((_) {}, onError: (Object _) {}));
    }
  }

  /// Forgets what is held in memory. The pages kept on the phone stay.
  @visibleForTesting
  void forget() => _held.clear();

  Future<String> _load(String ref) async {
    String? kept;
    try {
      kept = await store.read(ref);
    } catch (_) {}
    if (kept != null) {
      _hold(ref, kept);
      return kept;
    }
    final Stopwatch took = Stopwatch()..start();
    final String? body = await fetch(Uri.parse(kCardsBase).resolve(ref));
    if (body == null || body.trim().isEmpty) {
      throw StateError('the site has no page $ref');
    }
    _hold(ref, body);
    // A page is kept only when it is the one its name promises: a stale
    // copy from a cache on the way is shown this once and fetched again.
    if (matches(ref, body)) {
      unawaited(store.write(ref, body).catchError((Object _) {}));
    }
    debugPrint('Astute: fetched $ref in ${took.elapsedMilliseconds} ms');
    return body;
  }

  void _hold(String ref, String html) {
    _held.remove(ref);
    _held[ref] = html;
    while (_held.length > held) {
      _held.remove(_held.keys.first);
    }
  }

  /// Whether [html] is the page [ref] names: its hash begins with the `v`
  /// the name carries. A name without one names whatever is there.
  static bool matches(String ref, String html) {
    final String? v = Uri.parse(ref).queryParameters['v'];
    if (v == null || v.isEmpty) return true;
    return sha256.convert(utf8.encode(html)).toString().startsWith(v);
  }

  static Future<String?> _overHttp(Uri url) async {
    final http.Response response = await http
        .get(url)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    return utf8.decode(response.bodyBytes);
  }
}
