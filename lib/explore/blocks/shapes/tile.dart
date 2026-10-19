/// One card as a tile of a shape: its colour cut to an outline, a graphic
/// behind its words where it has one, the subject's mark, and the question
/// set to the room there is — Explore's card, in the shape of its shelf.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/explore/parts.dart';
import '../../../widgets/subject_icon.dart';
import 'look.dart';
import 'outlines.dart';

/// Where a tile's words stand.
enum TileWords {
  /// The head, then the question from the top: most tiles.
  top,

  /// The head, then the question in the middle of what is left: the large
  /// tiles, whose question is the poster.
  middle,

  /// The mark and the question centred: the arch.
  centred,

  /// The mark, the figure set large and the question under it, centred: the
  /// capsule of a number that surprises.
  figure,

  /// The figure large in the top corner, the mark across from it, the
  /// question at the foot: a number's tile on a grid.
  figureTop,
}

/// How a tile is cut and set.
@immutable
class TileLook {
  const TileLook({
    required this.outline,
    this.padding = const EdgeInsets.all(14),
    this.named = false,
    this.words = TileWords.top,
    this.min = 10.5,
    this.max = 15,
    this.lineHeight = 1.15,
    this.tracking = -0.027,
    this.gap = 10,
    this.markInset = 0,
    this.figureSize = 40,
    this.tickBeside = false,
  });

  final TileOutline outline;
  final EdgeInsets padding;

  /// Whether the head names the subject beside its mark.
  final bool named;
  final TileWords words;

  /// The band the question's type may move in, as the reader sees it.
  final double min;
  final double max;
  final double lineHeight;

  /// Letter spacing, in ems.
  final double tracking;

  /// Between the head and the question.
  final double gap;

  /// How far in the mark sits from the padding: the leaf's long corner
  /// would otherwise crowd it.
  final double markInset;

  /// The figure's size, on a tile that sets one.
  final double figureSize;

  /// Whether the tick of a card read goes beside the mark: the tile's far
  /// corner is taken.
  final bool tickBeside;
}

/// The figure a number card is about, set as large as its line allows, in
/// [colour].
class FigureText extends StatelessWidget {
  const FigureText({
    super.key,
    required this.figure,
    required this.size,
    required this.colour,
    this.alignment = Alignment.centerLeft,
    this.height = 0.9,
  });

  final String figure;
  final double size;
  final Color colour;
  final Alignment alignment;
  final double height;

  @override
  Widget build(BuildContext context) {
    // A figure is one word: it scales down to its line rather than break,
    // as the app's own numbers shelf sets it.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        figure,
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: AppText.display(
          size: size,
          weight: FontWeight.w600,
          height: height,
          spacing: -0.04 * size,
          color: colour,
        ),
      ),
    );
  }
}

/// How tall [text] stands set by [look] [width] wide at its smallest, as the
/// reader sees it: the question of a tile that has the least room for it.
///
/// Measured as the app's own fitting sets it (ScaledText): at the reader's
/// text size, at the smallest size the reader will see, and in their
/// direction.
double questionHeight(
  BuildContext context,
  String text,
  TileLook look,
  double width,
) {
  final TextScaler scaler = MediaQuery.textScalerOf(context);
  final double least = math.min(
    look.min,
    look.min * look.min / scaler.scale(look.min),
  );
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: AppText.display(
        size: least,
        weight: FontWeight.w600,
        height: look.lineHeight,
        spacing: look.tracking * least,
      ),
    ),
    textDirection: Directionality.of(context),
    textScaler: scaler,
  )..layout(maxWidth: math.max(0, width));
  final double height = painter.height;
  painter.dispose();
  return height;
}

/// How tall a tile [width] wide, cut and set by [look], must stand for
/// [pill]'s question to fit whole at its smallest, so it never has to be
/// scrolled inside its tile: a shape whose tiles are shorter than this for
/// a card it is dealt grows to it, all its tiles alike.
///
/// [read] and [figure] are what the tile shows beside the question: the
/// tick of a card read, the figure of a number.
double tileHeightFor(
  BuildContext context,
  Pill pill,
  TileLook look, {
  required double width,
  bool read = false,
  bool figure = false,
}) {
  final double inner = width - look.padding.horizontal;
  // The mark and the tick, on the tiles that centre them.
  const double marks = 15;
  final double above = switch (look.words) {
    TileWords.top || TileWords.middle =>
      ShapeHead.heightFor(
            context,
            pill,
            width: inner - look.markInset,
            named: look.named,
            read: read,
          ) +
          look.gap,
    TileWords.centred => marks + look.gap,
    TileWords.figure =>
      marks + look.gap + (figure ? look.figureSize * 0.95 + 8 : 0),
    TileWords.figureTop => look.figureSize * 0.86 + look.gap,
  };
  // A pixel over, for the fractions a paragraph is laid out in.
  return look.padding.vertical +
      above +
      questionHeight(context, pill.question, look, inner) +
      1;
}

