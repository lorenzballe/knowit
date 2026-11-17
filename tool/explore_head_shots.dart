// The Explore screen as a phone shows it, at the top and once the reader has
// gone down the shelves: the head (title, streak, search, subjects) in view,
// then put away so the cards have the screen.
//
//   SHOTS=shots flutter test tool/explore_head_shots.dart --update-goldens
//
// LANG_SHOT (Italian by default) picks the language.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/sync/trace.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/core_harness.dart';
import '../test/web/thumbs_harness.dart' show onePixel;

void main() {
  setUpAll(loadFonts);

  testWidgets('explore, at the top and down the shelves', (tester) async {
    final String out = Platform.environment['SHOTS'] ?? 'shots';
    final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'it');
    Analytics.useForTest(null);
    Trace.useForTest(Trace());
    Served.useForTest(Served());
    // No network in a camera: pictures stay as their drawn stand-ins.
    CardThumb.image = (url) => onePixel;
    final app = await readyApp();
    tester.view.physicalSize = const Size(402, 874) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(child: ExploreScreen(app: app)),
        ),
      ),
    );
    for (int f = 0; f < 10; f++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('$out/explore-top.png'),
    );
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -700),
    );
    for (int f = 0; f < 10; f++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('$out/explore-down.png'),
    );
  });
}
