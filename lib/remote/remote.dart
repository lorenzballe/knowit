/// What the server says about the app: which Explore, which looks, which
/// words, which switches — everything that can change without a release.
///
/// It travels the bank's road (lib/data/pill_bank.dart). The sources are
/// JSON in the repository, under `remote/`; `tool/remote/bundle.py` checks
/// them and bundles them into one document, written twice from the same
/// bytes: baked into the build as `embedded_config.dart`, so a phone that
/// has never been online has exactly the app the build shipped with, and
/// published with the site as `web/remote/config.json`. A phone asks the
/// small note beside it first (`version.json`), and downloads the document
/// only when the note names one it does not hold.
///
/// Unlike the bank, a newer document is taken up the moment it arrives — at
/// a launch, and at every return to the app — and [revision] says so, so
/// whatever it changes redraws then. The bank waits for the next start
/// because a deck on the table must not be re-dealt; nothing here deals.
///
/// The document is in parts, each read by its own code and none by this
/// file, which only fetches, keeps and hands them out:
///
/// * `app` — the update gate, the switches, the numbers the app tunes by;
/// * `strings` — words that replace the build's own, by language;
/// * `explore` — the shelves of Explore, their order, their sizes;
/// * `looks` — how cards look, and which look goes on which card.
///
/// A part an older build does not know is left alone, and a part it cannot
/// read is its own code's to refuse, item by item: one bad shelf must not
/// take the rest of the document with it. See docs/REMOTE.md.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics.dart';
import 'embedded_config.dart';

/// Where the newest document is published, beside the bank, behind the
/// site's CDN: no server and no key, and a phone that is offline keeps the
/// one it has.
const String kRemoteUrl = 'https://astutetheapp.com/remote/config.json';

/// The published document's hash and nothing else — a few dozen bytes,
/// asked first, so an app that is up to date spends a request, not the
/// whole document, finding that out.
const String kRemoteVersionUrl = 'https://astutetheapp.com/remote/version.json';

/// The document's layout this build reads. A document of a later schema is
/// left for the builds that read it: this one keeps what it has.
const int kRemoteSchema = 1;

/// What a fetch returns: the body on 200, null on anything else.
/// Replaceable, so tests never touch the network.
typedef RemoteFetcher = Future<String?> Function(String url);

/// One document: its parts, as JSON, and the hash that names it.
@immutable
class RemoteConfig {
  final String hash;
  final int schema;
  final Map<String, Object?> parts;

  const RemoteConfig({
    required this.hash,
    required this.schema,
    required this.parts,
  });

  /// A part of the document, as it came: a map, a list, or null when the
  /// document has no such part. Whoever reads a part reads it defensively.
  Object? operator [](String part) => parts[part];

  /// A part that is a JSON object, or an empty one.
  Map<String, Object?> part(String name) {
    final Object? raw = parts[name];
    return raw is Map<String, Object?> ? raw : const {};
  }

  /// Reads a document. Throws [FormatException] on one this build cannot
  /// take up whole: not an object, no hash, a later schema. What is inside
  /// each part is not looked at here.
  factory RemoteConfig.parse(String text) {
    final Object? doc = jsonDecode(text);
    if (doc is! Map<String, Object?>) {
      throw const FormatException('a remote document is an object');
    }
    final Object? hash = doc['hash'];
    if (hash is! String || hash.isEmpty) {
      throw const FormatException('a remote document has a hash');
    }
    final Object? schema = doc['schema'];
    if (schema is! int) {
      throw const FormatException('a remote document has a schema');
    }
    if (schema > kRemoteSchema) {
      throw FormatException('schema $schema is later than this build reads');
    }
    return RemoteConfig(
      hash: hash,
      schema: schema,
      parts: {
        for (final MapEntry<String, Object?> e in doc.entries)
          if (e.key != 'hash' && e.key != 'schema') e.key: e.value,
      },
    );
  }
}

/// Who is looking, as far as a part's audience asks: what the rules in
/// [Audience] are measured against.
@immutable
class RemoteContext {
  /// `ios`, `android`, `web`, or `other`.
  final String platform;

  /// The build number the app was released as (the `+n` of its version).
  final int build;

  /// The language the app is shown in: `en`, `it`, …
  final String language;

  /// Whether the reader is on Astute+.
  final bool plus;

  /// Whole days since the app was first opened on this phone.
  final int daysSinceInstall;

  /// The phone's own clock, now.
  final DateTime now;

  const RemoteContext({
    required this.platform,
    required this.build,
    required this.language,
    required this.plus,
    required this.daysSinceInstall,
    required this.now,
  });
}

/// The document in use, and how it is kept current.
class Remote {
  const Remote._();

  static const String _kStored = 'knowit.remote';
  static const String _kSeed = 'knowit.remoteSeed';

