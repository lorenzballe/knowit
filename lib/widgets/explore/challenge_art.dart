/// The pictures of the challenges: one for every game Explore's challenges
/// open, drawn the way the app's drawn cards are (tool/cards/bank, e.g.
/// science-bradyseism-breathing-ground.html) — flat colours, a thick line
/// of ink round everything, no gradients, no shadows — so a game's tile
/// reads as one of the app's own pictures rather than an icon.
///
/// Every picture is drawn in a box of 200 by 150 and scaled to the room it
/// is given, keeping its proportions, so the same picture is the tile's, a
/// game's screen's and everything between while one grows into the other.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The ink every picture is outlined in: the drawn cards' own.
const Color kArtInk = Color(0xFF10100C);

/// The paper of the drawn cards, for whatever is white in a picture.
const Color kArtCream = Color(0xFFFFFBF0);

/// The cards' few colours besides the ground's.
const Color _orange = Color(0xFFFF5A1F);
const Color _gold = Color(0xFFFFC83D);
const Color _blue = Color(0xFF2F7FE0);
const Color _coral = Color(0xFFFF5A4E);
const Color _green = Color(0xFF2BD67B);
const Color _glass = Color(0xFFBFE6FF);

/// The proportions every picture is drawn in.
const double kArtAspect = 200 / 150;

/// Which picture.
enum ChallengeArt {
  /// Sixty seconds: a stopwatch, the time gone a wedge of its face.
  sixty,

  /// Spot the false one: four claims, and the glass on the one that is not
  /// so.
  spot,

  /// True or false: a tick and a cross.
  trueFalse,

  /// Which is bigger: two columns, and the crown the bigger wins.
  bigger,

  /// Closer, closer: a target, and a dart near its middle.
  closer,

  /// Orders of magnitude: a staircase, each step ten times the last.
  magnitude,

  /// Bet a range: a track, the band bet on, the pin dropped into it.
  range,

  /// Place your bet: stacks of chips, and one in the air.
  stake,

  /// Your number: a number set on a counter, its minus and its plus.
  number,
}

/// Draws [art] on a ground of [ground]. [time] is how much of Sixty
/// seconds' minute is gone, 0 to 1: its wedge and its hand.
class ChallengePainter extends CustomPainter {
  const ChallengePainter(this.art, {required this.ground, this.time = 0.25});

  final ChallengeArt art;
  final Color ground;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final double k = math.min(size.width / 200, size.height / 150);
    canvas.save();
    canvas.translate((size.width - 200 * k) / 2, (size.height - 150 * k) / 2);
    canvas.scale(k);
    final _Pen pen = _Pen(canvas, ground);
    switch (art) {
      case ChallengeArt.sixty:
        _sixty(pen, time.clamp(0.0, 1.0));
      case ChallengeArt.spot:
        _spot(pen);
      case ChallengeArt.trueFalse:
        _trueFalse(pen);
      case ChallengeArt.bigger:
        _bigger(pen);
      case ChallengeArt.closer:
        _closer(pen);
      case ChallengeArt.magnitude:
        _magnitude(pen);
      case ChallengeArt.range:
        _range(pen);
      case ChallengeArt.stake:
        _stake(pen);
      case ChallengeArt.number:
        _number(pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ChallengePainter old) =>
      old.art != art || old.ground != ground || old.time != time;
}

/// [ChallengePainter] as a widget, at the size it is given.
class ChallengeArtView extends StatelessWidget {
  const ChallengeArtView({
    super.key,
    required this.art,
    required this.ground,
    this.time = 0.25,
  });

  final ChallengeArt art;
  final Color ground;
  final double time;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: ChallengePainter(art, ground: ground, time: time),
        size: Size.infinite,
      ),
    ),
  );
}

/// What every picture is drawn with: shapes filled flat and outlined in
/// ink, in the box of 200 by 150.
class _Pen {
  _Pen(this.c, this.ground);

  final Canvas c;
  final Color ground;

  /// The outline, in the box's units: about the drawn cards' three pixels
  /// on a picture of their width.
  static const double line = 3.4;

  /// A lighter tone of the ground, for the halo behind a picture's thing.
  Color get halo => Color.lerp(ground, Colors.white, 0.34)!;

  Paint fill(Color colour) => Paint()
    ..color = colour
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint ink([double width = line, Color colour = kArtInk]) => Paint()
    ..color = colour
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  /// [path] filled with [colour] and outlined.
  void shape(Path path, Color colour, {double width = line}) {
    c.drawPath(path, fill(colour));
    c.drawPath(path, ink(width));
  }

