// Photographs every block of the shapes family (lib/explore/blocks/shapes/)
// at each of its sizes, on three phones, at night and on paper, so each can
// be set beside the canvas's own design of it (docs/explore/shapes.md).
//
//   flutter test tool/shapes_shots.dart --update-goldens
//   flutter test tool/shapes_shots.dart --update-goldens --dart-define=ONLY=shape-fold,shape-torn
//
// A camera, not a check, so it lives outside test/ like the other shots.
// The pictures land in tool/shots/gallery/shapes/ (gitignored), one folder
// per block: <size>-<phone>-<night|paper>.png, and for each of the block's
// other looks (its other signatures, the canvas's other designs of it)
// <size>-<phone>-<night|paper>-<look>.png. The cards are the bank's, the
// canvas's own where the bank has them, so the two can be compared card
// for card.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/shapes/kinds.dart';
import 'package:astuto/explore/blocks/shapes/shelf.dart';
import 'package:astuto/explore/blocks/shapes/vocabulary.dart';
import 'package:astuto/explore/blocks/shapes_blocks.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

import '../test/explore/fake_host.dart';

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

/// The three phones every shape is seen on, with the insets of their
/// notches and home bars.
const Map<String, (Size, EdgeInsets)> _phones = {
  '375': (Size(375, 667), EdgeInsets.only(top: 20)),
  '402': (Size(402, 874), EdgeInsets.only(top: 62, bottom: 34)),
  '430': (Size(430, 932), EdgeInsets.only(top: 59, bottom: 34)),
};

/// The canvas's own cards, by the kind of shelf it put them on, first; the
/// rest of each shelf is the bank's first cards of the kind.
const Map<String, List<String>> _canvas = {
  'myths': [
    'history-ottoman-8',
    'psychology-expectations-3',
    'music-classical-1',
    'pop_culture-celebrity-4',
  ],
  'past': ['cinema-women-directors-2', 'sport-formations-3'],
  'numbers': [
    'human_body-studies-on-mice-2',
    'nature-deep-sea-8',
    'medicine-false-positives-1',
  ],
  'debates': [
    'philosophy-responsibility-9',
    'space-signals-1',
    'economics-subscriptions-10',
  ],
  'place': ['sport-formations-3', 'medicine-symptoms-7', 'food-crust-10'],
  'practical': ['medicine-shared-decisions-4'],
  'paradoxes': ['life-time-3', 'food-espresso-10'],
  'month': ['pop_culture-celebrity-4', 'pop_culture-celebrity-7'],
};

/// The cards a shelf of [block]'s kind is shown with: the canvas's, then
/// the bank's, every one of the kind.
List<Pill> _cardsFor(ShapeBlock block, ExploreSection section) {
  final ShapeAim aim = ShapeAim.of(
    section,
    block.kindFor(section),
    DateTime.now(),
  );
  final bool Function(Pill)? keep = block.keep(section);
  final List<Pill> out = [
    for (final String id in _canvas[aim.kind] ?? const [])
      if (PillBank.byId(id) case final Pill p
          when aim.fits(p) && (keep == null || keep(p)))
        p,
  ];
  for (final Pill p in PillBank.cards) {
    if (out.length >= 24) break;
    if (aim.fits(p) && (keep == null || keep(p)) && !out.contains(p)) {
      out.add(p);
    }
  }
  return out;
}

/// The looks [block] is photographed in, by name: its own (unnamed), each
/// of its other signatures, and the canvas's other designs of it.
Map<String, Map<String, Object?>> _looks(ShapeBlock block) {
  final Map<String, Map<String, Object?>> looks = {'': {}};
  for (final String s in block.words.signatures.skip(1)) {
    looks[s] = {'signature': s};
  }
  // 132b's stamps, stuck on by hand; 131e's checklist, a ring on every row.
  if (block.name == 'shape-stamp') {
    looks['tilt'] = {
      'style': {'tilt': true},
    };
  }
  if (block.name == 'shape-checklist') {
    looks['none'] = {
      'signature': 'none',
      'style': {'rings': 'all'},
    };
  }
  return looks;
}

/// The section a block is shown in: its own kind, at [size], in [look],
/// aimed as the canvas aimed it — the last century, Europe, the month of
/// Pop culture.
ExploreSection _section(
  ShapeBlock block,
  String size,
  Map<String, Object?> look,
) {
  final String kind = block.words.kindWith(
    look['signature'] as String? ?? block.words.signatures.first,
  );
  final Map<String, Object?> json = {
    'id': block.name,
    'block': block.name,
    'size': size,
    if (kind == 'past' || kind == 'place') 'variant': 2,
    if (kind == 'month') 'subject': 'pop_culture',
    ...look,
  };
  return ExploreSection.fromJson(json);
}

/// What is photographed: the whole phone, painted twice as large.
const ValueKey<String> _shot = ValueKey('shapes-shot');

void main() {
  setUpAll(_loadFonts);

  const String only = String.fromEnvironment('ONLY');
  final Set<String> wanted = only.isEmpty ? {} : only.split(',').toSet();

  for (final ExploreBlock b in blocks) {
    final ShapeBlock block = b as ShapeBlock;
    if (wanted.isNotEmpty && !wanted.contains(block.name)) continue;
    testWidgets(block.name, (tester) async {
      for (final MapEntry<String, Map<String, Object?>> look in _looks(
        block,
      ).entries) {
        for (final String size in kShapeSizes) {
          for (final MapEntry<String, (Size, EdgeInsets)> phone
              in _phones.entries) {
            for (final Brightness light in Brightness.values) {
              final (Size screen, EdgeInsets insets) = phone.value;
              // A golden is taken at one pixel a point. The phone is laid out
              // at its own size and painted twice as large, so the picture
              // has the detail of a real screen to judge an edge by.
              tester.view.physicalSize = screen * 2;
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);

              final ExploreSection section = _section(block, size, look.value);
              final AppState app = AppState();
              final FakeExploreHost host = FakeExploreHost(app);
              host.cards[section.id] = _cardsFor(block, section);
              // One card read, to show its tick where the shape puts it.
              app.seenIds = {host.cards[section.id]![1].id};

              await tester.pumpWidget(
                RepaintBoundary(
                  key: _shot,
                  child: Transform.scale(
                    scale: 2,
                    alignment: Alignment.topLeft,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: screen.width,
                      maxWidth: screen.width,
                      minHeight: screen.height,
                      maxHeight: screen.height,
                      child: MaterialApp(
                        debugShowCheckedModeBanner: false,
                        localizationsDelegates:
                            AppLocalizations.localizationsDelegates,
                        supportedLocales: AppLocalizations.supportedLocales,
                        theme: buildAstutoTheme(light),
                        home: MediaQuery(
                          data: MediaQueryData(size: screen, padding: insets),
                          child: Scaffold(
                            body: Builder(
                              builder: (context) => ListView(
                                padding: EdgeInsets.only(top: insets.top + 14),
                                children: [
                                  block.build(context, host, section) ??
                                      const SizedBox.shrink(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              for (int f = 0; f < 6; f++) {
                await tester.pump(const Duration(milliseconds: 100));
              }
              final String theme = light == Brightness.dark ? 'night' : 'paper';
              await expectLater(
                find.byKey(_shot),
                matchesGoldenFile(
                  'shots/gallery/shapes/${block.name}/'
                  '$size-${phone.key}-$theme'
                  '${look.key.isEmpty ? '' : '-${look.key}'}.png',
                ),
              );
            }
          }
        }
      }
    });
  }
}
