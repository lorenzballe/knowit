// When one day becomes the next: counted on the calendar, so a night the
// clocks change on is a day like any other, and dealt again when the app
// comes back from a night asleep in memory.
//
// The streak cases mean most where the clocks change: run them as
// `TZ=Europe/Rome flutter test test/day_turns_test.dart`, where 25 October
// 2026 is 25 hours long and 28 March 2027 is 23.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/state/app_state.dart';

Future<AppState> _openedAt(
  DateTime Function() clock, [
  Map<String, Object> prefs = const {},
]) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final AppState app = AppState(
    clock: clock,
    hasPermission: () async => false,
    askPermission: () async => false,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
  );
  await app.init();
  return app;
}

Future<void> _read(AppState app, int cards) async {
  for (var i = 0; i < cards && !app.todayCompleted; i++) {
    await app.advance();
  }
}

Future<void> _finish(AppState app) => _read(app, 10);

void main() {
  setUp(() {
    PillBank.reset();
    resetCalendar();
  });

  group('days on the calendar', () {
    test('the day before and after, whatever the hour', () {
      expect(
        dateKey(dayShift(DateTime(2026, 10, 25, 23, 30), -1)),
        '2026-10-24',
      );
      expect(dateKey(dayShift(DateTime(2026, 10, 25, 0, 30), 1)), '2026-10-26');
      expect(dateKey(dayShift(DateTime(2027, 3, 1), -1)), '2027-02-28');
      expect(dateKey(dayShift(DateTime(2026, 12, 31, 23), 1)), '2027-01-01');
      expect(dateKey(dayShift(DateTime(2026, 10, 21), -7)), '2026-10-14');
    });

    test('whole days between two dates, whatever the clocks did', () {
      expect(
        daysBetween(
          DateTime(2026, 10, 24, 23, 59),
          DateTime(2026, 10, 26, 0, 1),
        ),
        2,
      );
      expect(
        daysBetween(DateTime(2027, 3, 28), DateTime(2027, 3, 29, 0, 30)),
        1,
      );
      expect(
        daysBetween(DateTime(2026, 10, 25), DateTime(2026, 10, 25, 23)),
        0,
      );
    });

    test('the edition is counted as the server counts it', () {
      expect(editionOf(DateTime(2026, 9, 1)), 1);
      expect(editionOf(DateTime(2026, 10, 25, 23, 30)), 55);
      expect(editionOf(DateTime(2027, 3, 29, 0, 30)), 210);
      expect(
        dateKey(dateOfEdition(editionOf(DateTime(2027, 3, 29)))),
        '2027-03-29',
      );
    });
  });

  group('a streak across a night the clocks change', () {
    for (final DateTime at in [
      DateTime(2026, 10, 25, 22, 30),
      // The last hour of a 25-hour day: 24 hours before it is the same day.
      DateTime(2026, 10, 25, 23, 30),
    ]) {
      test('kept on 24 October, finished at $at, goes on', () async {
        final AppState app = await _openedAt(() => at, {
          'knowit.streak': 12,
          'knowit.bestStreak': 12,
          'knowit.lastCompletionDate': '2026-10-24',
          'knowit.completedDates': <String>['2026-10-24'],
        });
        expect(app.liveStreak, 12);
        await _finish(app);
        expect(app.streak, 13);
        expect(app.lastCompletionDate, '2026-10-25');
      });
    }

    test(
      'kept on 28 March, finished in the first hour of the 29th, goes on',
      () async {
        // The hour after midnight following a 23-hour day.
        final AppState app = await _openedAt(
          () => DateTime(2027, 3, 29, 0, 30),
          {
            'knowit.streak': 30,
            'knowit.bestStreak': 30,
            'knowit.lastCompletionDate': '2027-03-28',
            'knowit.completedDates': <String>['2027-03-28'],
          },
        );
        expect(app.liveStreak, 30);
        expect(app.missedDays, 0);
        await _finish(app);
        expect(app.streak, 31);
      },
    );

    test('a day missed across the change is one day missed', () async {
      final AppState app = await _openedAt(() => DateTime(2027, 3, 29, 9), {
        'knowit.streak': 30,
        'knowit.lastCompletionDate': '2027-03-27',
        // None to spend: a freeze would fill the day in.
        'knowit.freezes': 0,
      });
      expect(app.missedDays, 1);
    });
  });

  group('back after a night asleep in memory', () {
    test('the same day: nothing turns', () async {
      DateTime now = DateTime(2026, 10, 20, 9);
      final AppState app = await _openedAt(() => now);
      final List<String> deck = [for (final p in app.todaysDeck) p.id];
      now = DateTime(2026, 10, 20, 21);
      expect(await app.turnDayIfDue(), isFalse);
      expect([for (final p in app.todaysDeck) p.id], deck);
    });

    test('a day finished at night, back in the morning: a new day', () async {
      DateTime now = DateTime(2026, 10, 20, 22);
      final AppState app = await _openedAt(() => now);
      await _finish(app);
      expect(app.dayClosed, isTrue);
      final int streak = app.streak;

      now = DateTime(2026, 10, 21, 8, 30);
      expect(await app.turnDayIfDue(), isTrue);
      expect(dateKey(app.today), '2026-10-21');
      expect(app.todayIndex, 0);
      expect(app.todayCompleted, isFalse);
      expect(app.dayClosed, isFalse);
      expect(app.liveStreak, streak, reason: 'kept yesterday, still alive');
      await _finish(app);
      expect(app.streak, streak + 1);
    });

    test('an evening begun before midnight is finished after it, and counts '
        'for the evening', () async {
      DateTime now = DateTime(2026, 10, 20, 23, 40);
      final AppState app = await _openedAt(() => now, {
        'knowit.streak': 4,
        'knowit.bestStreak': 4,
        'knowit.lastCompletionDate': '2026-10-19',
        'knowit.completedDates': <String>['2026-10-19'],
      });
      await _read(app, 2);
      expect(app.todayCompleted, isFalse);

      now = DateTime(2026, 10, 21, 0, 20);
      expect(await app.turnDayIfDue(), isFalse);
      await _finish(app);
      expect(app.lastCompletionDate, '2026-10-20');
      expect(app.streak, 5);

      // The first return after three: the new day.
      now = DateTime(2026, 10, 21, 7);
      expect(await app.turnDayIfDue(), isTrue);
      expect(dateKey(app.today), '2026-10-21');
      expect(app.liveStreak, 5);
    });

    test('a day left unfinished, back the next morning: a new day, and the '
        'lapse said as a launch would', () async {
      DateTime now = DateTime(2026, 10, 20, 18);
      final AppState app = await _openedAt(() => now, {
        'knowit.streak': 4,
        'knowit.lastCompletionDate': '2026-10-19',
        'knowit.freezes': 0,
      });
      await _read(app, 1);

      now = DateTime(2026, 10, 21, 9);
      expect(await app.turnDayIfDue(), isTrue);
      expect(app.missedDays, 1);
      expect(app.liveStreak, 0);
    });
  });
}
