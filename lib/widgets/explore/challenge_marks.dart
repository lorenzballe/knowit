/// The marks of the challenges: one for every challenge Explore's tiles
/// open, drawn in hairlines in the challenge's own tone — a clock, a scale,
/// a ruler, a line of time — the way a diagram in a serious book is drawn,
/// never a picture. Each stands for the skill the challenge trains.
///
/// Every mark is drawn in a box of 24 by 24 and scaled to the room it is
/// given; its lines stay hairlines at any size, a point and a quarter at a
/// tile's and never heavier than a point and three quarters.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which mark.
enum ChallengeMark {
  /// Sixty seconds: a clock, the time gone a shaded wedge of its face.
  sixty,

  /// Spot the false one: four lines of claims, one singled out.
  spot,

  /// True or false: a circle, half of it filled.
  trueFalse,

  /// Which is bigger: two columns on a line, the taller one filled.
  bigger,

  /// Closer, closer: two chevrons closing on a point.
  closer,

  /// Orders of magnitude: three squares, each many times the last.
  magnitude,

  /// Bet a range: an interval in brackets, the answer inside it.
  range,

  /// Place your bet: a beam on its fulcrum, weighed down on one side.
  stake,

  /// Your number: a counter of three figures, one of them set.
  number,

  /// In order: four points along the line of time.
  order,

  /// What year?: a ruler, and the needle on it.
  year,

  /// Before or after?: two moments, one above the other.
  chain,
}

/// Draws [mark] in [colour]. [time] is how much of Sixty seconds' minute is
/// gone, 0 to 1: the wedge of its clock and its hand.
class ChallengeMarkPainter extends CustomPainter {
  const ChallengeMarkPainter(this.mark, {required this.colour, this.time = 0.25});

  final ChallengeMark mark;
  final Color colour;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final double side = math.min(size.width, size.height);
    final double k = side / 24;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(k);
    final _Pen pen = _Pen(canvas, colour, (1.3 * k).clamp(1.0, 1.75) / k);
    switch (mark) {
      case ChallengeMark.sixty:
        _sixty(pen, time.clamp(0.0, 1.0));
      case ChallengeMark.spot:
        _spot(pen);
      case ChallengeMark.trueFalse:
        _trueFalse(pen);
      case ChallengeMark.bigger:
        _bigger(pen);
      case ChallengeMark.closer:
        _closer(pen);
      case ChallengeMark.magnitude:
        _magnitude(pen);
      case ChallengeMark.range:
        _range(pen);
      case ChallengeMark.stake:
        _stake(pen);
      case ChallengeMark.number:
        _number(pen);
      case ChallengeMark.order:
        _order(pen);
      case ChallengeMark.year:
        _year(pen);
      case ChallengeMark.chain:
        _chain(pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ChallengeMarkPainter old) =>
      old.mark != mark || old.colour != colour || old.time != time;
}

/// [ChallengeMarkPainter] as a widget, [size] square.
class ChallengeMarkView extends StatelessWidget {
  const ChallengeMarkView({
    super.key,
    required this.mark,
    required this.colour,
    this.size = 20,
    this.time = 0.25,
  });

  final ChallengeMark mark;
  final Color colour;
  final double size;
  final double time;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: ChallengeMarkPainter(mark, colour: colour, time: time),
      ),
    ),
  );
}

/// What every mark is drawn with: hairlines and a few small fills, in one
/// colour and a fainter tone of it, in the box of 24 by 24.
class _Pen {
  _Pen(this.c, this.colour, this.line);

  final Canvas c;
  final Color colour;

  /// The hairline, in the box's units.
  final double line;

  /// The fainter tone: what a mark's thing stands on, or among.
  Color get faint => colour.withValues(alpha: colour.a * 0.42);

  Paint stroke({bool faint = false}) => Paint()
    ..color = faint ? this.faint : colour
    ..style = PaintingStyle.stroke
    ..strokeWidth = line
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  Paint fill({double alpha = 1}) => Paint()
    ..color = colour.withValues(alpha: colour.a * alpha)
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  void segment(Offset a, Offset b, {bool faint = false}) =>
      c.drawLine(a, b, stroke(faint: faint));

  void path(Path p, {bool faint = false}) => c.drawPath(p, stroke(faint: faint));

  void ring(Offset at, double r, {bool faint = false}) =>
      c.drawCircle(at, r, stroke(faint: faint));

  void dot(Offset at, double r) => c.drawCircle(at, r, fill());

  void box(Rect r, {bool filled = false, bool faint = false}) => filled
      ? c.drawRect(r, fill())
      : c.drawRect(r, stroke(faint: faint));
}

double _rad(double degrees) => degrees * math.pi / 180;

/// A clock: its face, the time gone a faint wedge, the hand at its edge,
/// the crown on top.
void _sixty(_Pen p, double time) {
  const Offset c = Offset(12, 13.4);
  const double r = 8.6;
  p.segment(const Offset(10.4, 2.3), const Offset(13.6, 2.3));
  p.segment(const Offset(12, 2.3), const Offset(12, 4.8));
  if (time > 0.001) {
    p.c.drawPath(
      Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(
          Rect.fromCircle(center: c, radius: r),
          _rad(-90),
          _rad(360 * math.min(time, 0.9999)),
          false,
        )
        ..close(),
      p.fill(alpha: 0.2),
    );
  }
  p.ring(c, r);
  final double a = _rad(360 * time - 90);
  p.segment(c, c + Offset(math.cos(a), math.sin(a)) * (r - 2.2));
  p.dot(c, 1.1);
}

