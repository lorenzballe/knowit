import 'package:flutter/services.dart';

import 'widget_open.dart';

/// The home-screen widget, on a phone.
///
/// The widget is native — WidgetKit on iOS, an AppWidgetProvider on
/// Android — and neither can run a line of Dart, so the app hands over
/// what the widget will need: today's cards and today's shelf, the streak,
/// and the same for each of the next fourteen mornings, so the widget
/// turns over by itself at midnight whether or not the app is opened.
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

/// The widgets the reader has placed, as "kind.family" — `card.systemSmall`,
/// `streak.accessoryCircular` — one entry per widget on a screen. Empty where
/// there are none, or nothing to ask.
Future<List<String>> installedHomeWidgets() async {
  try {
    final List<Object?>? found = await _channel.invokeMethod<List<Object?>>(
      'installed',
    );
    return [for (final item in found ?? const []) '$item'];
  } on MissingPluginException {
    return const [];
  } on PlatformException {
    return const [];
  }
}

/// The widget whose tap opened the app, and the card it named, once:
/// asking clears it. Null when the app was opened any other way.
Future<WidgetOpen?> takeWidgetOpen() async {
  try {
    return WidgetOpen.read(
      await _channel.invokeMethod<Object?>('takeOpenedFrom'),
    );
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}

/// Calls [opened] when the phone says a widget's tap has just come in, or
/// stops listening when it is null.
///
/// A tap on a running app arrives beside its return to the foreground, and
/// the phone does not promise which comes first; asking on the way back
/// alone could ask a moment too early and leave the tap for the next time.
void onWidgetOpened(void Function()? opened) {
  _channel.setMethodCallHandler(
    opened == null
        ? null
        : (call) async {
            if (call.method == 'opened') opened();
            return null;
          },
  );
}
