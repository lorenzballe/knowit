import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Where the system share sheet points from, in the screen's logical
/// pixels — which on iOS are the points the sheet is placed in.
///
/// On iPhone since iOS 26 the sheet is anchored to whatever opened it, as it
/// always was on iPad, and share_plus refuses outright when it is not told
/// where that is: "sharePositionOrigin: argument must be set". Readers on an
/// older iOS never saw it; App Review, on the newest one, did on every build,
/// and the sheet never opened.
///
/// The box of [context] when it is on screen, cut to the screen; otherwise a
/// point in the middle of it. Anywhere inside the screen will do. An empty
/// rectangle, or one reaching past the edge, will not.
Rect shareOrigin([BuildContext? context]) {
  final Rect screen = Offset.zero & _screenSize();
  final RenderObject? box = context?.findRenderObject();
  if (box is RenderBox && box.attached && box.hasSize) {
    final Rect onScreen = (box.localToGlobal(Offset.zero) & box.size).intersect(
      screen,
    );
    if (onScreen.width > 0 && onScreen.height > 0) return onScreen;
  }
  return Rect.fromCenter(center: screen.center, width: 1, height: 1);
}

Size _screenSize() {
  final PlatformDispatcher dispatcher = PlatformDispatcher.instance;
  final FlutterView? view =
      dispatcher.implicitView ??
      (dispatcher.views.isEmpty ? null : dispatcher.views.first);
  if (view == null || view.devicePixelRatio <= 0) return const Size(320, 568);
  final Size size = view.physicalSize / view.devicePixelRatio;
  // Before the first frame a view can report nothing; the smallest iPhone
  // screen is a safe stand-in, being inside every larger one.
  return size.isEmpty ? const Size(320, 568) : size;
}
