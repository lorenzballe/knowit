import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'page_messages.dart';
import 'web_surface.dart';

/// A surface with no platform view behind it, for widget tests and the
/// cameras, where none can be drawn: it keeps what it was given and says
/// what the test tells it to, in the page's place.
///
/// It says it is ready as soon as a page is loaded, as a page does once its
/// first frame is drawn, unless told to wait ([readyOnLoad]); [say] speaks
/// any other part of the page's side of the bridge.
class FakeWebSurface implements WebSurface {
  FakeWebSurface({this.readyOnLoad = true, this.face}) {
    made.add(this);
    WebSurfaces.live++;
  }

  /// Every fake made since [reset], oldest first.
  static final List<FakeWebSurface> made = [];

  /// Forgets the fakes made so far.
  static void reset() => made.clear();

  /// Whether the page says it is ready the moment it is loaded.
  final bool readyOnLoad;

  /// What is drawn in the page's place: a picture of the page, in a
  /// camera; the page's ground, when null.
  final Widget Function(FakeWebSurface surface)? face;

  /// The page as it would have been shown: the kit inside it, the bridge
  /// first.
  String? html;
  Color? background;

  /// Every message the app said to the page, in order.
  final List<Map<String, Object?>> told = [];

  /// The recognisers the page was last drawn with.
  Set<Factory<OneSequenceGestureRecognizer>> gestures = const {};

  bool disposed = false;
  int loads = 0;

  @override
  bool get available => true;

  @override
  ValueChanged<PageMessage>? onMessage;

  @override
  Future<void> load(String html, {required Color background}) async {
    this.html = html;
    this.background = background;
    loads++;
    if (readyOnLoad) scheduleMicrotask(() => say(const PageReady()));
  }

  /// The page says [message].
  void say(PageMessage message) {
    if (!disposed) onMessage?.call(message);
  }

  @override
  Future<void> tell(Map<String, Object?> message) async {
    if (!disposed) told.add(message);
  }

  @override
  Widget view({required Set<Factory<OneSequenceGestureRecognizer>> gestures}) {
    this.gestures = gestures;
    return KeyedSubtree(
      key: const ValueKey('fake-page'),
      child:
          face?.call(this) ??
          ColoredBox(color: background ?? const Color(0x00000000)),
    );
  }

  @override
  void dispose() {
    if (disposed) return;
    disposed = true;
    onMessage = null;
    WebSurfaces.live--;
  }
}
