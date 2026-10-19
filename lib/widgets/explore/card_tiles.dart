/// A card as a tile, at any size a section asks for: the subject's colour,
/// its mark and name, and the question set as large as the tile takes.
///
/// Explore drew two tiles before it came from the server — the big one of
/// today's shelf and the small one further down — and a row of either. They
/// are the middle of a scale here ([TileSize.l] and [TileSize.m], drawn
/// exactly as they were), with a smaller step on each side and a larger one
/// above, and a tile that takes any box a grid, a mosaic or a pair gives it
/// ([BoxTile]).
///
/// A question is never cut and never runs out of its tile. It is set with
/// the app's own [ScaledText], as large as the box allows and no smaller than
/// the size each tile is designed for; a card whose question cannot be set
/// whole at that size, in that box, at the reader's text size, is not put in
/// it ([questionFits]) — the section takes the next card instead, so a small
/// box gets a short question and a long one waits for a bigger box.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/explore_mix.dart' show minutesFor;
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../card_edge.dart';
import '../scaled_text.dart';
import '../subject_icon.dart';
import 'first_shelves.dart' show ReadTick;

/// The steps of a row of cards, smallest first. [m] and [l] are the two
/// tiles Explore always had: the small one of the shelves further down and
/// the big one of today's shelf.
enum TileSize {
  xs(width: 120, row: 144),
  s(width: 140, row: 162),
  m(width: 158, row: 176),
  l(width: 214, row: 240),
  xl(width: 280, row: 304);

  const TileSize({required this.width, required this.row});

  /// How wide a tile is.
  final double width;

  /// How tall its row is: the tile, and two points above and below it for
  /// the lift of the card on the day paper.
  final double row;

  /// How tall the tile itself is.
  double get height => row - 4;

  /// The step a section names, `xs` to `xl`, or null for one this build
  /// does not draw.
  static TileSize? named(String? name) {
    for (final TileSize size in values) {
      if (size.name == name) return size;
    }
    return null;
  }
}

/// How a tile is drawn: its margins and corner, its head, the band its
/// question is set in, and whether it has a foot.
@immutable
class TileLook {
  const TileLook({
    required this.padding,
    required this.radius,
    required this.icon,
    required this.tick,
    required this.label,
    required this.labelSize,
    required this.labelGap,
    required this.questionGap,
    required this.min,
    required this.max,
    required this.lineHeight,
    required this.spacing,
    required this.alignment,
    required this.foot,
    this.footLines,
  });

  /// The margin inside the tile, all round.
  final double padding;

  /// The tile's corner.
  final double radius;

  /// The subject's mark, and the read tick beside it.
  final double icon;
  final double tick;

  /// Whether the subject's name follows its mark, and at what size and how
  /// far from it. Without it the mark stands alone and the tick goes to the
  /// far end.
  final bool label;
  final double labelSize;
  final double labelGap;

  /// The room between the head and the question, and under the question
  /// when the tile has a foot.
  final double questionGap;

  /// The band the question is set in.
  final double min;
  final double max;
  final double lineHeight;

  /// The question's letter spacing at a size, as the tile it came from set
  /// it.
  final double Function(double size) spacing;
  final Alignment alignment;

  /// Whether the foot says how long the card takes (and, once read, the line
  /// to keep).
  final bool foot;

  /// The most lines the line to keep takes in the foot, or null for as many
  /// as it needs; the tile Explore always had kept it to two.
  final int? footLines;

