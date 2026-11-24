/// The drawings of Go deeper (deeper_sheet.dart): each part's own small
/// picture, drawn the way the drawn cards draw (docs/cards/STILE.md): flat
/// colours, a thick near-black outline, round joins. Each one draws itself
/// in as its part arrives — the blocks drop, the arrow lands, the scale
/// settles — and is still for a reader who asked for less motion.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../chunky.dart' show chunkyEdge;
import 'look.dart';

/// What a part's picture shows.
enum DeeperArt {
  /// Three toy blocks, a circle, a triangle and a diamond on them: the idea
  /// said simply.
  blocks,

  /// An arrow in the middle of a target: why it matters, where it lands.
  target,

  /// A balance with a pan for each side: the two views.
  scale,

  /// A cup on its saucer, steaming: an everyday moment.
  cup,

  /// A clipboard of three answers, one ticked: a test on a new case.
  quiz,

  /// A lens over a speech bubble: the reader's own idea, looked at.
  lens,

  /// Two speech bubbles, a question and an answer coming: ask.
  chat,

  /// An open book with its ribbon: the source.
  book,
}

/// A part's mark: its picture on a square of the part's colour, the square
/// sitting on a darker edge as the app's buttons do.
class DeeperMedallion extends StatelessWidget {
  const DeeperMedallion({
    super.key,
    required this.art,
    required this.vivid,
    required this.accent,
    required this.second,
    required this.progress,
    this.size = 58,
  });

  final DeeperArt art;

  /// The square's colour, and the picture's main one.
  final DeeperVivid vivid;

  /// The colour across the wheel from it, for the one detail that should
  /// stand out: a triangle, the arrow's feathers, the ribbon.
  final Color accent;

  /// A second colour beside [accent], where a picture needs two: the
  /// balance's other pan.
  final Color second;

  /// How far the picture has drawn itself in, 0 to 1.
  final Animation<double> progress;

  final double size;

  @override
  Widget build(BuildContext context) {
    final double depth = (size * 0.065).roundToDouble();
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(size, size + depth),
          painter: _MedallionPainter(
            art: art,
            vivid: vivid,
            accent: accent,
            second: second,
            progress: progress,
            depth: depth,
          ),
        ),
      ),
    );
  }
}

/// The part of [t] that falls between [a] and [b], as 0 to 1.
double _seg(double t, double a, double b) =>
    b <= a ? (t >= b ? 1 : 0) : ((t - a) / (b - a)).clamp(0.0, 1.0);

double _back(double v) => Curves.easeOutBack.transform(v);
double _out(double v) => Curves.easeOutCubic.transform(v);

class _MedallionPainter extends CustomPainter {
  _MedallionPainter({
    required this.art,
    required this.vivid,
    required this.accent,
    required this.second,
    required this.progress,
    required this.depth,
  }) : super(repaint: progress);

  final DeeperArt art;
  final DeeperVivid vivid;
  final Color accent;
  final Color second;
  final Animation<double> progress;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.value.clamp(0.0, 1.0);
    if (t <= 0) return;
    final double s = size.width;
    final Rect face = Rect.fromLTWH(0, 0, s, s);
    final Radius r = Radius.circular(s * 0.31);

    // The square pops into place: up from a little smaller, past its size,
    // back.
    final double pop = _back(_seg(t, 0, 0.42));
    canvas.save();
    final double grow = 0.62 + 0.38 * pop;
    canvas.translate(s / 2, s / 2 + depth / 2);
    canvas.scale(grow, grow);
    canvas.translate(-s / 2, -s / 2 - depth / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(face.shift(Offset(0, depth)), r),
      Paint()..color = chunkyEdge(vivid.deep, 0.13),
    );
    final RRect square = RRect.fromRectAndRadius(face, r);
    canvas.drawRRect(
      square,
      Paint()
        ..shader = ui.Gradient.linear(face.topLeft, face.bottomRight, [
          vivid.fill,
          vivid.deep,
        ]),
    );
    // Light on the upper half, as on a glazed tile.
    canvas.drawRRect(
      square,
      Paint()
        ..shader = ui.Gradient.linear(face.topCenter, face.center, [
          Colors.white.withValues(alpha: 0.26),
          Colors.white.withValues(alpha: 0),
        ]),
    );