/// One card, cut and set by [look], with [art] painted and [behind] laid
/// under its words.
class ShapeTile extends StatelessWidget {
  const ShapeTile({
    super.key,
    required this.pill,
    required this.look,
    this.read = false,
    this.art = const [],
    this.behind,
    this.figure,
    this.figureColour,
    this.ground,
  });

  final Pill pill;
  final TileLook look;
  final bool read;
  final List<FaceArt> art;
  final Widget? behind;

  /// The figure, for a tile whose words set one.
  final String? figure;

  /// Its colour: the card's ink unless told.
  final Color? figureColour;

  /// What the tile lies on, when it is not the page.
  final Color? ground;

  @override
  Widget build(BuildContext context) {
    return OutlinedFace(
      outline: look.outline,
      colour: pill.color,
      art: art,
      behind: behind,
      ground: ground,
      padding: look.padding,
      child: _words(context),
    );
  }

  Widget _question({required Alignment alignment, bool centred = false}) {
    final Widget q = CardQuestion(
      text: pill.question,
      color: pill.ink,
      min: look.min,
      max: look.max,
      height: look.lineHeight,
      tracking: look.tracking,
      alignment: alignment,
    );
    // The fitted question is a plain paragraph; centring it is the page's
    // default alignment, which it takes up, and does not change where its
    // lines break or how tall it is.
    return centred
        ? DefaultTextStyle.merge(textAlign: TextAlign.center, child: q)
        : q;
  }

  Widget _centredMark() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SubjectIcon(subject: pill.topic, size: 15, ink: pill.ink),
      if (read) ...[const SizedBox(width: 6), ReadMark(pill: pill)],
    ],
  );

  Widget _words(BuildContext context) {
    final Widget head = Padding(
      padding: EdgeInsets.only(left: look.markInset),
      child: ShapeHead(
        pill: pill,
        named: look.named,
        read: read,
        tickBeside: look.tickBeside,
      ),
    );
    switch (look.words) {
      case TileWords.top:
      case TileWords.middle:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            head,
            SizedBox(height: look.gap),
            Expanded(
              child: _question(
                alignment: look.words == TileWords.top
                    ? Alignment.topLeft
                    : Alignment.centerLeft,
              ),
            ),
          ],
        );
      case TileWords.centred:
        return Column(
          children: [
            _centredMark(),
            SizedBox(height: look.gap),
            Expanded(
              child: _question(alignment: Alignment.topCenter, centred: true),
            ),
          ],
        );
      case TileWords.figure:
        final String? f = figure;
        return Column(
          children: [
            _centredMark(),
            if (f != null) ...[
              SizedBox(height: look.gap),
              SizedBox(
                height: look.figureSize * 0.95,
                width: double.infinity,
                child: FigureText(
                  figure: f,
                  size: look.figureSize,
                  colour: figureColour ?? pill.ink,
                  alignment: Alignment.center,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 8),
            ] else
              SizedBox(height: look.gap),
            Expanded(
              child: _question(alignment: Alignment.topCenter, centred: true),
            ),
          ],
        );
      case TileWords.figureTop:
        final String? f = figure;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: look.figureSize * 0.86,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: f == null
                        ? const SizedBox.shrink()
                        : Transform.translate(
                            offset: const Offset(-2, 0),
                            child: FigureText(
                              figure: f,
                              size: look.figureSize,
                              colour: figureColour ?? pill.ink,
                              alignment: Alignment.topLeft,
                              height: 0.86,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _centredMark(),
                  ),
                ],
              ),
            ),
            SizedBox(height: look.gap),
            Expanded(child: _question(alignment: Alignment.bottomLeft)),
          ],
        );
    }
  }
}
