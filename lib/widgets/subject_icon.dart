import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/subject_icons.dart';

/// The subject's own mark, recoloured to whatever ink it sits on.
///
/// One widget for every place a subject is named with its mark beside it —
/// the shelf, the chips, the line about tomorrow — so the marks cannot come
/// out at two weights or two sizes depending on which screen drew them.
class SubjectIcon extends StatelessWidget {
  const SubjectIcon({
    super.key,
    required this.subject,
    required this.size,
    required this.ink,
    this.stroke = 1.9,
  });

  final String subject;
  final double size;
  final Color ink;

  /// The line's weight on the 24-unit grid. The one weight everywhere, except
  /// where the mark is drawn large behind a card as its signature.
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final String svg = subjectIconSvg(subject, stroke: stroke);
    if (svg.isEmpty) return SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        svg,
        colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
      ),
    );
  }
}

/// A subject at a glance: its mark on a disc of its own colour.
///
/// Where a list names a subject in passing — a kept card, a day in the
/// archive, a chip to narrow a shelf — it used to be a square of colour, a
/// few pixels that said "some subject" and left the reader to remember which
/// colour was which. The mark says which. The disc keeps the colour, so the
/// two ways of knowing a subject are on the same spot.
class SubjectBadge extends StatelessWidget {
  const SubjectBadge({
    super.key,
    required this.subject,
    required this.color,
    required this.ink,
    this.size = 20,
  });

  /// The subject's name as the cards carry it ('Space', 'Weird facts').
  final String subject;
  final Color color;
  final Color ink;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        // Thinking's near-white would vanish on paper without an edge.
        border: color.computeLuminance() > 0.8
            ? Border.all(color: ink.withValues(alpha: 0.16), width: 0.8)
            : null,
      ),
      child: SubjectIcon(subject: subject, size: size * 0.6, ink: ink),
    );
  }
}