  void circle(Offset at, double r, Color colour, {double width = line}) =>
      shape(
        Path()..addOval(Rect.fromCircle(center: at, radius: r)),
        colour,
        width: width,
      );

  void box(Rect r, double radius, Color colour, {double width = line}) => shape(
    Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius))),
    colour,
    width: width,
  );

  /// A line of ink.
  void stroke(Path path, {double width = line, Color colour = kArtInk}) =>
      c.drawPath(path, ink(width, colour));

  void segment(Offset a, Offset b, {double width = line}) =>
      c.drawLine(a, b, ink(width));

  /// A mark drawn as a fat stroke of [colour] with an outline of ink: a
  /// tick, a cross, a handle.
  void outlined(Path path, Color colour, {double width = 8}) {
    c.drawPath(path, ink(width + line * 2));
    c.drawPath(path, ink(width, colour));
  }

  /// The soft disc behind a picture's thing.
  void haloAt(Offset at, double r) => c.drawCircle(at, r, fill(halo));

  /// A star of four points, filled and outlined: a sparkle.
  void sparkle(Offset at, double r, Color colour) {
    final double w = r * 0.3;
    shape(
      Path()
        ..moveTo(at.dx, at.dy - r)
        ..quadraticBezierTo(at.dx + w * 0.4, at.dy - w * 0.4, at.dx + r, at.dy)
        ..quadraticBezierTo(at.dx + w * 0.4, at.dy + w * 0.4, at.dx, at.dy + r)
        ..quadraticBezierTo(at.dx - w * 0.4, at.dy + w * 0.4, at.dx - r, at.dy)
        ..quadraticBezierTo(at.dx - w * 0.4, at.dy - w * 0.4, at.dx, at.dy - r)
        ..close(),
      colour,
      width: line * 0.8,
    );
  }

  /// [text] in the app's display face, its middle at [at].
  void glyph(String text, Offset at, double size, Color colour) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: size,
          fontWeight: FontWeight.w800,
          height: 1,
          color: colour,
          fontVariations: const [
            FontVariation('wght', 800),
            FontVariation('SOFT', 30),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      c,
      at - Offset(painter.width / 2, painter.height / 2 + size * 0.04),
    );
    painter.dispose();
  }

  /// A tick, its corner at [at], [s] across.
  Path tick(Offset at, double s) => Path()
    ..moveTo(at.dx - s * 0.5, at.dy - s * 0.05)
    ..lineTo(at.dx - s * 0.14, at.dy + s * 0.3)
    ..lineTo(at.dx + s * 0.52, at.dy - s * 0.36);

  /// A cross, its middle at [at], [s] across.
  Path cross(Offset at, double s) => Path()
    ..moveTo(at.dx - s / 2, at.dy - s / 2)
    ..lineTo(at.dx + s / 2, at.dy + s / 2)
    ..moveTo(at.dx + s / 2, at.dy - s / 2)
    ..lineTo(at.dx - s / 2, at.dy + s / 2);
}

double _rad(double degrees) => degrees * math.pi / 180;

/// A stopwatch, the time gone a wedge of its face and the hand at its edge;
/// lines behind it, for the hurry.
void _sixty(_Pen p, double time) {
  const Offset c = Offset(106, 84);
  const double r = 52;
  p.haloAt(const Offset(106, 80), 68);
  // The hurry: three lines streaming off to the left.
  for (final (double y, double from, double to) in const [
    (62.0, 26.0, 44.0),
    (84.0, 16.0, 42.0),
    (106.0, 26.0, 44.0),
  ]) {
    p.segment(Offset(from, y), Offset(to, y), width: 5);
  }
  // The crown and its stem, and the button at the side.
  p.box(const Rect.fromLTWH(99, 22, 14, 14), 2, kArtCream);
  p.box(const Rect.fromLTWH(89, 11, 34, 13), 6, _orange);
  p.c.save();
  p.c.translate(c.dx + r * 0.78, c.dy - r * 0.78);
  p.c.rotate(_rad(45));
  p.box(const Rect.fromLTWH(-7, -7, 14, 12), 3, kArtCream);
  p.c.restore();
  // The case, and the face inside it.
  p.circle(c, r, kArtCream);
  p.c.drawCircle(c, r - 7, p.ink(2.2));
  // The time gone.
  if (time > 0.001) {
    final Path wedge = Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(
        Rect.fromCircle(center: c, radius: r - 12),
        _rad(-90),
        _rad(360 * math.min(time, 0.9999)),
        false,
      )
      ..close();
    p.shape(wedge, _orange, width: 2.6);
  }
  // The minutes' marks.
  for (int i = 0; i < 12; i++) {
    final double a = _rad(i * 30 - 90);
    final bool major = i % 3 == 0;
    final Offset dir = Offset(math.cos(a), math.sin(a));
    p.segment(
      c + dir * (r - (major ? 19 : 16)),
      c + dir * (r - 10),
      width: major ? 3.6 : 2.4,
    );
  }
  // The hand, at the edge of the time gone.
  final double a = _rad(360 * time - 90);
  p.segment(c, c + Offset(math.cos(a), math.sin(a)) * (r - 16), width: 4.6);
  p.c.drawCircle(c, 5.5, p.fill(kArtInk));
}