    canvas.save();
    canvas.clipRRect(square);
    // The picture is drawn on a 64-unit grid, inset in the square.
    final double inset = s * 0.07;
    final double k = (s - inset * 2) / 64;
    canvas.translate(inset, inset);
    canvas.scale(k, k);
    final _Ink ink = _Ink(
      line: kDeeperLine,
      cream: kDeeperCream,
      main: Color.lerp(vivid.fill, Colors.white, 0.08)!,
      deep: vivid.deep,
      light: Color.lerp(vivid.fill, Colors.white, 0.55)!,
      accent: accent,
      second: second,
      onMain: vivid.ink,
    );
    final double u = _seg(t, 0.08, 1);
    switch (art) {
      case DeeperArt.blocks:
        _blocks(canvas, u, ink);
      case DeeperArt.target:
        _target(canvas, u, ink);
      case DeeperArt.scale:
        _scale(canvas, u, ink);
      case DeeperArt.cup:
        _cup(canvas, u, ink);
      case DeeperArt.quiz:
        _quiz(canvas, u, ink);
      case DeeperArt.lens:
        _lens(canvas, u, ink);
      case DeeperArt.chat:
        _chat(canvas, u, ink);
      case DeeperArt.book:
        _book(canvas, u, ink);
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MedallionPainter old) =>
      old.art != art ||
      old.vivid != vivid ||
      old.accent != accent ||
      old.second != second ||
      old.progress != progress;
}

/// The colours one picture is drawn in.
class _Ink {
  const _Ink({
    required this.line,
    required this.cream,
    required this.main,
    required this.deep,
    required this.light,
    required this.accent,
    required this.second,
    required this.onMain,
  });

  final Color line;
  final Color cream;
  final Color main;
  final Color deep;
  final Color light;
  final Color accent;
  final Color second;
  final Color onMain;

  Paint stroke([double width = 3.2]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = line;

  /// [path] filled with [fill] and outlined.
  void shape(Canvas c, Path path, Color fill, [double width = 3.2]) {
    c.drawPath(path, Paint()..color = fill);
    c.drawPath(path, stroke(width));
  }
}

/// [path] drawn up to [v] of its length.
Path _part(Path path, double v) {
  if (v >= 1) return path;
  final Path out = Path();
  if (v <= 0) return out;
  for (final ui.PathMetric m in path.computeMetrics()) {
    out.addPath(m.extractPath(0, m.length * v), Offset.zero);
  }
  return out;
}

Path _rrect(double l, double t, double r, double b, double radius) =>
    Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));

/// Scales whatever is drawn next by [scale] about [at].
void _about(Canvas c, Offset at, double scale) {
  c.translate(at.dx, at.dy);
  c.scale(scale, scale);
  c.translate(-at.dx, -at.dy);
}

// ── The pictures, each on a 64-unit grid ───────────────────────────────

