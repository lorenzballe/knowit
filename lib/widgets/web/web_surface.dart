/// Where a kit page is drawn: a WebView on a phone (webview_flutter), an
/// iframe on the web build, a stand-in under test.
///
/// Everything that shows a page — a free card's face, a block of Explore —
/// reaches it only through this, which is what lets a widget test, where no
/// platform view can be drawn, put a [FakeWebSurface] in its place and
/// drive the page's side of the bridge by hand.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'page_messages.dart';
import 'web_surface_native.dart'
    if (dart.library.js_interop) 'web_surface_frame.dart';

/// One page, alive.
abstract class WebSurface {
  /// Whether this surface can show a page at all. One that cannot — a
  /// platform with no WebView — is the card's cue to be drawn natively.
  bool get available;

  /// Told each message the page sends, in the order it sends them.
  ValueChanged<PageMessage>? onMessage;

  /// Shows [html] on [background], the colour the surface is before the
  /// page has drawn anything, so a page coming up never flashes white.
  Future<void> load(String html, {required Color background});

  /// Says [message] to the page (see docs/cards/kit/astute-bridge.js).
  Future<void> tell(Map<String, Object?> message);

  /// The page, drawn. [gestures] are the recognisers that win a touch for
  /// the page (see lib/widgets/web/page_gestures.dart); every touch they do
  /// not win stays with whatever holds the surface.
  Widget view({required Set<Factory<OneSequenceGestureRecognizer>> gestures});

  /// Lets the page go, for good.
  void dispose();
}

/// How surfaces are made: the platform's own, or whatever a test puts in.
abstract final class WebSurfaces {
  static WebSurface Function() _make = makePlatformSurface;
  static bool _fake = false;

  /// Whether a page can be shown here at all, asked without making a
  /// surface to find out: what a block asks before it gives a page room.
  static bool get available => _fake || platformShowsPages();

  /// How many surfaces are alive now, for the tests that hold the deck to
  /// its two.
  static int live = 0;

  /// A new surface.
  static WebSurface create() => _make();

  /// On the web build a page hands its drags out to the app (the kit's
  /// forwardPans) and hears one end only if the button comes up over it. A
  /// card thrown with a mouse is often let go over the card under it, or
  /// over the app, and was left in the air there, the card under it looking
  /// live and answering nothing. While [onRelease] is set, the pages other
  /// than the one dragged ([over]) let the pointer through and the app's own
  /// window says when the button comes up; null ends the watch. A phone's
  /// WebView hands no drag out, so there it does nothing.
  static void watchRelease(VoidCallback? onRelease, {WebSurface? over}) {
    watching = onRelease;
    if (!_fake) platformWatchRelease(onRelease, over: over);
  }

  /// What the button coming up would end now, so a test can let go.
  @visibleForTesting
  static VoidCallback? watching;

  /// Makes every surface with [make] from now on; null puts the
  /// platform's back.
  @visibleForTesting
  static void debugUse(WebSurface Function()? make) {
    _make = make ?? makePlatformSurface;
    _fake = make != null;
  }
}

/// The surface of a platform that has no WebView: it shows nothing, says
/// so, and the card is drawn natively.
class UnavailableWebSurface implements WebSurface {
  @override
  bool get available => false;

  @override
  ValueChanged<PageMessage>? onMessage;

  @override
  Future<void> load(String html, {required Color background}) async {}

  @override
  Future<void> tell(Map<String, Object?> message) async {}

  @override
  Widget view({required Set<Factory<OneSequenceGestureRecognizer>> gestures}) =>
      const SizedBox.shrink();

  @override
  void dispose() {}
}
