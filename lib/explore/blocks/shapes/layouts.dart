/// The shapes that are not one row: a grid (131c, and 132b's grid of
/// figures), one big card beside two (131c), two rows that scroll together
/// (131e) and a masonry of tall and short cards (131e, and 132b's with the
/// subject's mark).
library;

import 'package:flutter/material.dart';

import '../../../models/pill.dart';
import '../../../widgets/explore/parts.dart';
import '../../explore_block.dart';
import 'deal.dart';
import 'look.dart';
import 'outlines.dart';
import 'rows.dart';
import 'shelf.dart';
import 'signatures.dart';
import 'tile.dart';
import 'vocabulary.dart';

/// A card opened from a shape that shows all its cards at once: each is
/// seen as it is built, and opens among the others.
Widget _tile(
  ExploreHost host,
  ShapeDeal deal,
  List<Pill> shelf,
  Pill p,
  Widget child,
) {
  host.seen(deal.section, p);
  return CardTap(
    pill: p,
    onTap: () => host.open(deal.section, shelf, p),
    child: child,
  );
}

// ── The grid (131c, 132b) ────────────────────────────────────────────────

/// Two cards to a row, in rows down the page: a month of one subject in
/// 131c; with the figure signature, numbers that surprise, the figure set
/// large in each tile's corner (132b).
class GridBlock extends ShapeBlock {
  const GridBlock();

  @override
  String get name => 'shape-grid';

