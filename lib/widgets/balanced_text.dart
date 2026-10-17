import 'package:flutter/material.dart';

/// Text whose lines are as even as the width allows.
///
/// A line that wraps by one word leaves that word alone underneath, and a
/// shelf whose line ends "compared to / what?" reads as a layout that ran out
/// of room rather than one that was set. So the text keeps the number of
/// lines it needs at the full width and takes the narrowest width that still
/// holds it in that many: the same lines, broken evenly. One line stays one
/// line, and nothing ever takes a line more than it would have.
class BalancedText extends StatelessWidget {
  const BalancedText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final Widget plain = Text(text, style: style, textAlign: textAlign);
    return LayoutBuilder(
      builder: (context, box) {
        final double width = box.maxWidth;
        if (!width.isFinite || width <= 0) return plain;
        final TextPainter painter = TextPainter(
          text: TextSpan(
            text: text,
            style: DefaultTextStyle.of(context).style.merge(style),
          ),
          textAlign: textAlign,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
        );
        int linesAt(double w) {
          painter.layout(maxWidth: w);
          return painter.computeLineMetrics().length;
        }

        final int lines = linesAt(width);
        if (lines < 2) {
          painter.dispose();
          return plain;
        }
        // The narrowest width that keeps the count, to within half a pixel.
        double fits = width;
        double fails = width / lines - 1;
        while (fits - fails > 0.5) {
          final double mid = (fits + fails) / 2;
          if (linesAt(mid) <= lines) {
            fits = mid;
          } else {
            fails = mid;
          }
        }
        painter.dispose();
        return Align(
          alignment: switch (textAlign) {
            TextAlign.center => Alignment.topCenter,
            TextAlign.right || TextAlign.end => AlignmentDirectional.topEnd,
            _ => AlignmentDirectional.topStart,
          },
          widthFactor: 1,
          child: SizedBox(width: fits.ceilToDouble(), child: plain),
        );
      },
    );
  }
}
