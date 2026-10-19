/// How a tile is cut: the silhouettes of round 131d and the folded corner of
/// 131b, each a path worked out for whatever size the tile is given, so a
/// shape is as crisp on the largest phone as on the smallest and a tile can
/// be any size its section asks for.
///
/// Outlines and what is painted on a face are values: two built alike are
/// equal, so a tile rebuilt with the same look is neither re-cut nor
/// repainted.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../widgets/card_edge.dart';

/// One way of cutting a tile.
@immutable
abstract class TileOutline {
  const TileOutline();

  /// The tile's edge at [size].
  Path pathFor(Size size);
}

/// A card's own corners, all alike: the app's tile.
class RoundOutline extends TileOutline {
  const RoundOutline(this.radius);

  final double radius;

  @override
  Path pathFor(Size size) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(_fit(radius, size)),
      ),
    );

  @override
  bool operator ==(Object other) =>
      other is RoundOutline && other.radius == radius;

  @override
  int get hashCode => Object.hash(RoundOutline, radius);
}

/// Each corner its own: the arch (a half circle over a card), the leaf (two
/// opposite corners drawn long), the capsule (both ends round).
class CornersOutline extends TileOutline {
  const CornersOutline({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  /// Round at both ends, whatever the tile's width: a pill stood on end.
  const CornersOutline.capsule()
    : topLeft = double.infinity,
      topRight = double.infinity,
      bottomRight = double.infinity,
      bottomLeft = double.infinity;

  /// A half circle over a card: the window of an arcade.
  const CornersOutline.arch(double radius)
    : topLeft = double.infinity,
      topRight = double.infinity,
      bottomRight = radius,
      bottomLeft = radius;

  final double topLeft;
  final double topRight;
  final double bottomRight;
  final double bottomLeft;

  @override
  Path pathFor(Size size) => Path()
    ..addRRect(
      RRect.fromRectAndCorners(
        Offset.zero & size,
        topLeft: Radius.circular(_fit(topLeft, size)),
        topRight: Radius.circular(_fit(topRight, size)),
        bottomRight: Radius.circular(_fit(bottomRight, size)),
        bottomLeft: Radius.circular(_fit(bottomLeft, size)),
      ),
    );

  @override
  bool operator ==(Object other) =>
      other is CornersOutline &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomRight == bottomRight &&
      other.bottomLeft == bottomLeft;

  @override
  int get hashCode =>
      Object.hash(CornersOutline, topLeft, topRight, bottomRight, bottomLeft);
}

/// The top right corner folded down, as a page of a book is to keep a place:
/// the cut, here, and the flap, which is drawn over it ([flapFor]).
class FoldOutline extends TileOutline {
  const FoldOutline({required this.radius, required this.fold});

  final double radius;

  /// How far along each edge the fold runs.
  final double fold;

  double _fold(Size size) =>
      math.min(fold, math.min(size.width, size.height) / 2);

  @override
  Path pathFor(Size size) {
    final double w = size.width, h = size.height;
    final double r = _fit(radius, size);
    final double f = _fold(size);
    return Path()
      ..moveTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(w - f, 0)
      ..lineTo(w, f)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..close();
  }

  /// The flap: the corner turned down onto the page, its inside corner
  /// rounded the way paper bends.
  Path flapFor(Size size) {
    final double w = size.width;
    final double f = _fold(size);
    final double bend = math.min(10, f * 0.3);
    return Path()
      ..moveTo(w - f, 0)
      ..lineTo(w - f, f - bend)
      ..arcToPoint(
        Offset(w - f + bend, f),
        radius: Radius.circular(bend),
        clockwise: false,
      )
      ..lineTo(w, f)
      ..close();
  }

  @override
  bool operator ==(Object other) =>
      other is FoldOutline && other.radius == radius && other.fold == fold;

  @override
  int get hashCode => Object.hash(FoldOutline, radius, fold);
}

/// Round at the top, torn along the bottom: a page ripped out of a book of
/// things everybody believed.
class TornOutline extends TileOutline {
  const TornOutline({required this.radius, this.tooth = 13});

  final double radius;

  /// The width of one tooth of the tear; its depth is half of it.
  final double tooth;

  @override
  Path pathFor(Size size) {
    final double w = size.width, h = size.height;
    final double r = _fit(radius, size);
    // A whole number of teeth, so the tear starts and ends the same way.
    final int n = math.max(1, (w / tooth).round());
    final double step = w / n;
    final double depth = step / 2;
    final Path p = Path()
      ..moveTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, h - depth);
    for (int k = 0; k < n; k++) {
      p
        ..lineTo(w - (k + 0.5) * step, h)
        ..lineTo(w - (k + 1) * step, h - depth);
    }
    return p..close();
  }

  @override
  bool operator ==(Object other) =>
      other is TornOutline && other.radius == radius && other.tooth == tooth;

  @override
  int get hashCode => Object.hash(TornOutline, radius, tooth);
}

/// A folder: a tab on its top left, joined to the body by a curve.
class TabOutline extends TileOutline {
  const TabOutline({
    required this.radius,
    required this.tabWidth,
    required this.tabHeight,
  });

  final double radius;
  final double tabWidth;
  final double tabHeight;

  /// Where the body begins under the tab.
  double bodyTop(Size size) => math.min(tabHeight, size.height / 3);

