/// The head of Go deeper (deeper_sheet.dart): the card's own colour, lit by
/// slow lights that drift across it, the subject's mark and name as the
/// card wears them, and the card's question set large in the display face.
///
/// As the sheet scrolls, the head moves slower than the parts sliding up
/// over it, so they read as lying on top of it.
library;

import 'dart:math' as math;
import 'dart:typed_data' show Float32List;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../subject_icon.dart';
import 'look.dart';

class DeeperHeader extends StatelessWidget {
  const DeeperHeader({
    super.key,
    required this.pill,
    required this.look,
    required this.drift,
    required this.scroll,
    required this.entrance,
    required this.still,
    required this.overlap,
    this.paintGround = true,
  });

  /// Whether the head paints its own colour; off where the sheet paints
  /// head and body as one (app_style.dart, AppWhole).
  final bool paintGround;

  final Pill pill;
  final DeeperLook look;

  /// The lights' one slow drift, 0 to 1, at rest at both ends.
  final Animation<double> drift;

  /// How far the sheet has scrolled.
  final ValueListenable<double> scroll;

  /// The sheet's arrival, 0 to 1: the head's words come in at its start.
  final Animation<double> entrance;

  /// Whether the reader asked for less motion: then nothing drifts or
  /// lags, and everything is where it ends.
  final bool still;

  /// How far the first part lies over the head's foot.
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = look.worldInk;
    final double width = MediaQuery.sizeOf(context).width;
    final double size = (width / 13.2).clamp(25.0, 32.0);
    final String subject = l.subjectOf(pill.topic);

    final Widget words = Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 34 + overlap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _Rise(
            animation: entrance,
            from: 0.02,
            to: 0.3,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CardMark(pill: pill, size: 18, ink: ink),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        subject.toUpperCase(),
                        style: AppText.label(
                          size: 11.5,
                          weight: FontWeight.w700,
                          spacing: 1.6,
                          color: ink.withValues(alpha: 0.86),
                        ),
                      ),
                    ),
                  ],
                ),
                // The sheet's name, worn as a card wears its tag.
                Semantics(
                  header: true,
                  label: l.deeperTitle,
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        l.deeperTitle.toUpperCase(),
                        style: AppText.label(
                          size: 11,
                          weight: FontWeight.w800,
                          spacing: 1.5,
                          color: look.pearl
                              ? Colors.white
                              : Color.lerp(look.world, Colors.white, 0.12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Rise(
            animation: entrance,
            from: 0.06,
            to: 0.38,
            child: Semantics(
              header: true,
              child: Text(
                pill.question,
                style: AppText.display(
                  size: size,
                  weight: FontWeight.w700,
                  height: 1.13,
                  spacing: -0.6,
                  color: ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return ClipRect(
      child: Stack(
        children: [
          if (paintGround)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: DeeperGlow(
                    look: look,
                    drift: drift,
                    scroll: still ? null : scroll,
                    foot: overlap,
                  ),
                ),
              ),
            ),
          // The subject's mark, drawn large and faint past the head's edge:
          // the card's signature.
          Positioned(
            right: -38,
            top: 4,
            child: _Lag(
              scroll: scroll,
              still: still,
              factor: 0.22,
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: -0.2,
                  child: SubjectIcon(
                    subject: pill.topic,
                    size: 200,
                    stroke: 1.5,
                    ink: ink.withValues(alpha: look.pearl ? 0.06 : 0.1),
                  ),
                ),
              ),
            ),
          ),
          _Lag(
            scroll: scroll,
            still: still,
            factor: 0.42,
            fade: true,
            child: words,
          ),
        ],
      ),
    );
  }
}

/// Fades and lifts [child] in over a stretch of the sheet's arrival.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.animation,
    required this.from,
    required this.to,
    required this.child,
  });

  final Animation<double> animation;
  final double from;
  final double to;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final double v = Curves.easeOutCubic.transform(
        ((animation.value - from) / (to - from)).clamp(0.0, 1.0),
      );
      return Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      );
    },
  );
}

/// Holds [child] back as the sheet scrolls, by [factor] of the distance, and
/// with [fade] lets it go as it does.
class _Lag extends StatelessWidget {
  const _Lag({
    required this.scroll,
    required this.still,
    required this.factor,
    required this.child,
    this.fade = false,
  });

  final ValueListenable<double> scroll;
  final bool still;
  final double factor;
  final bool fade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (still) return child;
    return AnimatedBuilder(
      animation: scroll,
      // Drawn once, then only moved and faded as the sheet scrolls.
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        final double s = scroll.value.clamp(0.0, 600.0);
        return Opacity(
          opacity: fade ? (1 - s / 300).clamp(0.0, 1.0) : 1,
          child: Transform.translate(
            offset: Offset(0, s * factor),
            child: child,
          ),
        );
      },
    );
  }
}

