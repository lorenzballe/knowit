import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Liquid Glass, the material of iOS 26, for the layer of controls that
/// floats over the content: the tab bar, the round buttons laid on a screen,
/// the sheets that rise over it, the switch between light and dark.
///
/// What is behind shows through, softened (a blur of the backdrop), under a
/// thin tint that lifts it off the content: lighter on paper, smoked at
/// night. The edge catches the light: a rim brighter where the light falls,
/// top left and bottom right, as on a bead of glass, and a sheen along the
/// top inside, where a lens bends the most. A soft shadow sets it above.
///
/// Content is never glass. The cards are the thing the app is for and stay
/// solid: glass is for what is laid on top of them, so the two never blur
/// into each other.
///
/// With high contrast asked for, the glass is solid ground with a plain
/// edge: what shows through glass is what high contrast is there to remove.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = 26,
    this.circle = false,
    this.blur = 24,
    this.shadow = true,
    this.tint,
    this.strength = 1,
  });

  final Widget child;

  /// The corners, when it is not a [circle].
  final double radius;

  /// A round button rather than a rounded panel.
  final bool circle;

  /// How much the backdrop is softened, as a blur's sigma.
  final double blur;

  /// Whether it casts a shadow: a panel laid on content does; a sheet that
  /// is itself the ground of what is on it need not.
  final bool shadow;

  /// A colour washed into the glass, for glass that belongs to something
  /// coloured (a card's own buttons).
  final Color? tint;

  /// How much glass: 1 the standard, more for a sheet that carries text.
  final double strength;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool dark = p.isDark;
    final BorderRadius corners = BorderRadius.circular(circle ? 999 : radius);
    final ShapeBorder shape = circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: corners);
    final List<BoxShadow> shadows = shadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.42 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ]
        : const [];

    if (MediaQuery.highContrastOf(context)) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          color: p.surfaceRaised,
          shape: circle
              ? CircleBorder(side: BorderSide(color: p.lineStrong))
              : RoundedRectangleBorder(
                  borderRadius: corners,
                  side: BorderSide(color: p.lineStrong),
                ),
          shadows: shadows,
        ),
        child: child,
      );
    }

    final double k = strength.clamp(0.5, 2.0);
    // The tint: on paper a milk glass, at night a smoked one; a coloured
    // tint takes the place of either, as thin.
    final Color top = tint != null
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.22), tint!).withValues(alpha: 0.34 * k)
        : dark
        ? Colors.white.withValues(alpha: 0.13 * k)
        : Colors.white.withValues(alpha: 0.62 * k);
    final Color bottom = tint != null
        ? tint!.withValues(alpha: 0.22 * k)
        : dark
        ? Colors.white.withValues(alpha: 0.06 * k)
        : Colors.white.withValues(alpha: 0.42 * k);

    return DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: shadows),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            foregroundPainter: _Rim(circle: circle, radius: radius, dark: dark),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: shape,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [top, bottom],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The edge of the glass: a hairline brighter where the light falls, and a
/// sheen inside along the top.
class _Rim extends CustomPainter {
  const _Rim({required this.circle, required this.radius, required this.dark});

  final bool circle;
  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = Offset.zero & size;
    final RRect outer = circle
        ? RRect.fromRectAndRadius(box, Radius.circular(size.shortestSide / 2))
        : RRect.fromRectAndRadius(box, Radius.circular(radius));

    // The sheen: a band of light just inside the top, fading down.
    final Rect band = Rect.fromLTWH(0, 0, size.width, size.height * 0.55);
    canvas.save();
    canvas.clipRRect(outer);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.10 : 0.30),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.restore();

    // The rim: bright top left and bottom right, faint between.
    final RRect edge = outer.deflate(0.5);
    canvas.drawRRect(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.42 : 0.95),
            Colors.white.withValues(alpha: dark ? 0.08 : 0.35),
            Colors.white.withValues(alpha: dark ? 0.06 : 0.25),
            Colors.white.withValues(alpha: dark ? 0.26 : 0.70),
          ],
          stops: const [0, 0.38, 0.62, 1],
        ).createShader(box),
    );
    // And a darker line just outside it on paper, so the glass has an edge
    // against white.
    if (!dark) {
      canvas.drawRRect(
        outer.inflate(0.0),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = Colors.black.withValues(alpha: 0.06),
      );
    }
  }

  @override
  bool shouldRepaint(_Rim old) =>
      old.circle != circle || old.radius != radius || old.dark != dark;
}

/// The ground of a sheet that rises from the foot of the screen, in glass:
/// the screen it rose over shows through, blurred deep enough that the
/// sheet's words read over anything, with the sheen along its top edge.
/// The corners are the sheets' own, 30 at the top.
class GlassSheet extends StatelessWidget {
  const GlassSheet({super.key, required this.child, this.radius = 30});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool dark = p.isDark;
    final BorderRadius corners = BorderRadius.vertical(
      top: Radius.circular(radius),
    );
    if (MediaQuery.highContrastOf(context)) {
      return DecoratedBox(
        decoration: BoxDecoration(color: p.surface, borderRadius: corners),
        child: child,
      );
    }
    return ClipRRect(
      borderRadius: corners,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 34, sigmaY: 34),
        child: CustomPaint(
          foregroundPainter: _SheetEdge(radius: radius, dark: dark),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: corners,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  p.surface.withValues(alpha: dark ? 0.74 : 0.80),
                  p.surface.withValues(alpha: dark ? 0.90 : 0.94),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The top edge of a glass sheet: a hairline of light along its rim.
class _SheetEdge extends CustomPainter {
  const _SheetEdge({required this.radius, required this.dark});

  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = Offset.zero & size;
    final RRect top = RRect.fromRectAndCorners(
      box.deflate(0.5),
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
    final Rect band = Rect.fromLTWH(0, 0, size.width, radius * 2);
    canvas.save();
    canvas.clipRect(band);
    canvas.drawRRect(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.30 : 0.95),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheetEdge old) =>
      old.radius != radius || old.dark != dark;
}
