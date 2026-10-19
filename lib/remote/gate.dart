/// The update gate: what the server says about the build this phone runs.
///
/// It is the `gate` of the remote document's `app` part, and it can say
/// three things, each read on its own so that one written wrong does not
/// take the others with it:
///
/// * **update** — `minBuild` (`{"ios": 7, "android": 7}`) and `blocked`
///   (`[5, 6]`, or the same per platform): a build below the one, or named
///   in the other, can no longer be used. A full screen asks the reader to
///   update and nothing of the app is under it.
/// * **suggest** — `suggestBuild` (`{"ios": 8}`): a newer build is out and
///   worth having. A sheet says so, once for each build suggested.
/// * **pause** — `{"on": true, "audience": {…}}`: the app is closed for a
///   while, for an emergency the app cannot ride out — a backend that is
///   down, a release that does damage — with a way to try again.
///
/// `message` holds the server's own words for each screen, by language
/// (`{"pause": {"it": "…", "en": "…"}}`), said in place of the build's line
/// under the title; the titles and buttons are the build's, and change, as
/// every string does, through the `strings` part.
///
/// It is decided from what the phone knows before anything else is read —
/// its platform, its build, its language and the document kept from the
/// last run — so it holds on a phone that is offline and on one whose
/// state never finished loading. A pause aimed by the plan or by the days
/// since the install waits for that state to be read (see [stateKnown] on
/// [UpdateGate.verdict]). docs/REMOTE.md has the whole of it.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'remote.dart';

/// What the gate does to the app.
enum GateKind {
  /// Nothing: the app as it is.
  open,

  /// This build can no longer be used: update it.
  update,

  /// The app is closed for a while: try again later.
  pause,
}

/// The gate's word for this phone now: what it does, and the server's own
/// words for it, if it sent some in the reader's language.
@immutable
class GateVerdict {
  const GateVerdict(this.kind, {this.message, this.reason});

  /// The gate is open: the app as it is.
  static const GateVerdict open = GateVerdict(GateKind.open);

  final GateKind kind;

  /// What the server wrote for this screen in the reader's language, said
  /// in place of the build's line; null for the build's own.
  final String? message;

  /// Why, for measurement: `min build` or `blocked` for an update, `pause`
  /// for a pause.
  final String? reason;

  /// Whether the app is closed behind it.
  bool get closes => kind != GateKind.open;

  @override
  bool operator ==(Object other) =>
      other is GateVerdict &&
      other.kind == kind &&
      other.message == message &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(kind, message, reason);
}

/// The gate, read from the document in use (Remote.config).
abstract final class UpdateGate {
  /// The highest build the sheet has already been shown for, kept so that
  /// a suggestion is made once — and made again when a newer build is.
  static const String _kSuggested = 'knowit.updateSuggested';

  static SharedPreferences? _prefs;
  static int _suggestedUpTo = 0;

  /// Reads what the phone keeps for the gate: the builds already suggested.
  /// From main(), with the document itself (Remote.restore).
  static void restore(SharedPreferences prefs) {
    _prefs = prefs;
    _suggestedUpTo = prefs.getInt(_kSuggested) ?? 0;
  }

  /// Forgets what [restore] read. Tests, and nothing else.
  @visibleForTesting
  static void resetForTest() {
    _prefs = null;
    _suggestedUpTo = 0;
  }

  /// The gate as the document in use writes it, or nothing.
  static Map<Object?, Object?> get _gate {
    final Object? raw = Remote.config.part('app')['gate'];
    return raw is Map ? raw : const {};
  }

  /// What the gate does for the phone [at] describes, now.
  ///
  /// An update first: it is the one thing the reader can do about either.
  /// A build the phone could not read (0) is never sent to update. A pause
  /// whose audience asks about the plan or the days since the install is
  /// decided only once those are known, with [stateKnown]: before then the
  /// app is not shown either — the splash is up — and a guess could close
  /// the app on a reader it was never aimed at.
  static GateVerdict verdict(RemoteContext at, {bool stateKnown = true}) {
    final Map<Object?, Object?> gate = _gate;
    final String? updating = _updateReason(gate, at);
    if (updating != null) {
      return GateVerdict(
        GateKind.update,
        message: message('hard', at.language),
        reason: updating,
      );
    }
    final Object? pause = gate['pause'];
    if (pause is Map && pause['on'] == true) {
      final Object? who = pause['audience'];
      if ((stateKnown || !_asksState(who)) &&
          Audience.allows(who, at, salt: 'gate.pause')) {
        return GateVerdict(
          GateKind.pause,
          message: message('pause', at.language),
          reason: 'pause',
        );
      }
    }
    return GateVerdict.open;
  }

  static String? _updateReason(Map<Object?, Object?> gate, RemoteContext at) {
    if (at.build < 1) return null;
    final int? min = _forPlatform(gate['minBuild'], at.platform);
    if (min != null && at.build < min) return 'min build';
    final Object? blocked = gate['blocked'];
    final Object? list = blocked is Map ? blocked[at.platform] : blocked;
    if (list is List && list.any((b) => _whole(b) == at.build)) {
      return 'blocked';
    }
    return null;
  }

  /// The newest build the server suggests for the phone [at] describes,
  /// when it is newer than the one it runs and the sheet has not been shown
  /// for it; null otherwise. Never while the gate closes the app.
  static int? suggestion(RemoteContext at) {
    if (at.build < 1 || verdict(at).closes) return null;
    final int? suggested = _forPlatform(_gate['suggestBuild'], at.platform);
    if (suggested == null || suggested <= at.build) return null;
    if (suggested <= _suggestedUpTo) return null;
    return suggested;
  }

  /// The sheet was shown for [build]: it is not shown again for it, or for
  /// any build before it.
  static Future<void> noteSuggested(int build) async {
    if (build <= _suggestedUpTo) return;
    _suggestedUpTo = build;
    try {
      await (_prefs ?? await SharedPreferences.getInstance()).setInt(
        _kSuggested,
        build,
      );
    } catch (_) {
      // Not remembering costs one more sheet, at the next launch at most.
    }
  }

  /// The server's own words for [screen] — `hard`, `soft` or `pause` — in
  /// [language], or null for the build's.
  static String? message(String screen, String language) {
    final Object? all = _gate['message'];
    if (all is! Map) return null;
    final Object? forScreen = all[screen];
    if (forScreen is! Map) return null;
    final Object? text = forScreen[language];
    return text is String && text.trim().isNotEmpty ? text.trim() : null;
  }

  /// A build number for [platform] from `{"ios": 7, "android": 7}`.
  static int? _forPlatform(Object? perPlatform, String platform) =>
      perPlatform is Map ? _whole(perPlatform[platform]) : null;

  static int? _whole(Object? value) {
    if (value is int) return value;
    if (value is double && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return null;
  }

  /// Whether [rule] asks about anything only the app's state can answer:
  /// the plan, or the days since the install.
  static bool _asksState(Object? rule) {
    if (rule is! Map) return false;
    for (final MapEntry<Object?, Object?> e in rule.entries) {
      switch (e.key) {
        case 'plus' || 'minDays' || 'maxDays':
          return true;
        case 'all' || 'any':
          final Object? rules = e.value;
          if (rules is List && rules.any(_asksState)) return true;
        case 'not':
          if (_asksState(e.value)) return true;
      }
    }
    return false;
  }
}