void _blocks(Canvas c, double t, _Ink ink) {
  void block(double x, double y, double drop, void Function(Rect) mark) {
    if (drop <= 0) return;
    const double s = 18;
    const double d = 5;
    c.save();
    c.translate(0, -30 * (1 - _back(drop)));
    final Path top = Path()
      ..moveTo(x, y)
      ..lineTo(x + d, y - d)
      ..lineTo(x + s + d, y - d)
      ..lineTo(x + s, y)
      ..close();
    final Path side = Path()
      ..moveTo(x + s, y)
      ..lineTo(x + s + d, y - d)
      ..lineTo(x + s + d, y + s - d)
      ..lineTo(x + s, y + s)
      ..close();
    ink.shape(c, top, ink.light);
    ink.shape(c, side, ink.deep);
    final Rect front = Rect.fromLTWH(x, y, s, s);
    ink.shape(
      c,
      Path()
        ..addRRect(RRect.fromRectAndRadius(front, const Radius.circular(2))),
      ink.cream,
    );
    mark(front);
    c.restore();
  }

  block(8, 41, _seg(t, 0, 0.45), (f) {
    ink.shape(
      c,
      Path()..addOval(Rect.fromCircle(center: f.center, radius: 4.6)),
      ink.main,
      2.4,
    );
  });
  block(31, 41, _seg(t, 0.14, 0.6), (f) {
    final Offset m = f.center;
    ink.shape(
      c,
      Path()
        ..moveTo(m.dx, m.dy - 5.2)
        ..lineTo(m.dx + 5.6, m.dy + 4.2)
        ..lineTo(m.dx - 5.6, m.dy + 4.2)
        ..close(),
      ink.accent,
      2.4,
    );
  });
  block(19.5, 23, _seg(t, 0.32, 0.82), (f) {
    final Offset m = f.center;
    ink.shape(
      c,
      Path()
        ..moveTo(m.dx, m.dy - 5.4)
        ..lineTo(m.dx + 5.4, m.dy)
        ..lineTo(m.dx, m.dy + 5.4)
        ..lineTo(m.dx - 5.4, m.dy)
        ..close(),
      ink.second,
      2.4,
    );
  });
}

void _target(Canvas c, double t, _Ink ink) {
  const Offset mid = Offset(29, 37);
  final double grow = _back(_seg(t, 0, 0.5));
  if (grow > 0) {
    c.save();
    _about(c, mid, grow);
    ink.shape(
      c,
      Path()..addOval(Rect.fromCircle(center: mid, radius: 23)),
      ink.cream,
    );
    ink.shape(
      c,
      Path()..addOval(Rect.fromCircle(center: mid, radius: 16.5)),
      ink.main,
    );
    ink.shape(
      c,
      Path()..addOval(Rect.fromCircle(center: mid, radius: 10)),
      ink.cream,
    );
    ink.shape(
      c,
      Path()..addOval(Rect.fromCircle(center: mid, radius: 4.2)),
      ink.accent,
      2.6,
    );
    c.restore();
  }
  // The arrow flies in along its own line, lands, and shivers.
  final double fly = _seg(t, 0.38, 0.72);
  if (fly <= 0) return;
  const Offset hit = Offset(31.5, 34.5);
  final Offset along = const Offset(1, -1) / math.sqrt2;
  final double away = 34 * (1 - _out(fly));
  final double shiver = _seg(t, 0.72, 1);
  final double angle = 0.16 * math.sin(shiver * math.pi * 5) * (1 - shiver);
  c.save();
  c.translate(hit.dx + along.dx * away, hit.dy + along.dy * away);
  c.rotate(angle);
  final Offset tail = along * 26;
  c.drawLine(Offset.zero, tail, ink.stroke(3.6));
  // Two feathers at the tail.
  final Offset back = tail - along * 8;
  final Offset side = Offset(-along.dy, along.dx) * 5.5;
  for (final double sign in [1.0, -1.0]) {
    ink.shape(
      c,
      Path()
        ..moveTo(back.dx, back.dy)
        ..lineTo(tail.dx + side.dx * sign * 0.2, tail.dy + side.dy * sign * 0.2)
        ..lineTo(
          tail.dx + side.dx * sign + along.dx * 2,
          tail.dy + side.dy * sign + along.dy * 2,
        )
        ..lineTo(back.dx + side.dx * sign, back.dy + side.dy * sign)
        ..close(),
      ink.accent,
      2.4,
    );
  }
  c.restore();
}

