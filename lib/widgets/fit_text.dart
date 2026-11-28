import 'package:flutter/material.dart';

import 'balanced_text.dart';

/// Text that takes the largest size, down from [style]'s, at which it fits
/// the width it is given in at most [maxLines] lines.
///
/// A headline set once, in one size, fits the language it was designed in
/// and truncates in the others: "Want five more?" is two words longer in
/// Italian and a word longer again in German, and a card whose headline
/// ends in three dots reads as broken. Shrinking is the honest answer — a
/// line of type a size smaller is still the line, and the reader never
/// knows it was ever bigger. Nothing is ever clipped: at [minSize] the text
/// wraps on as many lines as it needs — unless it is a line that must stay
/// [maxLines] long whatever comes ([ellipsis]), which at [minSize] is cut
/// with three dots as the last resort.
class FitText extends StatelessWidget {
  const FitText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 2,
    this.minSize = 18,
    this.textAlign = TextAlign.start,
    this.ellipsis = false,
    this.wholeWords = false,
    this.balanced = false,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final double minSize;
  final TextAlign textAlign;

  /// Never more than [maxLines] lines: at [minSize], what still does not
  /// fit ends in three dots rather than wrapping on.
  final bool ellipsis;

  /// Whether every word must also fit a line of its own at the size taken:
  /// in a narrow box a long name ("Wissenschaftlich denken") breaks inside
  /// its first word and still keeps to two lines, which is no better than
  /// cut. Words in scripts that break between any two characters — Chinese,
  /// Japanese, Korean — are no such words.
  final bool wholeWords;

  /// Whether, once the size is found, the lines are broken evenly
  /// ([BalancedText]): a title that wraps by one word does not leave that
  /// word alone on the line under it. It never takes a line more.
  final bool balanced;

  /// A character of a script whose lines break between any two of them.
  static final RegExp _breaksAnywhere = RegExp(
    r'[\u1100-\u11ff\u2e80-\u9fff\uac00-\ud7af\uf900-\ufaff\uff00-\uffef]',
  );

  /// Whether each word of [text], set in [style], fits [width] alone: what
  /// [wholeWords] asks at each size, and what a box choosing its own width
  /// can ask before it sets one.
  static bool wordsFit(
    String text,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
    double width,
  ) {
    for (final String word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty || _breaksAnywhere.hasMatch(word)) continue;
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        maxLines: 1,
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      final bool fits = painter.width <= width;
      painter.dispose();
      if (!fits) return false;
    }
    return true;
  }

  /// The one size [texts] are all set at in [width]: the largest, from
  /// [from] down by half points to [least], at which each of their words
  /// fits a line alone in [style] at that size; null where none does. What
  /// names laid side by side ask, so that none reads louder than the one
  /// beside it and none breaks inside a word.
  static double? oneSize(
    List<String> texts,
    TextStyle Function(double size) style,
    double width, {
    required double from,
    required double least,
    required TextScaler scaler,
    required TextDirection direction,
  }) {
    for (double size = from; size >= least; size -= 0.5) {
      if (texts.every(
        (t) => wordsFit(t, style(size), scaler, direction, width),
      )) {
        return size;
      }
    }
    return null;
  }

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
          final bool fits =
              !painter.didExceedMaxLines &&
              (!wholeWords ||
                  wordsFit(
                    text,
                    base.copyWith(fontSize: size),
                    scaler,
                    direction,
                    width,
                  ));
          painter.dispose();
          if (fits) break;
          size -= 1;
        }
        if (balanced && !ellipsis) {
          return BalancedText(
            text,
            textAlign: textAlign,
            style: base.copyWith(fontSize: size),
          );
        }
        return Text(
          text,
          textAlign: textAlign,
          style: base.copyWith(fontSize: size),
          maxLines: size <= minSize && !ellipsis ? null : maxLines,
          overflow: ellipsis ? TextOverflow.ellipsis : null,
          softWrap: true,
        );
      },
    );
  }
}
