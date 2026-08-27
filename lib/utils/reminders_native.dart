import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// The daily nudge, on a phone.
///
/// A daily app that never speaks first is a daily app somebody opens twice.
/// This is the single mechanism that brings anybody back, and it was a
/// placeholder for the whole of this project's life.
///
/// Scheduling is deliberately inexact. A reminder to read five cards does not
/// need to land on the second, and asking for exact alarms means asking
/// Android for a permission it now guards closely — a trade with nothing on
/// the app's side of it.
const int _dailyId = 1;

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

bool _ready = false;

/// Whether a real daily reminder can be delivered at all here.
bool get remindersSupported => true;

Future<void> _init() async {
  if (_ready) return;
  tz.initializeTimeZones();
  await _plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        // Asked for explicitly later, so the prompt lands when the reader has
        // chosen a time rather than on first launch.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );
  _ready = true;
}

/// Asks for permission, returning whether it was given.
Future<bool> ensureReminderPermission() async {
  await _init();

  final android = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (android != null) {
    return await android.requestNotificationsPermission() ?? false;
  }

  final ios = _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
  if (ios != null) {
    return await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }
  return false;
}

/// Puts the reminder on at [hour]:[minute], every day, replacing any earlier
/// one. Cancelling first is what keeps a changed time from leaving the old
/// one behind.
Future<void> scheduleDailyReminder({
  required int hour,
  required int minute,
  required String title,
  required String body,
}) async {
  await _init();
  await _plugin.cancel(_dailyId);

  final now = tz.TZDateTime.now(tz.local);
  var when = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

  await _plugin.zonedSchedule(
    _dailyId,
    title,
    body,
    when,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'knowit_daily',
        'Daily pills',
        channelDescription: 'The nudge that your five are ready.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.wallClockTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

Future<void> cancelDailyReminder() async {
  await _init();
  await _plugin.cancel(_dailyId);
}
