// Photographs the app past the onboarding, on a phone rather than in a
// browser.
//
//   flutter test tool/app_shots.dart --update-goldens
//
// Like tool/intro_shots.dart this lives outside test/ so CI never runs it:
// it is a camera, not a check. Both tabs and the paywall are here because a
// screen nobody looks at is a screen nobody notices breaking.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/main.dart';

Future<void> _loadFonts() async {
  const fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons': '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    final bytes = await File(entry.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Future<void> settle(WidgetTester tester) async {
    for (int f = 0; f < 14; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/app-$name.png'),
    );
  }

  testWidgets('the three tabs', (tester) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    await shoot(tester, 'today');

    await tester.tap(find.byKey(const ValueKey('tab-Saved')));
    await settle(tester);
    await shoot(tester, 'saved');

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    await shoot(tester, 'profile');
  });

  testWidgets('a card, opened and answered', (tester) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    // Whatever the day deals, tap the first card through to its answer.
    final card = find.byType(GestureDetector);
    if (card.evaluate().isNotEmpty) {
      await tester.tap(card.first, warnIfMissed: false);
      await settle(tester);
    }
    await shoot(tester, 'card');
  });

  testWidgets('the foot of the profile, where the debug tools live', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await settle(tester);
    await shoot(tester, 'profile-foot');
  });

  testWidgets('the paywall', (tester) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);

    final plans = find.text('SEE THE PLANS');
    expect(plans, findsOneWidget, reason: 'the way into the paywall moved');
    await tester.tap(plans);
    await settle(tester);
    await shoot(tester, 'paywall');
  });
}
