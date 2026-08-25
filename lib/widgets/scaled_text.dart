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

  /// The band the type may move in. It never goes below [min]: past that,
  /// filling the box costs more than it buys and the text scrolls instead.
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

  bool _fits(double size, double width, double height) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: styleFor(size)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    return painter.height <= height && painter.width <= width;
  }

  /// Largest size that still fits, to within a tenth of a point.
  double _fit(double width, double height) {
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return min;
    }
    if (_fits(max, width, height)) return max;
    var lo = min;
    var hi = max;
    while (hi - lo > 0.1) {
      final mid = (lo + hi) / 2;
      if (_fits(mid, width, height)) {
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
        final size = _fit(constraints.maxWidth, constraints.maxHeight);
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
