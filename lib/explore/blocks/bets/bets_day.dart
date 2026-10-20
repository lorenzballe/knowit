/// What the reader bet on Explore today, kept on the phone.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/pills_repository.dart' show dateKey;
import '../../../state/explore_play.dart';

/// One bet laid, and what it came to.
///
/// What it showed is kept as numbers and words of the card's, never as a
/// sentence: the slip says it again in whatever language the reader has
/// moved to since.
@immutable
class Bet {
  const Bet({
    required this.kind,
    required this.section,
    required this.pill,
    required this.said,
    required this.right,
    this.other,
    this.points = 0,
    this.confidence,
    this.facts = const {},
    this.at = 0,
  });

  /// The way it was laid: `range`, `stake`, `number`, `magnitude`, `day`,
  /// `closer`, `bigger`.
  final String kind;

  /// The section it was laid in.
  final String section;

  /// The card, and for a comparison the card it was set against.
  final String pill;
  final String? other;

  /// What the reader said, in the form the card keeps an answer: a number,
  /// an option's index; for a game that is not an answer, its own record
  /// ("LML" for three steps of more or less).
  final String said;

  /// Whether it was right: the card's own judgement where it was the
  /// card's answer, the game's where it was a game.
  final bool right;

  /// What it did to the day's points.
  final int points;

  /// How sure the reader said they were, 50 to 90, where it was asked.
  final int? confidence;

  /// What else the slip needs to say it: the range's ends, the stake.
  final Map<String, Object?> facts;

  /// When, in milliseconds since the epoch.
  final int at;

  Map<String, Object?> toJson() => {
    'k': kind,
    's': section,
    'p': pill,
    if (other != null) 'o': other,
    'w': said,
    'r': right,
    if (points != 0) 'n': points,
    if (confidence != null) 'c': confidence,
    if (facts.isNotEmpty) 'f': facts,
    't': at,
  };

  static Bet? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? kind = raw['k'], section = raw['s'], pill = raw['p'];
    final Object? said = raw['w'], right = raw['r'];
    if (kind is! String || section is! String || pill is! String) return null;
    if (said is! String || right is! bool) return null;
    final Object? other = raw['o'], points = raw['n'], sure = raw['c'];
    final Object? facts = raw['f'], at = raw['t'];
    return Bet(
      kind: kind,
      section: section,
      pill: pill,
      other: other is String ? other : null,
      said: said,
      right: right,
      points: points is num ? points.toInt() : 0,
      confidence: sure is num ? sure.toInt() : null,
      facts: facts is Map ? facts.cast<String, Object?>() : const {},
      at: at is num ? at.toInt() : 0,
    );
  }
}

/// The day's bets: the points left of the day's hundred, every bet laid
/// and what it came to, a bet half laid, and the cards each shelf of bets
/// was dealt.
///
/// A day's play and nothing more, like the rest of what is played on the
/// shelves (lib/state/explore_play.dart): kept across a restart for the day
/// it was made on, and the next day on the phone's own calendar starts
/// clean — a hundred points again, nothing bet, the shelves dealt afresh.
/// What is worth keeping for good is not kept here: a bet that is a card's
/// answer is recorded as the card's answer, by the app, like any other.
class BetsDay extends ChangeNotifier {
  BetsDay._({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// The day's points are not the bets' own: Work it out stakes from the
  /// same hundred (lib/state/explore_play.dart), and two purses on one
  /// screen, each saying a different number, would be one too many. So the
  /// points live there, and what changes them is heard here too.
  ExplorePlay get _purse {
    final ExplorePlay now = ExplorePlay.instance;
    if (!identical(now, _heard)) {
      _heard?.removeListener(notifyListeners);
      _heard = now..addListener(notifyListeners);
    }
    return now;
  }

  ExplorePlay? _heard;

  static BetsDay _instance = BetsDay._();

  /// The one store: a day has one wallet, whichever shelf a bet is laid on.
  static BetsDay get instance => _instance;

  /// A fresh, empty store for a test, on [clock]'s calendar, with a fresh
  /// purse on the same calendar.
  @visibleForTesting
  static void resetForTest({DateTime Function()? clock}) {
    // A test's own reset, calling the purse's: both are for tests only.
    // ignore: invalid_use_of_visible_for_testing_member
    ExplorePlay.resetForTest(clock: clock);
    _instance = BetsDay._(clock: clock);
  }

  /// Where the day is kept: every key the family writes starts with this.
  static const String prefix = 'knowit.explore.bets.';
  static const String _kDay = '${prefix}day';
  static const String _kSlip = '${prefix}slip';
  static const String _kPlay = '${prefix}play';
  static const String _kDeals = '${prefix}deals';

  /// The points a day starts with.
  static const int dailyPoints = 100;

  final DateTime Function() _clock;

  String _day = '';
  List<Bet> _slip = [];
  Map<String, Object?> _play = {};
  Map<String, List<String>> _deals = {};
  Future<void>? _loading;
  bool _loaded = false;

  /// Today, on the phone's calendar.
  String get today => dateKey(_clock());

  /// Whether what was kept has been read.
  bool get loaded => _loaded;

  /// Reads what was bet earlier today, and the day's purse. Safe to call
  /// more than once; the calls share one read.
  Future<void> load() =>
      _loading ??= Future.wait([_load(), _purse.load()]).then((_) {});

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String day = prefs.getString(_kDay) ?? '';
      if (day == today) {
        // What was bet before the read finished wins over what was read:
        // a bet laid in the first second must not be lost to it.
        final List<Bet> kept = [
          for (final Object? b in _list(prefs.getString(_kSlip)))
            ?Bet.fromJson(b),
        ];
        final Set<String> placed = {
          for (final b in _slip) '${b.kind}:${b.pill}',
        };
        _slip = [
          for (final Bet b in kept)
            if (!placed.contains('${b.kind}:${b.pill}')) b,
          ..._slip,
        ];
        _play = {..._map(prefs.getString(_kPlay)), ..._play};
        _deals = {
          for (final MapEntry<String, Object?> e in _map(
            prefs.getString(_kDeals),
          ).entries)
            if (e.value is List)
              e.key: [
                for (final Object? id in e.value as List)
                  if (id is String) id,
              ],
          ..._deals,
        };
        _day = day;
      }
    } catch (_) {
      // A store that cannot be read is a day that starts clean.
    }
    _loaded = true;
    notifyListeners();
  }

