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
  });

  final String subject;
  final double size;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final String svg = subjectIconSvg(subject);
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
