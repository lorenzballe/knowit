import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// What `window.posthog` is, once the library has loaded: the app only ever
/// asks it to start, because everything after that goes through the plugin.
extension type _PostHogJs._(JSObject _) implements JSObject {
  external void init(String key, JSAny? config);
}

@JS('window.posthog')
external _PostHogJs? get _posthog;

/// Puts posthog-js on the page, because the browser is the one platform where
/// the plugin brings no library of its own.
///
/// The plugin's web side calls straight through to `window.posthog` and, where
/// there is none, quietly does nothing — which is a sound way to fail and a
/// terrible way to be configured: the preview would look measured and be
/// silent. So this loads the library and starts it, and the app carries on
/// whether or not it arrives.
///
/// It is a `<script>` and not a bundled copy because the file is PostHog's to
/// version; pinning a copy in `web/` would mean shipping their bug fixes by
/// hand. It is also why nothing here awaits the load: the first paint of a
/// card must not wait on a CDN.
Future<void> bootAnalytics({required String key, required String host}) async {
  if (_posthog != null) return;

  final done = Completer<void>();
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..src = '${_assetsFor(host)}/static/array.js'
    ..async = true;

  script.onload = (JSAny _) {
    try {
      _posthog?.init(
        key,
        {
          'api_host': host,
          // The app says which screen it is on; posthog-js would otherwise
          // report the one URL a single-page Flutter build ever has.
          'capture_pageview': false,
          'capture_pageleave': false,
          // The person is made when the reader signs in, matching
          // personProfiles.identifiedOnly on the phones.
          'person_profiles': 'identified_only',
        }.jsify(),
      );
      if (!done.isCompleted) done.complete();
    } catch (error) {
      if (!done.isCompleted) done.completeError(error);
    }
  }.toJS;

  script.onerror = (JSAny _) {
    // A blocked CDN, an ad blocker, no network. The preview still runs.
    if (!done.isCompleted) done.complete();
  }.toJS;

  web.document.head?.append(script);

  // Long enough that a slow connection still gets measured, short enough that
  // a dead one does not hold the splash. The app starts either way.
  return done.future.timeout(const Duration(seconds: 5), onTimeout: () {});
}

/// Where the library itself is served from, which is not where the events go.
///
/// PostHog serves the two from different hosts per region — events to
/// `eu.i.posthog.com`, the script to `eu-assets.i.posthog.com` — and asking
/// the events host for the script gets a 404. A self-hosted instance serves
/// both itself, so anything that is not one of the two clouds is left alone.
String _assetsFor(String host) {
  const Map<String, String> clouds = {
    'https://eu.i.posthog.com': 'https://eu-assets.i.posthog.com',
    'https://us.i.posthog.com': 'https://us-assets.i.posthog.com',
    'https://app.posthog.com': 'https://us-assets.i.posthog.com',
  };
  final String trimmed = host.endsWith('/')
      ? host.substring(0, host.length - 1)
      : host;
  return clouds[trimmed] ?? trimmed;
}
