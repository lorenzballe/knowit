// Renders the onboarding to PNGs, on a phone rather than in a browser.
//
//   flutter test tool/intro_shots.dart --update-goldens
//
// It lives outside test/ so it never runs in CI: this is a camera, not a
// check. The point is the MediaQuery below — a notch and a home indicator,
// which a browser window does not have and which is exactly where the layout
// went wrong while every screenshot said it was fine.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/screens/intro_screen.dart';
import 'package:astuto/screens/mix_screen.dart';
import 'package:astuto/theme.dart';

Future<void> _loadFonts() async {
  const fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    // Without this the Apple mark on the button comes out as an empty box,
    // which would be a picture of a fault the app does not have.
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
  const Size phone = Size(402, 874);
  const EdgeInsets insets = EdgeInsets.only(top: 59, bottom: 34);

  setUpAll(_loadFonts);

  testWidgets('the five scenes, on a phone', (tester) async {
    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: const MediaQueryData(size: phone, padding: insets),
          child: IntroScreen(
            onContinue: () {},
            onApple: () async => false,
            onGoogle: () async => false,
            onNotConnected: (_) {},
          ),
        ),
      ),
    );

    // Real image decoding needs real async, which a test clock does not give.
    // Without it the app mark renders as an empty box.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );

    for (int i = 0; i < 5; i++) {
      // Never pumpAndSettle: the ambient loops never end. A few frames is
      // enough to let the entrances play and catch the motion mid-flight.
      for (int f = 0; f < 8; f++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await expectLater(
        find.byType(IntroScreen),
        matchesGoldenFile('shots/intro-$i.png'),
      );
      if (i < 4) {
        await tester.tapAt(const Offset(200, 300));
        await tester.pump(const Duration(milliseconds: 400));
      }
    }
  });

  testWidgets('the mix, on a phone', (tester) async {
    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: const MediaQueryData(size: phone, padding: insets),
          child: MixScreen(onDone: (_) {}),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    for (int f = 0; f < 10; f++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    await expectLater(
      find.byType(MixScreen),
      matchesGoldenFile('shots/mix.png'),
    );
  });
}
