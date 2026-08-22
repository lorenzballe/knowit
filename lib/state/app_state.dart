import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pills_repository.dart';
import '../models/pill.dart';

class AppState extends ChangeNotifier {
  static const _kStreak = 'knowit.streak';
  static const _kLastCompletion = 'knowit.lastCompletionDate';
  static const _kCompletedDates = 'knowit.completedDates';
  static const _kSavedIds = 'knowit.savedIds';
  static const _kTodayDate = 'knowit.todayDate';
  static const _kTodayIndex = 'knowit.todayIndex';

  late SharedPreferences _prefs;
  bool ready = false;

  int streak = 0;
  String? lastCompletionDate;
  List<String> completedDates = [];
  Set<String> savedIds = {};
  int todayIndex = 0;

  late DateTime today;
  late List<Pill> todaysDeck;

  bool get todayCompleted => todayIndex >= todaysDeck.length;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    today = DateTime.now();
    todaysDeck = pillsForDate(today);

    streak = _prefs.getInt(_kStreak) ?? 0;
    lastCompletionDate = _prefs.getString(_kLastCompletion);
    completedDates = _prefs.getStringList(_kCompletedDates) ?? [];
    savedIds = (_prefs.getStringList(_kSavedIds) ?? []).toSet();

    final storedDay = _prefs.getString(_kTodayDate);
    if (storedDay == dateKey(today)) {
      todayIndex = _prefs.getInt(_kTodayIndex) ?? 0;
    } else {
      todayIndex = 0;
      await _prefs.setString(_kTodayDate, dateKey(today));
      await _prefs.setInt(_kTodayIndex, 0);
    }

    ready = true;
    notifyListeners();
  }

  Future<void> advance() async {
    if (todayCompleted) return;
    todayIndex += 1;
    await _prefs.setInt(_kTodayIndex, todayIndex);
    if (todayCompleted) {
      await _completeToday();
    }
    notifyListeners();
  }

  Future<void> _completeToday() async {
    final key = dateKey(today);
    if (lastCompletionDate == key) return;

    final yesterday = dateKey(today.subtract(const Duration(days: 1)));
    streak = (lastCompletionDate == yesterday) ? streak + 1 : 1;
    lastCompletionDate = key;

    completedDates = [...completedDates, key];
    if (completedDates.length > 30) {
      completedDates = completedDates.sublist(completedDates.length - 30);
    }

    await _prefs.setInt(_kStreak, streak);
    await _prefs.setString(_kLastCompletion, lastCompletionDate!);
    await _prefs.setStringList(_kCompletedDates, completedDates);
  }

  bool isSaved(String pillId) => savedIds.contains(pillId);

  Future<void> toggleSaved(String pillId) async {
    if (savedIds.contains(pillId)) {
      savedIds.remove(pillId);
    } else {
      savedIds.add(pillId);
    }
    await _prefs.setStringList(_kSavedIds, savedIds.toList());
    notifyListeners();
  }

  /// True/false for the last 7 calendar days, oldest first.
  List<bool> weekCompletion() {
    final set = completedDates.toSet();
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return set.contains(dateKey(d));
    });
  }
}
