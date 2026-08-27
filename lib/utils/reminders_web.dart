/// The daily nudge, in a browser.
///
/// There is nothing honest to implement here. A browser can only raise a
/// notification while the page is open, and a reminder that requires the app
/// to already be open is not a reminder. Delivering one properly needs a
/// service worker and a push server, which is a backend this app does not
/// have — so the web build says so rather than accepting a time and silently
/// never using it.
bool get remindersSupported => false;

Future<bool> ensureReminderPermission() async => false;

Future<void> scheduleDailyReminder({
  required int hour,
  required int minute,
  required String title,
  required String body,
}) async {}

Future<void> cancelDailyReminder() async {}
