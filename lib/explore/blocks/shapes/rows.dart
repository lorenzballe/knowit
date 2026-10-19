/// The shapes that scroll sideways, as every shelf of the app does, each a
/// tile of its own cut: rounds 131b to 131d and the signatures of 132a.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/pill.dart';
import '../../../widgets/explore/parts.dart';
import '../../explore_block.dart';
import 'deal.dart';
import 'look.dart';
import 'outlines.dart';
import 'shelf.dart';
import 'signatures.dart';
import 'tile.dart';
import 'vocabulary.dart';

/// One tile of a row, at one size.
@immutable
class RowTile {
  const RowTile(this.width, this.height, this.look);

  final double width;

  /// The row's height, as the canvas drew it: the tiles stand 4 points
  /// shorter, within the 2 the row keeps above and below them.
  final double height;
  final TileLook look;

  /// The row's height for [cards], where [read] says which the reader has
  /// read: the canvas's, or taller when a question needs it, so that none
  /// has to scroll inside its tile.
  double heightFor(
    BuildContext context,
    List<Pill> cards,
    bool Function(Pill) read,
  ) {
    final bool figures =
        look.words == TileWords.figure || look.words == TileWords.figureTop;
    double tallest = height;
    for (final Pill p in cards) {
      tallest = math.max(
        tallest,
        tileHeightFor(
              context,
              p,
              look,
              width: width,
              read: read(p),
              figure: figures && figureOf(p) != null,
            ) +
            4,
      );
    }
    return tallest;
  }
}

/// What a signature paints on the face of [p], for the ones a tile's face
/// carries whatever its shape.
List<FaceArt> signatureArt(String signature, Pill p) => switch (signature) {
  'quote' => [QuoteArt(mark: tone(p, Tones.graphic), bar: tone(p, Tones.over))],
  'circles' => [
    CirclesArt(disc: tone(p, Tones.graphic), overlap: tone(p, Tones.over)),
  ],
  'halves' => [SplitArt.halves(tone(p, Tones.half))],
  'diagonal' => [SplitArt.diagonal(tone(p, Tones.half))],
  _ => const [],
};

/// What a signature lays behind the words of [p]: the subject's mark.
Widget? signatureBehind(String signature, Pill p, {double angle = -14}) =>
    signature == 'mark' ? MarkBehind(pill: p, angle: angle) : null;

/// The colour a number's figure is set in when it is the tile's signature:
/// the card's colour taken well down, as the app's own numbers shelf sets it.
Color figureTone(Pill p) => Color.lerp(p.color, Colors.black, 0.42)!;

/// A sideways row of one tile.
class ShapeRow extends ShapeBlock {
  const ShapeRow({
    required this.name,
    required this.words,
    required this.tiles,
    this.gap = 10,
  });

  @override
  final String name;

  @override
  final ShapeVocabulary words;

  /// The tile at each size.
  final Map<String, RowTile> tiles;

  /// Between two tiles.
  final double gap;

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final ExploreSection section = deal.section;
    final RowTile tile = tiles[sizeOf(section)]!;
    final String signature = signatureOf(section);
    final List<Pill> cards = deal.cards;
    final TileOutline outline = tile.look.outline;
    return SideRow(
      height: tile.heightFor(context, cards, host.isRead),
      gap: gap,
      count: cards.length,
      itemBuilder: (context, i) {
        final Pill p = cards[i];
        host.seen(section, p);
        final String? figure =
            tile.look.words == TileWords.figure ||
                tile.look.words == TileWords.figureTop
            ? figureOf(p)
            : null;
        return CardTap(
          pill: p,
          onTap: () => host.open(section, cards, p),
          child: SizedBox(
            width: tile.width,
            child: ShapeTile(
              pill: p,
              look: tile.look,
              read: host.isRead(p),
              figure: figure,
              figureColour: tile.look.words == TileWords.figureTop
                  ? figureTone(p)
                  : null,
              art: [
                if (outline is FoldOutline)
                  FlapArt(outline, tone(p, Tones.fold)),
                ...signatureArt(signature, p),
              ],
              behind: signatureBehind(signature, p),
            ),
          ),
        );
      },
    );
  }
}

