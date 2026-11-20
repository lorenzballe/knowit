import 'dart:math' as math;

import 'package:flutter/material.dart';

/// What a reader may want to learn, asked on the profile, the way a reading
/// app asks it: for the people who write the cards to know what to write
/// next. It changes nothing in the app, which deals as it did; it is kept on
/// the phone and told to the reader's profile in analytics.
///
/// Each has its colour, a deeper one to draw its mark on paper, and its two
/// hues: a badge of them carries its mark, so a skill reads as a badge on the
/// page's own ground, never as a tile of one colour like a subject's.
enum Skill {
  critical(Color(0xFF2B5CFF), Color(0xFF2B5CFF), [
    Color(0xFF3A5BFF),
    Color(0xFF7A4DFF),
  ]),
  decisions(Color(0xFFFF7A1A), Color(0xFFE06A00), [
    Color(0xFFFF8A00),
    Color(0xFFFF4D4D),
  ]),
  money(Color(0xFF00D451), Color(0xFF14A04A), [
    Color(0xFF00C853),
    Color(0xFF00A88F),
  ]),
  numbers(Color(0xFFFFE600), Color(0xFFC79200), [
    Color(0xFFFFB300),
    Color(0xFFFF7A00),
  ]),
  talk(Color(0xFF00D9D9), Color(0xFF00A99C), [
    Color(0xFF00C2E0),
    Color(0xFF2F7BFF),
  ]),
  persuade(Color(0xFFFF3D7F), Color(0xFFE0336F), [
    Color(0xFFFF4F9A),
    Color(0xFFB14DFF),
  ]),
  people(Color(0xFF9B5CFF), Color(0xFF6E3AFF), [
    Color(0xFF8E5CFF),
    Color(0xFFFF5CB8),
  ]),
  fakes(Color(0xFFFF3B30), Color(0xFFD8341A), [
    Color(0xFFFF3B30),
    Color(0xFFB0002A),
  ]),
  science(Color(0xFF00E5A0), Color(0xFF0E9A70), [
    Color(0xFF00D9A3),
    Color(0xFF00A3FF),
  ]),
  focus(Color(0xFFFFB000), Color(0xFFC77A00), [
    Color(0xFFFFD500),
    Color(0xFFFF9F0A),
  ]),
  lead(Color(0xFFC13AFF), Color(0xFF9B1FD6), [
    Color(0xFFC13AFF),
    Color(0xFF5B4DFF),
  ]),
  culture(Color(0xFF00A6FF), Color(0xFF0077CC), [
    Color(0xFF00B2FF),
    Color(0xFF00E0C6),
  ]);

  const Skill(this.colour, this.onPaper, this.hues);

  /// The two hues of the skill's badge, from its top left to its bottom
  /// right.
  final List<Color> hues;

  /// The ink of the mark on the badge: white, or near-black where the hues
  /// are too light for white to read.
  Color get onHues {
    final double light =
        (hues[0].computeLuminance() + hues[1].computeLuminance()) / 2;
    return light > 0.5 ? const Color(0xFF15130F) : Colors.white;
  }

  /// The tile's colour when picked, and the mark's in the dark.
  final Color colour;

  /// The mark's colour on paper, where the bright one would not read.
  final Color onPaper;

  /// The mark's colour on a page of [dark] or not.
  Color mark(bool dark) => dark ? colour : onPaper;

  /// The skill with this key, or null for one this build does not know.
  static Skill? of(String key) {
    for (final Skill s in values) {
      if (s.name == key) return s;
    }
    return null;
  }
}

/// A skill's mark: drawn at 22 by 22 in one weight of line, rounded at the
/// ends, as the app's own marks are.
class SkillGlyph extends CustomPainter {
  const SkillGlyph(this.skill, this.colour);

