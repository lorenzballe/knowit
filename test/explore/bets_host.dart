// A stand-in Explore for the bets family's tests and camera: the fake host
// every family is tested with, that can also take how sure a bet was and
// count a card read when a shelf showed its answer (BetHost), and, when
// asked, records what it is given into the app's own state the way the
// Explore screen does. And a page that draws sections the way the engine
// will: each through its block, one under another, the ones with nothing to
// show left out.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;

import 'package:astuto/explore/blocks/bets/bet_host.dart';
import 'package:astuto/explore/catalogue.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';

import 'fake_host.dart';

class BetsTestHost extends FakeExploreHost implements BetHost {
  BetsTestHost(
    super.app, {
    super.language,
    super.subject,
    this.records = false,
  });

  /// Whether answers reach the app's state, as on the Explore screen.
  final bool records;

  /// Answers given with how sure: card, response, confidence.
  final List<(String, String, int)> sure = [];

  /// Cards whose answer a shelf showed without one being given.
  final List<(String, String)> revealedCards = [];

  @override
  Future<void> commit(Pill pill, String response) async {
    await super.commit(pill, response);
    if (!records) return;
    await app.recordAnswer(pill.id, response);
    await app.markReadElsewhere(pill.id);
  }

  @override
  Future<void> commitSure(Pill pill, String response, int confidence) async {
    answered.add((pill.id, response));
    sure.add((pill.id, response, confidence));
    if (!records) return;
    await app.recordAnswer(pill.id, response, confidence: confidence);
    await app.markReadElsewhere(pill.id);
  }

  @override
  void revealed(ExploreSection section, Pill pill) {
    revealedCards.add((section.id, pill.id));
    if (records) app.markReadElsewhere(pill.id);
  }
}

/// Sections drawn one under another, as Explore will draw them.
class BetsPage extends StatelessWidget {
  const BetsPage({super.key, required this.host, required this.sections});

  final ExploreHost host;
  final List<ExploreSection> sections;

  @override
  Widget build(BuildContext context) {
    final List<Widget> shown = [];
    for (final ExploreSection s in sections) {
      final ExploreBlock? block = kExploreBlocks[s.block];
      final Widget? w = block?.build(context, host, s);
      if (w == null) continue;
      shown.add(
        RepaintBoundary(
          key: ValueKey('page-${s.id}'),
          child: ColoredBox(
            color: context.p.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: w,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: context.p.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: shown,
        ),
      ),
    );
  }
}

/// The app's frame around [home]: its theme, its words, the phone's size
/// and text size.
Widget betsApp(
  Widget home, {
  Brightness brightness = Brightness.dark,
  Locale locale = const Locale('en'),
  Size? phone,
  double text = 1,
  bool still = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAstutoTheme(brightness),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: phone,
        textScaler: TextScaler.linear(text),
        disableAnimations: still,
      ),
      child: child!,
    ),
    home: home,
  );
}

/// The app's faces, for a picture that shows them rather than boxes.
Future<void> loadBetsFonts() async {
  final Map<String, String> fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final MapEntry<String, String> e in fonts.entries) {
    final FontLoader loader = FontLoader(e.key);
    final Uint8List bytes = await File(e.value).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}
