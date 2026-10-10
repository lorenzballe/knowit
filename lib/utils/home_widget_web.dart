import 'widget_open.dart';

/// A browser has no home screen to put a widget on.
Future<void> pushHomeWidget(Map<String, Object?> data) async {}

Future<List<String>> installedHomeWidgets() async => const [];

Future<WidgetOpen?> takeWidgetOpen() async => null;

void onWidgetOpened(void Function()? opened) {}