  /// The step of a row of cards.
  static TileLook of(TileSize size) => switch (size) {
    TileSize.xs => TileLook(
      padding: 11,
      radius: 16,
      icon: 13,
      tick: 12,
      label: false,
      labelSize: 0,
      labelGap: 0,
      questionGap: 8,
      min: 9.5,
      max: 12.5,
      lineHeight: 1.15,
      spacing: _spacingOf(15, 0.4),
      alignment: Alignment.topLeft,
      foot: false,
    ),
    TileSize.s => TileLook(
      padding: 12,
      radius: 17,
      icon: 14,
      tick: 13,
      label: false,
      labelSize: 0,
      labelGap: 0,
      questionGap: 9,
      min: 10,
      max: 13.5,
      lineHeight: 1.15,
      spacing: _spacingOf(15, 0.4),
      alignment: Alignment.topLeft,
      foot: false,
    ),
    // The small tile of the shelves further down, as it always was.
    TileSize.m => TileLook(
      padding: 14,
      radius: 19,
      icon: 15,
      tick: 14,
      label: false,
      labelSize: 0,
      labelGap: 0,
      questionGap: 10,
      min: 10.5,
      max: 15,
      lineHeight: 1.15,
      spacing: (size) => -0.4 * size / 15,
      alignment: Alignment.topLeft,
      foot: false,
    ),
    // The big tile of today's shelf, as it always was.
    TileSize.l => TileLook(
      padding: 17,
      radius: 22,
      icon: 15,
      tick: 14,
      label: true,
      labelSize: 9,
      labelGap: 7,
      questionGap: 12,
      min: 12,
      max: 19,
      lineHeight: 1.14,
      spacing: (size) => -0.6 * size / 19,
      alignment: Alignment.centerLeft,
      foot: true,
      footLines: 2,
    ),
    TileSize.xl => TileLook(
      padding: 20,
      radius: 26,
      icon: 17,
      tick: 16,
      label: true,
      labelSize: 10,
      labelGap: 8,
      questionGap: 14,
      min: 14,
      max: 26,
      lineHeight: 1.12,
      spacing: _spacingOf(26, 0.7),
      alignment: Alignment.centerLeft,
      foot: true,
    ),
  };

  /// A tile for any box: margins, corner and type that grow with the box,
  /// the subject's name once there is room for it, and a foot on a tile
  /// tall enough to carry one. The band of the question starts where the
  /// steps of a row start, by the box's shorter side, and its top grows with
  /// the box's area, so a card as wide as the page reads as a poster.
  static TileLook forBox(Size box) {
    final double side = math.min(box.width, box.height);
    final double min = side < 110
        ? 9.5
        : side < 150
        ? 10
        : side < 200
        ? 10.5
        : side < 260
        ? 12
        : 14;
    final double max = (math.sqrt(box.width * box.height) / 9.5).clamp(
      min + 2,
      38,
    );
    final bool foot = box.height >= 200 && box.width >= 180;
    return TileLook(
      padding: (side * 0.085).clamp(8, 24).roundToDouble(),
      radius: (side * 0.11).clamp(13, 30).roundToDouble(),
      icon: side < 110
          ? 12
          : side < 170
          ? 14
          : side < 260
          ? 15
          : 18,
      tick: side < 110
          ? 11
          : side < 170
          ? 13
          : side < 260
          ? 14
          : 17,
      label: box.width >= 150,
      labelSize: box.width >= 260 ? 10 : 9,
      labelGap: box.width >= 260 ? 8 : 7,
      questionGap: (side * 0.06).clamp(5, 16).roundToDouble(),
      min: min,
      max: max,
      lineHeight: max >= 24 ? 1.1 : 1.15,
      spacing: _spacingOf(15, 0.4),
      alignment: foot ? Alignment.centerLeft : Alignment.topLeft,
      foot: foot,
    );
  }

  /// Letter spacing that tightens with the size, [by] points at [at].
  static double Function(double) _spacingOf(double at, double by) =>
      (size) => -by * size / at;

  /// The question's type at [size].
  TextStyle questionStyle(Pill pill, double size) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: lineHeight,
    spacing: spacing(size),
    color: pill.ink,
  );

  /// The subject's name, small and spaced, in the card's quieter ink.
  TextStyle labelStyle(Pill pill) => AppText.label(
    size: labelSize,
    weight: FontWeight.w700,
    spacing: labelSize >= 10 ? 1.3 : 1.2,
    color: pill.ink.withValues(alpha: 0.66),
  );

  /// How long the card takes, in the foot.
  TextStyle minutesStyle(Pill pill) => AppText.label(
    size: 9,
    weight: FontWeight.w700,
    spacing: 1.2,
    color: pill.ink.withValues(alpha: 0.66),
  );

  /// The line to keep, in the foot of a card read.
  TextStyle moveStyle(Pill pill) => AppText.body(
    size: 11.5,
    weight: FontWeight.w500,
    height: 1.3,
    color: pill.ink,
  );
}

/// A card at one step of a row.
class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.pill,
    required this.size,
    this.read = false,
  });

  /// The card.
  final Pill pill;

  /// Its step; the height is the row's to give.
  final TileSize size;

  /// Read already: a tick by its mark, and on the steps with a foot, the line
  /// to keep in place of how long it takes.
  final bool read;

  @override
  Widget build(BuildContext context) => Container(
    width: size.width,
    padding: EdgeInsets.all(TileLook.of(size).padding),
    decoration: cardFace(context, pill.color, radius: TileLook.of(size).radius),
    child: TileBody(pill: pill, look: TileLook.of(size), read: read),
  );
}