/// Four lines of claims, one of them singled out by a ring at its end.
void _spot(_Pen p) {
  for (int i = 0; i < 4; i++) {
    final double y = 5.5 + i * 4.3;
    final bool odd = i == 2;
    p.segment(Offset(3, y), Offset(odd ? 15 : 18, y), faint: !odd);
  }
  p.ring(Offset(19, 5.5 + 2 * 4.3), 2.4);
}

/// A circle, half of it filled: the one side or the other.
void _trueFalse(_Pen p) {
  const Offset c = Offset(12, 12);
  const double r = 8.4;
  p.c.drawPath(
    Path()
      ..moveTo(c.dx, c.dy - r)
      ..arcTo(Rect.fromCircle(center: c, radius: r), _rad(-90), _rad(-180), false)
      ..close(),
    p.fill(),
  );
  p.ring(c, r);
}

/// Two columns on a line, the taller one filled.
void _bigger(_Pen p) {
  p.segment(const Offset(3, 20.5), const Offset(21, 20.5));
  p.box(const Rect.fromLTRB(5.5, 12.5, 10.5, 20.5));
  p.box(const Rect.fromLTRB(13.5, 4.5, 18.5, 20.5), filled: true);
}

/// Two chevrons closing on a point.
void _closer(_Pen p) {
  p.path(
    Path()
      ..moveTo(4.5, 7.5)
      ..lineTo(9, 12)
      ..lineTo(4.5, 16.5),
  );
  p.path(
    Path()
      ..moveTo(19.5, 7.5)
      ..lineTo(15, 12)
      ..lineTo(19.5, 16.5),
  );
  p.dot(const Offset(12, 12), 1.4);
}

/// Three squares from one corner, each many times the last.
void _magnitude(_Pen p) {
  p.box(const Rect.fromLTRB(3, 3, 21, 21), faint: true);
  p.box(const Rect.fromLTRB(3, 12.5, 11.5, 21));
  p.box(const Rect.fromLTRB(3, 17.4, 6.6, 21), filled: true);
}

/// An interval in brackets on a line, the answer inside it.
void _range(_Pen p) {
  p.segment(const Offset(2, 12.5), const Offset(22, 12.5), faint: true);
  p.segment(const Offset(6.5, 12.5), const Offset(17.5, 12.5));
  p.path(
    Path()
      ..moveTo(8.4, 7.5)
      ..lineTo(6.5, 7.5)
      ..lineTo(6.5, 17.5)
      ..lineTo(8.4, 17.5),
  );
  p.path(
    Path()
      ..moveTo(15.6, 7.5)
      ..lineTo(17.5, 7.5)
      ..lineTo(17.5, 17.5)
      ..lineTo(15.6, 17.5),
  );
  p.dot(const Offset(13.6, 12.5), 1.5);
}

/// A beam on its fulcrum, weighed down on one side.
void _stake(_Pen p) {
  const Offset a = Offset(3, 9.2);
  const Offset b = Offset(21, 14.8);
  p.segment(a, b);
  p.path(
    Path()
      ..moveTo(12, 12)
      ..lineTo(9, 20.5)
      ..lineTo(15, 20.5)
      ..close(),
  );
  // What lies on the beam: a light ring at the high end, the weight at
  // the low one.
  double yAt(double x) => a.dy + (x - a.dx) * (b.dy - a.dy) / (b.dx - a.dx);
  p.ring(Offset(5, yAt(5) - 2.4), 1.7, faint: true);
  p.dot(Offset(18.6, yAt(18.6) - 2.9), 2.3);
}

/// A counter of three figures, the middle one set.
void _number(_Pen p) {
  final RRect frame = RRect.fromRectAndRadius(
    const Rect.fromLTRB(2.5, 7, 21.5, 17),
    const Radius.circular(1.6),
  );
  p.c.drawRRect(frame, p.stroke());
  const double third = 19 / 3;
  p.segment(const Offset(2.5 + third, 7), const Offset(2.5 + third, 17));
  p.segment(const Offset(2.5 + third * 2, 7), const Offset(2.5 + third * 2, 17));
  p.c.drawRect(
    Rect.fromLTRB(2.5 + third + 1.6, 8.6, 2.5 + third * 2 - 1.6, 15.4),
    p.fill(),
  );
}

/// Four points along the line of time, its arrow at the end.
void _order(_Pen p) {
  p.segment(const Offset(2.5, 13), const Offset(21.5, 13));
  p.path(
    Path()
      ..moveTo(19.2, 10.7)
      ..lineTo(21.5, 13)
      ..lineTo(19.2, 15.3),
  );
  for (int i = 0; i < 4; i++) {
    p.dot(Offset(4.6 + i * 4.1, 13), 1.45);
  }
}

/// A ruler of the years, and the needle standing on it.
void _year(_Pen p) {
  p.segment(const Offset(2, 19.5), const Offset(22, 19.5), faint: true);
  for (int i = 0; i <= 10; i++) {
    final double x = 2 + i * 2;
    p.segment(Offset(x, 19.5), Offset(x, i % 5 == 0 ? 15 : 17.2), faint: true);
  }
  p.segment(const Offset(13, 6.5), const Offset(13, 19.5));
  p.c.drawPath(
    Path()
      ..moveTo(10.8, 3.6)
      ..lineTo(15.2, 3.6)
      ..lineTo(13, 6.6)
      ..close(),
    p.fill(),
  );
}

/// Two moments, one above the other, the line of time between them.
void _chain(_Pen p) {
  p.ring(const Offset(12, 6), 2.9);
  p.segment(const Offset(12, 9.4), const Offset(12, 14.6));
  p.dot(const Offset(12, 18), 2.9);
}