/// The head's ground: the card's colour, the lights drifting over it, a
/// sheen across the top, and the foot deepening where the first part lies.
class DeeperGlow extends CustomPainter {
  DeeperGlow({
    required this.look,
    required this.drift,
    required this.scroll,
    required this.foot,
    this.head,
    this.whole = false,
  }) : super(repaint: Listenable.merge([drift, scroll]));

  /// The head's height, when the painting is taller than the head: its
  /// colour then runs on down below it, its lights placed in the head.
  final double? head;

  /// Painted as part of one whole: no foot of its own and no grain, both
  /// left to the whole.

  final DeeperLook look;
  final Animation<double> drift;
  final ValueListenable<double>? scroll;
  final double foot;
  final bool whole;

  /// Where each light rests, as parts of the head's width and height, how
  /// big it is against the width, and the turns it makes in one drift.
  static const List<(double, double, double, double, double)> _lights = [
    (0.1, 0.15, 0.62, 1, 0.3),
    (0.9, 0.05, 0.55, 2, 1.7),
    (0.72, 0.95, 0.68, 1, 3.1),
    (0.08, 0.98, 0.58, 2, 4.4),
  ];

  /// The stops of a light's falloff, closer together where it bends.
  static const List<double> _falloff = [
    0,
    0.08,
    0.16,
    0.24,
    0.32,
    0.4,
    0.48,
    0.56,
    0.64,
    0.72,
    0.8,
    0.88,
    1,
  ];

  /// How far the lights travel, as parts of the head's width and height.
  static const double _reachX = 0.3;
  static const double _reachY = 0.24;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = Offset.zero & size;
    final double hh = head ?? size.height;
    final double v = drift.value;
    // Under way within a second, slowing to rest over the last two: the
    // lights are where they started at both ends, so a drift begun again
    // starts from where the last one stopped.
    final double swing =
        Curves.easeOut.transform((v / 0.07).clamp(0.0, 1.0)) *
        Curves.easeInOut.transform(((1 - v) / 0.14).clamp(0.0, 1.0));
    final double lag = (scroll?.value ?? 0).clamp(0.0, 600.0) * 0.3;

    canvas.drawRect(
      box,
      Paint()
        ..shader = ui.Gradient.linear(
          box.topLeft,
          Offset(size.width, hh),
          [look.glow[1], look.world, look.glow[3]],
          const [0, 0.5, 1],
        ),
    );

    // Depth: the colour's own deeper shade pooled low in the head and in
    // its far corner, as a dyed paper is darker where it is thick. Not on
    // Thinking's paper, which is lit, not dyed.
    if (!look.pearl) {
      final Color deep = _deep(look.world);
      // At night the colour deepens all the way into the black; on paper
      // only a little, and it is let go again before the foot, so the
      // colour lightens into the paper with no darker band on the way.
      final double low = hh - foot - 90;
      canvas.drawRect(
        box,
        Paint()
          ..shader = look.dark
              ? ui.Gradient.linear(Offset(0, hh * 0.35), Offset(0, hh), [
                  deep.withValues(alpha: 0),
                  deep.withValues(alpha: 0.45),
                ])
              : ui.Gradient.linear(
                  Offset(0, hh * 0.3),
                  Offset(0, low),
                  [
                    deep.withValues(alpha: 0),
                    deep.withValues(alpha: 0.22),
                    deep.withValues(alpha: 0),
                  ],
                  const [0, 0.7, 1],
                ),
      );
    }