  /// The document the app shipped with, parsed once: the floor the app can
  /// never fall below.
  static final RemoteConfig embedded = RemoteConfig.parse(kEmbeddedRemote);

  static RemoteConfig? _current;

  /// The document a test starts from in place of [embedded]: the build's
  /// own, with nothing the server has said in it. The document changes
  /// without a release, and the deploy runs the tests before it publishes
  /// one, so no test may rest on what it says today. Null in the app.
  @visibleForTesting
  static RemoteConfig? baseline;

  /// The document in use.
  static RemoteConfig get config => _current ??= baseline ?? embedded;

  /// Moves on whenever a different document is taken up. Whatever draws
  /// from a part listens here and redraws.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// The build number the app runs as, set once at start by whoever can
  /// read it (the platform's own record of the release). 0 until then, so a
  /// rule asking for a build at least something is false rather than true
  /// by accident.
  static int build = 0;

  /// This phone's platform, for [RemoteContext.platform].
  static String get platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'other',
    };
  }

  static String _seed = '';

  /// The phone's own random seed, kept: what a rollout or an experiment
  /// splits readers by, so the same phone lands on the same side every
  /// time, and two switches split independently.
  static String get seed => _seed;

  /// Makes [config] the document in use, and says so when it is a
  /// different one.
  static void adopt(RemoteConfig config) {
    final bool changed = config.hash != Remote.config.hash;
    _current = config;
    if (changed) revision.value += 1;
  }

  /// Back to the document the app shipped with. Tests, and nothing else.
  @visibleForTesting
  static void reset() {
    _current = baseline ?? embedded;
    _lastAsked = null;
    // A test that wants an answer says what it is; nothing asks the network.
    fetch = (url) async => null;
  }

  /// For the tests: the seed a rollout splits by.
  @visibleForTesting
  static set seedForTest(String seed) => _seed = seed;

  /// Takes up the document the last run downloaded, and the phone's seed,
  /// before anything reads a part. Cheap when nothing is stored.
  static void restore(SharedPreferences prefs) {
    String? seed = prefs.getString(_kSeed);
    if (seed == null || seed.isEmpty) {
      final math.Random random = math.Random.secure();
      seed = List<String>.generate(
        16,
        (_) => random.nextInt(16).toRadixString(16),
      ).join();
      prefs.setString(_kSeed, seed);
    }
    _seed = seed;
    final String? stored = prefs.getString(_kStored);
    if (stored == null) return;
    try {
      adopt(RemoteConfig.parse(stored));
    } on FormatException {
      // A stored document this build can no longer read is worth less than
      // the one it shipped with. Forget it; the next fetch replaces it.
      prefs.remove(_kStored);
    }
  }

  /// How a document is fetched. Tests replace it; the default goes over
  /// HTTP.
  static RemoteFetcher fetch = _fetchOverHttp;

  /// The least time between two asks: a return to the app a few seconds
  /// after the last is not a reason to ask again.
  static const Duration kAskEvery = Duration(seconds: 30);

  static DateTime? _lastAsked;
  static Future<bool>? _asking;

  /// Asks for the newest document — the note first ([kRemoteVersionUrl]) —
  /// and, when it is a different one, keeps it and takes it up. Returns
  /// whether it did. Never throws: a phone with no signal is the normal
  /// case, not an error.
  static Future<bool> refresh(SharedPreferences prefs, {bool force = false}) {
    final DateTime now = DateTime.now();
    final DateTime? last = _lastAsked;
    if (!force && last != null && now.difference(last) < kAskEvery) {
      return Future<bool>.value(false);
    }
    return _asking ??= _refresh(prefs).whenComplete(() {
      _asking = null;
      _lastAsked = DateTime.now();
    });
  }

  static Future<bool> _refresh(SharedPreferences prefs) async {
    final Stopwatch took = Stopwatch()..start();
    void say(String outcome, [RemoteConfig? got]) =>
        Analytics.capture('remote refreshed', {
          'outcome': outcome,
          'ms': took.elapsedMilliseconds,
          'hash_in_use': config.hash,
          'hash_fetched': got?.hash,
        });
    try {
      String? latest;
      try {
        final String? note = await fetch(kRemoteVersionUrl);
        final Object? parsed = note == null ? null : jsonDecode(note);
        if (parsed is Map && parsed['hash'] is String) {
          latest = parsed['hash'] as String;
        }
      } catch (_) {}
      if (latest != null && latest == config.hash) {
        say('up to date');
        return false;
      }
      final String? body = await fetch(kRemoteUrl);
      if (body == null) {
        say('no answer');
        return false;
      }
      final RemoteConfig got = RemoteConfig.parse(body);
      if (got.hash == config.hash) {
        say('up to date', got);
        return false;
      }
      await prefs.setString(_kStored, body);
      adopt(got);
      say('newer', got);
      return true;
    } catch (error) {
      debugPrint('Astute: the remote document did not refresh: $error');
      say('failed');
      return false;
    }
  }

  static Future<String?> _fetchOverHttp(String url) async {
    final http.Response response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    return utf8.decode(response.bodyBytes);
  }

  /// Where this phone falls, 0 to 9999, for whatever [salt] names — a
  /// switch, an experiment — so the same phone always falls in the same
  /// place for it, and two salts split readers independently.
  static int bucketOf(String salt) {
    // FNV-1a, 32 bits: stable across runs and platforms, unlike hashCode.
    int h = 0x811c9dc5;
    for (final int unit in utf8.encode('$_seed:$salt')) {
      h ^= unit;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h % 10000;
  }
}