void _scale(Canvas c, double t, _Ink ink) {
  final double stand = _back(_seg(t, 0, 0.4));
  if (stand <= 0) return;
  c.save();
  _about(c, const Offset(32, 60), stand);
  ink.shape(
    c,
    Path()
      ..moveTo(19, 60)
      ..lineTo(45, 60)
      ..lineTo(40, 53)
      ..lineTo(24, 53)
      ..close(),
    ink.deep,
  );
  ink.shape(c, _rrect(29.6, 17, 34.4, 54, 2), ink.cream);
  c.restore();

  // The beam comes in tipped, swings and settles level.
  final double settle = _seg(t, 0.22, 1);
  final double tilt =
      -0.42 * (1 - settle) * (1 - settle) * math.cos(settle * 11);
  const Offset pivot = Offset(32, 17);
  final Offset reach = Offset(math.cos(tilt), math.sin(tilt)) * 22;
  final Offset left = pivot - reach;
  final Offset right = pivot + reach;
  // A pan the colour of the square it hangs on would vanish: cream instead.
  Color seen(Color pan) {
    final double d =
        (pan.r - ink.main.r).abs() +
        (pan.g - ink.main.g).abs() +
        (pan.b - ink.main.b).abs();
    return d < 0.35 ? ink.cream : pan;
  }

  for (final (Offset end, Color fill) in [
    (left, seen(ink.second)),
    (right, seen(ink.accent)),
  ]) {
    final double rim = end.dy + 16;
    c.drawLine(end, Offset(end.dx - 8.5, rim), ink.stroke(2.2));
    c.drawLine(end, Offset(end.dx + 8.5, rim), ink.stroke(2.2));
    ink.shape(
      c,
      Path()
        ..moveTo(end.dx - 11, rim)
        ..lineTo(end.dx + 11, rim)
        ..quadraticBezierTo(end.dx + 9, rim + 9, end.dx, rim + 9)
        ..quadraticBezierTo(end.dx - 9, rim + 9, end.dx - 11, rim)
        ..close(),
      fill,
    );
  }
  c.drawLine(left, right, ink.stroke(4.2));
  ink.shape(
    c,
    Path()..addOval(Rect.fromCircle(center: pivot, radius: 4)),
    ink.main,
    2.6,
  );
}

void _cup(Canvas c, double t, _Ink ink) {
  final double grow = _back(_seg(t, 0, 0.45));
  if (grow > 0) {
    c.save();
    _about(c, const Offset(32, 58), grow);
    ink.shape(c, _rrect(7, 52, 57, 58.5, 3.2), ink.cream);
    // The handle, an outlined ring behind the cup.
    c.drawCircle(const Offset(48.5, 38), 6, ink.stroke(7.4));
    c.drawCircle(
      const Offset(48.5, 38),
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = ink.main,
    );
    final Path body = Path()
      ..moveTo(14, 27)
      ..lineTo(50, 27)
      ..lineTo(46.5, 46)
      ..quadraticBezierTo(45.5, 52, 39.5, 52)
      ..lineTo(24.5, 52)
      ..quadraticBezierTo(18.5, 52, 17.5, 46)
      ..close();
    c.drawPath(body, Paint()..color = ink.main);
    c.save();
    c.clipPath(body);
    c.drawRect(
      const Rect.fromLTWH(10, 35, 44, 5.5),
      Paint()..color = ink.cream,
    );
    c.restore();
    c.drawPath(body, ink.stroke());
    ink.shape(
      c,
      Path()..addOval(const Rect.fromLTRB(15, 24.2, 49, 29.8)),
      ink.deep,
      2.6,
    );
    c.restore();
  }
  // Steam, drawn upwards a wisp at a time.
  for (int i = 0; i < 3; i++) {
    final double x = 24.5 + i * 7.5;
    final double v = _seg(t, 0.4 + i * 0.12, 0.82 + i * 0.06);
    if (v <= 0) continue;
    final Path wisp = Path()
      ..moveTo(x, 21)
      ..cubicTo(x - 4, 17, x + 4, 13.5, x, 9.5)
      ..cubicTo(x - 3.2, 6.8, x + 2.4, 4.2, x + 0.5, 2);
    c.drawPath(_part(wisp, v), ink.stroke(2.6));
  }
}

