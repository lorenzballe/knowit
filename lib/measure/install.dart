import 'dart:async';

import 'package:flutter/foundation.dart';

import '../debug_flags.dart';

/// Where this install came from, as one word stamped on every event and on
/// the reader's profile — so that the phones that are not readers can be
/// told from the ones that are.
///
/// Almost every "reader" PostHog saw in the app's first month was a device
/// reviewing or testing it: one iPhone per build from Apple's review, Google
/// Play's pre-launch robots, a closed test. They are tagged here, by the app
/// itself, rather than found by hand afterwards.
///
/// - `debug`: a build run from a developer's machine, on any platform.
/// - `testflight`: an iPhone install with a sandbox receipt — TestFlight's,
///   and the copy App Review installs.
/// - `app_store`: any other iPhone install.
/// - `test_lab`: an Android phone in Firebase Test Lab, which is where Google
///   Play's pre-launch robots run.
/// - `play`: an Android install made by Google Play.
/// - `sideload`: any other Android install, or one that would not say.
/// - `web`: the site.
/// - `other`: a desktop, which no build is shipped to.
String installChannelFor({
  required ToolsPlatform platform,
  required bool debugMode,
  bool testFlight = false,
  String? installer,
  bool testLab = false,
}) {
  if (debugMode) return 'debug';
  return switch (platform) {
    ToolsPlatform.web => 'web',
    ToolsPlatform.iOS => testFlight ? 'testflight' : 'app_store',
    ToolsPlatform.android =>
      testLab
          ? 'test_lab'
          : installer == 'com.android.vending'
          ? 'play'
          : 'sideload',
    ToolsPlatform.other => 'other',
  };
}

/// Whether [channel] is a device that is not a reader at all: a developer's
/// build, or a robot. PostHog's own "internal and test users" filter is
/// told so through the profile (`$internal_or_test_user`).
bool isTestChannel(String channel) =>
    channel == 'test_lab' || channel == 'debug';

/// How long an Android phone is given to say where the app came from. It
/// answers from what it already holds, so this only bounds a phone that
/// would not answer at all; and it is asked while Firebase starts, so the
/// wait almost never adds anything.
const Duration kInstallWait = Duration(milliseconds: 300);

/// Asks the phone where this install came from. Never throws, and never
/// waits longer than the phone's own bound: an iPhone's is the TestFlight
/// question's ([kTestFlightWait]), an Android phone's [kInstallWait].
Future<String> readInstallChannel({
  bool debugMode = kDebugMode,
  ToolsPlatform? platform,
  Future<bool> Function() testFlight = testFlightOnce,
}) async {
  final ToolsPlatform on = platform ?? ToolsPlatform.current;
  if (debugMode) return installChannelFor(platform: on, debugMode: true);
  switch (on) {
    case ToolsPlatform.iOS:
      return installChannelFor(
        platform: on,
        debugMode: false,
        testFlight: await testFlight(),
      );
    case ToolsPlatform.android:
      try {
        final Map<String, Object?>? said = await kInstallChannel
            .invokeMapMethod<String, Object?>('installSource')
            .timeout(kInstallWait);
        final Object? installer = said?['installer'];
        return installChannelFor(
          platform: on,
          debugMode: false,
          installer: installer is String ? installer : null,
          testLab: said?['testLab'] == true,
        );
      } catch (_) {
        // A phone that would not say, in time or at all: an install nobody
        // can vouch for, which is what a sideload is.
        return installChannelFor(platform: on, debugMode: false);
      }
    case ToolsPlatform.web:
    case ToolsPlatform.other:
      return installChannelFor(platform: on, debugMode: false);
  }
}