  final Skill skill;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 22);
    final Paint line = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fill = Paint()..color = colour;
    switch (skill) {
      case Skill.critical:
        // A lens.
        canvas.drawCircle(const Offset(9.5, 9.5), 6.5, line);
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(9.5, 9.5), radius: 3.8),
          3.6,
          1.3,
          false,
          line,
        );
        canvas.drawLine(
          const Offset(14.4, 14.4),
          const Offset(19.5, 19.5),
          Paint()
            ..color = colour
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      case Skill.decisions:
        // A signpost, two ways.
        canvas.drawLine(const Offset(11, 3), const Offset(11, 20), line);
        canvas.drawPath(
          Path()
            ..moveTo(11, 4)
            ..lineTo(17.5, 4)
            ..lineTo(20, 6.5)
            ..lineTo(17.5, 9)
            ..lineTo(11, 9),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(11, 11.5)
            ..lineTo(4.5, 11.5)
            ..lineTo(2, 14)
            ..lineTo(4.5, 16.5)
            ..lineTo(11, 16.5),
          line,
        );
      case Skill.money:
        // Coins, stacked.
        canvas.drawOval(const Rect.fromLTRB(4, 3.5, 18, 7.5), line);
        canvas.drawPath(
          Path()
            ..moveTo(4, 5.5)
            ..lineTo(4, 16)
            ..arcToPoint(
              const Offset(18, 16),
              radius: const Radius.elliptical(7, 2),
              clockwise: false,
            )
            ..lineTo(18, 5.5),
          line,
        );
        canvas.drawArc(
          const Rect.fromLTRB(4, 7.5, 18, 11.5),
          0,
          math.pi,
          false,
          line,
        );
        canvas.drawArc(
          const Rect.fromLTRB(4, 11.3, 18, 15.3),
          0,
          math.pi,
          false,
          line,
        );
      case Skill.numbers:
        // Bars, the last the tallest.
        canvas.drawLine(
          const Offset(2.5, 19.5),
          const Offset(19.5, 19.5),
          line,
        );
        final Paint bar = Paint()
          ..color = colour
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round;
        for (final (double x, double top) in const [
          (5.0, 13.0),
          (9.5, 9.0),
          (14.0, 11.0),
          (18.5, 4.5),
        ]) {
          canvas.drawLine(Offset(x, 16.8), Offset(x, top), bar);
        }
      case Skill.talk:
        // Two speech bubbles.
        canvas.drawRRect(
          RRect.fromLTRBR(2, 3, 14, 11.5, const Radius.circular(3)),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5, 11.5)
            ..lineTo(4.5, 14.5)
            ..lineTo(8, 11.5),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(16.5, 8)
            ..lineTo(17, 8)
            ..arcToPoint(const Offset(20, 11), radius: const Radius.circular(3))
            ..lineTo(20, 14.5)
            ..arcToPoint(
              const Offset(17, 17.5),
              radius: const Radius.circular(3),
            )
            ..lineTo(16.5, 17.5)
            ..lineTo(17, 20)
            ..lineTo(13.5, 17.5)
            ..lineTo(10.5, 17.5)
            ..arcToPoint(
              const Offset(8, 15),
              radius: const Radius.circular(2.5),
            )
            ..lineTo(8, 14.5),
          line,
        );
      case Skill.persuade:
        // A megaphone, and what comes out of it.
        canvas.drawPath(
          Path()
            ..moveTo(3, 9)
            ..lineTo(13.5, 4)
            ..lineTo(13.5, 18)
            ..lineTo(3, 13)
            ..close(),
          line,
        );
        canvas.drawLine(const Offset(6, 14), const Offset(7.5, 19), line);
        canvas.drawLine(const Offset(16.5, 8), const Offset(19, 6.5), line);
        canvas.drawLine(const Offset(17, 11), const Offset(20, 11), line);
        canvas.drawLine(const Offset(16.5, 14), const Offset(19, 15.5), line);
      case Skill.people:
        // Two people.
        canvas.drawCircle(const Offset(8, 7), 3.2, line);
        canvas.drawArc(
          const Rect.fromLTRB(2, 12, 14, 24),
          3.3,
          2.82,
          false,
          line,
        );
        canvas.drawCircle(const Offset(15.5, 8.5), 2.6, line);
        canvas.drawArc(
          const Rect.fromLTRB(12.5, 13, 21.5, 22),
          3.6,
          2.2,
          false,
          line,
        );
      case Skill.fakes:
        // A page, and a cross on it.
        canvas.drawPath(
          Path()
            ..moveTo(4, 2.5)
            ..lineTo(13, 2.5)
            ..lineTo(17, 6.5)
            ..lineTo(17, 10),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4, 2.5)
            ..lineTo(4, 19.5)
            ..lineTo(11, 19.5),
          line,
        );
        canvas.drawLine(const Offset(7, 8), const Offset(13.5, 8), line);
        canvas.drawLine(const Offset(7, 11.5), const Offset(11, 11.5), line);
        canvas.drawCircle(const Offset(16.5, 16.5), 3.8, line);
        canvas.drawLine(const Offset(15, 15), const Offset(18, 18), line);
        canvas.drawLine(const Offset(18, 15), const Offset(15, 18), line);
      case Skill.science:
        // A flask.
        canvas.drawPath(
          Path()
            ..moveTo(8.5, 2.5)
            ..lineTo(8.5, 8.5)
            ..lineTo(3.2, 17.5)
            ..quadraticBezierTo(2.4, 19.5, 4.6, 19.5)
            ..lineTo(17.4, 19.5)
            ..quadraticBezierTo(19.6, 19.5, 18.8, 17.5)
            ..lineTo(13.5, 8.5)
            ..lineTo(13.5, 2.5),
          line,
        );
        canvas.drawLine(const Offset(7, 2.5), const Offset(15, 2.5), line);
        canvas.drawLine(
          const Offset(5.6, 13.5),
          const Offset(16.4, 13.5),
          line,
        );
        canvas.drawCircle(const Offset(10, 16.3), 0.9, fill);
        canvas.drawCircle(const Offset(13, 15.6), 0.7, fill);
      case Skill.focus:
        // A target.
        canvas.drawCircle(const Offset(11, 11), 8.5, line);
        canvas.drawCircle(const Offset(11, 11), 5, line);
        canvas.drawCircle(const Offset(11, 11), 1.6, fill);
      case Skill.lead:
        // A flag.
        canvas.drawLine(const Offset(5, 20), const Offset(5, 2.5), line);
        canvas.drawPath(
          Path()
            ..moveTo(5, 3.5)
            ..quadraticBezierTo(9, 1.8, 12, 3.5)
            ..quadraticBezierTo(15.5, 5.3, 19, 3.5)
            ..lineTo(19, 11.5)
            ..quadraticBezierTo(15.5, 13.3, 12, 11.5)
            ..quadraticBezierTo(9, 9.8, 5, 11.5),
          line,
        );
      case Skill.culture:
        // The globe.
        canvas.drawCircle(const Offset(11, 11), 8.5, line);
        canvas.drawOval(const Rect.fromLTRB(7, 2.5, 15, 19.5), line);
        canvas.drawLine(const Offset(2.5, 11), const Offset(19.5, 11), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SkillGlyph old) =>
      old.skill != skill || old.colour != colour;
}
