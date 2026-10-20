/// The past laid along a line of years: each card under the year it is set
/// in, a dot on the line for it, the line running the length of the shelf
/// (131b); and the same line as a ruler, ticked, its years set large
/// (132a's ruler of years).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/explore/parts.dart';
import '../../explore_block.dart';
import 'deal.dart';
import 'look.dart';
import 'outlines.dart';
import 'shelf.dart';
import 'tile.dart';
import 'vocabulary.dart';

/// The cards of [deal] in the order a line of time puts them: the years
/// they are set in, earliest first, unless the section asks for its own
/// order with `"order": "given"`.
List<Pill> inOrderOfTime(ShapeDeal deal) {
  if (deal.section.get<String>('order') == 'given') return deal.cards;
  final List<(int, Pill)> keyed = [
    for (int i = 0; i < deal.cards.length; i++) (i, deal.cards[i]),
  ];
  // Stable: cards of the same year keep the order they were dealt in.
  keyed.sort((a, b) {
    final int by = timeKey(a.$2).compareTo(timeKey(b.$2));
    return by != 0 ? by : a.$1.compareTo(b.$1);
  });
  return [for (final (_, Pill p) in keyed) p];
}

/// The cards a line of time shows first when it has more than it needs:
/// those whose question names a year, so the line reads as years (1915,
/// 1953) rather than as one age over and over, which is all most cards of
/// an age carry. A section that gives its own order keeps it whole.
bool Function(Pill)? yearsFirst(ExploreSection section) =>
    section.get<String>('order') == 'given' ? null : namesAYear;

/// One size of a line of years.
@immutable
class YearsSize {
  const YearsSize({
    required this.column,
    required this.card,
    required this.year,
    required this.dot,
    required this.look,
    this.gap = 10,
  });

  /// The width of a card and its year.
  final double column;

  /// The card's height.
  final double card;

  /// The year's type size.
  final double year;

  /// The dot's diameter.
  final double dot;
  final TileLook look;

  /// Between two columns.
  final double gap;
}

/// The cards on a line of years, scrolling sideways.
class YearsBlock extends ShapeBlock {
  const YearsBlock({
    required this.name,
    required this.words,
    required this.sizes,
    this.ruler = false,
  });

  @override
  final String name;

  @override
  final ShapeVocabulary words;
  final Map<String, YearsSize> sizes;

  /// Whether the line is a ruler, ticked every few points.
  final bool ruler;

