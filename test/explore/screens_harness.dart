// What the tests of the whole-screen blocks share: a reader on a phone with
// nothing on it but what a test puts there, the faces the app ships, and a
// block pumped on its own on a phone of a given width, at night or on
// paper, at a given text size.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/screens/memory.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

import 'fake_host.dart';

/// The faces the app ships, so a block that would overflow on a phone
/// overflows here too, and not only in the test font.
Future<void> loadScreensFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final face in fonts.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

/// A reader whose phone holds [stored] and nothing else, with the screens'
/// own store fresh and open.
Future<AppState> screensReader([Map<String, Object> stored = const {}]) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...stored});
  ScreensMemory.resetForTest();
  final AppState app = AppState();
  await app.init();
  await ScreensMemory.instance.ready();
  return app;
}

/// A section as the document would give it.
ExploreSection screensSection(
  String block, [
  Map<String, Object?> more = const {},
]) => ExploreSection.fromJson({'id': 'x', 'block': block, ...more});

/// The bank's live cards that pass [test], in the bank's order.
List<Pill> bankWhere(bool Function(Pill) test, {int most = 400}) =>
    PillBank.cards.where(test).take(most).toList();

/// Pumps what [block] draws for [section] on a phone [width] wide, inside a
/// page that scrolls, as Explore's does. Returns whether the block drew
/// anything at all.
Future<bool> pumpBlock(
  WidgetTester tester,
  ExploreBlock block,
  ExploreSection section,
  FakeExploreHost host, {
  double width = 402,
  double height = 900,
  bool paper = false,
  double text = 1,
  String language = 'en',
}) async {
  tester.view.physicalSize = Size(width, height) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  bool drew = false;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAstutoTheme(paper ? Brightness.light : Brightness.dark),
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(text)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Builder(
                  builder: (context) {
                    final Widget? w = block.build(context, host, section);
                    drew = w != null;
                    return w ?? const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  return drew;
}

/// Lets what was tapped settle.
Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
