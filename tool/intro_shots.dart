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

void _nothing(Map<String, double> _) {}

void _noop() {}
Future<bool> _no() async => false;
void _ignore(String _) {}

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

  testWidgets('the five scenes, on a 390 by 844 handset', (tester) async {
    const Size small = Size(390, 844);
    await tester.binding.setSurfaceSize(small);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: const MediaQuery(
          data: MediaQueryData(
            size: small,
            padding: EdgeInsets.only(top: 47, bottom: 34),
          ),
          child: IntroScreen(
            onContinue: _noop,
            onApple: _no,
            onGoogle: _no,
            onNotConnected: _ignore,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    for (int f = 0; f < 10; f++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    for (int scene = 0; scene < 5; scene++) {
      if (scene > 0) {
        await tester.fling(
          find.byType(IntroScreen),
          const Offset(-300, 0),
          900,
        );
        for (int f = 0; f < 10; f++) {
          await tester.pump(const Duration(milliseconds: 120));
        }
      }
      await expectLater(
        find.byType(IntroScreen),
        matchesGoldenFile('shots/p390-$scene.png'),
      );
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

  testWidgets('the mix on a short phone', (tester) async {
    // An SE. Nine rows have to share a much smaller middle, and the rule is
    // that they get shorter — never that the page starts scrolling.
    const Size small = Size(375, 667);
    await tester.binding.setSurfaceSize(small);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: const MediaQuery(
          data: MediaQueryData(size: small, padding: EdgeInsets.only(top: 20)),
          child: MixScreen(onDone: _nothing),
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
      matchesGoldenFile('shots/mix-short.png'),
    );
  });

  testWidgets('the mix, turned down', (tester) async {
    // The state the empty half has to be judged in: some subjects at about
    // half, one at nothing. A glow bleeding through a see-through tile only
    // shows here, never on the all-full screen.
    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: const MediaQueryData(size: phone, padding: insets),
          child: MixScreen(onDone: _nothing),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    for (int f = 0; f < 10; f++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    Future<void> setTo(String name, double fraction) async {
      final Rect tile = tester.getRect(find.text(name));
      // The label starts 14 + tick + 7 in from the tile's left edge; walk
      // back to the tile and take the fraction across its width.
      final double left = tile.left - 33;
      const double width = 178;
      await tester.tapAt(Offset(left + width * fraction, tile.center.dy));
      await tester.pump(const Duration(milliseconds: 200));
    }

    await setTo('Music', 0.5);
    await setTo('Cinema', 0.28);
    await setTo('Medicine', 0.72);
    await setTo('Sport', 0.0);
    for (int f = 0; f < 6; f++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    await expectLater(
      find.byType(MixScreen),
      matchesGoldenFile('shots/mix-down.png'),
    );
  });
}