void _quiz(Canvas c, double t, _Ink ink) {
  final double grow = _back(_seg(t, 0, 0.42));
  if (grow > 0) {
    c.save();
    _about(c, const Offset(32, 34), grow);
    ink.shape(c, _rrect(12, 10, 50, 58, 6), ink.deep);
    ink.shape(c, _rrect(16.5, 15.5, 45.5, 53.5, 3), ink.cream, 2.6);
    ink.shape(c, _rrect(23.5, 6.5, 38.5, 14.5, 3), ink.line, 2.2);
    c.restore();
  }
  const List<double> ends = [41, 37, 39.5];
  for (int i = 0; i < 3; i++) {
    final double v = _seg(t, 0.3 + i * 0.12, 0.55 + i * 0.12);
    if (v <= 0) continue;
    final double y = 24 + i * 10;
    ink.shape(
      c,
      Path()..addOval(Rect.fromCircle(center: Offset(23, y), radius: 2.9)),
      i == 1 ? ink.main : ink.cream,
      2.2,
    );
    c.drawLine(
      Offset(29, y),
      Offset(29 + (ends[i] - 29) * _out(v), y),
      ink.stroke(2.4),
    );
  }
  // The tick, on a badge of its own.
  final double badge = _back(_seg(t, 0.68, 0.95));
  if (badge <= 0) return;
  const Offset at = Offset(48.5, 49);
  c.save();
  _about(c, at, badge);
  ink.shape(
    c,
    Path()..addOval(Rect.fromCircle(center: at, radius: 9.6)),
    const Color(0xFF3CCB6C),
    2.8,
  );
  final Path tick = Path()
    ..moveTo(at.dx - 4.6, at.dy + 0.2)
    ..lineTo(at.dx - 1.2, at.dy + 3.6)
    ..lineTo(at.dx + 4.8, at.dy - 3.4);
  c.drawPath(
    _part(tick, _seg(t, 0.8, 1)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white,
  );
  c.restore();
}

void _lens(Canvas c, double t, _Ink ink) {
  final double grow = _back(_seg(t, 0, 0.42));
  if (grow > 0) {
    c.save();
    _about(c, const Offset(14, 46), grow);
    final Path bubble = Path.combine(
      PathOperation.union,
      _rrect(5, 8, 47, 39, 9),
      Path()
        ..moveTo(11, 36)
        ..lineTo(8.5, 48)
        ..lineTo(21, 37)
        ..close(),
    );
    ink.shape(c, bubble, ink.cream);
    for (final (double y, double end) in [
      (17.0, 39.0),
      (23.5, 35.0),
      (30.0, 27.0),
    ]) {
      c.drawLine(Offset(12.5, y), Offset(end, y), ink.stroke(2.6));
    }
    c.restore();
  }
  // The lens slides in over the words and looks round them once.
  final double come = _seg(t, 0.3, 0.68);
  if (come <= 0) return;
  final double look = _seg(t, 0.68, 1);
  final double away = 22 * (1 - _out(come));
  final Offset mid = Offset(
    41 + away + 3.4 * (math.cos(look * math.pi * 2) - 1),
    38 + away + 3.4 * math.sin(look * math.pi * 2),
  );
  final Offset grip = mid + const Offset(8, 8);
  c.drawLine(grip, grip + const Offset(8.5, 8.5), ink.stroke(7.2));
  ink.shape(
    c,
    Path()..addOval(Rect.fromCircle(center: mid, radius: 11.5)),
    ink.main,
  );
  ink.shape(
    c,
    Path()..addOval(Rect.fromCircle(center: mid, radius: 7.2)),
    Color.lerp(ink.cream, Colors.white, 0.4)!,
    2.4,
  );
  c.drawArc(
    Rect.fromCircle(center: mid, radius: 4.4),
    math.pi * 1.05,
    math.pi * 0.5,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = ink.main,
  );
}

void _chat(Canvas c, double t, _Ink ink) {
  final double first = _back(_seg(t, 0, 0.42));
  if (first > 0) {
    c.save();
    _about(c, const Offset(10, 42), first);
    final Path bubble = Path.combine(
      PathOperation.union,
      _rrect(4, 8, 40, 35, 9),
      Path()
        ..moveTo(10, 32)
        ..lineTo(7.5, 43)
        ..lineTo(20, 34)
        ..close(),
    );
    ink.shape(c, bubble, ink.cream);
    // A question mark, drawn: the hook, then its dot.
    c.drawPath(
      Path()
        ..moveTo(16.8, 17.6)
        ..cubicTo(16.8, 12, 27.2, 12, 27.2, 17.6)
        ..cubicTo(27.2, 21.4, 22, 21.6, 22, 25.6),
      ink.stroke(3.8)..color = ink.deep,
    );
    c.drawCircle(const Offset(22, 31), 2.3, Paint()..color = ink.deep);
    c.restore();
  }
  final double second = _back(_seg(t, 0.26, 0.66));
  if (second <= 0) return;
  c.save();
  _about(c, const Offset(55, 59), second);
  final Path bubble = Path.combine(
    PathOperation.union,
    _rrect(22, 30, 60, 53, 9),
    Path()
      ..moveTo(47, 50)
      ..lineTo(57.5, 60.5)
      ..lineTo(55, 49)
      ..close(),
  );
  ink.shape(c, bubble, ink.main);
  // The answer coming: three dots that jump once each, in turn.
  final double hop = _seg(t, 0.6, 1);
  for (int i = 0; i < 3; i++) {
    final double v = ((hop - i * 0.16) / 0.5).clamp(0.0, 1.0);
    final double up = 3.4 * math.sin(v * math.pi);
    c.drawCircle(
      Offset(32 + i * 9, 41.5 - up),
      2.7,
      Paint()..color = ink.onMain,
    );
  }
  c.restore();
}

void _book(Canvas c, double t, _Ink ink) {
  final double open = _back(_seg(t, 0, 0.5));
  if (open > 0) {
    c.save();
    c.translate(32, 0);
    c.scale(0.25 + 0.75 * open, 1);
    c.translate(-32, 0);
    ink.shape(
      c,
      Path()
        ..moveTo(32, 25)
        ..lineTo(4, 21)
        ..lineTo(4, 55)
        ..lineTo(32, 59)
        ..lineTo(60, 55)
        ..lineTo(60, 21)
        ..close(),
      ink.deep,
    );
    for (final double side in [-1.0, 1.0]) {
      final double edge = 32 + 24 * side;
      ink.shape(
        c,
        Path()
          ..moveTo(32, 21)
          ..quadraticBezierTo(32 + 12 * side, 14, edge, 16)
          ..lineTo(edge, 51)
          ..quadraticBezierTo(32 + 12 * side, 48.5, 32, 55)
          ..close(),
        ink.cream,
      );
      for (int k = 0; k < 3; k++) {
        final double y = 25 + k * 7;
        c.drawPath(
          Path()
            ..moveTo(32 + 20 * side, y - 3)
            ..quadraticBezierTo(32 + 11 * side, y - 4.4, 32 + 4.5 * side, y),
          ink.stroke(2.2)..color = ink.line.withValues(alpha: 0.55),
        );
      }
    }
    c.restore();
  }
  // The ribbon, let down from the spine.
  final double fall = _out(_seg(t, 0.45, 0.9));
  if (fall <= 0) return;
  final double end = 26 + 36 * fall;
  ink.shape(
    c,
    Path()
      ..moveTo(36, 20)
      ..lineTo(42, 20)
      ..lineTo(42, end)
      ..lineTo(39, end - 4)
      ..lineTo(36, end)
      ..close(),
    ink.accent,
    2.4,
  );
}