const EdgeInsets _p14 = EdgeInsets.all(14);

/// A myth, on a page with its corner turned down (131b, 131f).
const ShapeRow foldRow = ShapeRow(
  name: 'shape-fold',
  words: ShapeVocabulary(canvas: ['131b', '131f'], kind: 'myths'),
  tiles: {
    's': RowTile(
      148,
      176,
      TileLook(
        outline: FoldOutline(radius: 19, fold: 30),
        padding: EdgeInsets.all(13),
        min: 10,
        max: 15,
        tickBeside: true,
      ),
    ),
    'm': RowTile(
      168,
      200,
      TileLook(
        outline: FoldOutline(radius: 19, fold: 34),
        padding: _p14,
        max: 16.5,
        tickBeside: true,
      ),
    ),
    'l': RowTile(
      192,
      228,
      TileLook(
        outline: FoldOutline(radius: 21, fold: 38),
        padding: EdgeInsets.all(16),
        min: 11,
        max: 18.5,
        tickBeside: true,
      ),
    ),
  },
);

/// A myth, on a page torn out (131d).
const ShapeRow tornRow = ShapeRow(
  name: 'shape-torn',
  words: ShapeVocabulary(canvas: ['131d'], kind: 'myths'),
  tiles: {
    's': RowTile(
      144,
      176,
      TileLook(
        outline: TornOutline(radius: 19, tooth: 12),
        padding: EdgeInsets.fromLTRB(13, 13, 13, 18),
        min: 10,
        max: 15,
      ),
    ),
    'm': RowTile(
      164,
      200,
      TileLook(
        outline: TornOutline(radius: 19),
        padding: EdgeInsets.fromLTRB(14, 14, 14, 20),
        max: 16.5,
      ),
    ),
    'l': RowTile(
      188,
      228,
      TileLook(
        outline: TornOutline(radius: 21, tooth: 14),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 22),
        min: 11,
        max: 18.5,
      ),
    ),
  },
);

/// A month of one subject, in folders (131d).
const ShapeRow tabRow = ShapeRow(
  name: 'shape-tab',
  words: ShapeVocabulary(canvas: ['131d'], kind: 'month'),
  tiles: {
    's': RowTile(
      140,
      158,
      TileLook(
        outline: TabOutline(radius: 17, tabWidth: 54, tabHeight: 12),
        padding: EdgeInsets.fromLTRB(12, 24, 12, 12),
        min: 10,
        max: 13,
      ),
    ),
    'm': RowTile(
      158,
      178,
      TileLook(
        outline: TabOutline(radius: 19, tabWidth: 62, tabHeight: 14),
        padding: EdgeInsets.fromLTRB(14, 28, 14, 14),
        max: 14.5,
      ),
    ),
    'l': RowTile(
      180,
      204,
      TileLook(
        outline: TabOutline(radius: 21, tabWidth: 70, tabHeight: 16),
        padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
        min: 11,
        max: 16.5,
      ),
    ),
  },
);

/// The past, framed in arches (131d).
const ShapeRow archRow = ShapeRow(
  name: 'shape-arch',
  words: ShapeVocabulary(canvas: ['131d'], kind: 'past'),
  tiles: {
    's': RowTile(
      140,
      194,
      TileLook(
        outline: CornersOutline.arch(17),
        padding: EdgeInsets.fromLTRB(14, 34, 14, 14),
        words: TileWords.centred,
        min: 10,
        max: 14,
      ),
    ),
    'm': RowTile(
      160,
      220,
      TileLook(
        outline: CornersOutline.arch(19),
        padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
        words: TileWords.centred,
        max: 15.5,
      ),
    ),
    'l': RowTile(
      182,
      250,
      TileLook(
        outline: CornersOutline.arch(21),
        padding: EdgeInsets.fromLTRB(18, 46, 18, 18),
        words: TileWords.centred,
        min: 11,
        max: 17.5,
      ),
    ),
  },
);

