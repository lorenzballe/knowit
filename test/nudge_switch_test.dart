import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/state/app_state.dart';

// Profile's daily nudge said "on" from the install, before the system was
// ever asked whether the app may notify, to a reader for whom nothing was
// going to arrive. It is off until the system has been asked, on from the
// tap that asks, and the setting after that.

void main() {
  group('The daily nudge', () {
    testWidgets('is off until the system has been asked, and on from the '
        'tap that asks', (tester) async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      var asked = 0;
      final app = AppState(
        hasPermission: () async => false,
        askPermission: () async {
          asked++;
          return true;
        },
        arm: (_) async {},
        disarm: () async {},
      );
      await app.init();
      await app.refreshDailyReminder();

      // The setting is on from the install; nothing would come of it.
      expect(app.notificationsOn, isTrue);
      expect(app.nudgeShownOn, isFalse);

      final Future<void> turning = app.setNotifications(true);
      // The switch answers the tap, not the system's prompt.
      expect(app.nudgeShownOn, isTrue);
      await turning;
      expect(asked, 1);
      expect(app.remindersLive, isTrue);
      expect(app.nudgeShownOn, isTrue);

      await app.setNotifications(false);
      expect(app.nudgeShownOn, isFalse);
    });

    testWidgets('a no from the system keeps the setting, with the answer '
        'beside it', (tester) async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      final app = AppState(
        hasPermission: () async => false,
        askPermission: () async => false,
        arm: (_) async {},
        disarm: () async {},
      );
      await app.init();
      await app.refreshDailyReminder();
      expect(app.nudgeShownOn, isFalse);

      await app.setNotifications(true);
      expect(app.remindersLive, isFalse);
      expect(app.nudgeShownOn, isTrue);
    });

    testWidgets('a phone that already lets the app notify shows it on', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      final app = AppState(
        hasPermission: () async => true,
        askPermission: () async => true,
        arm: (_) async {},
        disarm: () async {},
      );
      await app.init();
      await app.refreshDailyReminder();
      expect(app.nudgeShownOn, isTrue);
    });
  });
}
