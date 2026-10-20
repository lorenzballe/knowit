/// What a reader did on the whole-screen blocks that has to outlast the
/// visit, and that the app keeps nowhere else: the expert and the subject
/// they last picked, how deep a chain of whys is open, where they stood on
/// a claim before and after reading it, the lines they said and when, and
/// the questions they typed with the card that answered each.
///
/// It is kept on the phone, under `knowit.explore.screens.*`, and nowhere
/// else: the questions above all, since what a reader types is theirs (the
/// search is said only by its shape, docs/TRACKING.md). Everything is read
/// through the phone's own store every time rather than copied out of it,
/// so a sign-out, which clears that store, clears this with it at once.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where a reader stood on a claim: a place on the scale from 0 (strongly
/// disagree) to 4 (strongly agree), before reading and after.
@immutable
class Stance {
  const Stance({this.before, this.after});

  final int? before;
  final int? after;

  /// The places on the scale.
  static const int places = 5;
}

/// A question the reader typed, and the card that answered it, if one has.
@immutable
class AskedQuestion {
  const AskedQuestion({required this.question, this.cardId, this.on});

  final String question;

  /// The card opened from the question's answers; null for a question kept
  /// because no card answered it yet.
  final String? cardId;

  /// The day it was asked, as a date key.
  final String? on;

  Map<String, Object?> toJson() => {
    'q': question,
    if (cardId != null) 'c': cardId,
    if (on != null) 'd': on,
  };

  static AskedQuestion? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? q = raw['q'];
    if (q is! String || q.trim().isEmpty) return null;
    final Object? c = raw['c'];
    final Object? d = raw['d'];
    return AskedQuestion(
      question: q,
      cardId: c is String && c.isNotEmpty ? c : null,
      on: d is String ? d : null,
    );
  }
}

/// The store. One for the app; a test starts a fresh one.
class ScreensMemory extends ChangeNotifier {
  ScreensMemory._();

  static ScreensMemory _instance = ScreensMemory._();

  /// The store in use.
  static ScreensMemory get instance => _instance;

  /// A fresh store for a test, over whatever the test put in the phone's.
  @visibleForTesting
  static void resetForTest() => _instance = ScreensMemory._();

  /// What every key of this store begins with.
  static const String prefix = 'knowit.explore.screens.';

  /// The most questions kept: the newest, as a list a reader can still
  /// read down, not a log.
  static const int keepQuestions = 30;

  SharedPreferences? _prefs;
  Future<void>? _opening;

  /// What was written before the phone's store was open, kept to be
  /// written the moment it is: a tap in the first frame is not lost.
  final Map<String, Object?> _pending = {};

  /// Each part as it was last decoded, and the text it was decoded from.
  final Map<String, (String?, Object?)> _decoded = {};

  /// Whether the phone's store has been reached.
  bool get isOpen => _prefs != null;

  /// Reaches the phone's store, once; a block calls it as it builds. Until
  /// it is reached everything reads empty, and the blocks redraw when it is.
  void open() {
    if (_prefs != null || _opening != null) return;
    _opening = SharedPreferences.getInstance().then(
      (prefs) {
        _prefs = prefs;
        final pending = Map<String, Object?>.of(_pending);
        _pending.clear();
        for (final MapEntry<String, Object?> e in pending.entries) {
          _write(e.key, e.value);
        }
        notifyListeners();
      },
      onError: (Object _) {
        // A phone whose store cannot be reached keeps what is played for
        // the visit and nothing more.
        _opening = null;
      },
    );
  }

  /// Done once the phone's store is reached: for whoever wants to draw
  /// from it with nothing missing, a test or a camera above all.
  Future<void> ready() {
    open();
    return _opening ?? Future<void>.value();
  }

  Object? _read(String part) {
    if (_pending.containsKey(part)) return _pending[part];
    final String? raw = _prefs?.getString('$prefix$part');
    final (String?, Object?)? kept = _decoded[part];
    if (kept != null && kept.$1 == raw) return kept.$2;
    Object? value;
    try {
      value = raw == null ? null : jsonDecode(raw);
    } on FormatException {
      // A part this build cannot read is a part that starts clean.
      value = null;
    }
    _decoded[part] = (raw, value);
    return value;
  }