/// A number that surprises, in a capsule with its figure set large (131d,
/// 131f).
const ShapeRow capsuleRow = ShapeRow(
  name: 'shape-capsule',
  words: ShapeVocabulary(canvas: ['131d', '131f'], kind: 'numbers'),
  tiles: {
    's': RowTile(
      132,
      208,
      TileLook(
        outline: CornersOutline.capsule(),
        padding: EdgeInsets.fromLTRB(16, 26, 16, 26),
        words: TileWords.figure,
        min: 9.5,
        max: 11,
        tracking: -0.02,
        figureSize: 34,
      ),
    ),
    'm': RowTile(
      150,
      236,
      TileLook(
        outline: CornersOutline.capsule(),
        padding: EdgeInsets.fromLTRB(18, 30, 18, 30),
        words: TileWords.figure,
        min: 10,
        max: 12,
        tracking: -0.02,
      ),
    ),
    'l': RowTile(
      172,
      270,
      TileLook(
        outline: CornersOutline.capsule(),
        padding: EdgeInsets.fromLTRB(20, 34, 20, 34),
        words: TileWords.figure,
        min: 10.5,
        max: 13.5,
        tracking: -0.02,
        figureSize: 46,
      ),
    ),
  },
);

/// A debate, the card cut corner to corner in its two tones (131d).
const ShapeRow diagonalRow = ShapeRow(
  name: 'shape-diagonal',
  words: ShapeVocabulary(
    canvas: ['131d'],
    kind: 'debates',
    signatures: ['diagonal'],
  ),
  tiles: {
    's': RowTile(
      264,
      156,
      TileLook(
        outline: RoundOutline(20),
        padding: EdgeInsets.all(15),
        words: TileWords.middle,
        min: 11,
        max: 16,
        lineHeight: 1.14,
        tracking: -0.032,
      ),
    ),
    'm': RowTile(
      300,
      176,
      TileLook(
        outline: RoundOutline(22),
        padding: EdgeInsets.all(17),
        words: TileWords.middle,
        min: 12,
        max: 18,
        lineHeight: 1.14,
        tracking: -0.032,
      ),
    ),
    'l': RowTile(
      340,
      200,
      TileLook(
        outline: RoundOutline(24),
        padding: EdgeInsets.all(19),
        words: TileWords.middle,
        min: 13,
        max: 20.5,
        lineHeight: 1.14,
        tracking: -0.032,
      ),
    ),
  },
);

/// A paradox, on a leaf: two opposite corners drawn long (131d).
const ShapeRow leafRow = ShapeRow(
  name: 'shape-leaf',
  words: ShapeVocabulary(canvas: ['131d'], kind: 'paradoxes'),
  tiles: {
    's': RowTile(
      148,
      176,
      TileLook(
        outline: CornersOutline(
          topLeft: 50,
          topRight: 9,
          bottomRight: 50,
          bottomLeft: 9,
        ),
        padding: EdgeInsets.all(16),
        markInset: 5,
        min: 10,
        max: 14,
      ),
    ),
    'm': RowTile(
      168,
      200,
      TileLook(
        outline: CornersOutline(
          topLeft: 56,
          topRight: 10,
          bottomRight: 56,
          bottomLeft: 10,
        ),
        padding: EdgeInsets.all(18),
        markInset: 6,
        max: 15.5,
      ),
    ),
    'l': RowTile(
      192,
      228,
      TileLook(
        outline: CornersOutline(
          topLeft: 64,
          topRight: 11,
          bottomRight: 64,
          bottomLeft: 11,
        ),
        padding: EdgeInsets.all(20),
        markInset: 7,
        min: 11,
        max: 17.5,
      ),
    ),
  },
);

