import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/debug_flags.dart';

/// The platforms a build is made for, as opposed to the site.
const List<ToolsPlatform> _builds = [
  ToolsPlatform.iOS,
  ToolsPlatform.android,
  ToolsPlatform.other,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('who gets the developer tools', () {
    test('a build that does not ask for them has none', () {
      // This one: the tests are built without DEBUG_TOOLS, as the App Store
      // build, the Google Play build and the site are.
      expect(kDebugTools, isFalse);
      expect(debugToolsOn, isFalse);
    });

    test('a build without DEBUG_TOOLS=true has none, whatever else is '
        'true', () {
      for (final ToolsPlatform platform in _builds) {
        for (final bool testFlight in const [false, true]) {
          for (final bool debugMode in const [false, true]) {
            expect(
              debugToolsFor(
                platform: platform,
                testFlight: testFlight,
                debugMode: debugMode,
                define: false,
              ),
              isFalse,
              reason: '$platform, TestFlight $testFlight, debug $debugMode',
            );
          }
        }
      }
    });

    test('a debug build made with them has them everywhere', () {
      for (final ToolsPlatform platform in ToolsPlatform.values) {
        expect(
          debugToolsFor(
            platform: platform,
            testFlight: false,
            debugMode: true,
            define: true,
          ),
          isTrue,
          reason: '$platform',
        );
      }
    });

    test('an iPhone release build made with them has them from TestFlight '
        'and nowhere else', () {
      // A TestFlight build, made with DEBUG_TOOLS=true: only where it was
      // installed from says whether to show them.
      expect(
        debugToolsFor(
          platform: ToolsPlatform.iOS,
          testFlight: true,
          debugMode: false,
          define: true,
        ),
        isTrue,
      );
      expect(
        debugToolsFor(
          platform: ToolsPlatform.iOS,
          testFlight: false,
          debugMode: false,
          define: true,
        ),
        isFalse,
      );
    });

    test('Android has whatever it was built with', () {
      // Built with DEBUG_TOOLS=true, as a tester's build would be.
      expect(
        debugToolsFor(
          platform: ToolsPlatform.android,
          testFlight: false,
          debugMode: false,
          define: true,
        ),
        isTrue,
      );
      // The build for Google Play, made without it.
      expect(
        debugToolsFor(
          platform: ToolsPlatform.android,
          testFlight: false,
          debugMode: false,
          define: false,
        ),
        isFalse,
      );
    });

    test('the site keeps ?debug', () {
      // Built without them, as deploy.yml builds it: off for everyone who
      // opens it...
      expect(
        debugToolsFor(
          platform: ToolsPlatform.web,
          testFlight: false,
          debugMode: false,
          define: false,
        ),
        isFalse,
      );
      // ...and on for a visit whose address asks.
      expect(
        debugToolsFor(
          platform: ToolsPlatform.web,
          testFlight: false,
          debugMode: false,
          define: false,
          debugInAddress: true,
        ),
        isTrue,
      );
      // Built with them, on for everyone.
      expect(
        debugToolsFor(
          platform: ToolsPlatform.web,
          testFlight: false,
          debugMode: false,
          define: true,
        ),
        isTrue,
      );
    });

    test('the address counts only on the site, and TestFlight only on an '
        'iPhone', () {
      for (final ToolsPlatform platform in _builds) {
        expect(
          debugToolsFor(
            platform: platform,
            testFlight: false,
            debugMode: false,
            define: false,
            debugInAddress: true,
          ),
          isFalse,
          reason: '$platform',
        );
      }
      // An iPhone release build is not turned on by an address either.
      expect(
        debugToolsFor(
          platform: ToolsPlatform.iOS,
          testFlight: false,
          debugMode: false,
          define: true,
          debugInAddress: true,
        ),
        isFalse,
      );
      // A browser on an iPhone is still the site.
      expect(
        debugToolsFor(
          platform: ToolsPlatform.web,
          testFlight: true,
          debugMode: false,
          define: false,
        ),
        isFalse,
      );
    });
  });

  group('asking the phone', () {
    const MethodChannel channel = MethodChannel('astut/install');
    final TestDefaultBinaryMessenger messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('a phone that says TestFlight is believed', () async {
      final List<String> asked = [];
      messenger.setMockMethodCallHandler(channel, (call) async {
        asked.add(call.method);
        return true;
      });
      expect(await fromTestFlight(), isTrue);
      expect(asked, ['isTestFlight']);
    });

    test('an install from the App Store says no', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => false);
      expect(await fromTestFlight(), isFalse);
    });

    test('no channel, an error or an empty answer is a no', () async {
      // Nothing behind the channel, as on a build without it.
      expect(await fromTestFlight(), isFalse);

      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'broken'),
      );
      expect(await fromTestFlight(), isFalse);

      messenger.setMockMethodCallHandler(channel, (call) async => null);
      expect(await fromTestFlight(), isFalse);
    });

    test('a phone that never answers is a no, and holds launch only for '
        'the wait', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) => Completer<Object?>().future,
      );
      final Stopwatch took = Stopwatch()..start();
      expect(await fromTestFlight(), isFalse);
      expect(took.elapsed, greaterThanOrEqualTo(kTestFlightWait));
      expect(took.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('a build that did not ask for them settles without asking, and '
        'has none', () async {
      // A debug build made without DEBUG_TOOLS, as the tests are: the phone
      // is not asked, since nothing it said could turn the tools on.
      expect(kDebugMode, isTrue, reason: 'tests run as a debug build');
      expect(kDebugTools, isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var asked = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        asked = true;
        return true;
      });

      await readDebugTools();

      expect(asked, isFalse);
      expect(debugToolsOn, isFalse);
    });
  });

  test('each platform is the one the tools think it is', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final (TargetPlatform target, ToolsPlatform tools) in const [
      (TargetPlatform.iOS, ToolsPlatform.iOS),
      (TargetPlatform.android, ToolsPlatform.android),
      (TargetPlatform.macOS, ToolsPlatform.other),
      (TargetPlatform.windows, ToolsPlatform.other),
      (TargetPlatform.linux, ToolsPlatform.other),
      (TargetPlatform.fuchsia, ToolsPlatform.other),
    ]) {
      debugDefaultTargetPlatformOverride = target;
      expect(ToolsPlatform.current, tools, reason: '$target');
    }
  });
}
