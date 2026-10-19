/// One confident graphic per kind of shelf (design 132), drawn in a darker
/// tone of the card's own colour so it never fights the text: a quote
/// struck out for a myth, two circles that overlap for a paradox, a sun
/// about to set for something to try before tonight, a postmark for a
/// place, the card split in two for a debate, the subject's own mark for a
/// month of it. Each is laid out against the tile it is drawn on rather
/// than at the canvas's pixel positions, so it sits the same on a tile of
/// any size.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/explore/parts.dart' show shade;
import '../../../widgets/subject_icon.dart';
import 'outlines.dart';

/// The darker tones the canvas draws its signatures in, as fractions of the
/// card's colour: the graphic, the part of it drawn over itself, the second
/// half of a card, the corner turned down, the card behind.
abstract final class Tones {
  static const double graphic = 0.86;
  static const double over = 0.74;
  static const double half = 0.84;
  static const double fold = 0.70;
  static const double behind = 0.42;
}

/// The card's colour taken down to [k] of itself.
Color tone(Pill p, double k) => shade(p.color, k);

/// The second half of a card, either side of a line down its middle, or
/// of one from corner to corner.
class SplitArt extends FaceArt {
  const SplitArt.halves(this.colour) : diagonal = false;
  const SplitArt.diagonal(this.colour) : diagonal = true;

  final Color colour;
  final bool diagonal;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = colour;
    if (!diagonal) {
      canvas.drawRect(
        Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
        paint,
      );
      return;
    }
    // The line runs corner to corner whatever the tile's shape, as the
    // canvas's gradient does: the lower right is the darker tone.
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      paint,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SplitArt && other.colour == colour && other.diagonal == diagonal;

  @override
  int get hashCode => Object.hash(SplitArt, colour, diagonal);
}

/// The corner of a page turned down (131b's folded corner).
class FlapArt extends FaceArt {
  const FlapArt(this.outline, this.colour);

  final FoldOutline outline;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawPath(outline.flapFor(size), Paint()..color = colour);

  @override
  bool operator ==(Object other) =>
      other is FlapArt && other.outline == outline && other.colour == colour;

  @override
  int get hashCode => Object.hash(FlapArt, outline, colour);
}

/// A myth: an opening quote mark, large, and a bar struck through it.
///
/// Set against the tile's height, which is what the canvas's two sizes of
/// it share: the mark is a little taller than the tile and runs off its
/// foot, and the bar crosses it at the angle a pen would.
class QuoteArt extends FaceArt {
  const QuoteArt({required this.mark, required this.bar});

  final Color mark;
  final Color bar;

  @override
  void paint(Canvas canvas, Size size) {
    final double g = math.min(size.height * 1.3, size.width * 1.58);
    final TextPainter glyph = TextPainter(
      text: TextSpan(
        text: '“',
        style: AppText.display(
          size: g,
          weight: FontWeight.w600,
          height: 1,
          color: mark,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final double right = size.width - g * 0.02;
    final double top = size.height - g * 0.47;
    glyph.paint(canvas, Offset(right - glyph.width, top));
    glyph.dispose();
    final double length = g * 0.5;
    final double thick = g * 0.0235;
    canvas
      ..save()
      ..translate(right - g * 0.29, top + g * 0.3)
      ..rotate(-22 * math.pi / 180)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: length, height: thick),
          Radius.circular(thick),
        ),
        Paint()..color = bar,
      )
      ..restore();
  }

  @override
  bool operator ==(Object other) =>
      other is QuoteArt && other.mark == mark && other.bar == bar;

  @override
  int get hashCode => Object.hash(QuoteArt, mark, bar);
}

/// A paradox: two circles that overlap, rising from the foot of the tile,
/// the part they share in the deeper tone — two true things that should not
/// both be true.
class CirclesArt extends FaceArt {
  const CirclesArt({required this.disc, required this.overlap});