/// A card in a box of any size: a cell of a grid or a mosaic, one of a pair,
/// the one card across the page.
class BoxTile extends StatelessWidget {
  const BoxTile({
    super.key,
    required this.pill,
    required this.box,
    this.read = false,
    this.look,
  });

  /// The card.
  final Pill pill;

  /// The tile's size.
  final Size box;

  /// Read already.
  final bool read;

  /// How it is drawn, when not as [TileLook.forBox] draws a box this size.
  final TileLook? look;

  @override
  Widget build(BuildContext context) {
    final TileLook drawn = look ?? TileLook.forBox(box);
    return Container(
      width: box.width,
      height: box.height,
      padding: EdgeInsets.all(drawn.padding),
      decoration: cardFace(context, pill.color, radius: drawn.radius),
      child: TileBody(pill: pill, look: drawn, read: read),
    );
  }
}

/// What is inside a tile's margins: the head, the question, the foot.
class TileBody extends StatelessWidget {
  const TileBody({
    super.key,
    required this.pill,
    required this.look,
    required this.read,
  });

  /// The card.
  final Pill pill;

  /// How it is drawn.
  final TileLook look;

  /// Read already.
  final bool read;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: look.label
              ? [
                  SubjectIcon(
                    subject: pill.topic,
                    size: look.icon,
                    ink: pill.ink,
                  ),
                  SizedBox(width: look.labelGap),
                  Flexible(
                    child: Text(
                      context.l10n.subjectOf(pill.topic).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: look.labelStyle(pill),
                    ),
                  ),
                  if (read) ...[
                    const SizedBox(width: 6),
                    ReadTick(pill: pill, color: pill.ink, size: look.tick),
                  ],
                ]
              : [
                  SubjectIcon(
                    subject: pill.topic,
                    size: look.icon,
                    ink: pill.ink,
                  ),
                  const Spacer(),
                  if (read)
                    ReadTick(pill: pill, color: pill.ink, size: look.tick),
                ],
        ),
        // The canvas was drawn around four-word questions and the pool is
        // not written to that length. Set to the space rather than cut with
        // an ellipsis: a question that stops mid-sentence is a card nobody
        // taps. From the top on a tile without a foot, whatever the length:
        // a short question at the bottom of its card next to a long one
        // filling its own reads as two designs on one shelf.
        Expanded(
          child: Padding(
            padding: look.foot
                ? EdgeInsets.symmetric(vertical: look.questionGap)
                : EdgeInsets.only(top: look.questionGap),
            child: ScaledText(
              text: pill.question,
              min: look.min,
              max: look.max,
              alignment: look.alignment,
              styleFor: (size) => look.questionStyle(pill, size),
            ),
          ),
        ),
        // The line to keep once the card is read; until then, only how long
        // it takes. Printed under a question nobody had answered, it gave the
        // answer away from the shelf.
        if (look.foot)
          if (read)
            Text(
              pill.barMove,
              maxLines: look.footLines,
              overflow: look.footLines == null ? null : TextOverflow.ellipsis,
              style: look.moveStyle(pill),
            )
          else
            Text(
              context.l10n.minutesShort(minutesFor(pill)),
              style: look.minutesStyle(pill),
            ),
      ],
    );
  }
}

/// A row of cards at one step, sideways, at the margins every shelf keeps:
/// the row of today's shelf at [TileSize.l], of the shelves further down at
/// [TileSize.m].
class TileRow extends StatelessWidget {
  const TileRow({
    super.key,
    required this.size,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  /// The step of its tiles.
  final TileSize size;

  /// The cards, in order.
  final List<Pill> pills;

  /// Whether the reader has read a card.
  final bool Function(Pill) isRead;

  /// A tile tapped: the card, with the rest of the row a swipe away.
  final void Function(List<Pill>, Pill) onOpen;

  /// Each card the row builds, which is a card it shows: a row builds a
  /// tile just before it slides into view.
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.row,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        itemCount: pills.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final pill = pills[i];
          onShown?.call(pill);
          return GestureDetector(
            key: ValueKey('explore-${pill.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onOpen(pills, pill),
            child: CardTile(pill: pill, size: size, read: isRead(pill)),
          );
        },
      ),
    );
  }
}

