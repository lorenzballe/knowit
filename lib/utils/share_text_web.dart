import 'dart:ui';

/// A browser has no share sheet worth the name, so the text is copied.
Future<bool> shareText(String text, {Rect? origin}) async => false;
