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
    test('DEBUG_TOOLS=false takes them out of every build, whatever else is '
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

    test('a debug build has them everywhere', () {
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

    test('an iPhone release build has them from TestFlight and nowhere '
        'else', () {
      // The binary testers get is the one the App Store gets, built the same
      // way: only where it was installed from tells them apart.
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
      // Built as it is by default: on, in release as before.
      expect(
        debugToolsFor(
          platform: ToolsPlatform.android,
          testFlight: false,
          debugMode: false,
          define: true,
        ),
        isTrue,
      );
      // The build for Google Play, made with DEBUG_TOOLS=false.
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
      // Built with DEBUG_TOOLS=false, as deploy.yml builds it: off for
      // everyone who opens it...
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
      // Built without it, on as before.
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

    test('a debug build settles without asking', () async {
      expect(kDebugMode, isTrue, reason: 'tests run as a debug build');
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var asked = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        asked = true;
        return false;
      });

      await readDebugTools();

      expect(asked, isFalse);
      expect(debugToolsOn, isTrue);
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