  /// A grid of figures is a shelf of numbers that surprise (132b): with the
  /// figure signature the grid keeps to numbers unless told otherwise.
  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131c', '132b'],
    kind: 'month',
    signatures: ['none', 'figure'],
    signatureKinds: {'figure': 'numbers'},
    limit: 4,
    most: 8,
    fewest: 2,
  );

  static const Map<String, (double, TileLook)> _plain = {
    's': (
      132,
      TileLook(
        outline: RoundOutline(18),
        padding: EdgeInsets.all(12),
        min: 10,
        max: 12.5,
        gap: 7,
      ),
    ),
    'm': (
      150,
      TileLook(
        outline: RoundOutline(19),
        padding: EdgeInsets.all(14),
        min: 10,
        max: 14,
        gap: 8,
      ),
    ),
    'l': (
      172,
      TileLook(
        outline: RoundOutline(21),
        padding: EdgeInsets.all(15),
        min: 10.5,
        max: 16,
        gap: 9,
      ),
    ),
  };

  static const Map<String, (double, TileLook)> _figures = {
    's': (
      172,
      TileLook(
        outline: RoundOutline(18),
        padding: EdgeInsets.all(12),
        words: TileWords.figureTop,
        figureSize: 54,
        min: 10,
        max: 12.5,
        lineHeight: 1.18,
        tracking: -0.022,
      ),
    ),
    'm': (
      196,
      TileLook(
        outline: RoundOutline(19),
        padding: EdgeInsets.all(14),
        words: TileWords.figureTop,
        figureSize: 64,
        min: 10.5,
        max: 14,
        lineHeight: 1.18,
        tracking: -0.022,
      ),
    ),
    'l': (
      222,
      TileLook(
        outline: RoundOutline(21),
        padding: EdgeInsets.all(15),
        words: TileWords.figureTop,
        figureSize: 74,
        min: 11,
        max: 15.5,
        lineHeight: 1.18,
        tracking: -0.022,
      ),
    ),
  };

  @override
  bool Function(Pill)? keep(ExploreSection section) =>
      signatureOf(section) == 'figure' ? (p) => figureOf(p) != null : null;

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final bool figures = signatureOf(deal.section) == 'figure';
    final (double height, TileLook look) = (figures
        ? _figures
        : _plain)[sizeOf(deal.section)]!;
    // A grid of two has no lone card at its foot.
    final List<Pill> cards = deal.cards
        .take(deal.cards.length - deal.cards.length % 2)
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (int r = 0; r < cards.length; r += 2) ...[
            if (r > 0) const SizedBox(height: 10),
            SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int c = 0; c < 2; c++) ...[
                    if (c > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _tile(
                        host,
                        deal,
                        cards,
                        cards[r + c],
                        ShapeTile(
                          pill: cards[r + c],
                          look: look,
                          read: host.isRead(cards[r + c]),
                          figure: figures ? figureOf(cards[r + c]) : null,
                          figureColour: figures
                              ? figureTone(cards[r + c])
                              : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── One big and two (131c) ───────────────────────────────────────────────

/// One card large, two beside it stacked, all three on the screen at once:
/// a place's shelf in 131c. The two small slots take the shortest of the
/// cards dealt, so a long question is never set in a small one.
class BentoBlock extends ShapeBlock {
  const BentoBlock();

  @override
  String get name => 'shape-bento';

  @override
  ShapeVocabulary get words =>
      const ShapeVocabulary(canvas: ['131c'], kind: 'place', limit: 3, most: 3);

  @override
  int get spare => 3;

  static const Map<String, (double, TileLook, TileLook)> _sizes = {
    's': (
      208,
      TileLook(
        outline: RoundOutline(20),
        padding: EdgeInsets.all(15),
        named: true,
        words: TileWords.middle,
        min: 11,
        max: 17,
        lineHeight: 1.14,
        tracking: -0.032,
        gap: 11,
      ),
      TileLook(
        outline: RoundOutline(17),
        padding: EdgeInsets.all(11),
        min: 9.5,
        max: 10.5,
        gap: 5,
      ),
    ),
    'm': (
      236,
      TileLook(
        outline: RoundOutline(22),
        padding: EdgeInsets.all(17),
        named: true,
        words: TileWords.middle,
        min: 12,
        max: 19,
        lineHeight: 1.14,
        tracking: -0.032,
        gap: 12,
      ),
      TileLook(
        outline: RoundOutline(19),
        padding: EdgeInsets.all(12),
        min: 9.5,
        max: 11.5,
        gap: 6,
      ),
    ),
    'l': (
      262,
      TileLook(
        outline: RoundOutline(24),
        padding: EdgeInsets.all(18),
        named: true,
        words: TileWords.middle,
        min: 13,
        max: 21,
        lineHeight: 1.14,
        tracking: -0.032,
        gap: 13,
      ),
      TileLook(
        outline: RoundOutline(20),
        padding: EdgeInsets.all(13),
        min: 10,
        max: 12.5,
        gap: 7,
      ),
    ),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double height, TileLook big, TileLook small) =
        _sizes[sizeOf(deal.section)]!;
    final Pill lead = deal.cards.first;
    final List<Pill> rest = deal.cards.skip(1).toList();
    // The two shortest of the rest, in the order they were dealt.
    final List<Pill> byLength = [...rest]
      ..sort((a, b) => a.question.length.compareTo(b.question.length));
    final Set<Pill> chosen = byLength.take(2).toSet();
    final List<Pill> two = [
      for (final Pill p in rest)
        if (chosen.contains(p)) p,
    ];
    final List<Pill> shown = [lead, ...two];
    Widget card(Pill p, TileLook look) => _tile(
      host,
      deal,
      shown,
      p,
      ShapeTile(pill: p, look: look, read: host.isRead(p)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: card(lead, big)),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < two.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Expanded(child: card(two[i], small)),
                  ],
                  if (two.length < 2) ...[
                    const SizedBox(height: 10),
                    const Expanded(child: SizedBox()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Two rows (131e) ──────────────────────────────────────────────────────

/// Two rows of small cards that scroll sideways together: twice the places
/// in the same width (131e).
class TwoRowsBlock extends ShapeBlock {
  const TwoRowsBlock();

  @override
  String get name => 'shape-two-rows';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131e'],
    kind: 'place',
    limit: 8,
    most: 12,
    fewest: 4,
  );

  static const Map<String, (double, double, TileLook)> _sizes = {
    's': (
      180,
      110,
      TileLook(
        outline: RoundOutline(17),
        padding: EdgeInsets.all(12),
        min: 9.5,
        max: 11,
        gap: 6,
      ),
    ),
    'm': (
      200,
      120,
      TileLook(
        outline: RoundOutline(19),
        padding: EdgeInsets.all(14),
        min: 10,
        max: 12,
        gap: 8,
      ),
    ),
    'l': (
      226,
      136,
      TileLook(
        outline: RoundOutline(21),
        padding: EdgeInsets.all(15),
        min: 10.5,
        max: 13.5,
        gap: 9,
      ),
    ),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double width, double height, TileLook look) =
        _sizes[sizeOf(deal.section)]!;
    final List<Pill> cards = deal.cards;
    final int columns = (cards.length / 2).ceil();
    // The row keeps two points above and below its cards, as every
    // sideways shelf does.
    return SideRow(
      height: height * 2 + 10 + 4,
      count: columns,
      itemBuilder: (context, c) => SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int r = 0; r < 2; r++) ...[
              if (r > 0) const SizedBox(height: 10),
              SizedBox(
                height: height,
                child: c * 2 + r < cards.length
                    ? _tile(
                        host,
                        deal,
                        cards,
                        cards[c * 2 + r],
                        ShapeTile(
                          pill: cards[c * 2 + r],
                          look: look,
                          read: host.isRead(cards[c * 2 + r]),
                        ),
                      )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Masonry (131e, 132b) ─────────────────────────────────────────────────

/// Two columns of cards, tall and short in turn and out of step, so the
/// shelf reads as a page rather than a grid: a month of one subject (131e),
/// and with the mark signature its mark drawn large behind the tall ones
/// (132b). The tall places take the longest questions.
class MasonryBlock extends ShapeBlock {
  const MasonryBlock();

  @override
  String get name => 'shape-masonry';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131e', '132b'],
    kind: 'month',
    signatures: ['none', 'mark'],
    limit: 4,
    most: 8,
    fewest: 4,
  );

  static const Map<String, (double, double, double, double, EdgeInsets)>
  _sizes = {
    's': (200, 134, 10.5, 15, EdgeInsets.all(13)),
    'm': (226, 150, 11, 17, EdgeInsets.all(14)),
    'l': (250, 170, 11.5, 17.5, EdgeInsets.all(15)),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double tall, double short, double min, double max, EdgeInsets pad) =
        _sizes[sizeOf(deal.section)]!;
    final bool mark = signatureOf(deal.section) == 'mark';
    // An even number, laid two at a time: the left column starts tall and
    // the right one short, and each column then turns about.
    final List<Pill> dealt = deal.cards
        .take(deal.cards.length - deal.cards.length % 2)
        .toList();
    final List<Pill> cards = _longestTall(dealt);
    final TileLook look = TileLook(
      outline: const RoundOutline(19),
      padding: pad,
      min: min,
      max: max,
    );
    Widget card(Pill p, bool isTall) => SizedBox(
      height: isTall ? tall : short,
      child: _tile(
        host,
        deal,
        cards,
        p,
        ShapeTile(
          pill: p,
          look: look,
          read: host.isRead(p),
          behind: mark && isTall ? MarkBehind(pill: p, angle: -12) : null,
        ),
      ),
    );
    Widget column(int side) => Expanded(
      child: Column(
        children: [
          for (int i = side; i < cards.length; i += 2) ...[
            if (i > side) const SizedBox(height: 10),
            card(cards[i], _isTall(i)),
          ],
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [column(0), const SizedBox(width: 10), column(1)],
      ),
    );
  }

  /// Whether the card at [i] of the laid-out order sits in a tall place:
  /// the left column (even places) is tall then short, the right short then
  /// tall.
  static bool _isTall(int i) {
    final int row = i ~/ 2;
    return i.isEven ? row.isEven : row.isOdd;
  }

  /// The cards in their places, the longest questions in the tall ones and
  /// each lot in the order it was dealt.
  static List<Pill> _longestTall(List<Pill> cards) {
    final int tallCount = [
      for (int i = 0; i < cards.length; i++)
        if (_isTall(i)) i,
    ].length;
    final List<Pill> byLength = [...cards]
      ..sort((a, b) => b.question.length.compareTo(a.question.length));
    final Set<Pill> long = byLength.take(tallCount).toSet();
    final Iterator<Pill> tallOnes = cards.where(long.contains).iterator;
    final Iterator<Pill> shortOnes = cards
        .where((p) => !long.contains(p))
        .iterator;
    return [
      for (int i = 0; i < cards.length; i++)
        if (_isTall(i))
          (tallOnes..moveNext()).current
        else
          (shortOnes..moveNext()).current,
    ];
  }
}