  @override
  bool Function(Pill)? first(ExploreSection section) => yearsFirst(section);

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final ExploreSection section = deal.section;
    final YearsSize size = sizes[sizeOf(section)]!;
    final List<Pill> cards = inOrderOfTime(deal);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    // The row the years stand on is as tall as the year, at the reader's
    // text size, so a year set larger never runs into its card.
    final double marker = math.max(
      ruler ? 30 : 22,
      scaler.scale(size.year) + 6,
    );
    // A little under the dot's middle, as the canvas draws it: the ruler's
    // ticks stand on it and reach up past the dot's centre.
    final double line = marker / 2 + 2.5;
    final Color ink = context.p.ink;
    final Color page = context.p.surface;
    final double step = size.column + size.gap;
    return SizedBox(
      height: marker + 12 + size.card + 4,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: cards.length,
        itemBuilder: (context, i) {
          final Pill p = cards[i];
          host.seen(section, p);
          final bool firstOne = i == 0;
          final bool lastOne = i == cards.length - 1;
          // Each column draws its own stretch of the line, and the margins
          // at either end of the shelf, so the line runs the whole way and
          // scrolls with the cards.
          final double lead = firstOne ? 20 : 0;
          final double tail = lastOne ? 20 : size.gap;
          return SizedBox(
            width: lead + size.column + tail,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: marker,
                  child: CustomPaint(
                    painter: _LinePainter(
                      colour: ink.withValues(alpha: ruler ? 0.22 : 0.16),
                      y: line,
                      ticks: ruler,
                      phase: firstOne ? 0 : 20 + i * step,
                    ),
                  ),
                ),
                Positioned(
                  left: lead,
                  top: 0,
                  width: size.column,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: marker,
                        child: _Marker(
                          year: yearLabel(context, p),
                          size: size,
                          dotColour: p.color,
                          page: page,
                          ink: ink,
                          ruler: ruler,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: size.card,
                        child: CardTap(
                          pill: p,
                          onTap: () => host.open(section, cards, p),
                          child: ShapeTile(
                            pill: p,
                            look: size.look,
                            read: host.isRead(p),
                          ),
                        ),
                      ),
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

/// A card's place on the line: a dot in its colour, ringed in the page's
/// so the line stops short of it, and the year, on the page's own colour so
/// the line passes behind it rather than through it.
class _Marker extends StatelessWidget {
  const _Marker({
    required this.year,
    required this.size,
    required this.dotColour,
    required this.page,
    required this.ink,
    required this.ruler,
  });

  final String year;
  final YearsSize size;
  final Color dotColour;
  final Color page;
  final Color ink;
  final bool ruler;

  @override
  Widget build(BuildContext context) {
    // The dot's own edge lines up with the card's; its ring reaches past.
    return Transform.translate(offset: const Offset(-4, 0), child: _row());
  }

  Widget _row() {
    return Row(
      children: [
        Container(
          width: size.dot + 8,
          height: size.dot + 8,
          decoration: BoxDecoration(color: page, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Container(
            width: size.dot,
            height: size.dot,
            decoration: BoxDecoration(color: dotColour, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Container(
            color: page,
            padding: EdgeInsets.fromLTRB(ruler ? 4 : 6, 0, ruler ? 8 : 6, 0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                year,
                maxLines: 1,
                style: AppText.display(
                  size: size.year,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -0.025 * size.year,
                  color: ink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The line the years stand on, and the ruler's ticks along it.
class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.colour,
    required this.y,
    required this.ticks,
    required this.phase,
  });

  final Color colour;
  final double y;
  final bool ticks;

  /// Where this stretch begins along the whole line, so its ticks fall
  /// where the stretch before it left off.
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = colour
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y + 0.5), Offset(size.width, y + 0.5), p);
    if (!ticks) return;
    const double every = 9;
    final double first = (every - phase % every) % every;
    for (double x = first; x <= size.width; x += every) {
      canvas.drawLine(Offset(x + 0.5, y - 5), Offset(x + 0.5, y), p);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.colour != colour ||
      old.y != y ||
      old.ticks != ticks ||
      old.phase != phase;
}

/// The past, each card under its year on a line (131b).
const YearsBlock yearsRow = YearsBlock(
  name: 'shape-years',
  words: ShapeVocabulary(canvas: ['131b'], kind: 'past', fields: ['order']),
  sizes: {
    's': YearsSize(
      column: 156,
      card: 146,
      year: 15,
      dot: 8,
      look: TileLook(
        outline: RoundOutline(17),
        padding: EdgeInsets.all(12),
        min: 10,
        max: 14,
      ),
    ),
    'm': YearsSize(
      column: 176,
      card: 164,
      year: 17,
      dot: 9,
      look: TileLook(outline: RoundOutline(19), max: 15.5),
    ),
    'l': YearsSize(
      column: 200,
      card: 186,
      year: 19.5,
      dot: 10,
      look: TileLook(
        outline: RoundOutline(21),
        padding: EdgeInsets.all(16),
        min: 11,
        max: 17.5,
      ),
    ),
  },
);

/// The past on a ruler of years, the years set large (132a).
const YearsBlock rulerRow = YearsBlock(
  name: 'shape-ruler',
  ruler: true,
  words: ShapeVocabulary(canvas: ['132a'], kind: 'past', fields: ['order']),
  sizes: {
    's': YearsSize(
      column: 188,
      card: 152,
      year: 21,
      dot: 10,
      gap: 12,
      look: TileLook(
        outline: RoundOutline(18),
        padding: EdgeInsets.all(14),
        min: 10.5,
        max: 15,
      ),
    ),
    'm': YearsSize(
      column: 216,
      card: 172,
      year: 24,
      dot: 11,
      gap: 12,
      look: TileLook(
        outline: RoundOutline(19),
        padding: EdgeInsets.all(16),
        min: 11,
        max: 16.5,
      ),
    ),
    'l': YearsSize(
      column: 244,
      card: 194,
      year: 27,
      dot: 12,
      gap: 12,
      look: TileLook(
        outline: RoundOutline(21),
        padding: EdgeInsets.all(18),
        min: 11.5,
        max: 18.5,
      ),
    ),
  },
);
