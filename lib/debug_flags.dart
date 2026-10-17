import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Temporary developer tools, shown at the bottom of the profile.
///
/// Off unless a build asks for them with `--dart-define=DEBUG_TOOLS=true`.
/// They can switch Astute+ on without a purchase, so a build that forgets
/// the flag is a build without them: the App Store review build, the Google
/// Play build, the site and every test. Only the TestFlight builds ask
/// (codemagic.yaml's "iOS · TestFlight", and .github/workflows/
/// ios-testflight.yml), and on an iPhone even they show the tools only to an
/// install from TestFlight ([readDebugTools]) — but the copy App Review
/// installs carries a sandbox receipt too, so a TestFlight build is never
/// the one submitted for review. The site, built without them, still shows
/// them for a visit whose address says `?debug` (see [debugToolsFor]). A
/// developer running the app asks for them the same way: `flutter run
/// --dart-define=DEBUG_TOOLS=true`.
const bool kDebugTools = bool.fromEnvironment('DEBUG_TOOLS');

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
/// - A build made without `DEBUG_TOOLS=true` ([define]) — which is every
///   build that does not ask — has none, everywhere but on the site, which
///   still turns them on for a visit whose address says `?debug`
///   ([debugInAddress]): that is how they are used from a browser without
///   being shown to everyone who opens it.
/// - A build made with them has them in debug ([debugMode]).
/// - An iPhone release build made with them has them only when the phone
///   says it was installed from TestFlight ([testFlight]).
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
    testFlight: ask && await testFlightOnce(),
    debugMode: kDebugMode,
    define: kDebugTools,
    debugInAddress:
        platform == ToolsPlatform.web &&
        Uri.base.queryParameters.containsKey('debug'),
  );
}

/// Where the phone answers (ios/Runner/AppDelegate.swift, and on Android
/// MainActivity.kt, which says where the app was installed from).
const MethodChannel kInstallChannel = MethodChannel('astut/install');

/// The phone's answer about TestFlight, asked at most once a run and
/// shared: the developer tools and the measurement of where this install
/// came from (lib/measure/install.dart) both want it, and the second need
/// not wait for it again.
Future<bool> testFlightOnce() => _testFlight ??= fromTestFlight();
Future<bool>? _testFlight;

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
    final bool? said = await kInstallChannel
        .invokeMethod<bool>('isTestFlight')
        .timeout(kTestFlightWait);
    return said ?? false;
  } catch (_) {
    return false;
  }
}