/// A myth, one to the width of the screen, its question the poster (131c).
const ShapeRow heroRow = ShapeRow(
  name: 'shape-hero',
  words: ShapeVocabulary(canvas: ['131c'], kind: 'myths'),
  tiles: {
    's': RowTile(
      280,
      208,
      TileLook(
        outline: RoundOutline(20),
        padding: EdgeInsets.all(16),
        named: true,
        words: TileWords.middle,
        min: 12,
        max: 19.5,
        lineHeight: 1.12,
        tracking: -0.034,
        gap: 11,
      ),
    ),
    'm': RowTile(
      316,
      236,
      TileLook(
        outline: RoundOutline(22),
        padding: EdgeInsets.all(17),
        named: true,
        words: TileWords.middle,
        min: 13,
        max: 22,
        lineHeight: 1.12,
        tracking: -0.034,
        gap: 12,
      ),
    ),
    'l': RowTile(
      340,
      262,
      TileLook(
        outline: RoundOutline(24),
        padding: EdgeInsets.all(19),
        named: true,
        words: TileWords.middle,
        min: 14,
        max: 25,
        lineHeight: 1.12,
        tracking: -0.034,
        gap: 13,
      ),
    ),
  },
);

/// The past, as the spines of books on a shelf (131c).
const ShapeRow spinesRow = ShapeRow(
  name: 'shape-spines',
  words: ShapeVocabulary(canvas: ['131c'], kind: 'past'),
  gap: 8,
  tiles: {
    's': RowTile(
      110,
      190,
      TileLook(
        outline: RoundOutline(17),
        padding: EdgeInsets.all(12),
        min: 10,
        max: 12.5,
      ),
    ),
    'm': RowTile(
      124,
      212,
      TileLook(outline: RoundOutline(19), padding: _p14, min: 10, max: 14),
    ),
    'l': RowTile(
      142,
      242,
      TileLook(
        outline: RoundOutline(21),
        padding: EdgeInsets.all(15),
        min: 10.5,
        max: 16,
      ),
    ),
  },
);

/// A number that surprises, on a square (131c).
const ShapeRow squaresRow = ShapeRow(
  name: 'shape-squares',
  words: ShapeVocabulary(canvas: ['131c'], kind: 'numbers'),
  tiles: {
    's': RowTile(
      140,
      140,
      TileLook(
        outline: RoundOutline(18),
        padding: EdgeInsets.all(12),
        min: 9.5,
        max: 11.5,
        gap: 7,
      ),
    ),
    'm': RowTile(
      150,
      150,
      TileLook(
        outline: RoundOutline(19),
        padding: _p14,
        min: 9.5,
        max: 12.5,
        gap: 8,
      ),
    ),
    'l': RowTile(
      172,
      172,
      TileLook(
        outline: RoundOutline(21),
        padding: EdgeInsets.all(15),
        min: 10,
        max: 14,
        gap: 9,
      ),
    ),
  },
);

/// A debate, on a wide card that names its subject (131c).
const ShapeRow wideRow = ShapeRow(
  name: 'shape-wide',
  words: ShapeVocabulary(canvas: ['131c'], kind: 'debates'),
  tiles: {
    's': RowTile(
      264,
      134,
      TileLook(
        outline: RoundOutline(17),
        padding: EdgeInsets.all(15),
        named: true,
        min: 11,
        max: 15,
        lineHeight: 1.14,
        tracking: -0.03,
        gap: 9,
      ),
    ),
    'm': RowTile(
      300,
      150,
      TileLook(
        outline: RoundOutline(19),
        padding: EdgeInsets.all(17),
        named: true,
        min: 11.5,
        max: 17,
        lineHeight: 1.14,
        tracking: -0.03,
      ),
    ),
    'l': RowTile(
      340,
      170,
      TileLook(
        outline: RoundOutline(21),
        padding: EdgeInsets.all(19),
        named: true,
        min: 12.5,
        max: 19.5,
        lineHeight: 1.14,
        tracking: -0.03,
        gap: 11,
      ),
    ),
  },
);

