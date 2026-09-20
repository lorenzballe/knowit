import 'package:flutter/material.dart';

/// Text that takes the largest size, down from [style]'s, at which it fits
/// the width it is given in at most [maxLines] lines.
///
/// A headline set once, in one size, fits the language it was designed in
/// and truncates in the others: "Want five more?" is two words longer in
/// Italian and a word longer again in German, and a card whose headline
/// ends in three dots reads as broken. Shrinking is the honest answer — a
/// line of type a size smaller is still the line, and the reader never
/// knows it was ever bigger. Nothing is ever clipped: at [minSize] the text
/// wraps on as many lines as it needs.
class FitText extends StatelessWidget {
  const FitText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 2,
    this.minSize = 18,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final double minSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double width = box.maxWidth.isFinite ? box.maxWidth : 1e9;
        final TextStyle base = DefaultTextStyle.of(context).style.merge(style);
        final TextScaler scaler = MediaQuery.textScalerOf(context);
        final TextDirection direction = Directionality.of(context);
        double size = base.fontSize ?? 14;
        while (size > minSize) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: base.copyWith(fontSize: size),
            ),
            maxLines: maxLines,
            textDirection: direction,
            textScaler: scaler,
            textAlign: textAlign,
          )..layout(maxWidth: width);
          final bool fits = !painter.didExceedMaxLines;
          painter.dispose();
          if (fits) break;
          size -= 1;
        }
        return Text(
          text,
          textAlign: textAlign,
          style: base.copyWith(fontSize: size),
          maxLines: size <= minSize ? null : maxLines,
          softWrap: true,
        );
      },
    );
  }
}