  final Color disc;
  final Color overlap;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double r = math.min(w * 0.29, size.height * 0.36);
    final double y = size.height - w * 0.126;
    final Path left = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.33, y), radius: r));
    final Path right = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.67, y), radius: r));
    final Paint fill = Paint()..color = disc;
    canvas
      ..drawPath(left, fill)
      ..drawPath(right, fill)
      ..drawPath(
        Path.combine(PathOperation.intersect, left, right),
        Paint()..color = overlap,
      );
  }

  @override
  bool operator ==(Object other) =>
      other is CirclesArt && other.disc == disc && other.overlap == overlap;

  @override
  int get hashCode => Object.hash(CirclesArt, disc, overlap);
}

/// Something to try before tonight: a sun low in the corner, its lower part
/// already gone behind whatever the tile stands on.
class SunArt extends FaceArt {
  const SunArt({
    required this.colour,
    required this.radius,
    required this.fromCorner,
  });

  final Color colour;
  final double radius;

  /// Where its centre is, from the tile's bottom right corner.
  final Offset fromCorner;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(
    Offset(size.width, size.height) + fromCorner,
    radius,
    Paint()..color = colour,
  );

  @override
  bool operator ==(Object other) =>
      other is SunArt &&
      other.colour == colour &&
      other.radius == radius &&
      other.fromCorner == fromCorner;

  @override
  int get hashCode => Object.hash(SunArt, colour, radius, fromCorner);
}

/// A place: a postmark's two rings, half off the corner of the stamp.
class PostmarkArt extends FaceArt {
  const PostmarkArt({required this.colour, this.scale = 1});

  final Color colour;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width - 23 * scale, size.height - 23 * scale);
    final Paint ring = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke;
    canvas
      ..drawCircle(c, 38 * scale, ring..strokeWidth = 2 * scale)
      ..drawCircle(c, 29 * scale, ring..strokeWidth = 1.2 * scale);
  }

  @override
  bool operator ==(Object other) =>
      other is PostmarkArt && other.colour == colour && other.scale == scale;

  @override
  int get hashCode => Object.hash(PostmarkArt, colour, scale);
}

/// A postcard's postmark: two wavy lines beside its stamp.
class WavesArt extends FaceArt {
  const WavesArt({required this.colour, required this.at, this.scale = 1});

  final Color colour;

  /// The top right corner of the lines, from the tile's top right.
  final Offset at;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = 30 * scale;
    final Offset origin = Offset(size.width - at.dx - w, at.dy);
    final Paint line = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * scale
      ..strokeCap = StrokeCap.round;
    for (final double base in [3 * scale, 10 * scale]) {
      // Two waves to the line, as the canvas draws them: four half waves
      // of 7.5 across, up two and down again.
      double from = origin.dy + base;
      final Path p = Path()..moveTo(origin.dx, from);
      for (int k = 0; k < 4; k++) {
        final double x0 = origin.dx + k * 7.5 * scale;
        final double to = origin.dy + base - (k.isEven ? 2 * scale : 0);
        p.cubicTo(
          x0 + 3.75 * scale,
          from,
          x0 + 3.75 * scale,
          to,
          x0 + 7.5 * scale,
          to,
        );
        from = to;
      }
      canvas.drawPath(p, line);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is WavesArt &&
      other.colour == colour &&
      other.at == at &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(WavesArt, colour, at, scale);
}

/// A month of one subject: its own mark drawn large behind the words,
/// tipped and cut by the tile's edge, at the weight the mark is drawn
/// large everywhere (lib/widgets/explore/month_shelf.dart).
class MarkBehind extends StatelessWidget {
  const MarkBehind({super.key, required this.pill, this.angle = -14});

  final Pill pill;

  /// How far it is tipped, in degrees.
  final double angle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double m = box.maxWidth * 1.14;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -m * 0.276,
              bottom: -m * 0.3,
              child: Transform.rotate(
                angle: angle * math.pi / 180,
                child: SubjectIcon(
                  subject: pill.topic,
                  size: m,
                  stroke: 2.4,
                  ink: tone(pill, Tones.graphic),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
