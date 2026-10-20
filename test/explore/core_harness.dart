// What the tests of Explore's engine and core blocks share: the app's own
// faces, so a question is measured as a reader sees it; a reader past the
// first run; a host that deals cards from the sources as the screen does;
// and a page of sections drawn by the engine on a phone of a given size.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/explore/blocks/core/shelves.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/explore_engine.dart';

import 'fake_host.dart';

/// The faces the app ships, and its icons.
Future<void> loadFonts() async {
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

/// A reader past the first run, with [prefs] besides. The remote document
/// is asked of nobody: a test's Explore is the one it adopts.
Future<AppState> readyApp([
  Map<String, Object> prefs = const {},
  DateTime Function()? clock,
]) async {
  Remote.fetch = (_) async => null;
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final app = AppState(
    hasPermission: () async => false,
    askPermission: () async => false,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
    clock: clock,
  );
  await app.init();
  return app;
}

/// The stand-in host, dealing every section's cards from its source as the
/// screen deals them, unless a test hands a section its own.
class CoreHost extends FakeExploreHost {
  CoreHost(super.app, {super.language, super.subject});

  @override
  List<Pill> cardsFor(ExploreSection section, {int? limit}) {
    final List<Pill>? given = cards[section.id];
    if (given != null) {
      return given.take(limit ?? section.limit ?? given.length).toList();
    }
    return ExploreShelves.of(this).cardsFor(section, limit: limit);
  }
}

/// Sections read from [json].
List<ExploreSection> sectionsOf(List<Map<String, Object?>> json) => [
  for (final Map<String, Object?> section in json)
    ExploreSection.fromJson(section),
];

/// Draws [sections] for [host] as the engine does, on a phone of [size], at
/// [text] times the text size, at night or on paper, with motion or without.
Future<void> pumpSections(
  WidgetTester tester,
  ExploreHost host,
  List<ExploreSection> sections, {
  Size size = const Size(375, 667),
  double text = 1,
  bool paper = false,
  bool calm = false,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(paper ? Brightness.light : Brightness.dark),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(text),
            disableAnimations: calm,
          ),
          child: Scaffold(
            body: Builder(
              builder: (context) => CustomScrollView(
                slivers: [
                  ExploreSliver(
                    host: host,
                    slots: exploreSlots(
                      context,
                      host,
                      sections,
                      host.app.remoteContext(host.language),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}
