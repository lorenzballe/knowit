/// A kit page on the web build: an iframe of its own, sandboxed to run its
/// scripts and nothing else, spoken to with postMessage.
///
/// webview_flutter's own web implementation draws an iframe too, but cannot
/// carry a JavaScript channel, so the bridge is wired here directly: the
/// page posts `{astute: text}` to its parent (astute-bridge.js), and the
/// app posts `{astuteApp: text}` to the frame. The frame's origin is opaque
/// (no `allow-same-origin`), so the page cannot reach into the app either.
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'page_messages.dart';
import 'web_surface.dart';

/// The web build's surface: an iframe.
WebSurface makePlatformSurface() => FrameWebSurface();

/// Whether this platform can show a page: a browser always can.
bool platformShowsPages() => true;

/// Every page alive, so the others can let the pointer through while one
/// page's drag is out ([platformWatchRelease]).
final Set<FrameWebSurface> _surfaces = {};

/// The window's ear for the button coming up, while a drag is out.
JSFunction? _release;

/// The page a drag is out from, while one is ([platformWatchRelease]).
FrameWebSurface? _dragged;
bool _dragOut = false;

/// Whether [surface]'s iframe takes the pointer: not while something the
/// app draws covers it ([pageTouchable]), nor while another page's drag is
/// out. Otherwise the browser hands the iframe every pointer that lands on
/// it, whatever is drawn over it.
void _letThrough(FrameWebSurface surface) {
  final bool through =
      !surface._open || (_dragOut && !identical(surface, _dragged));
  surface._frame.style.pointerEvents = through ? 'none' : '';
}

/// [WebSurfaces.watchRelease] on the web build: every iframe but the one
/// dragged ([over]) lets the pointer through to the app's window, and the
/// window says when the button comes up there, once.
void platformWatchRelease(VoidCallback? onRelease, {WebSurface? over}) {
  final JSFunction? was = _release;
  _release = null;
  if (was != null) {
    web.window.removeEventListener('pointerup', was, true.toJS);
    web.window.removeEventListener('pointercancel', was, true.toJS);
  }
  _dragOut = onRelease != null;
  _dragged = _dragOut && over is FrameWebSurface ? over : null;
  _surfaces.forEach(_letThrough);
  if (onRelease == null) return;
  final JSFunction heard = ((web.Event _) => onRelease()).toJS;
  _release = heard;
  web.window.addEventListener('pointerup', heard, true.toJS);
  web.window.addEventListener('pointercancel', heard, true.toJS);
}

/// One iframe, registered as a platform view of its own.
class FrameWebSurface implements WebSurface {
  FrameWebSurface() {
    _frame = web.HTMLIFrameElement()
      ..setAttribute('sandbox', 'allow-scripts')
      ..setAttribute('scrolling', 'no')
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block';
    _surfaces.add(this);
    ui_web.platformViewRegistry.registerViewFactory(_type, (int _) => _frame);
    _listener = _heard.toJS;
    web.window.addEventListener('message', _listener);
    WebSurfaces.live++;
  }

  static int _made = 0;
  final String _type = 'astute-page-${_made++}';
  late final web.HTMLIFrameElement _frame;
  late final JSFunction _listener;
  bool _gone = false;

  /// Whether the place the page is drawn lets it take the pointer, as its
  /// view last read it ([pageTouchable]).
  bool _open = true;

  @override
  bool get available => true;

  @override
  ValueChanged<PageMessage>? onMessage;

  void _heard(web.MessageEvent event) {
    final web.Window? own = _frame.contentWindow;
    final JSAny? source = event.source;
    if (_gone || own == null || source == null) return;
    if (!source.strictEquals(own).toDart) return;
    final Object? data = event.data.dartify();
    if (data is! Map || data['astute'] is! String) return;
    final PageMessage? said = PageMessage.parse(data['astute'] as String);
    if (said != null) onMessage?.call(said);
  }

  @override
  Future<void> load(String html, {required Color background}) async {
    if (_gone) return;
    _frame.style.background =
        '#${(background.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';
    _frame.srcdoc = html.toJS;
  }

  @override
  Future<void> tell(Map<String, Object?> message) async {
    if (_gone) return;
    _frame.contentWindow?.postMessage(
      {'astuteApp': jsonEncode(message)}.jsify(),
      '*'.toJS,
    );
  }

  /// The iframe, letting the pointer through whenever something the app
  /// draws is over it: read again whenever a route rises over its own or a
  /// [PageTouch] above it shuts.
  @override
  Widget view({required Set<Factory<OneSequenceGestureRecognizer>> gestures}) =>
      Builder(
        builder: (context) {
          final bool open = pageTouchable(context);
          if (open != _open) {
            _open = open;
            _letThrough(this);
          }
          return HtmlElementView(viewType: _type);
        },
      );

  @override
  void dispose() {
    if (_gone) return;
    _gone = true;
    onMessage = null;
    WebSurfaces.live--;
    _surfaces.remove(this);
    if (identical(_dragged, this)) _dragged = null;
    web.window.removeEventListener('message', _listener);
    _frame.srcdoc = ''.toJS;
  }
}