  @override
  Path pathFor(Size size) {
    final double w = size.width, h = size.height;
    final double th = bodyTop(size);
    final double tw = math.min(tabWidth, w * 0.6);
    // The tab's corners and the curve that joins it to the body share its
    // height, so neither runs into the other.
    final double tr = th * 0.58;
    final double f = th - tr;
    final double r = math.min(radius, math.min(w, h - th) / 2);
    return Path()
      ..moveTo(0, tr)
      ..arcToPoint(Offset(tr, 0), radius: Radius.circular(tr))
      ..lineTo(tw - tr, 0)
      ..arcToPoint(Offset(tw, tr), radius: Radius.circular(tr))
      ..arcToPoint(
        Offset(tw + f, th),
        radius: Radius.circular(f),
        clockwise: false,
      )
      ..lineTo(w - r, th)
      ..arcToPoint(Offset(w, th + r), radius: Radius.circular(r))
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..close();
  }

  @override
  bool operator ==(Object other) =>
      other is TabOutline &&
      other.radius == radius &&
      other.tabWidth == tabWidth &&
      other.tabHeight == tabHeight;

  @override
  int get hashCode => Object.hash(TabOutline, radius, tabWidth, tabHeight);
}

/// A ticket: a half circle bitten out of either side where the stub tears
/// off.
class TicketOutline extends TileOutline {
  const TicketOutline({
    required this.radius,
    required this.notch,
    required this.at,
  });

  final double radius;
  final double notch;

  /// How far down the tile the stub begins.
  final double at;

  @override
  Path pathFor(Size size) {
    final Path card = RoundOutline(radius).pathFor(size);
    final double y = math.min(at, size.height - notch);
    final Path bites = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(size.width, y), radius: notch));
    return Path.combine(PathOperation.difference, card, bites);
  }

  @override
  bool operator ==(Object other) =>
      other is TicketOutline &&
      other.radius == radius &&
      other.notch == notch &&
      other.at == at;

  @override
  int get hashCode => Object.hash(TicketOutline, radius, notch, at);
}

/// A postage stamp: square corners, and every edge perforated.
class StampOutline extends TileOutline {
  const StampOutline({this.hole = 3.8, this.pitch = 12});

  /// The radius of one perforation, which sits on the edge so half of it
  /// bites into the stamp.
  final double hole;

  /// The distance between two, adjusted so a whole number fits each edge.
  final double pitch;

  @override
  Path pathFor(Size size) {
    final double w = size.width, h = size.height;
    final Path holes = Path();
    final int across = math.max(2, (w / pitch).round());
    final int down = math.max(2, (h / pitch).round());
    for (int i = 0; i <= across; i++) {
      final double x = w * i / across;
      holes
        ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: hole))
        ..addOval(Rect.fromCircle(center: Offset(x, h), radius: hole));
    }
    for (int j = 1; j < down; j++) {
      final double y = h * j / down;
      holes
        ..addOval(Rect.fromCircle(center: Offset(0, y), radius: hole))
        ..addOval(Rect.fromCircle(center: Offset(w, y), radius: hole));
    }
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      holes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StampOutline && other.hole == hole && other.pitch == pitch;

  @override
  int get hashCode => Object.hash(StampOutline, hole, pitch);
}

/// A corner no larger than the tile allows: half its shorter side, at most.
double _fit(double radius, Size size) =>
    math.min(radius, math.min(size.width, size.height) / 2);

/// Something painted on a tile's face, under its words: a signature, a
/// second tone. A value, like an outline.
@immutable
abstract class FaceArt {
  const FaceArt();

  /// Paints itself on a face of [size], inside its outline.
  void paint(Canvas canvas, Size size);
}

/// A card's face cut to [outline]: its colour, the [art] painted on it, what
/// lies [behind] its words, and the words — and, on paper, where the colour
/// is too like the page for the eye to find its edge, the hairline every
/// card on the app is cut out with (lib/widgets/card_edge.dart).
class OutlinedFace extends StatelessWidget {
  const OutlinedFace({
    super.key,
    required this.outline,
    required this.colour,
    required this.child,
    this.art = const [],
    this.behind,
    this.ground,
    this.padding = EdgeInsets.zero,
  });

  final TileOutline outline;
  final Color colour;
  final Widget child;

  /// Painted on the colour, in order, under everything else.
  final List<FaceArt> art;

  /// Laid under the words: the subject's mark drawn large.
  final Widget? behind;

  /// What the tile lies on: the page, unless it lies on something else.
  final Color? ground;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final Color page = ground ?? context.p.surface;
    final bool edged = colourContrast(colour, page) < kEdgeContrast;
    return CustomPaint(
      painter: _FacePainter(outline, colour, art),
      foregroundPainter: edged
          ? _EdgePainter(outline, cardEdgeColour(colour))
          : null,
      child: ClipPath(
        clipper: _OutlineClipper(outline),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (behind != null) Positioned.fill(child: behind!),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.outline, this.colour, this.art);

  final TileOutline outline;
  final Color colour;
  final List<FaceArt> art;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = outline.pathFor(size);
    canvas.drawPath(path, Paint()..color = colour);
    if (art.isEmpty) return;
    canvas.save();
    canvas.clipPath(path);
    for (final FaceArt a in art) {
      a.paint(canvas, size);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.outline != outline ||
      old.colour != colour ||
      !listEquals(old.art, art);
}

class _EdgePainter extends CustomPainter {
  _EdgePainter(this.outline, this.colour);

  final TileOutline outline;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    // A width of nought is one device pixel, whatever the phone: the cut
    // edge of a printed card, not a line drawn round it.
    canvas.drawPath(
      outline.pathFor(size),
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0,
    );
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.outline != outline || old.colour != colour;
}

class _OutlineClipper extends CustomClipper<Path> {
  _OutlineClipper(this.outline);

  final TileOutline outline;

  @override
  Path getClip(Size size) => outline.pathFor(size);

  @override
  bool shouldReclip(_OutlineClipper old) => old.outline != outline;
}