/// Whether [pill]'s question can be set whole in a tile of [box] drawn as
/// [look], at the smallest size the tile allows and the reader's text size:
/// what a section asks before it puts a card in a box.
///
/// It is measured the way [ScaledText] measures — at the size it falls back
/// to, every word whole on its line — in the room the tile's head and foot
/// leave, so a tile never holds a question it would have to scroll.
bool questionFits(
  BuildContext context,
  Pill pill,
  Size box,
  TileLook look, {
  bool read = false,
}) {
  final TextScaler scaler = MediaQuery.textScalerOf(context);
  final TextDirection direction = Directionality.of(context);
  final String key =
      '${pill.id}|${box.width.toStringAsFixed(1)}x'
      '${box.height.toStringAsFixed(1)}|${look.min}|${look.padding}|'
      '${look.icon}|${look.tick}|${look.label ? look.labelSize : 0}|'
      '${look.questionGap}|${look.foot}|${look.footLines}|$read|'
      '${scaler.scale(10)}|$direction';
  final bool? known = _fitted[key];
  if (known != null) return known;

  double lineOf(TextStyle style, {double? width, int? lines}) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: lines,
    )..layout(maxWidth: width ?? double.infinity);
    final double height = painter.height;
    painter.dispose();
    return height;
  }

  final double width = box.width - look.padding * 2;
  double room = box.height - look.padding * 2;
  room -= math.max(
    math.max(look.icon, look.tick),
    look.label ? lineOf(look.labelStyle(pill)) : 0,
  );
  room -= look.questionGap * (look.foot ? 2 : 1);
  if (look.foot) {
    if (read) {
      final TextPainter move = TextPainter(
        text: TextSpan(text: pill.barMove, style: look.moveStyle(pill)),
        textDirection: direction,
        textScaler: scaler,
        maxLines: look.footLines,
      )..layout(maxWidth: width);
      room -= move.height;
      move.dispose();
    } else {
      room -= lineOf(look.minutesStyle(pill));
    }
  }

  bool fits = false;
  if (width > 0 && room > 0) {
    // The size ScaledText falls back to: never below what the tile is drawn
    // for, as the reader sees it.
    final double floor = math.min(
      look.min,
      look.min * look.min / scaler.scale(look.min),
    );
    final TextStyle style = look.questionStyle(pill, floor);
    final TextPainter painter = TextPainter(
      text: TextSpan(text: pill.question, style: style),
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: width);
    fits = painter.height <= room && painter.width <= width;
    painter.dispose();
    if (fits) {
      for (final String word in pill.question.split(RegExp(r'\s+'))) {
        final TextPainter one = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final bool whole = one.width <= width;
        one.dispose();
        if (!whole) {
          fits = false;
          break;
        }
      }
    }
  }
  if (_fitted.length > 4000) _fitted.clear();
  return _fitted[key] = fits;
}

/// What [questionFits] found, by card, box and text size: a grid asks of
/// the same cards on every build, and the answer only changes with them.
final Map<String, bool> _fitted = {};

/// The cards to put in boxes of [boxes], in order, from [cards] in theirs:
/// each box the first card not yet placed whose question it holds whole.
/// The smallest boxes choose first, since they can hold the fewest; a box
/// no card fits is left empty (null), and the section leaves it out.
List<Pill?> fitCards(
  BuildContext context,
  List<Pill> cards,
  List<Size> boxes, {
  required bool Function(Pill) isRead,
  TileLook Function(Size box)? look,
}) {
  final List<int> order = List<int>.generate(boxes.length, (i) => i)
    ..sort((a, b) {
      final double byArea =
          boxes[a].width * boxes[a].height - boxes[b].width * boxes[b].height;
      return byArea != 0 ? byArea.sign.toInt() : a.compareTo(b);
    });
  final List<Pill?> placed = List<Pill?>.filled(boxes.length, null);
  final Set<String> used = {};
  for (final int i in order) {
    final TileLook drawn = (look ?? TileLook.forBox)(boxes[i]);
    for (final Pill pill in cards) {
      if (used.contains(pill.id)) continue;
      if (questionFits(context, pill, boxes[i], drawn, read: isRead(pill))) {
        placed[i] = pill;
        used.add(pill.id);
        break;
      }
    }
  }
  return placed;
}
