import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The moving background the onboarding screens share: colour blooms, a drift
/// of out-of-focus dots and a vignette that pins the eye to the middle.
///
/// The design canvas places every dot with `(sin((i + 1) * n) + 1) / 2`, so
/// the same seed is reproduced here rather than a random one — the layout is
/// part of the drawing, not noise.
double seeded(int i, double n) => (math.sin((i + 1) * n) + 1) / 2;

/// A soft colour bloom. The canvas blurs a filled circle by ~90px; a radial
/// gradient is the same thing to the eye and costs a fraction of the frame,
/// which matters when three of them animate for as long as the screen is up.
class Bloom extends StatelessWidget {
  const Bloom({
    super.key,
    required this.color,
    required this.size,
    this.alignment = Alignment.center,
  });

  final Color color;
  final double size;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.72, 1],
          ),
        ),
      ),
    );
  }
}

/// Drives a value that runs 0 → 1 → 0 forever, for the slow ambient drifts.
class _Loop extends StatefulWidget {
  const _Loop({
    required this.period,
    required this.builder,
    this.reverse = true,
  });

  final Duration period;
  final bool reverse;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    // Never Future.delayed for a stagger: a pending timer outlives a disposed
    // widget and hangs pumpAndSettle. Where a phase offset is wanted the
    // period carries it instead.
    _c.repeat(reverse: widget.reverse);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.builder(context, widget.reverse ? 0.5 : 0);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => widget.builder(context, _c.value),
    );
  }
}

/// Colour is not the brand here — having many of them is.
///
/// Each scene gets its own three, so the ground under the app never settles
/// into one hue and moving between scenes is a change of light rather than a
/// change of slide.
const List<List<Color>> kSceneBlooms = [
  [Color(0xFFFF2E9C), Color(0xFF2B4BFF), Color(0xFF00B083)],
  [Color(0xFFFF9500), Color(0xFF7A5CFF), Color(0xFF00C2A8)],
  [Color(0xFF2B4BFF), Color(0xFFFFC93C), Color(0xFFFF2E9C)],
  [Color(0xFFC24BE0), Color(0xFF2FA84F), Color(0xFFFF5AD1)],
  [Color(0xFFFF4E2D), Color(0xFF00A3FF), Color(0xFFFFC93C)],
];

/// The three blooms behind the intro, each drifting on its own clock and
/// crossfading to whatever the scene asks for.
class AmbientBlooms extends StatelessWidget {
  const AmbientBlooms({super.key, required this.colors});

  /// Three, in the order they are painted: top left, top right, lower left.
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          children: [
            Positioned(
              left: -130,
              top: -70,
              child: _Loop(
                period: const Duration(seconds: 19),
                builder: (context, t) => Transform.translate(
                  offset: Offset(34 * t, -30 * t),
                  child: Transform.scale(
                    scale: 1 + 0.18 * t,
                    child: _Tinted(colors[0], alpha: 0.32, size: 360),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -150,
              top: 40,
              child: _Loop(
                period: const Duration(seconds: 26),
                builder: (context, t) => Transform.translate(
                  offset: Offset(-30 * t, 26 * t),
                  child: Transform.scale(
                    scale: 1.1 - 0.18 * t,
                    child: _Tinted(colors[1], alpha: 0.36, size: 380),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 290,
              child: _Loop(
                // A different period is what keeps the three from breathing
                // in step; it does not need a delay to start out of phase.
                period: const Duration(seconds: 23),
                builder: (context, t) => Transform.translate(
                  offset: Offset(34 * t, -30 * t),
                  child: Transform.scale(
                    scale: 1 + 0.18 * t,
                    child: _Tinted(colors[2], alpha: 0.28, size: 280),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A bloom that crossfades when its colour changes, so a new scene arrives
/// as the light moving rather than as a cut.
class _Tinted extends StatelessWidget {
  const _Tinted(this.color, {required this.alpha, required this.size});

  final Color color;
  final double alpha;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color.withValues(alpha: alpha)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, _) => Bloom(
        color: value ?? color.withValues(alpha: alpha),
        size: size,
      ),
    );
  }
}

/// Fades whatever it wraps out at the edges, so an animation ends in light
/// rather than against a straight line. A clipped rectangle reads as a frame
/// somebody forgot to remove.
class SoftEdges extends StatelessWidget {
  const SoftEdges({super.key, required this.child, this.fade = 0.14});

  final Widget child;
  final double fade;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0x00FFFFFF),
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0, fade, 1 - fade, 1],
      ).createShader(rect),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0x00FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0, fade * 0.8, 1 - fade * 0.8, 1],
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

/// Sixteen out-of-focus dots drifting across the whole screen.
class Bokeh extends StatelessWidget {
  const Bokeh({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, box) {
            return Stack(
              children: [for (int i = 0; i < 16; i++) _dot(i, box.biggest)],
            );
          },
        ),
      ),
    );
  }

  Widget _dot(int i, Size box) {
    final bool near = i % 3 == 0;
    final double left = (-6 + seeded(i, 12.9898) * 104) / 100 * box.width;
    final double top = (-4 + seeded(i, 78.233) * 62) / 100 * box.height;
    final double size = near
        ? 34 + seeded(i, 45.11) * 42
        : 8 + seeded(i, 45.11) * 16;
    final double opacity = near
        ? 0.05 + seeded(i, 33.7) * 0.07
        : 0.16 + seeded(i, 33.7) * 0.5;
    final Duration period = Duration(
      milliseconds: ((13 + seeded(i, 9.13) * 14) * 1000).round(),
    );

    return Positioned(
      left: left,
      top: top,
      child: _Loop(
        period: period,
        builder: (context, t) => Transform.translate(
          offset: Offset(22 * t, -30 * t),
          child: Bloom(
            color: Colors.white.withValues(alpha: opacity),
            size: size,
          ),
        ),
      ),
    );
  }
}

/// Darkens the edges so the middle of the screen carries the eye.
class Vignette extends StatelessWidget {
  const Vignette({super.key, required this.ground, this.height = 0.68});

  final Color ground;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              ground.withValues(alpha: 0),
              ground.withValues(alpha: 0.6),
              ground,
            ],
            stops: const [0, 0.6, 1],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// The band of light that crosses the top of the intro every few seconds.
class LightSweep extends StatelessWidget {
  const LightSweep({super.key, this.height = 460});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: ClipRect(
          child: _Loop(
            // 8s of sweep plus a 1.5s pause, folded into one period so the
            // gap needs no timer of its own.
            period: const Duration(milliseconds: 9500),
            reverse: false,
            builder: (context, raw) {
              const double pause = 1.5 / 9.5;
              if (raw < pause) return const SizedBox.shrink();
              final double t = (raw - pause) / (1 - pause);
              final double opacity = t < 0.12
                  ? t / 0.12 * 0.5
                  : t < 0.55
                  ? 0.5
                  : 0.5 * (1 - (t - 0.55) / 0.45);
              return LayoutBuilder(
                builder: (context, box) => Transform.translate(
                  offset: Offset(box.maxWidth * (-0.6 + 2.2 * t), 0),
                  child: Transform.rotate(
                    angle: 18 * math.pi / 180,
                    child: Opacity(
                      opacity: opacity.clamp(0, 1),
                      child: Container(
                        width: 120,
                        height: height * 1.6,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0x17FFFFFF),
                              Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
