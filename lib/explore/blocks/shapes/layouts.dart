/// The shapes that are not one row: a grid (131c, and 132b's grid of
/// figures), one big card beside two (131c), two rows that scroll together
/// (131e) and a masonry of tall and short cards (131e, and 132b's with the
/// subject's mark).
library;

import 'dart:math' as math;

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
      child: LayoutBuilder(
        builder: (context, box) {
          // The canvas's height, or taller when the lead or one of the two
          // beside it needs it to hold its question.
          final double room = box.maxWidth - 10;
          double tallest = math.max(
            height,
            tileHeightFor(
              context,
              lead,
              big,
              width: room * 3 / 5,
              read: host.isRead(lead),
            ),
          );
          for (final Pill p in two) {
            final double each = tileHeightFor(
              context,
              p,
              small,
              width: room * 2 / 5,
              read: host.isRead(p),
            );
            tallest = math.max(tallest, each * 2 + 10);
          }
          return SizedBox(
            height: tallest,
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
          );
        },
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
    final (double width, double canvas, TileLook look) =
        _sizes[sizeOf(deal.section)]!;
    final List<Pill> cards = deal.cards;
    final int columns = (cards.length / 2).ceil();
    // Every tile as tall as the canvas's, or as the longest question needs.
    double height = canvas;
    for (final Pill p in cards) {
      height = math.max(
        height,
        tileHeightFor(context, p, look, width: width, read: host.isRead(p)),
      );
    }
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
/// (132b).
///
/// Each card stands as tall as its question set whole at the top of its
/// type, never less than two lines of it, so a long question takes more of
/// the page and a short one less, and no card is left half empty under a
/// question that ends halfway down it. The cards are split between the two
/// columns so the columns come out as nearly level as they can, and are
/// made level by what the shorter one lacks, shared among its cards; in
/// each column the longer questions take the tall places.
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

  /// The question's type and the tile's margin, at each size.
  static const Map<String, (double, double, EdgeInsets)> _sizes = {
    's': (10.5, 15, EdgeInsets.all(13)),
    'm': (11, 17, EdgeInsets.all(14)),
    'l': (11.5, 17.5, EdgeInsets.all(15)),
  };

  /// Between two cards, across and down.
  static const double _gap = 10;

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double min, double max, EdgeInsets pad) =
        _sizes[sizeOf(deal.section)]!;
    final bool mark = signatureOf(deal.section) == 'mark';
    // An even number, two columns of as many cards each.
    final List<Pill> cards = deal.cards
        .take(deal.cards.length - deal.cards.length % 2)
        .toList();
    final TileLook look = TileLook(
      outline: const RoundOutline(19),
      padding: pad,
      min: min,
      max: max,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          final double width = (box.maxWidth - _gap) / 2;
          final List<double> stands = [
            for (final Pill p in cards)
              math.max(
                tileHeightFor(
                  context,
                  p,
                  look,
                  width: width,
                  read: host.isRead(p),
                  atTop: true,
                ),
                tileLeastFor(
                  context,
                  p,
                  look,
                  width: width,
                  read: host.isRead(p),
                ),
              ),
          ];
          final MasonryLaid laid = MasonryLaid.of(stands, gap: _gap);
          // The order a reader meets them, top to bottom and then left to
          // right: the order a swipe from one opened card to the next
          // takes.
          final List<Pill> met = [for (final int i in laid.met) cards[i]];
          Widget column(int side) => Expanded(
            child: Column(
              children: [
                for (int r = 0; r < laid.columns[side].length; r++) ...[
                  if (r > 0) const SizedBox(height: _gap),
                  _card(
                    host,
                    deal,
                    met,
                    cards[laid.columns[side][r]],
                    look,
                    height: laid.heights[laid.columns[side][r]],
                    tall: laid.tall[laid.columns[side][r]],
                    mark: mark,
                  ),
                ],
              ],
            ),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              column(0),
              const SizedBox(width: _gap),
              column(1),
            ],
          );
        },
      ),
    );
  }

  Widget _card(
    ExploreHost host,
    ShapeDeal deal,
    List<Pill> shelf,
    Pill p,
    TileLook look, {
    required double height,
    required bool tall,
    required bool mark,
  }) => SizedBox(
    height: height,
    child: _tile(
      host,
      deal,
      shelf,
      p,
      ShapeTile(
        pill: p,
        look: look,
        read: host.isRead(p),
        behind: mark && tall ? MarkBehind(pill: p, angle: -12) : null,
      ),
    ),
  );
}

