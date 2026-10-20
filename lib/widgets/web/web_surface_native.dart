/// A kit page on a phone: webview_flutter's WebView, the platform's own
/// browser engine (WKWebView on iOS, Android System WebView on Android).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'page_messages.dart';
import 'web_surface.dart';

/// The platform's surface, or one that shows nothing where there is no
/// WebView (a desktop, a test that did not put a fake in).
WebSurface makePlatformSurface() => WebViewPlatform.instance == null
    ? UnavailableWebSurface()
    : NativeWebSurface();

/// One WebView, set up for a card: JavaScript on, the bridge's channel
/// open, no zoom, no scrolling, nothing that navigates, the system's text
/// size kept out of a layout that has to fit.
class NativeWebSurface implements WebSurface {
  NativeWebSurface() {
    final WebViewPlatform? platform = WebViewPlatform.instance;
    // Video in a card plays in the card, and nothing sounds until a tap.
    final PlatformWebViewControllerCreationParams params =
        platform is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true)
        : const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params);
    WebSurfaces.live++;
    _set = _setUp();
  }

  late final WebViewController _controller;

  /// The settings, made before anything is loaded: the channel has to be
  /// open before the page's first word.
  late final Future<void> _set;
  String? _html;
  Color _background = const Color(0x00000000);
  bool _gone = false;

  @override
  bool get available => true;

  @override
  ValueChanged<PageMessage>? onMessage;

  Future<void> _setUp() async {
    final WebViewController c = _controller;
    await _quietly(() => c.setJavaScriptMode(JavaScriptMode.unrestricted));
    await _quietly(
      () => c.addJavaScriptChannel(
        'AstuteBridge',
        onMessageReceived: (message) {
          final PageMessage? said = PageMessage.parse(message.message);
          if (said != null && !_gone) onMessage?.call(said);
        },
      ),
    );
    await _quietly(
      () => c.setNavigationDelegate(
        NavigationDelegate(
          // The page is a string, loaded once; nothing navigates it away.
          // A link opens outside the app, through the bridge.
          onNavigationRequest: (request) =>
              request.url.startsWith('about:') ||
                  request.url.startsWith('data:')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          // iOS can end a page's process under memory pressure; it comes
          // back drawn from the start rather than left blank.
          onWebResourceError: (error) {
            if (error.errorType ==
                    WebResourceErrorType.webContentProcessTerminated &&
                _html != null &&
                !_gone) {
              load(_html!, background: _background);
            }
          },
        ),
      ),
    );
    await _quietly(() => c.enableZoom(false));
    await _quietly(() => c.setVerticalScrollBarEnabled(false));
    await _quietly(() => c.setHorizontalScrollBarEnabled(false));
    await _quietly(() => c.setOverScrollMode(WebViewOverScrollMode.never));
    final Object own = c.platform;
    if (own is AndroidWebViewController) {
      // The page sizes its own words to the card; the system's font scale
      // on top would push them out of it.
      await _quietly(() => own.setTextZoom(100));
      await _quietly(() => own.setMediaPlaybackRequiresUserGesture(true));
    }
    if (own is WebKitWebViewController) {
      await _quietly(() => own.setAllowsLinkPreview(false));
      await _quietly(() => own.setInspectable(kDebugMode));
    }
    if (kDebugMode) {
      await _quietly(
        () => c.setOnConsoleMessage((m) {
          if (m.level == JavaScriptLogLevel.error) {
            debugPrint('Astute: a card page said: ${m.message}');
          }
        }),
      );
    }
  }

  /// A setting a platform does not have is a setting it does not need.
  static Future<void> _quietly(Future<void> Function() set) async {
    try {
      await set();
    } catch (_) {}
  }

  @override
  Future<void> load(String html, {required Color background}) async {
    await _set;
    if (_gone) return;
    _html = html;
    _background = background;
    await _quietly(() => _controller.setBackgroundColor(background));
    await _controller.loadHtmlString(html);
  }

  @override
  Future<void> tell(Map<String, Object?> message) async {
    await _set;
    if (_gone) return;
    await _quietly(
      () => _controller.runJavaScript(
        'window.Astute&&window.Astute.receive(${jsonEncode(message)})',
      ),
    );
  }

  @override
  Widget view({required Set<Factory<OneSequenceGestureRecognizer>> gestures}) =>
      WebViewWidget(controller: _controller, gestureRecognizers: gestures);

  @override
  void dispose() {
    if (_gone) return;
    _gone = true;
    onMessage = null;
    WebSurfaces.live--;
    // A WebView goes with its controller; what is left of the page is told
    // to stop first, so nothing it scheduled runs on into the next card.
    _quietly(() => _controller.loadHtmlString('<!doctype html>'));
  }
}