/// Four claims on cards, three ticked; the glass over the fourth finds its
/// cross.
void _spot(_Pen p) {
  p.haloAt(const Offset(100, 78), 66);
  const List<(double, double, double)> cards = [
    // middle x, top, turn in degrees
    (36, 58, -8),
    (78, 50, -2),
    (122, 44, 4),
    (164, 56, 9),
  ];
  for (int i = 0; i < cards.length; i++) {
    final (double x, double top, double turn) = cards[i];
    final bool odd = i == 2;
    p.c.save();
    p.c.translate(x, top + 28);
    p.c.rotate(_rad(turn));
    p.box(const Rect.fromLTWH(-19, -28, 38, 56), 6, kArtCream);
    // Two lines of a claim.
    p.c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -18, 24, 4.5),
        const Radius.circular(3),
      ),
      p.fill(kArtInk.withValues(alpha: 0.28)),
    );
    p.c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -9, 16, 4.5),
        const Radius.circular(3),
      ),
      p.fill(kArtInk.withValues(alpha: 0.28)),
    );
    // Its mark: a tick, or the cross the glass finds.
    p.circle(const Offset(0, 12), 9.5, odd ? _coral : _green, width: 2.6);
    if (odd) {
      p.stroke(p.cross(const Offset(0, 12), 8), width: 3, colour: kArtCream);
    } else {
      p.stroke(p.tick(const Offset(0, 12.5), 10), width: 3, colour: kArtCream);
    }
    p.c.restore();
  }
  // The glass, over the false one, its cross made large in it.
  const Offset lens = Offset(124, 70);
  p.outlined(
    Path()
      ..moveTo(lens.dx + 21, lens.dy + 21)
      ..lineTo(lens.dx + 40, lens.dy + 42),
    _orange,
    width: 9,
  );
  p.c.drawCircle(lens, 28, p.fill(_glass.withValues(alpha: 0.5)));
  p.circle(lens + const Offset(1, 3), 15, _coral, width: 3);
  p.stroke(
    p.cross(lens + const Offset(1, 3), 12),
    width: 4.4,
    colour: kArtCream,
  );
  p.c.drawCircle(lens, 28, p.ink(4.2));
  p.c.drawArc(
    Rect.fromCircle(center: lens, radius: 21),
    _rad(200),
    _rad(62),
    false,
    p.ink(3.6, Colors.white),
  );
}

/// A tick on green and a cross on coral, side by side; sparkles round them.
void _trueFalse(_Pen p) {
  p.haloAt(const Offset(100, 78), 64);
  p.sparkle(const Offset(30, 36), 9, kArtCream);
  p.sparkle(const Offset(176, 34), 7, kArtCream);
  p.sparkle(const Offset(172, 122), 8, _gold);
  p.sparkle(const Offset(24, 118), 6, _gold);
  p.circle(const Offset(76, 74), 40, _green);
  p.outlined(p.tick(const Offset(75, 76), 40), kArtCream, width: 8);
  p.c.save();
  p.c.translate(130, 88);
  p.c.rotate(_rad(10));
  p.circle(Offset.zero, 34, _coral);
  p.outlined(p.cross(Offset.zero, 30), kArtCream, width: 7.5);
  p.c.restore();
}

/// Two columns on a line, a question on each, the crown over the taller.
void _bigger(_Pen p) {
  p.haloAt(const Offset(100, 80), 64);
  Path column(Rect r) => Path()
    ..addRRect(
      RRect.fromRectAndCorners(
        r,
        topLeft: const Radius.circular(9),
        topRight: const Radius.circular(9),
      ),
    );
  p.shape(column(const Rect.fromLTWH(50, 82, 42, 48)), kArtCream);
  p.shape(column(const Rect.fromLTWH(108, 44, 42, 86)), _gold);
  p.glyph('?', const Offset(71, 106), 30, kArtInk);
  p.glyph('?', const Offset(129, 87), 34, kArtInk);
  p.segment(const Offset(30, 130), const Offset(170, 130), width: 4.4);
  // The crown, a little above the taller.
  p.shape(
    Path()
      ..moveTo(110, 37)
      ..lineTo(112, 16)
      ..lineTo(121, 26)
      ..lineTo(129, 8)
      ..lineTo(137, 26)
      ..lineTo(146, 16)
      ..lineTo(148, 37)
      ..close(),
    _orange,
  );
  p.sparkle(const Offset(166, 22), 7, kArtCream);
  p.sparkle(const Offset(36, 52), 6, kArtCream);
}

