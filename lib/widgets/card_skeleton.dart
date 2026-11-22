import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A card's outline in grey, at any size, while its picture is on its way:
/// the subject's mark and name and the chip at the head, the question's
/// lines, the drawing under them, and at the foot the source and the two
/// round buttons, the way the deck opens on the outline of its first card
/// (DeckSkeleton) rather than on an empty colour. A soft light crosses the
/// shapes and rests; still for a reader who asked for less motion, and when
/// [moving] is false (the picture has come and covers it).
class CardSkeleton extends StatefulWidget {
  const CardSkeleton({super.key, this.moving = true});

  /// Whether the light crosses it.
  final bool moving;

  /// The card's width the shapes are drawn for; a smaller box draws them
  /// smaller, a larger one larger.
  static const double drawnFor = 366;

  /// The grey of the card itself, a shade off the page: for what is drawn
  /// round a card while it is still its outline (its edge, the light under
  /// it), so nothing of its colour shows before the card does.
  static Color cardColour(Palette p) => Color.alphaBlend(
    p.ink.withValues(alpha: p.isDark ? 0.065 : 0.05),
    p.surface,
  );

  @override
  State<CardSkeleton> createState() => _CardSkeletonState();
}

class _CardSkeletonState extends State<CardSkeleton>
    with SingleTickerProviderStateMixin {
  /// One pass of the light and its rest.
  late final AnimationController _light = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  /// The part of each cycle the light takes to cross.
  static const double _crossing = 0.68;

  void _run() {
    final bool still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!widget.moving || still) {
      _light.stop();
      _light.value = 1;
    } else if (!_light.isAnimating) {
      _light.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(CardSkeleton old) {
    super.didUpdateWidget(old);
    if (old.moving != widget.moving) _run();
  }

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool dark = p.isDark;
    final Color ink = p.ink;
    // The card a shade off the page, the shapes on it a shade further, and
    // the light a shade lighter than they are: three steps of one grey, the
    // deck's own.
    final Color card = CardSkeleton.cardColour(p);
    final Color shape = Color.alphaBlend(
      ink.withValues(alpha: dark ? 0.075 : 0.07),
      card,
    );
    final Color glow = dark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.75);

    return ColoredBox(
      key: const ValueKey('card-skeleton'),
      color: card,
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.maxWidth.isFinite
              ? box.maxWidth
              : CardSkeleton.drawnFor;
          // Laid out at least a card's height, from the top, and cut where
          // the box is shorter, as a picture shown from the top is.
          final double h = math.max(
            box.maxHeight.isFinite ? box.maxHeight : 0,
            w * 606 / CardSkeleton.drawnFor,
          );
          final double s = w / CardSkeleton.drawnFor;
          Widget bar(double width, double tall, {double? radius}) => Container(
            width: width,
            height: tall,
            decoration: BoxDecoration(
              color: shape,
              borderRadius: BorderRadius.circular(radius ?? tall / 2),
            ),
          );
          Widget round(double size) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: shape, shape: BoxShape.circle),
          );
          final double inner = math.max(0, w - 52 * s);
          final double q = math.max(h * 0.034, 18 * s) * 0.92;
          final Widget shapes = Padding(
            padding: EdgeInsets.fromLTRB(26 * s, 26 * s, 26 * s, 22 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The head: the subject's mark and name, the chip.
                Row(
                  children: [
                    round(14 * s),
                    SizedBox(width: 9 * s),
                    bar(inner * 0.22, 10 * s),
                    const Spacer(),
                    bar(inner * 0.3, 22 * s),
                  ],
                ),
                SizedBox(height: h * 0.045),
                // The question.
                bar(inner * 0.94, q, radius: 7 * s),
                SizedBox(height: q * 0.45),
                bar(inner * 0.86, q, radius: 7 * s),
                SizedBox(height: q * 0.45),
                bar(inner * 0.58, q, radius: 7 * s),
                SizedBox(height: h * 0.05),
                // The drawing.
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: shape.withValues(alpha: shape.a * 0.7),
                      borderRadius: BorderRadius.circular(22 * s),
                    ),
                  ),
                ),
                SizedBox(height: h * 0.045),
                // The foot: the source, save and share.
                Row(
                  children: [
                    bar(inner * 0.36, 10 * s),
                    const Spacer(),
                    round(34 * s),
                    SizedBox(width: 10 * s),
                    round(34 * s),
                  ],
                ),
              ],
            ),
          );
          // The light lights the shapes alone, never the card between them.
          return AnimatedBuilder(
            animation: _light,
            builder: (context, child) {
              final double v = _light.value;
              if (v >= _crossing) return child!;
              final double t = Curves.easeInOut.transform(v / _crossing);
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) {
                  final double x = -0.45 + t * 1.9;
                  return LinearGradient(
                    begin: Alignment(x * 2 - 1 - 0.7, -0.25),
                    end: Alignment(x * 2 - 1 + 0.7, 0.25),
                    colors: [
                      glow.withValues(alpha: 0),
                      glow,
                      glow.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.5, 1],
                  ).createShader(rect);
                },
                child: child,
              );
            },
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: h,
                maxHeight: h,
                child: shapes,
              ),
            ),
          );
        },
      ),
    );
  }
}