/// Who a thing in the document is for, and when: the one rule every part
/// shares, so a shelf, a look and a switch are aimed the same way.
///
/// A rule is a JSON object, and every key in it must hold:
///
/// * `platforms`: `["ios", "android", "web"]`
/// * `minBuild`, `maxBuild`: the build number, inclusive
/// * `languages`: `["it", "en"]`
/// * `plus`: true for Astute+ only, false for the free plan only
/// * `minDays`, `maxDays`: days since the install, inclusive
/// * `from`, `until`: date keys, `2026-10-20`, inclusive, on the phone's
///   calendar
/// * `weekdays`: `[1, 7]`, Monday is 1
/// * `hours`: `[18, 23]`, from the first hour up to, not including, the
///   second; `[22, 3]` runs across midnight
/// * `rollout`: a share of phones, 0 to 100, split by `salt` (or by the
///   thing's own name, passed as [salt])
/// * `all`, `any`: lists of rules; `not`: one rule
///
/// A key this build does not know makes the rule false: a document written
/// for a later build, asking something this one cannot answer, is kept
/// from it rather than shown to everybody. No rule at all is everybody.
abstract final class Audience {
  static bool allows(Object? rule, RemoteContext at, {String salt = ''}) {
    if (rule == null) return true;
    if (rule is! Map) return false;
    for (final MapEntry<Object?, Object?> e in rule.entries) {
      if (!_holds('${e.key}', e.value, rule, at, salt)) return false;
    }
    return true;
  }

  static bool _holds(
    String key,
    Object? value,
    Map<Object?, Object?> rule,
    RemoteContext at,
    String salt,
  ) {
    switch (key) {
      case 'platforms':
        return value is List && value.contains(at.platform);
      case 'minBuild':
        return value is num && at.build >= value;
      case 'maxBuild':
        return value is num && at.build <= value;
      case 'languages':
        return value is List && value.contains(at.language);
      case 'plus':
        return value is bool && at.plus == value;
      case 'minDays':
        return value is num && at.daysSinceInstall >= value;
      case 'maxDays':
        return value is num && at.daysSinceInstall <= value;
      case 'from':
        final String? day = _day(value);
        return day != null && _key(at.now).compareTo(day) >= 0;
      case 'until':
        final String? day = _day(value);
        return day != null && _key(at.now).compareTo(day) <= 0;
      case 'weekdays':
        return value is List && value.contains(at.now.weekday);
      case 'hours':
        if (value is! List || value.length != 2) return false;
        final Object? a = value[0], b = value[1];
        if (a is! num || b is! num) return false;
        final int h = at.now.hour;
        return a <= b ? h >= a && h < b : h >= a || h < b;
      case 'rollout':
        if (value is! num) return false;
        final Object? own = rule['salt'];
        final String by = own is String ? own : salt;
        return Remote.bucketOf(by) < value * 100;
      case 'salt':
        return value is String;
      case 'all':
        return value is List && value.every((r) => allows(r, at, salt: salt));
      case 'any':
        return value is List && value.any((r) => allows(r, at, salt: salt));
      case 'not':
        return value is Map && !allows(value, at, salt: salt);
      default:
        return false;
    }
  }

  static String? _day(Object? value) =>
      value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)
      ? value
      : null;

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Which of [variants] this phone is given for the experiment [name], by
  /// their [weights] (equal when none are given): the same phone, the same
  /// variant, every time.
  static String variantOf(
    String name,
    List<String> variants, [
    List<num>? weights,
  ]) {
    if (variants.isEmpty) return '';
    final List<num> w = weights != null && weights.length == variants.length
        ? weights
        : List<num>.filled(variants.length, 1);
    final num total = w.fold<num>(0, (a, b) => a + (b > 0 ? b : 0));
    if (total <= 0) return variants.first;
    final double at = Remote.bucketOf('experiment:$name') / 10000 * total;
    num run = 0;
    for (int i = 0; i < variants.length; i++) {
      run += w[i] > 0 ? w[i] : 0;
      if (at < run) return variants[i];
    }
    return variants.last;
  }
}