/// A target, a dart near its middle, and arrows closing in from both
/// sides.
void _closer(_Pen p) {
  const Offset c = Offset(98, 80);
  p.haloAt(c, 66);
  p.circle(c, 52, kArtCream);
  p.circle(c, 39, _coral);
  p.circle(c, 26, kArtCream);
  p.circle(c, 13, _coral);
  // Closing in.
  for (final double dx in const [0, 11]) {
    p.stroke(
      Path()
        ..moveTo(14 + dx, 66)
        ..lineTo(22 + dx, 76)
        ..lineTo(14 + dx, 86),
      width: 4.2,
    );
    p.stroke(
      Path()
        ..moveTo(186 - dx, 66)
        ..lineTo(178 - dx, 76)
        ..lineTo(186 - dx, 86),
      width: 4.2,
    );
  }
  // The dart: its shaft, its flights, its point near the middle.
  const Offset tip = Offset(103, 75);
  const Offset back = Offset(150, 28);
  p.outlined(
    Path()
      ..moveTo(tip.dx + 6, tip.dy - 6)
      ..lineTo(back.dx, back.dy),
    _gold,
    width: 5,
  );
  p.shape(
    Path()
      ..moveTo(back.dx - 4, back.dy + 4)
      ..lineTo(back.dx + 2, back.dy - 18)
      ..lineTo(back.dx + 10, back.dy - 10)
      ..lineTo(back.dx + 4, back.dy - 4)
      ..lineTo(back.dx + 10, back.dy + 2)
      ..lineTo(back.dx + 18, back.dy - 2)
      ..close(),
    _blue,
    width: 2.8,
  );
  p.shape(
    Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 12, tip.dy - 4)
      ..lineTo(tip.dx + 4, tip.dy - 12)
      ..close(),
    kArtInk,
    width: 2,
  );
}

/// A staircase of four steps, each far taller than the last, a flag on the
/// top one.
void _magnitude(_Pen p) {
  p.haloAt(const Offset(104, 82), 64);
  const List<(double, double, Color)> steps = [
    (24, 20, kArtCream),
    (60, 42, _gold),
    (96, 66, _green),
    (132, 92, _coral),
  ];
  for (final (double x, double h, Color colour) in steps) {
    p.box(Rect.fromLTWH(x, 134 - h, 36, h), 4, colour);
  }
  // A dot for one, two for ten, and so on: each step's size, at a glance.
  for (int i = 0; i < steps.length; i++) {
    final (double x, double h, _) = steps[i];
    for (int d = 0; d <= i; d++) {
      p.c.drawCircle(
        Offset(x + 18 + (d - i / 2) * 7, 134 - h + 10),
        2.4,
        p.fill(kArtInk),
      );
    }
  }
  // The flag on the top step.
  p.segment(const Offset(150, 42), const Offset(150, 8), width: 3.6);
  p.shape(
    Path()
      ..moveTo(151, 9)
      ..lineTo(176, 17)
      ..lineTo(151, 26)
      ..close(),
    kArtCream,
    width: 3,
  );
  p.sparkle(const Offset(36, 70), 7, kArtCream);
  p.sparkle(const Offset(86, 46), 5, kArtCream);
}

/// A track with its marks, the band bet on, and the pin dropped into it.
void _range(_Pen p) {
  p.haloAt(const Offset(100, 76), 64);
  p.box(const Rect.fromLTWH(16, 94, 168, 15), 7.5, kArtCream);
  for (int i = 0; i <= 10; i++) {
    final double x = 24 + i * 15.2;
    p.segment(
      Offset(x, 118),
      Offset(x, i % 5 == 0 ? 130 : 125),
      width: i % 5 == 0 ? 3.2 : 2.4,
    );
  }
  // The band, and its two ends.
  p.box(const Rect.fromLTWH(72, 86, 60, 31), 8, _gold);
  p.box(const Rect.fromLTWH(66, 80, 11, 43), 5, kArtInk, width: 2);
  p.box(const Rect.fromLTWH(127, 80, 11, 43), 5, kArtInk, width: 2);
  // The pin, its point in the band.
  const Offset head = Offset(102, 42);
  p.shape(
    Path()
      ..moveTo(head.dx, 84)
      ..cubicTo(head.dx - 6, 72, head.dx - 21, 62, head.dx - 21, head.dy)
      ..arcToPoint(
        Offset(head.dx + 21, head.dy),
        radius: const Radius.circular(21),
      )
      ..cubicTo(head.dx + 21, 62, head.dx + 6, 72, head.dx, 84)
      ..close(),
    _coral,
  );
  p.circle(head, 7.5, kArtCream, width: 2.8);
  p.sparkle(const Offset(160, 40), 7, kArtCream);
  p.sparkle(const Offset(40, 50), 6, kArtCream);
}

