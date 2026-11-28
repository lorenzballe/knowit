// Photographs the card after the last of a long deck read again
// (lib/screens/deck_viewer_screen.dart, DeckEnd): Explore's hundred and fifty,
// at night and on paper (deck-end-dark, deck-end-light), and a short deck of
// five beside them (deck-end-short-dark).
//
//   SHOTS=/some/folder LANG_SHOT=it flutter test tool/deck_end_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. SHOTS is
// where the pictures go (tool/shots by default); LANG_SHOT is the phone's
// language, English when not given.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
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
  setUpAll(() async {
    await _loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
  });

  final String out = Platform.environment['SHOTS'] ?? 'shots';
  final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'en');

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Brightness brightness,
    int cards,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(
      top: 47 * 3,
      bottom: 34 * 3,
    );
    addTearDown(tester.view.reset);
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    final AppState app = await tester.runAsync(() async {
      final AppState a = AppState();
      await a.init();
      return a;
    }) as AppState;
    // A deck as Explore's flow deals it: subjects mixed, as read.
    final List<Pill> all = PillBank.cards;
    final List<Pill> deck = [
      for (int i = 0; i < cards; i++) all[(i * 37) % all.length],
    ];
    debugDisableShadows = false;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(brightness),
        home: DeckViewerScreen(
          app: app,
          deck: deck,
          title: 'Explore',
          initialIndex: deck.length,
        ),
      ),
    );
    for (int f = 0; f < 20; f++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('$out/$name.png'),
    );
    await tester.pumpWidget(const SizedBox());
    debugDisableShadows = true;
  }

  testWidgets('deck-end', (tester) async {
    await shoot(tester, 'deck-end-dark', Brightness.dark, 150);
    await shoot(tester, 'deck-end-light', Brightness.light, 150);
    await shoot(tester, 'deck-end-short-dark', Brightness.dark, 5);
  });
}
