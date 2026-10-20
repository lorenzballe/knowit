// Every block of the shapes family, on its own with a stand-in host: it
// draws its kind of card and no other, names its shelf for them, opens a
// card the way every shelf does, says which cards it showed, draws nothing
// at all when it has nothing to show, and stands at every size on both
// papers without a fault.
//
//   flutter test test/explore/shapes_blocks_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/shapes/kinds.dart';
import 'package:astuto/explore/blocks/shapes/vocabulary.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/models/pill.dart';

import 'shapes_harness.dart';

/// The section a block is tried in: aimed as the canvas aimed it, so its
/// kind has cards in the bank.
Map<String, Object?> _aimed(String kind) => {
  if (kind == 'past' || kind == 'place') 'variant': 2,
  if (kind == 'month') 'subject': 'pop_culture',
};

void main() {
  setUpAll(loadShapeFonts);

  for (final block in shapeBlocks) {
    final String kind = block.words.kind;
    final ExploreSection section = ExploreSection.fromJson({
      'id': 'x',
      'block': block.name,
      ..._aimed(kind),
    });

    testWidgets('${block.name} draws its kind and opens a card', (
      tester,
    ) async {
      final ShapeAim aim = ShapeAim.of(section, kind, DateTime.now());
      // Its own kind, and one card of another mixed in, which it leaves out.
      final List<Pill> own = cardsOfKind(block, section);
      final Pill stranger = PillBank.cards.firstWhere((p) => !aim.fits(p));
      final Pumped run = await pumpShape(
        tester,
        block,
        json: _aimed(kind),
        cards: [own.first, stranger, ...own.skip(1)],
      );
      expect(run.drawn, isTrue);
      expect(tester.takeException(), isNull);

      final BuildContext context = tester.element(find.byType(Scaffold));
      expect(find.text(aim.title(context)!), findsOneWidget);
      final shown = run.host.shown.map((s) => s.$2).toSet();
      expect(shown, isNotEmpty);
      expect(shown, isNot(contains(stranger.id)));
      for (final id in shown) {
        expect(aim.fits(PillBank.byId(id)!), isTrue, reason: id);
      }

      // The card in front: a hand's is the last of its fan.
      final List<String> order = [for (final s in run.host.shown) s.$2];
      final String tapped = block.name == 'shape-hand'
          ? order.last
          : order.firstWhere(
              (id) => find
                  .byKey(ValueKey('explore-$id'))
                  .hitTestable()
                  .evaluate()
                  .isNotEmpty,
            );
      await tester.tap(find.byKey(ValueKey('explore-$tapped')).hitTestable());
      await tester.pump();
      expect(run.host.opened, contains(('x', tapped)));
    });

    testWidgets('${block.name} draws nothing when it has nothing to show', (
      tester,
    ) async {
      final Pumped none = await pumpShape(
        tester,
        block,
        json: _aimed(kind),
        cards: const [],
      );
      expect(none.drawn, isFalse);
      expect(find.byType(Text), findsNothing);

      // Fewer than make its shape, and only cards of another kind, alike.
      final ShapeAim aim = ShapeAim.of(section, kind, DateTime.now());
      final Pumped others = await pumpShape(
        tester,
        block,
        json: _aimed(kind),
        cards: PillBank.cards.where((p) => !aim.fits(p)).take(12).toList(),
      );
      expect(others.drawn, isFalse);
      if (block.words.fewest > 1) {
        final Pumped few = await pumpShape(
          tester,
          block,
          json: _aimed(kind),
          cards: cardsOfKind(block, section, n: block.words.fewest - 1),
        );
        expect(few.drawn, isFalse);
      }
    });

    testWidgets('${block.name} stands at every size, on both papers', (
      tester,
    ) async {
      for (final String size in kShapeSizes) {
        for (final Brightness paper in Brightness.values) {
          for (final String signature in block.words.signatures) {
            // A signature can make the shelf another kind (a grid of
            // figures is numbers), so its cards are dealt as it aims them.
            final Map<String, Object?> json = {
              ..._aimed(block.words.kindWith(signature)),
              'size': size,
              'signature': signature,
            };
            final List<Pill> cards = cardsOfKind(
              block,
              ExploreSection.fromJson({
                'id': 'x',
                'block': block.name,
                ...json,
              }),
            );
            final Pumped run = await pumpShape(
              tester,
              block,
              json: json,
              cards: cards,
              read: {cards[1].id},
              theme: paper,
            );
            expect(run.drawn, isTrue);
            expect(
              tester.takeException(),
              isNull,
              reason: '$size, $signature, $paper',
            );
          }
        }
      }
    });
  }
}
