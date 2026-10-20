// Every block of the purpose family on its own: in the catalogue, drawn at
// each of its sizes at night and on paper, with larger text at the
// narrowest phone, nothing at all when it has no cards, and a tap on a card
// opening it.
//
//   flutter test test/explore/purpose_blocks_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/explore/blocks/purpose_blocks.dart' as purpose;
import 'package:astuto/explore/catalogue.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/state/app_state.dart';

import 'fake_host.dart';
import 'purpose_harness.dart';

void main() {
  test('every block of the family is in the catalogue, once, by its name', () {
    final List<String> names = [for (final b in purpose.blocks) b.name];
    expect(names.toSet().length, names.length);
    expect(names.toSet(), kPurposeSizes.keys.toSet());
    for (final String name in names) {
      expect(name, startsWith('purpose.'));
      expect(kExploreBlocks[name]?.name, name);
    }
  });

  for (final ExploreBlock block in purpose.blocks) {
    group(block.name, () {
      testWidgets('alone, at every size, at night and on paper', (
        tester,
      ) async {
        final AppState app = await tester.runAsync(purposeReader) as AppState;
        final List<String?> sizes = [null, ...kPurposeSizes[block.name]!];
        for (final String? size in sizes) {
          for (final bool dark in [true, false]) {
            for (final double width in [375.0, 430.0]) {
              final FakeExploreHost host = FakeExploreHost(app);
              final Built built = await pumpPurpose(
                tester,
                block,
                host,
                purposeSection(block.name, {'size': ?size}),
                dark: dark,
                width: width,
              );
              expect(built.widget, isNotNull, reason: '$size $dark');
              expect(tester.takeException(), isNull, reason: '$size $dark');
            }
          }
        }
      });

      testWidgets('with the text a size up, at the narrowest phone', (
        tester,
      ) async {
        final AppState app = await tester.runAsync(purposeReader) as AppState;
        for (final String? size in [null, ...kPurposeSizes[block.name]!]) {
          await pumpPurpose(
            tester,
            block,
            FakeExploreHost(app),
            purposeSection(block.name, {'size': ?size}),
            width: 375,
            scale: 1.3,
          );
          expect(tester.takeException(), isNull, reason: '$size');
        }
      });

      testWidgets(
        kWordsOnly.contains(block.name)
            ? 'says its words whatever the cards'
            : 'is left out with no cards',
        (tester) async {
          final AppState app = await tester.runAsync(purposeReader) as AppState;
          final FakeExploreHost host = FakeExploreHost(app)
            ..cards['x'] = const [];
          final Built built = await pumpPurpose(
            tester,
            block,
            host,
            purposeSection(block.name),
          );
          if (kWordsOnly.contains(block.name)) {
            expect(built.widget, isNotNull);
          } else {
            expect(built.widget, isNull);
          }
          expect(host.shown, isEmpty);
        },
      );
    });
  }

  testWidgets('a tap on a card opens it, from every block that shows cards', (
    tester,
  ) async {
    final AppState app = await tester.runAsync(purposeReader) as AppState;
    for (final ExploreBlock block in purpose.blocks) {
      final FakeExploreHost host = FakeExploreHost(app);
      final ExploreSection section = purposeSection(block.name, {
        // Cards under the chips come once a part of life is picked.
        if (block.name == 'purpose.life-topics') 'id': 'x',
      });
      await pumpPurpose(tester, block, host, section);
      if (block.name == 'purpose.life-topics') {
        await tester.tap(find.byKey(const ValueKey('life-money-off')));
        await tester.pump(const Duration(milliseconds: 200));
      }
      final Finder cards = keyedLike((k) => k.startsWith('explore-'));
      final Finder rings = keyedLike((k) => k.startsWith('sets-'));
      if (cards.evaluate().isEmpty && rings.evaluate().isEmpty) {
        expect(
          {
            ...kWordsOnly,
            'purpose.played',
            'purpose.tomorrow',
          }.contains(block.name),
          isTrue,
          reason: '${block.name} shows no card to open',
        );
        continue;
      }
      if (cards.evaluate().isNotEmpty) {
        final String id =
            (cards.first.evaluate().first.widget.key! as ValueKey<String>).value
                .substring('explore-'.length);
        await tapCard(tester, cards.first);
        expect(host.opened.map((o) => o.$2), contains(id), reason: block.name);
        // A card opened from a shelf is a card the shelf said it showed.
        expect(host.shown.map((s) => s.$2), contains(id), reason: block.name);
      } else {
        // A set's ring shows no card: it opens the first of the set not
        // yet read.
        await tester.tap(rings.first);
        await tester.pump(const Duration(milliseconds: 200));
        expect(host.opened, hasLength(1), reason: block.name);
        expect(app.seenIds, isNot(contains(host.opened.single.$2)));
      }
    }
  });

  testWidgets('a section names its own title and line, per language', (
    tester,
  ) async {
    final AppState app = await tester.runAsync(purposeReader) as AppState;
    await pumpPurpose(
      tester,
      purposeBlock('purpose.why'),
      FakeExploreHost(app, language: 'it'),
      purposeSection('purpose.why', {
        'title': {'en': 'Why', 'it': 'Ecco perché'},
        'subtitle': 'Una riga',
      }),
    );
    expect(find.text('Ecco perché'), findsOneWidget);
    expect(find.text('Una riga'), findsOneWidget);
  });
}