  static List<Object?> _list(String? raw) {
    if (raw == null) return const [];
    try {
      final Object? v = jsonDecode(raw);
      return v is List ? v : const [];
    } catch (_) {
      return const [];
    }
  }

  static Map<String, Object?> _map(String? raw) {
    if (raw == null) return {};
    try {
      final Object? v = jsonDecode(raw);
      return v is Map ? v.cast<String, Object?>() : {};
    } catch (_) {
      return {};
    }
  }

  /// A new day on the calendar starts clean, whenever it is first asked.
  ///
  /// It is asked while something is being drawn, which is no time to
  /// redraw anything; so what shows the day — the points left beside a
  /// shelf's name, which is drawn once and only redrawn when told — is told
  /// as soon as the drawing is done.
  void _roll() {
    final String now = today;
    if (_day == now) return;
    final bool started = _day.isNotEmpty;
    _day = now;
    _slip = [];
    _play = {};
    _deals = {};
    if (started) scheduleMicrotask(notifyListeners);
  }

  /// The points left to stake today.
  int get points {
    _roll();
    return _purse.points;
  }

  /// Today's bets, in the order they were laid.
  List<Bet> get slip {
    _roll();
    return List.unmodifiable(_slip);
  }

  /// The bet of [kind] laid on [pillId] today, if there is one.
  Bet? betOn(String kind, String pillId) {
    _roll();
    for (final Bet b in _slip.reversed) {
      if (b.kind == kind && b.pill == pillId) return b;
    }
    return null;
  }

  /// Lays [bet]: on the slip, and its points in the wallet. A second bet of
  /// the same kind on the same card is not laid: the first one stands, as
  /// a card's first answer does.
  void place(Bet bet) {
    _roll();
    if (betOn(bet.kind, bet.pill) != null) return;
    _slip = [..._slip, bet];
    _purse.addPoints(bet.points);
    _play.remove(draftKey(bet.kind, bet.pill));
    notifyListeners();
    _save();
  }

  /// The key a bet half laid on [pillId] is kept under.
  static String draftKey(String kind, String pillId) => '$kind:$pillId';

  /// A bet half laid — a thumb where it was let go, a width, a stake, the
  /// steps taken so far — or null.
  Object? draft(String key) {
    _roll();
    return _play[key];
  }

  /// Keeps a bet half laid for the rest of the day; null forgets it.
  void keepDraft(String key, Object? value) {
    _roll();
    if (value == null) {
      if (_play.remove(key) == null) return;
    } else {
      _play[key] = value;
    }
    notifyListeners();
    _save();
  }

  /// The cards a shelf was dealt today, under [key], or null when it has
  /// not been dealt.
  List<String>? deal(String key) {
    _roll();
    return _deals[key];
  }

  /// Keeps the cards a shelf was dealt for the rest of the day, so the
  /// shelf does not change under the reader as cards are read and answered
  /// elsewhere.
  void keepDeal(String key, List<String> ids) {
    _roll();
    _deals[key] = List.unmodifiable(ids);
    _save();
  }

  /// Every card another shelf of bets was dealt today: a card is bet on
  /// one shelf only.
  Set<String> claimedBesides(String key) {
    _roll();
    return {
      for (final MapEntry<String, List<String>> e in _deals.entries)
        if (e.key != key) ...e.value,
    };
  }

  Future<void> _save() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDay, _day);
      await prefs.setString(
        _kSlip,
        jsonEncode([for (final Bet b in _slip) b.toJson()]),
      );
      await prefs.setString(_kPlay, jsonEncode(_play));
      await prefs.setString(_kDeals, jsonEncode(_deals));
    } catch (_) {
      // Unsaved bets are lost at a restart, and nothing else.
    }
  }
}
