import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the reader did on Explore's shelves today: the bets laid and the
/// points they came to, the guesses set on a slider, the facts judged new or
/// known, the round against the clock.
///
/// A day's play and nothing more. It is kept for the day it was made on,
/// across a restart, and the next day starts clean — a hundred points again,
/// nothing guessed — because the shelves are dealt afresh too. What is worth
/// keeping for good is kept where it always was: a commitment made on a shelf
/// is an answer, recorded by [AppState] like any other.
class ExplorePlay extends ChangeNotifier {
  ExplorePlay._();

  static ExplorePlay _instance = ExplorePlay._();
  static ExplorePlay get instance => _instance;

  /// A fresh, empty store for a test.
  @visibleForTesting
  static void resetForTest() => _instance = ExplorePlay._();

  static const String _key = 'knowit.explorePlay';

  /// The points a day starts with.
  static const int dailyPoints = 100;

  String _day = '';
  Map<String, Object?> _values = {};
  bool _loaded = false;

  static String _today() {
    final DateTime d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Reads what was played earlier today. Safe to call more than once.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw == null) return;
      final Object? doc = jsonDecode(raw);
      if (doc is! Map || doc['day'] != _today()) return;
      final Object? values = doc['values'];
      if (values is! Map) return;
      // What was played before the load finished wins over what was read.
      _day = _today();
      _values = {...values.cast<String, Object?>(), ..._values};
      notifyListeners();
    } catch (_) {
      // A store that cannot be read is a day that starts clean.
    }
  }

  void _roll() {
    final String today = _today();
    if (_day == today) return;
    _day = today;
    _values = {};
  }

  /// What was kept under [key] today, or null.
  Object? operator [](String key) {
    _roll();
    return _values[key];
  }

  /// Keeps [value] under [key] for the rest of the day; null forgets it.
  void put(String key, Object? value) {
    _roll();
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode({'day': _day, 'values': _values}));
    } catch (_) {
      // Unsaved play is lost at a restart, and nothing else.
    }
  }

  /// The points left to stake today.
  int get points => (this['points'] as num?)?.toInt() ?? dailyPoints;

  void addPoints(int delta) => put('points', points + delta);
}
