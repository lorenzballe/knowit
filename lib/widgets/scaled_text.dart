import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Type set as large as the box will take.
///
/// A card whose question is set at a fixed size looks designed only for the
/// question that happens to be the length it was designed around. Anything
/// shorter floats in a void, which is the single thing that makes a
/// full-bleed card read as a placeholder rather than a page. Sizing the type
/// to the space instead means a short question becomes a poster and a long
/// one stays readable, and the card is full either way.
class ScaledText extends StatelessWidget {
  final String text;

  /// The band the type may move in, as the reader sees it. It never goes
  /// below [min]: past that, filling the box costs more than it buys and
  /// the text scrolls instead.
  final double min;
  final double max;

  /// Built at whatever size is chosen. A callback rather than a style so the
  /// optical-size axis and the tracking can follow the size, which is the
  /// whole reason a variable face is worth carrying.
  final TextStyle Function(double size) styleFor;

  final Alignment alignment;

  const ScaledText({
    super.key,
    required this.text,
    required this.styleFor,
    this.min = 20,
    this.max = 46,
    this.alignment = Alignment.bottomLeft,
  });

  /// Whether [text] at [size] fits [width] by [height] as it will be drawn:
  /// at the reader's text size, in the reader's direction, and with no word
  /// broken across two lines.
  ///
  /// Measured at a text size of one, the size chosen fitted the box only
  /// for a reader who never touched the setting: a step or two up, the
  /// question was drawn larger than it had been measured and was cut off
  /// in its own box.
  bool _fits(
    double size,
    double width,
    double height,
    TextScaler scaler,
    TextDirection direction,
    String longest,
  ) {
    final TextStyle style = styleFor(size);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: width);
    final bool fits = painter.height <= height && painter.width <= width;
    painter.dispose();
    if (!fits) return false;
    // A word wider than the line is broken in the middle, which no size
    // should buy: "tempera / tures".
    final word = TextPainter(
      text: TextSpan(text: longest, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final bool whole = word.width <= width;
    word.dispose();
    return whole;
  }

  /// The longest word, as it sets: the one a narrow box breaks first.
  String _longestWord(TextDirection direction) {
    String longest = '';
    double widest = 0;
    for (final String w in text.split(RegExp(r'\s+'))) {
      final painter = TextPainter(
        text: TextSpan(text: w, style: styleFor(max)),
        textDirection: direction,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) {
        widest = painter.width;
        longest = w;
      }
      painter.dispose();
    }
    return longest;
  }

  /// Largest size that still fits, to within a tenth of a point.
  ///
  /// Between [min] and [max] as sizes the reader sees: [max] grows with
  /// their text size where the box has room for it, and [min] does not, so
  /// a reader with larger text still gets the whole question, at the
  /// smallest size it was designed for, rather than a third of it.
  double _fit(
    double width,
    double height,
    TextScaler scaler,
    TextDirection direction,
  ) {
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return min;
    }
    final double floor = math.min(min, min * min / scaler.scale(min));
    final String longest = _longestWord(direction);
    bool fits(double size) =>
        _fits(size, width, height, scaler, direction, longest);
    if (fits(max)) return max;
    var lo = floor;
    var hi = max;
    while (hi - lo > 0.1) {
      final mid = (lo + hi) / 2;
      if (fits(mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _fit(
          constraints.maxWidth,
          constraints.maxHeight,
          MediaQuery.textScalerOf(context),
          Directionality.of(context),
        );
        // Measured against the bounded box, then rendered in a scroll view:
        // when it fits there is nothing to scroll, and when even [min] was
        // too big the question stays reachable instead of being clipped.
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: alignment,
              child: Text(text, style: styleFor(size)),
            ),
          ),
        );
      },
    );
  }
}