/// A masonry's cards in its two columns: which card stands where, how tall,
/// and which stand in its tall places.
@immutable
class MasonryLaid {
  const MasonryLaid._(this.columns, this.heights, this.tall, this.met);

  /// The cards of each column, top to bottom, by their place in the deal:
  /// the left column, then the right.
  final List<List<int>> columns;

  /// How tall each card stands, by its place in the deal.
  final List<double> heights;

  /// Whether each card stands in a tall place, by its place in the deal.
  final List<bool> tall;

  /// The cards in the order a reader meets them: top to bottom, then left
  /// to right.
  final List<int> met;

  /// Cards that stand [stands] tall (as tall as their questions, an even
  /// number of them), [gap] apart, in two columns of as many each.
  ///
  /// The first card dealt opens the left column; the rest are split so the
  /// two columns come out the closest to level, the first such split in
  /// the order dealt when two come out alike. The shorter column is then
  /// made level, what it lacks shared among its cards. In each column the
  /// longer cards take the tall places, which the left column starts with
  /// and the right one ends with, out of step; each lot keeps the order it
  /// was dealt in.
  factory MasonryLaid.of(List<double> stands, {required double gap}) {
    final int n = stands.length;
    final int half = n ~/ 2;
    List<int>? left;
    double closest = double.infinity;
    // Every set of the cards after the first to stand beside it.
    void choose(int from, List<int> chosen) {
      if (chosen.length == half) {
        final Set<int> inLeft = chosen.toSet();
        double l = 0, r = 0;
        for (int i = 0; i < n; i++) {
          if (inLeft.contains(i)) {
            l += stands[i];
          } else {
            r += stands[i];
          }
        }
        if ((l - r).abs() < closest - 0.01) {
          closest = (l - r).abs();
          left = List.of(chosen);
        }
        return;
      }
      for (int i = from; i < n; i++) {
        choose(i + 1, [...chosen, i]);
      }
    }

    if (half > 0) choose(1, [0]);
    final List<int> leftIds = left ?? const [];
    final Set<int> inLeft = leftIds.toSet();
    final List<int> rightIds = [
      for (int i = 0; i < n; i++)
        if (!inLeft.contains(i)) i,
    ];

    // In turn: the left column's tall places are its first, third…; the
    // right column's its second, fourth…
    final List<bool> tall = List<bool>.filled(n, false);
    List<int> inTurn(List<int> ids, bool startsTall) {
      final int tallPlaces = startsTall
          ? (ids.length + 1) ~/ 2
          : ids.length ~/ 2;
      final List<int> byStand = [...ids]
        ..sort((a, b) {
          final int by = stands[b].compareTo(stands[a]);
          return by != 0 ? by : a.compareTo(b);
        });
      final Set<int> high = byStand.take(tallPlaces).toSet();
      for (final int i in high) {
        tall[i] = true;
      }
      final Iterator<int> highs = ids.where(high.contains).iterator;
      final Iterator<int> lows = ids.where((i) => !high.contains(i)).iterator;
      return [
        for (int r = 0; r < ids.length; r++)
          if (r.isEven == startsTall)
            (highs..moveNext()).current
          else
            (lows..moveNext()).current,
      ];
    }

    final List<List<int>> columns = [
      inTurn(leftIds, true),
      inTurn(rightIds, false),
    ];
    final List<double> heights = List.of(stands);
    final List<double> sums = [
      for (final List<int> c in columns)
        c.fold<double>(0, (s, i) => s + stands[i]),
    ];
    final double level = sums.fold<double>(0, (a, b) => math.max(a, b));
    for (int c = 0; c < columns.length; c++) {
      if (columns[c].isEmpty) continue;
      final double share = (level - sums[c]) / columns[c].length;
      for (final int i in columns[c]) {
        heights[i] = stands[i] + share;
      }
    }

    final List<double> tops = List<double>.filled(n, 0);
    for (final List<int> c in columns) {
      double top = 0;
      for (final int i in c) {
        tops[i] = top;
        top += heights[i] + gap;
      }
    }
    final List<int> met = [for (final List<int> c in columns) ...c]
      ..sort((a, b) {
        final int byTop = tops[a].compareTo(tops[b]);
        if (byTop != 0) return byTop;
        if (inLeft.contains(a) == inLeft.contains(b)) return a.compareTo(b);
        return inLeft.contains(a) ? -1 : 1;
      });
    return MasonryLaid._(columns, heights, tall, met);
  }
}
