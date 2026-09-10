import 'package:flutter/services.dart';

/// The home-screen widget, on a phone.
///
/// The widget is native — WidgetKit on iOS, an AppWidgetProvider on
/// Android — and neither can run a line of Dart, so the app hands over
/// what the widget will need: today's question, the streak, and the
/// question for each of the next fourteen mornings, so the widget turns
/// over by itself at midnight whether or not the app is opened.
const MethodChannel _channel = MethodChannel('astut/widget');

Future<void> pushHomeWidget(Map<String, Object?> data) async {
  try {
    await _channel.invokeMethod<void>('update', data);
  } on MissingPluginException {
    // A host with no widget behind the channel: a desktop, a test.
  } on PlatformException {
    // The native side declined; the widget keeps what it last had.
  }
}