    for (int i = 0; i < _lights.length; i++) {
      final (double x, double y, double r, double turns, double phase) =
          _lights[i];
      final double a = 2 * math.pi * v * turns + phase;
      final Offset centre = Offset(
        size.width * (x + _reachX * swing * (math.sin(a) - math.sin(phase))),
        hh * (y + _reachY * swing * (math.cos(a) - math.cos(phase))) + lag,
      );
      final double radius = size.width * r;
      final Color colour = look.glow[i];
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            centre,
            radius,
            // A gaussian falloff over many stops: a light with no edge
            // and no rings where its slope changes.
            [
              for (final double t in _falloff)
                colour.withValues(
                  alpha:
                      (look.pearl ? 0.95 : 0.9) *
                      math.exp(-4.2 * t * t) *
                      (1 - t * t * t),
                ),
            ],
            _falloff,
          ),
      );
    }

    // Once, as the sheet opens, light runs across the head as across a
    // card turned in the hand.
    final double glint = (v - 0.03) / 0.15;
    if (glint > 0 && glint < 1) {
      final double at = -0.4 + glint * 1.8;
      canvas.drawRect(
        box,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(size.width * (at - 0.25), 0),
            Offset(size.width * (at + 0.25), hh * 0.6),
            [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0),
            ],
            const [0, 0.5, 1],
          ),
      );
    }

    // A soft light across the top left, as on glazed paper.
    canvas.drawRect(
      box,
      Paint()
        ..shader = ui.Gradient.linear(
          box.topLeft,
          Offset(size.width * 0.55, hh * 0.7),
          [
            Colors.white.withValues(alpha: look.pearl ? 0.35 : 0.09),
            Colors.white.withValues(alpha: 0),
          ],
        ),
    );

    if (whole) return;

    // A fine grain over it all, as in a printed colour: a few thousand
    // specks, lighter and darker, too small to see one by one.
    canvas.drawRawPoints(
      ui.PointMode.points,
      _grain(size, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: look.pearl ? 0.06 : 0.06)
        ..strokeWidth = 0.6,
    );
    canvas.drawRawPoints(
      ui.PointMode.points,
      _grain(size, 1),
      Paint()
        ..color = Colors.black.withValues(alpha: look.pearl ? 0.05 : 0.07)
        ..strokeWidth = 0.6,
    );

    // The foot, where the first part lies: let go into the sheet's own
    // ground below the words, on an eased curve so there is no line where
    // the colour ends, only a slow fall into the ground.
    //
    // The fall goes through the colour's own shades, not a mix of it with
    // the ground: at night through its own deeper hue (a yellow through
    // amber, never olive), on paper through its own palest tint (never a
    // grey), and only then into the ground itself.
    final double melt = foot + (look.dark ? 80 : 90);
    final Color g = look.ground;
    final (Color near, Color far) = _fall(look);
    canvas.drawRect(
      Rect.fromLTRB(0, size.height - melt, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height - melt),
          Offset(0, size.height),
          [
            near.withValues(alpha: 0),
            near.withValues(alpha: 0.14),
            near.withValues(alpha: 0.42),
            far.withValues(alpha: 0.7),
            far.withValues(alpha: 0.9),
            Color.alphaBlend(far.withValues(alpha: 0.25), g),
            g,
          ],
          const [0, 0.16, 0.34, 0.52, 0.68, 0.84, 1],
        ),
    );
  }

  static final Map<(int, bool, int), (Color, Color)> _falls = {};

  /// The two shades the foot falls through, from the colour to the ground.
  static (Color, Color) _fall(DeeperLook look) =>
      _falls[(
        look.world.toARGB32(),
        look.dark,
        look.ground.toARGB32(),
      )] ??= () {
        final Oklch o = Oklch.of(look.world);
        if (look.pearl) return (look.ground, look.ground);
        final double h = _richHue(o.h);
        if (look.dark) {
          return (
            Oklch(o.l * 0.72, o.c * 0.95, h).toColour(),
            Oklch(
              math.max(0.2, Oklch.of(look.ground).l + 0.02),
              o.c * 0.5,
              h,
            ).toColour(),
          );
        }
        final Oklch paper = Oklch.of(look.ground);
        return (
          Oklch(0.86, o.c * 0.55, o.h).toColour(),
          Oklch(paper.l, math.min(o.c * 0.18, 0.04), o.h).toColour(),
        );
      }();

  /// The hue a colour deepens towards: a yellow turns to amber as it
  /// darkens, as gold does, instead of to olive; the rest stay near their
  /// own.
  static double _richHue(double h) =>
      (h > 80 && h < 125 ? h - 32 : h - 10) % 360;

  static final Map<int, Color> _deeps = {};

  /// The world's own colour, deeper and a little richer.
  static Color _deep(Color world) => _deeps[world.toARGB32()] ??= () {
    final Oklch o = Oklch.of(world);
    // A light colour deepens less, or it turns muddy.
    return Oklch(
      (o.l - (o.l > 0.8 ? 0.1 : 0.16)).clamp(0.0, 1.0),
      o.c * 1.08,
      _richHue(o.h),
    ).toColour();
  }();

  static final Map<(int, int, int), Float32List> _grains = {};

  /// The specks of one grain, the same every frame for a head's size.
  static Float32List _grain(Size size, int seed) =>
      _grains[(size.width.round(), size.height.round(), seed)] ??= () {
        final math.Random r = math.Random(17 + seed);
        final int n = (size.width * size.height / 14).round();
        final Float32List at = Float32List(n * 2);
        for (int i = 0; i < n; i++) {
          at[i * 2] = r.nextDouble() * size.width;
          at[i * 2 + 1] = r.nextDouble() * size.height;
        }
        return at;
      }();

  @override
  bool shouldRepaint(DeeperGlow old) =>
      old.look != look ||
      old.drift != drift ||
      old.scroll != scroll ||
      old.foot != foot;
}
