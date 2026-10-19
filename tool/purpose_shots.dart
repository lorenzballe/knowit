// Photographs the purpose family's blocks (docs/explore/purpose.md) on
// their own, the way Explore will draw them: every block at each of its
// sizes, on three phones, at night and on paper.
//
//   flutter test tool/purpose_shots.dart --update-goldens
//   flutter test tool/purpose_shots.dart --update-goldens --dart-define=ONLY=purpose.why
//
// It lives outside test/ so it never runs in CI: this is a camera, not a
// check. The pictures land in tool/shots/gallery/purpose/ (gitignored), to
// be looked at beside the canvas's own designs rather than kept.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/purpose_blocks.dart' as purpose;
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/theme.dart';

import '../test/explore/fake_host.dart';

/// One block, and what to photograph it with.
class _Spec {
  const _Spec(this.block, this.sections, {this.cards, this.play});

  final String block;

  /// What each picture is of — a size, a state — and the section for it.
  final Map<String, Map<String, Object?>> sections;

  /// The cards a section is handed, when the bank's own order would not
  /// show the block at its best.
  final List<Pill> Function()? cards;

  /// Something done to the block before it is photographed, by label.
  final Future<void> Function(WidgetTester tester, String label)? play;
}

Map<String, Map<String, Object?>> _sizes(
  String block,
  List<String> sizes, [
  Map<String, Object?> extra = const {},
]) => {
  for (final String size in sizes)
    size: {'id': '$block-$size', 'block': block, 'size': size, ...extra},
};

/// The blocks, as each is photographed.
final List<_Spec> _specs = [
  _Spec('purpose.read-or-do', {
    ..._sizes('purpose.read-or-do', ['s', 'm', 'l']),
    'one shelf': {
      'id': 'read-or-do-one',
      'block': 'purpose.read-or-do',
      'shelves': [
        {'id': 'myths', 'theme': 'myths'},
      ],
    },
  }),
];

const List<Size> _phones = [Size(375, 667), Size(402, 874), Size(430, 932)];

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

/// A reader a few weeks in: cards read, debates taken, a level measured,
/// so the shelves picked for a reader have someone to pick for.
Future<AppState> _reader() async {
  final List<Pill> bank = PillBank.cards;
  final List<Pill> debates = bank
      .where((p) => p.challenge is TakeASide)
      .take(6)
      .toList();
  final List<String> read = [
    for (int i = 0; i < bank.length; i += 9) bank[i].id,
    ...debates.map((p) => p.id),
  ];
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.seenIds': read,
    'knowit.answersJson': jsonEncode({
      for (int i = 0; i < debates.length; i++) debates[i].id: {'r': '${i % 2}'},
    }),
  });
  ExplorePlay.resetForTest();
  final AppState app = AppState();
  await app.init();
  return app;
}

void main() {
  const String only = String.fromEnvironment('ONLY');
  setUpAll(_loadFonts);

  for (final _Spec spec in _specs) {
    if (only.isNotEmpty && !only.split(',').contains(spec.block)) continue;
    testWidgets(spec.block, (tester) async {
      final AppState app = await tester.runAsync(_reader) as AppState;
      final ExploreBlock block = purpose.blocks.firstWhere(
        (b) => b.name == spec.block,
      );
      for (final MapEntry<String, Map<String, Object?>> shot
          in spec.sections.entries) {
        for (final Size phone in _phones) {
          for (final bool dark in [true, false]) {
            final ExploreSection section = ExploreSection.fromJson(shot.value);
            final FakeExploreHost host = FakeExploreHost(app);
            if (spec.cards != null) host.cards[section.id] = spec.cards!();
            final Key frame = UniqueKey();
            Widget page(double height) => MaterialApp(
              key: frame,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildAstutoTheme(
                dark ? Brightness.dark : Brightness.light,
              ),
              debugShowCheckedModeBanner: false,
              // A page with nothing but the block on it, scrolling as
              // Explore's list does, so the block is laid out at the height
              // it takes there rather than stretched to the phone's.
              home: MediaQuery(
                data: MediaQueryData(size: Size(phone.width, height)),
                child: Builder(
                  builder: (context) => Material(
                    color: context.p.surface,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: KeyedSubtree(
                          key: const ValueKey('shot'),
                          child:
                              block.build(context, host, section) ??
                              const SizedBox(height: 40),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.binding.setSurfaceSize(Size(phone.width, 3200));
            await tester.pumpWidget(page(3200));
            await tester.pump(const Duration(milliseconds: 400));
            if (spec.play != null) await spec.play!(tester, shot.key);
            final double h =
                tester.getSize(find.byKey(const ValueKey('shot'))).height + 36;
            await tester.binding.setSurfaceSize(Size(phone.width, h));
            await tester.pumpWidget(page(h));
            for (int f = 0; f < 6; f++) {
              await tester.pump(const Duration(milliseconds: 120));
            }
            final String name =
                '${spec.block.replaceFirst('purpose.', '')}-'
                '${shot.key.replaceAll(' ', '_')}-${phone.width.round()}-'
                '${dark ? 'dark' : 'light'}';
            await expectLater(
              find.byType(MaterialApp).first,
              matchesGoldenFile('shots/gallery/purpose/$name.png'),
            );
          }
        }
      }
      await tester.binding.setSurfaceSize(null);
    });
  }
}
