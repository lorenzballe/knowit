import 'dart:io';

import 'package:astuto/utils/upright.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app is held upright on a phone. Three places say so, and each one
/// alone lets a phone turn it on its side if it forgets: the iPhone's
/// Info.plist, Android's manifest, and Flutter itself.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The strings in the array right after [key] in a plist.
  List<String> plistArray(String plist, String key) {
    final RegExpMatch? found = RegExp(
      '<key>${RegExp.escape(key)}</key>\\s*<array>(.*?)</array>',
      dotAll: true,
    ).firstMatch(plist);
    expect(found, isNotNull, reason: '$key is missing from Info.plist');
    return RegExp(r'<string>([^<]+)</string>')
        .allMatches(found!.group(1)!)
        .map((m) => m.group(1)!)
        .toList();
  }

  test('an iPhone holds the app upright, and only upright', () {
    final String plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plistArray(plist, 'UISupportedInterfaceOrientations'), [
      'UIInterfaceOrientationPortrait',
    ]);
  });

  test('an iPad keeps every orientation, as iPadOS requires', () {
    final String plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      plistArray(plist, 'UISupportedInterfaceOrientations~ipad'),
      containsAll([
        'UIInterfaceOrientationPortrait',
        'UIInterfaceOrientationPortraitUpsideDown',
        'UIInterfaceOrientationLandscapeLeft',
        'UIInterfaceOrientationLandscapeRight',
      ]),
    );
  });

  test("Android's main activity is held upright", () {
    final String manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final RegExpMatch? activity = RegExp(
      r'<activity\b[^>]*android:name="\.MainActivity"[^>]*>',
      dotAll: true,
    ).firstMatch(manifest);
    expect(activity, isNotNull);
    expect(
      activity!.group(0),
      contains('android:screenOrientation="portrait"'),
    );
  });

  test('Flutter is told to keep the app upright', () async {
    final List<Object?> asked = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            asked.add(call.arguments);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await holdUpright();

    expect(asked, [
      ['DeviceOrientation.portraitUp'],
    ]);
  });

  test('holding upright never throws where nothing answers', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          throw PlatformException(code: 'unavailable');
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await expectLater(holdUpright(), completes);
  });
}
