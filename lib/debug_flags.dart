import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Temporary developer tools, shown at the bottom of the profile.
///
/// The switch a build is made with: `--dart-define=DEBUG_TOOLS=false` turns
/// the tools off in it, everywhere but on the site (see [debugToolsFor]). On
/// an iPhone it cannot decide alone, because the build that reaches testers
/// through TestFlight is the very binary that is then submitted to the App
/// Store: whatever it was built with, readers would get too. So the iPhone is
/// asked at launch where it was installed from ([readDebugTools]). Android
/// is asked nothing, which is why the build that goes to Google Play has to
/// be made with `DEBUG_TOOLS=false`.
const bool kDebugTools = bool.fromEnvironment(
  'DEBUG_TOOLS',
  defaultValue: true,
);

/// Where the app is running, as far as the developer tools are concerned.
enum ToolsPlatform {
  iOS,
  android,
  web,

  /// A desktop: no build of it goes to anyone, and it has nothing to ask.
  other;

  /// This run's. The site is the web whatever opened it: a browser on an
  /// iPhone reports iOS, and has no TestFlight to be asked about.
  static ToolsPlatform get current {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => iOS,
      TargetPlatform.android => android,
      _ => other,
    };
  }
}

/// Whether the developer tools are on, from everything that decides it.
///
/// - `DEBUG_TOOLS=false` ([define]) turns them off, everywhere but on the
///   site. Built that way, the site still turns them on for a visit whose
///   address says `?debug` ([debugInAddress]): that is how they are used
///   from a browser without being shown to everyone who opens it.
/// - Otherwise a debug build ([debugMode]) has them.
/// - An iPhone release build has them only when the phone says it was
///   installed from TestFlight ([testFlight]), since the binary testers run
///   is the one the App Store then gets.
/// - Android, and anything else, has whatever it was built with.
///
/// Pure, so every case can be tested without a phone
/// (test/debug_tools_test.dart).
bool debugToolsFor({
  required ToolsPlatform platform,
  required bool testFlight,
  required bool debugMode,
  required bool define,
  bool debugInAddress = false,
}) => switch (platform) {
  ToolsPlatform.web => define || debugInAddress,
  ToolsPlatform.iOS => define && (debugMode || testFlight),
  ToolsPlatform.android || ToolsPlatform.other => define,
};

/// Whether the developer tools are on in this run.
///
/// Settled by [readDebugTools], from main(), before the first frame. Until
/// then, and under a test, which never runs main(), it is what the build
/// alone can say. On an iPhone release build that is off: the tools never
/// show before the phone has answered.
bool debugToolsOn = debugToolsFor(
  platform: ToolsPlatform.current,
  testFlight: false,
  debugMode: kDebugMode,
  define: kDebugTools,
);

/// Settles [debugToolsOn] for this run. Called once from main(), before the
/// first frame, so the site's address is read before anything can change it.
/// Never throws.
Future<void> readDebugTools() async {
  final ToolsPlatform platform = ToolsPlatform.current;
  // Only an iPhone release build made with the tools on has anything to ask,
  // so only it waits for an answer.
  final bool ask = platform == ToolsPlatform.iOS && kDebugTools && !kDebugMode;
  debugToolsOn = debugToolsFor(
    platform: platform,
    testFlight: ask && await fromTestFlight(),
    debugMode: kDebugMode,
    define: kDebugTools,
    debugInAddress:
        platform == ToolsPlatform.web &&
        Uri.base.queryParameters.containsKey('debug'),
  );
}

/// Where the phone answers (ios/Runner/AppDelegate.swift).
const MethodChannel _install = MethodChannel('astut/install');

/// How long launch waits for that answer. It is a file name the phone already
/// knows, so it comes at once or not at all; this bounds the "not at all",
/// which would otherwise hold back the first frame.
const Duration kTestFlightWait = Duration(milliseconds: 300);

/// Whether the phone says this install came from TestFlight: a sandbox
/// receipt, which a build run from Xcode and the copy App Review installs
/// also carry. False whenever it does not say so in time, or cannot, because
/// tools that failed open would be in front of every reader.
@visibleForTesting
Future<bool> fromTestFlight() async {
  try {
    final bool? said = await _install
        .invokeMethod<bool>('isTestFlight')
        .timeout(kTestFlightWait);
    return said ?? false;
  } catch (_) {
    return false;
  }
}