  void _write(String part, Object? value) {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      _pending[part] = value;
      open();
      return;
    }
    final String raw = jsonEncode(value);
    _decoded[part] = (raw, value);
    prefs.setString('$prefix$part', raw).catchError((Object _) => false);
  }

  Map<String, Object?> _map(String part) {
    final Object? raw = _read(part);
    return raw is Map ? raw.cast<String, Object?>() : const {};
  }

  void _put(String part, Map<String, Object?> value) {
    _write(part, value);
    notifyListeners();
  }

  // ── Picks ──────────────────────────────────────────────────────────────

  /// What the reader last picked on [section]'s chips or ruler.
  String? pick(String section) {
    final Object? v = _map('picks')[section];
    return v is String ? v : null;
  }

  /// Keeps [value] as what [section] opens on next time.
  void setPick(String section, String value) {
    if (pick(section) == value) return;
    _put('picks', {..._map('picks'), section: value});
  }

  // ── Chains of whys ─────────────────────────────────────────────────────

  /// How many answers past the first are open on [chain] in [section].
  int depth(String section, String chain) {
    final Object? v = _map('whys')['$section/$chain'];
    return v is num && v >= 0 ? v.toInt() : 0;
  }

  void setDepth(String section, String chain, int depth) {
    _put('whys', {..._map('whys'), '$section/$chain': depth});
  }

  // ── Stances ────────────────────────────────────────────────────────────

  /// Where the reader stood on the claim of [pillId].
  Stance stance(String pillId) {
    final Object? raw = _map('stances')[pillId];
    if (raw is! Map) return const Stance();
    int? place(Object? v) =>
        v is num && v >= 0 && v < Stance.places ? v.toInt() : null;
    return Stance(before: place(raw['b']), after: place(raw['a']));
  }

  /// Keeps where the reader stood before reading [pillId]'s evidence. It is
  /// taken once: the point is what they thought before they knew.
  void setBefore(String pillId, int place, {required String on}) {
    if (stance(pillId).before != null) return;
    _put('stances', {
      ..._map('stances'),
      pillId: {'b': place, 'd': on},
    });
  }

  /// Keeps where the reader stood after, once.
  void setAfter(String pillId, int place) {
    final Object? raw = _map('stances')[pillId];
    if (raw is! Map || raw['b'] == null || raw['a'] != null) return;
    _put('stances', {
      ..._map('stances'),
      pillId: {...raw.cast<String, Object?>(), 'a': place},
    });
  }

  // ── Lines said ─────────────────────────────────────────────────────────

  /// The day each line said from these screens was said on, by card.
  Map<String, String> get said => {
    for (final MapEntry<String, Object?> e in _map('said').entries)
      if (e.value is String) e.key: e.value as String,
  };

  /// Keeps the day [pillId] was said on, the first time only: said is said.
  void markSaid(String pillId, {required String on}) {
    if (said.containsKey(pillId)) return;
    _put('said', {..._map('said'), pillId: on});
  }

  // ── Questions asked ────────────────────────────────────────────────────

  /// The questions the reader kept, newest first.
  List<AskedQuestion> get asked {
    final Object? raw = _read('asked');
    return [
      if (raw is List)
        for (final Object? q in raw) ?AskedQuestion.fromJson(q),
    ];
  }

  /// Keeps [question], answered by [cardId] or not yet, at the top; the
  /// same question asked again replaces the older one, and an answer is
  /// never forgotten for the lack of one the second time.
  void keep(String question, {String? cardId, required String on}) {
    final String asked = question.trim();
    if (asked.isEmpty) return;
    final String same = _plain(asked);
    final List<AskedQuestion> before = this.asked;
    final AskedQuestion? older = before
        .where((q) => _plain(q.question) == same)
        .firstOrNull;
    final AskedQuestion kept = AskedQuestion(
      question: asked,
      cardId: cardId ?? older?.cardId,
      on: on,
    );
    _writeAsked([
      kept,
      for (final q in before)
        if (_plain(q.question) != same) q,
    ]);
  }

  /// Forgets the question at [index], and gives it back for an undo.
  AskedQuestion? forget(int index) {
    final List<AskedQuestion> before = asked;
    if (index < 0 || index >= before.length) return null;
    final AskedQuestion gone = before.removeAt(index);
    _writeAsked(before);
    return gone;
  }

  /// Puts a forgotten question back where it was.
  void restore(int index, AskedQuestion question) {
    final List<AskedQuestion> now = asked;
    now.insert(index.clamp(0, now.length), question);
    _writeAsked(now);
  }

  void _writeAsked(List<AskedQuestion> questions) {
    _write('asked', [
      for (final q in questions.take(keepQuestions)) q.toJson(),
    ]);
    notifyListeners();
  }

  static String _plain(String question) => question
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();
}

/// A day as the store keeps it: `2026-10-18`, on the phone's calendar.
String screensDayKey(DateTime on) =>
    '${on.year.toString().padLeft(4, '0')}-'
    '${on.month.toString().padLeft(2, '0')}-'
    '${on.day.toString().padLeft(2, '0')}';
