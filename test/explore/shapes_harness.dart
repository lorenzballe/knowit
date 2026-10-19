// What the shapes family's tests share: the app's own faces, so a question
// is fitted as a reader's phone fits it; a block pumped alone on a phone of
// any width, at any text size, in either paper, with a host that writes down
// everything it is asked; and cards to feed it.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/shapes/kinds.dart';
import 'package:astuto/explore/blocks/shapes/shelf.dart';
import 'package:astuto/explore/blocks/shapes_blocks.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

import 'fake_host.dart';

/// Every block of the family, as the shapes they are.
List<ShapeBlock> get shapeBlocks => blocks.cast<ShapeBlock>();

/// The block named [name].
ShapeBlock shapeNamed(String name) =>
    shapeBlocks.firstWhere((b) => b.name == name);

/// Loads Fraunces and Figtree, and the icons, once for a file.
Future<void> loadShapeFonts() async {
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

/// The bank's cards of the kind [block] keeps to, as its section aims it,
/// that it can draw.
List<Pill> cardsOfKind(ShapeBlock block, ExploreSection section, {int n = 12}) {
  final ShapeAim aim = ShapeAim.of(
    section,
    block.kindFor(section),
    DateTime.now(),
  );
  final bool Function(Pill)? keep = block.keep(section);
  return PillBank.cards
      .where((p) => aim.fits(p) && (keep == null || keep(p)))
      .take(n)
      .toList();
}

/// What a block was given and what it drew.
class Pumped {
  Pumped(this.host, this.section, this.drawn);

  final FakeExploreHost host;
  final ExploreSection section;

  /// Whether the block drew anything at all.
  final bool drawn;
}

/// Pumps [block] alone on a phone [width] wide, its section [json] (beside
/// an id of `x` and its own name), the host holding [cards] for it, the
/// reader having read [read].
Future<Pumped> pumpShape(
  WidgetTester tester,
  ShapeBlock block, {
  Map<String, Object?> json = const {},
  List<Pill>? cards,
  Set<String> read = const {},
  Brightness theme = Brightness.dark,
  double width = 375,
  double height = 900,
  double scale = 1,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ExploreSection section = ExploreSection.fromJson({
    'id': 'x',
    'block': block.name,
    ...json,
  });
  final AppState app = AppState()..seenIds = {...read};
  final FakeExploreHost host = FakeExploreHost(
    app,
    language: locale.languageCode,
  );
  if (cards != null) host.cards['x'] = cards;
  bool drawn = false;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(theme),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: Size(width, height),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                final Widget? shelf = block.build(context, host, section);
                drawn = shelf != null;
                return ListView(
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  children: [shelf ?? const SizedBox.shrink()],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return Pumped(host, section, drawn);
}