/// A paradox, on a card a size up from the app's (131c).
const ShapeRow mediumRow = ShapeRow(
  name: 'shape-medium',
  words: ShapeVocabulary(canvas: ['131c'], kind: 'paradoxes'),
  tiles: {
    's': RowTile(
      164,
      184,
      TileLook(
        outline: RoundOutline(18),
        padding: EdgeInsets.all(13),
        min: 10.5,
        max: 15,
      ),
    ),
    'm': RowTile(
      186,
      208,
      TileLook(outline: RoundOutline(19), padding: _p14, min: 11, max: 17),
    ),
    'l': RowTile(
      212,
      236,
      TileLook(
        outline: RoundOutline(21),
        padding: EdgeInsets.all(16),
        min: 11.5,
        max: 19.5,
      ),
    ),
  },
);

/// A month of one subject, its mark drawn large behind every card (132a).
const ShapeRow markRow = ShapeRow(
  name: 'shape-mark',
  words: ShapeVocabulary(canvas: ['132a'], kind: 'month', signatures: ['mark']),
  tiles: {
    's': RowTile(
      206,
      248,
      TileLook(
        outline: RoundOutline(20),
        padding: EdgeInsets.all(16),
        named: true,
        min: 11.5,
        max: 17,
        lineHeight: 1.12,
        tracking: -0.034,
        gap: 11,
      ),
    ),
    'm': RowTile(
      236,
      284,
      TileLook(
        outline: RoundOutline(22),
        padding: EdgeInsets.all(18),
        named: true,
        min: 12,
        max: 19,
        lineHeight: 1.12,
        tracking: -0.034,
        gap: 12,
      ),
    ),
    'l': RowTile(
      268,
      322,
      TileLook(
        outline: RoundOutline(24),
        padding: EdgeInsets.all(20),
        named: true,
        min: 13,
        max: 21.5,
        lineHeight: 1.12,
        tracking: -0.034,
        gap: 13,
      ),
    ),
  },
);

/// A myth, its opening quote struck out behind it (132a).
const ShapeRow quoteRow = ShapeRow(
  name: 'shape-quote',
  words: ShapeVocabulary(
    canvas: ['132a'],
    kind: 'myths',
    signatures: ['quote'],
  ),
  tiles: {
    's': RowTile(
      166,
      206,
      TileLook(
        outline: RoundOutline(18),
        padding: EdgeInsets.all(14),
        min: 10.5,
        max: 15,
      ),
    ),
    'm': RowTile(
      190,
      236,
      TileLook(
        outline: RoundOutline(19),
        padding: EdgeInsets.all(16),
        min: 11,
        max: 17,
      ),
    ),
    'l': RowTile(
      216,
      268,
      TileLook(
        outline: RoundOutline(21),
        padding: EdgeInsets.all(18),
        min: 11.5,
        max: 19.5,
      ),
    ),
  },
);

/// A paradox, over two circles that overlap (132a).
const ShapeRow circlesRow = ShapeRow(
  name: 'shape-circles',
  words: ShapeVocabulary(
    canvas: ['132a'],
    kind: 'paradoxes',
    signatures: ['circles'],
  ),
  tiles: {
    's': RowTile(
      180,
      214,
      TileLook(
        outline: RoundOutline(20),
        padding: EdgeInsets.all(14),
        min: 10.5,
        max: 14,
      ),
    ),
    'm': RowTile(
      206,
      244,
      TileLook(
        outline: RoundOutline(22),
        padding: EdgeInsets.all(16),
        min: 11,
        max: 15.5,
      ),
    ),
    'l': RowTile(
      236,
      278,
      TileLook(
        outline: RoundOutline(24),
        padding: EdgeInsets.all(18),
        min: 11.5,
        max: 17.5,
      ),
    ),
  },
);