/// Three stacks of chips, and one tossed in the air.
void _stake(_Pen p) {
  p.haloAt(const Offset(100, 80), 64);
  void chip(double x, double y, Color colour, Color stripes) {
    // The side, then the face on top.
    final Rect face = Rect.fromCenter(
      center: Offset(x, y - 8),
      width: 46,
      height: 17,
    );
    final Path side = Path()
      ..moveTo(x - 23, y - 8)
      ..lineTo(x - 23, y)
      ..arcTo(
        Rect.fromCenter(center: Offset(x, y), width: 46, height: 17),
        math.pi,
        -math.pi,
        false,
      )
      ..lineTo(x + 23, y - 8)
      ..close();
    p.shape(side, colour, width: 2.8);
    for (final double dx in const [-14, 0, 14]) {
      p.c.drawRect(
        Rect.fromCenter(center: Offset(x + dx, y + 0.5), width: 4, height: 7),
        p.fill(stripes),
      );
    }
    p.shape(Path()..addOval(face), colour, width: 2.8);
    p.c.drawOval(face.deflate(5), p.ink(1.8, stripes));
  }

  for (final (double x, int n, Color colour, Color stripes) in const [
    (50.0, 3, _coral, kArtCream),
    (100.0, 5, _blue, kArtCream),
    (150.0, 2, kArtCream, _coral),
  ]) {
    for (int i = 0; i < n; i++) {
      chip(x, 132 - i * 9.0, colour, stripes);
    }
  }
  // One in the air, turning.
  p.c.save();
  p.c.translate(150, 52);
  p.c.rotate(_rad(-24));
  p.shape(
    Path()
      ..addOval(Rect.fromCenter(center: Offset.zero, width: 44, height: 18)),
    _gold,
    width: 2.8,
  );
  p.c.drawOval(
    Rect.fromCenter(center: Offset.zero, width: 34, height: 11),
    p.ink(1.8, kArtCream),
  );
  p.c.restore();
  p.segment(const Offset(126, 30), const Offset(134, 38), width: 3.2);
  p.segment(const Offset(170, 26), const Offset(164, 36), width: 3.2);
}

/// A counter showing a number, a minus and a plus either side, and the
/// lock under it.
void _number(_Pen p) {
  p.haloAt(const Offset(100, 76), 66);
  p.box(const Rect.fromLTWH(38, 30, 124, 62), 14, kArtInk);
  const List<String> digits = ['0', '4', '2'];
  for (int i = 0; i < 3; i++) {
    final Rect cell = Rect.fromLTWH(47 + i * 37.0, 39, 32, 44);
    p.c.drawRRect(
      RRect.fromRectAndRadius(cell, const Radius.circular(7)),
      p.fill(kArtCream),
    );
    p.glyph(digits[i], cell.center, 34, kArtInk);
  }
  // Minus and plus.
  p.circle(const Offset(40, 120), 19, _coral);
  p.outlined(
    Path()
      ..moveTo(31, 120)
      ..lineTo(49, 120),
    kArtCream,
    width: 5,
  );
  p.circle(const Offset(160, 120), 19, _green);
  p.outlined(
    Path()
      ..moveTo(151, 120)
      ..lineTo(169, 120)
      ..moveTo(160, 111)
      ..lineTo(160, 129),
    kArtCream,
    width: 5,
  );
  // The lock.
  p.stroke(
    Path()
      ..moveTo(91, 118)
      ..lineTo(91, 110)
      ..arcToPoint(const Offset(109, 110), radius: const Radius.circular(9))
      ..lineTo(109, 118),
    width: 4.4,
  );
  p.box(const Rect.fromLTWH(84, 116, 32, 24), 5, _gold);
  p.c.drawCircle(const Offset(100, 127), 3.2, p.fill(kArtInk));
}
