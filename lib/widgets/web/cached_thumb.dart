/// A card's picture fetched once and kept on the phone: the next time it is
/// wanted, on any screen and after the app is opened again, it comes from the
/// phone at once instead of the network.
///
/// The pictures are named with the hash of the page they were taken from
/// (`?v=`), so a card drawn again is a new picture, never a stale one.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;

import '../../data/pill_bank.dart';
import 'thumb_store.dart';

/// A card's picture from its full address, kept on the phone once fetched.
@immutable
class CachedThumb extends ImageProvider<CachedThumb> {
  const CachedThumb(this.url);

  final Uri url;

  /// Where the pictures are kept. Replaceable, so a test keeps them in
  /// memory.
  static ThumbStore store = thumbStoreOnThisPhone();

  /// Whether a picture just fetched may be kept on the phone. Replaceable,
  /// so a test decides.
  static bool Function() mayKeep = () => PillBank.siteHasBank;

  /// How the bytes are fetched. Replaceable, so a test never touches the
  /// network.
  static Future<Uint8List> Function(Uri url) download = _download;

  /// The fetches under way, by address: a picture asked for twice at once,
  /// by the shelf and by the warming before it, is fetched once.
  static final Map<Uri, Future<Uint8List>> _going = {};

  static Future<Uint8List> _download(Uri url) async {
    final http.Response r = await http
        .get(url)
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200 || r.bodyBytes.isEmpty) {
      throw NetworkImageLoadException(statusCode: r.statusCode, uri: url);
    }
    return r.bodyBytes;
  }

  /// The name a picture is kept under: its address without the site.
  static String nameOf(Uri url) =>
      url.query.isEmpty ? url.path : '${url.path}?${url.query}';

  /// The picture's bytes: from the phone when it is kept there, from the
  /// network otherwise, and then kept.
  static Future<Uint8List> bytesOf(Uri url) {
    final Future<Uint8List>? going = _going[url];
    if (going != null) return going;
    final Future<Uint8List> fetch = () async {
      final String name = nameOf(url);
      try {
        final Uint8List? kept = await store.read(name);
        if (kept != null && kept.isNotEmpty) return kept;
      } catch (_) {
        // Nowhere to keep it (a test, a phone out of room): fetched as before.
      }
      final Uint8List bytes = await download(url);
      // Kept only from a site that publishes the bank in use: from one
      // behind it, the bytes under a card's new name can be its old picture
      // (PillBank.siteHasBank). Shown now, asked for again next time.
      if (!mayKeep()) return bytes;
      try {
        await store.write(name, bytes);
      } catch (_) {}
      return bytes;
    }();
    _going[url] = fetch;
    return fetch.whenComplete(() => _going.remove(url));
  }

  /// Fetches the pictures at [urls] that the phone does not keep yet, a few
  /// at a time, quietly: for a screen that is about to show them, so they are
  /// there when it does. What cannot be had now is asked for again when shown.
  static Future<void> warm(Iterable<Uri> urls, {int atOnce = 3}) async {
    final List<Uri> todo = [];
    for (final Uri url in urls) {
      try {
        if (!await store.has(nameOf(url))) todo.add(url);
      } catch (_) {
        return;
      }
    }
    Future<void> worker() async {
      while (todo.isNotEmpty) {
        final Uri url = todo.removeAt(0);
        try {
          await bytesOf(url);
        } catch (_) {}
      }
    }

    await Future.wait([for (int i = 0; i < atOnce; i++) worker()]);
  }

  @override
  Future<CachedThumb> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<CachedThumb>(this);

  @override
  ImageStreamCompleter loadImage(
    CachedThumb key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(key, decode),
    scale: 1,
    debugLabel: key.url.toString(),
  );

  Future<ui.Codec> _load(CachedThumb key, ImageDecoderCallback decode) async {
    final Uint8List bytes = await bytesOf(key.url);
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      bytes,
    );
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) => other is CachedThumb && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'CachedThumb($url)';
}
