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

/// The three blooms behind the intro, each drifting on its own clock.
class AmbientBlooms extends StatelessWidget {
  const AmbientBlooms({super.key});

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
                    child: const Bloom(color: Color(0x52FF2E9C), size: 360),
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
                    child: const Bloom(color: Color(0x5C2B4BFF), size: 380),
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
                    child: const Bloom(color: Color(0x2E00B083), size: 280),
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
