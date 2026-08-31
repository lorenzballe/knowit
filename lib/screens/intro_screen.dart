import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/ambient.dart';

/// The first thing the app shows: five scenes that say what Astuto is, over a
/// dark ground that keeps moving.
///
/// Swipe left or tap for the next scene, swipe right for the previous, or take
/// any of the three buttons at the foot — they all lead to the same place,
/// because no account is created here. The copy on the next screen makes that
/// promise explicit: an account is asked for once there is a streak worth
/// keeping.
class IntroScreen extends StatefulWidget {
  const IntroScreen({
    super.key,
    required this.onContinue,
    required this.onApple,
    required this.onGoogle,
    required this.onNotConnected,
  });

  /// Skip, and where every button lands once it is done.
  final VoidCallback onContinue;

  /// Sign in. Each returns false only when the reader backed out of the
  /// provider's sheet, which should leave them exactly where they were.
  final Future<bool> Function() onApple;
  final Future<bool> Function() onGoogle;

  /// A provider that has no backend behind it yet. Says so, then carries on
  /// — the next screen only needs a deck, not an account.
  final void Function(String provider) onNotConnected;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const int _sceneCount = 5;

  int _scene = 0;
  double _dragX = 0;
  double _moved = 0;

  List<Color> get _blooms => kSceneBlooms[_scene % kSceneBlooms.length];

  void _go(int i) => setState(() => _scene = i % _sceneCount);

  void _next() => _go(_scene + 1);

  void _prev() => _go(_scene == 0 ? _sceneCount - 1 : _scene - 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _dragX = 0;
          _moved = 0;
        },
        onHorizontalDragUpdate: (d) {
          _dragX += d.delta.dx;
          _moved = math.max(_moved, _dragX.abs());
        },
        onHorizontalDragEnd: (_) {
          if (_dragX < -50) {
            _next();
          } else if (_dragX > 50) {
            _prev();
          }
        },
        onTap: () {
          if (_moved < 8) _next();
        },
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Positioned.fill(child: AmbientBlooms(colors: _blooms)),
              const Positioned.fill(child: Bokeh()),
              const Positioned(left: 0, right: 0, top: 0, child: LightSweep()),

              // The picture is the background, not a panel inside the layout.
              // It runs off all three edges it can reach, so there is nothing
              // to see the end of, and it keeps the same size whatever the
              // copy under it happens to say.
              Positioned(
                left: 0,
                right: 0,
                // Below the notch, not behind it. The blooms may run under
                // the status bar because they are a wash; the drawing may
                // not, or every phone with an inset shows it shifted up by
                // however deep that inset is — which a browser, having none,
                // will never reveal.
                top: MediaQuery.paddingOf(context).top,
                // The scenes are drawn for a band 344 by 252 — the shape of
                // the room actually free above the copy. Drawn square, as
                // they were, a picture at full width is taller than that
                // space and has to either run off the top or sit under the
                // title. That was not something to tune: the shape was wrong.
                height: box.maxWidth * _SceneStage.ratio,
                child: _SceneStage(
                  key: const ValueKey('intro-stage'),
                  child: _Swap(
                    scene: _scene,
                    child: _IntroScene(index: _scene),
                  ),
                ),
              ),

              // What makes text on top of a picture readable. It also takes
              // the picture's lower edge away, which is why the scene needs
              // no fade of its own down there.
              const Positioned.fill(child: _Scrim()),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 26),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onContinue,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 4, 24, 4),
                            child: Text(
                              'Skip',
                              style: AppText.body(
                                size: 14,
                                weight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: _Swap(
                          scene: _scene,
                          child: _SceneCopy(index: _scene),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Dots(count: _sceneCount, active: _scene, onTap: _go),
                      SizedBox(
                        height: 26,
                        child: AnimatedOpacity(
                          opacity: _moved == 0 && _scene == 0 ? 1 : 0,
                          duration: const Duration(milliseconds: 350),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Swipe to see more',
                              style: AppText.body(
                                size: 12.5,
                                weight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: _SignInBlock(
                          onApple: () async {
                            if (await widget.onApple()) widget.onContinue();
                          },
                          onGoogle: () async {
                            if (await widget.onGoogle()) widget.onContinue();
                          },
                          onEmail: () {
                            widget.onNotConnected('Email');
                            widget.onContinue();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Darkens the lower half so text sits on something rather than on a picture.
///
/// It is what lets the scene run all the way down without an edge: the
/// picture does not stop, it is covered.
class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: 0.86),
              Colors.black.withValues(alpha: 0.96),
              Colors.black.withValues(alpha: 0.98),
            ],
            // Fully dark by the row the copy starts on. A title lying across
            // a bright card is legible and still looks like an accident.
            stops: const [0, 0.30, 0.42, 0.56, 1],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Gives a scene the whole width of the screen.
///
/// The scenes are composed on a 344 square. Fitting that square inside the
/// space available scales it to whichever side is shorter, which on a phone
/// is the height — so it came out small with the width unused on both sides,
/// looking like a picture in a frame rather than like the app.
///
/// It is scaled to the width instead, and allowed to run a little past the
/// top and bottom, where the fade takes it. The clamp stops that becoming a
/// crop on a short screen.
class _SceneStage extends StatelessWidget {
  const _SceneStage({super.key, required this.child});

  /// The band the scenes are drawn for.
  static const double width = 344;
  static const double bandHeight = 252;
  static const double ratio = bandHeight / width;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Scaled to the width. Nothing is cropped, because the band it is
        // scaled into is the same shape as the band it was drawn in.
        return Transform.scale(
          scale: box.maxWidth / width,
          child: SizedBox(width: width, height: bandHeight, child: child),
        );
      },
    );
  }
}

/// Fades and lifts whatever changes when the scene does.
class _Swap extends StatelessWidget {
  const _Swap({required this.scene, required this.child});

  final int scene;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.965, end: 1).animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) =>
          Stack(alignment: Alignment.center, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(scene), child: child),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active, required this.onTap});

  final int count;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          GestureDetector(
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.26),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SceneCopy extends StatelessWidget {
  const _SceneCopy({required this.index});

  final int index;

  static const List<(String, String)> _copy = [
    ('Astuto', 'Five smart things a day, ready to use in conversation'),
    (
      'Twelve topics, five pills',
      'Written fresh every morning, checked against a source before it '
          'reaches you.',
    ),
    (
      'A question, then the answer',
      'Every pill carries the one line that makes it worth saying out loud.',
    ),
    (
      'You choose the mix',
      'Turn a topic on and it appears tomorrow. Turn it off and it never '
          'comes back.',
    ),
    (
      'Thirty seconds a day',
      'One notification, five cards, and a streak you will not want to break.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final (String title, String sub) = _copy[index];
    final bool wordmark = index == 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: wordmark
              ? AppText.display(
                  size: 46,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -1.6,
                  color: Colors.white,
                )
              // The canvas sets the scene titles in Outfit, which the app does
              // not ship. Figtree at 700 is the closest face already bundled;
              // adding a third family for five lines is not worth the weight.
              : AppText.body(
                  size: 30,
                  weight: FontWeight.w700,
                  height: 1.12,
                  spacing: -1.2,
                  color: Colors.white,
                ),
        ),
        const SizedBox(height: wordmarkGap),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 302),
          child: Text(
            sub,
            textAlign: TextAlign.center,
            style: AppText.body(
              size: wordmark ? 18.5 : 17.5,
              height: wordmark ? 1.4 : 1.44,
              color: Colors.white.withValues(alpha: 0.58),
            ),
          ),
        ),
      ],
    );
  }

  static const double wordmarkGap = 14;
}

class _SignInBlock extends StatelessWidget {
  const _SignInBlock({
    required this.onApple,
    required this.onGoogle,
    required this.onEmail,
  });

  final VoidCallback onApple;
  final VoidCallback onGoogle;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WhiteButton(
          label: 'Continue with Apple',
          onTap: onApple,
          leading: const Icon(Icons.apple, size: 21, color: Colors.black),
        ),
        const SizedBox(height: 11),
        _WhiteButton(
          label: 'Continue with Google',
          onTap: onGoogle,
          leading: const _GoogleG(),
        ),
        const SizedBox(height: 11),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onEmail,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 13, 0, 7),
            child: Text(
              'Continue with Email',
              style: AppText.body(
                size: 16,
                weight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.74),
              ),
            ),
          ),
        ),
        Text(
          'By signing up you agree to our Terms of Service & Privacy Policy',
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 12.5,
            height: 1.5,
            color: Colors.white.withValues(alpha: 0.34),
          ),
        ),
      ],
    );
  }
}

class _WhiteButton extends StatefulWidget {
  const _WhiteButton({
    required this.label,
    required this.onTap,
    required this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final Widget leading;

  @override
  State<_WhiteButton> createState() => _WhiteButtonState();
}

class _WhiteButtonState extends State<_WhiteButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          opacity: _down ? 0.86 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: 57,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.leading,
                const SizedBox(width: 9),
                // Flexible, so a longer label in another language shortens
                // rather than running off the end of the button.
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 17,
                      weight: FontWeight.w600,
                      spacing: -0.2,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Google mark, drawn rather than shipped as an asset.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 19,
      height: 19,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = Offset.zero & size;
    final double stroke = size.width * 0.23;
    final Rect ring = box.deflate(stroke / 2);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    void arc(double from, double sweep, Color c) {
      p.color = c;
      canvas.drawArc(
        ring,
        from * math.pi / 180,
        sweep * math.pi / 180,
        false,
        p,
      );
    }

    arc(-8, -80, const Color(0xFF4285F4));
    arc(-88, -104, const Color(0xFFFBBC05));
    arc(168, -80, const Color(0xFF34A853));
    arc(88, -80, const Color(0xFFEA4335));

    // The bar that closes the G.
    final Paint bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.4,
        size.width * 0.5,
        stroke,
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The five scenes.
class _IntroScene extends StatelessWidget {
  const _IntroScene({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => const _SceneOrbits(),
      1 => const _SceneRain(),
      2 => const _SceneCard(),
      3 => const _SceneChips(),
      _ => const _SceneStreak(),
    };
  }
}

/// Scene 0 — the mark held inside two counter-rotating orbits.
class _SceneOrbits extends StatelessWidget {
  const _SceneOrbits();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _SceneStage.width,
      height: _SceneStage.bandHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Orbit(
            size: 236,
            period: const Duration(seconds: 38),
            opacity: 0.09,
            satellites: const [
              _Satellite(angle: -90, size: 10, color: Color(0xFFFF2E9C)),
              _Satellite(angle: 133, size: 6, color: Color(0xFF00B083)),
            ],
          ),
          _Orbit(
            size: 178,
            period: const Duration(seconds: 24),
            reverse: true,
            opacity: 0.13,
            satellites: const [
              _Satellite(angle: -25, size: 9, color: Color(0xFF2B4BFF)),
              _Satellite(angle: 104, size: 5, color: Color(0xFFFFC93C)),
            ],
          ),
          const _Pulse(size: 146, color: Color(0x992B4BFF)),
          _Pop(
            duration: const Duration(milliseconds: 850),
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xB3000000),
                    blurRadius: 60,
                    offset: Offset(0, 24),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/brand/mark-light.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Satellite {
  const _Satellite({
    required this.angle,
    required this.size,
    required this.color,
  });

  final double angle;
  final double size;
  final Color color;
}

class _Orbit extends StatefulWidget {
  const _Orbit({
    required this.size,
    required this.period,
    required this.opacity,
    required this.satellites,
    this.reverse = false,
  });

  final double size;
  final Duration period;
  final double opacity;
  final List<_Satellite> satellites;
  final bool reverse;

  @override
  State<_Orbit> createState() => _OrbitState();
}

class _OrbitState extends State<_Orbit> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double radius = widget.size / 2;
    final Widget ring = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: widget.opacity),
            ),
          ),
        ),
        for (final _Satellite s in widget.satellites)
          Transform.translate(
            offset: Offset(
              radius * math.cos(s.angle * math.pi / 180),
              radius * math.sin(s.angle * math.pi / 180),
            ),
            child: Container(
              width: s.size,
              height: s.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.color,
                boxShadow: [
                  BoxShadow(
                    color: s.color.withValues(alpha: 0.9),
                    blurRadius: s.size * 1.9,
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (MediaQuery.disableAnimationsOf(context)) return ring;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.rotate(
        angle: (widget.reverse ? -1 : 1) * _c.value * 2 * math.pi,
        child: child,
      ),
      child: ring,
    );
  }
}

/// A glow that breathes.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget glow = Bloom(color: widget.color, size: widget.size);
    if (MediaQuery.disableAnimationsOf(context)) return glow;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final double t = Curves.easeInOut.transform(_c.value);
        return Opacity(
          opacity: 0.45 + 0.35 * t,
          child: Transform.scale(scale: 1 + 0.14 * t, child: child),
        );
      },
      child: glow,
    );
  }
}

/// Scales up past its resting size and settles — the canvas `obcPop`.
class _Pop extends StatefulWidget {
  const _Pop({
    required this.child,
    this.duration = const Duration(milliseconds: 620),
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  @override
  State<_Pop> createState() => _PopState();
}

class _PopState extends State<_Pop> with SingleTickerProviderStateMixin {
  // The delay is an interval inside one controller rather than a timer: a
  // pending Future.delayed outlives a disposed widget and hangs the tests.
  late final Duration _total = widget.delay + widget.duration;
  late final double _start =
      widget.delay.inMicroseconds / _total.inMicroseconds;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _total,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        if (_c.value < _start) return const SizedBox.shrink();
        final double t = (_c.value - _start) / (1 - _start);
        // 0 → .82 scale and 12px low, overshooting 1.05 at 62%, then settling.
        final double scale = t < 0.62
            ? 0.82 + (1.05 - 0.82) * Curves.easeOut.transform(t / 0.62)
            : 1.05 - 0.05 * Curves.easeOut.transform((t - 0.62) / 0.38);
        final double lift = 12 * (1 - math.min(1, t / 0.62));
        return Opacity(
          opacity: math.min(1, t / 0.4),
          child: Transform.translate(
            offset: Offset(0, lift),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Scene 1 — cards falling past, near layer over a blurred far one.
class _SceneRain extends StatelessWidget {
  const _SceneRain();

  static const List<Color> _palette = [
    Color(0xFFFF2E9C),
    Color(0xFF2B4BFF),
    Color(0xFFFFC93C),
    Color(0xFF00B083),
    Color(0xFF7A5CFF),
    Color(0xFFFF9500),
    Color(0xFF00A3FF),
    Color(0xFFFF4E2D),
    Color(0xFFC24BE0),
    Color(0xFF2FA84F),
    Color(0xFF00C2A8),
    Color(0xFFFF5AD1),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _SceneStage.width,
      height: _SceneStage.bandHeight,
      child: ClipRect(
        child: Stack(
          children: [
            Opacity(
              opacity: 0.5,
              child: Stack(
                children: [
                  for (int i = 0; i < 10; i++)
                    _FallingCard(
                      left: 4 + seeded(i, 33.19) * 88,
                      width: 16 + seeded(i, 45.11) * 12,
                      height: 22 + seeded(i, 45.11) * 16,
                      color: _palette[(i + 2) % _palette.length],
                      turns: (seeded(i, 78.233) * 40 - 20) / 360,
                      seconds: 10 + seeded(i, 21.7) * 6,
                      offset: seeded(i, 9.13) * 14,
                      opacity: 1,
                      radius: 6,
                    ),
                ],
              ),
            ),
            for (int i = 0; i < 18; i++)
              _FallingCard(
                left: 2 + seeded(i, 12.9898) * 90,
                width: 26 + seeded(i, 45.11) * 30,
                height: 36 + seeded(i, 45.11) * 42,
                color: _palette[i % _palette.length],
                turns: (seeded(i, 78.233) * 46 - 23) / 360,
                seconds: 6.5 + seeded(i, 21.7) * 5,
                offset: seeded(i, 9.13) * 11,
                opacity: 0.5 + seeded(i, 33.7) * 0.5,
                radius: 8,
                shadow: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _FallingCard extends StatefulWidget {
  const _FallingCard({
    required this.left,
    required this.width,
    required this.height,
    required this.color,
    required this.turns,
    required this.seconds,
    required this.offset,
    required this.opacity,
    required this.radius,
    this.shadow = false,
  });

  final double left;
  final double width;
  final double height;
  final Color color;
  final double turns;
  final double seconds;

  /// How far into the loop this card starts, so they do not fall in step.
  final double offset;
  final double opacity;
  final double radius;
  final bool shadow;

  @override
  State<_FallingCard> createState() => _FallingCardState();
}

class _FallingCardState extends State<_FallingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.seconds * 1000).round()),
  );

  @override
  void initState() {
    super.initState();
    _c.value = (widget.offset / widget.seconds) % 1;
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget card = Transform.rotate(
      angle: widget.turns * 2 * math.pi,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: widget.shadow
              ? const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
        ),
      ),
    );

    return Positioned(
      // Placed inside the box rather than across its edge. Fractions of the
      // full width put a wide card half outside, and the clip then cuts it
      // down the middle — which reads as a rectangle drawn round the
      // animation rather than as cards falling past.
      left: widget.left / 100 * (_SceneStage.width - widget.width),
      top: 0,
      child: MediaQuery.disableAnimationsOf(context)
          ? Opacity(opacity: widget.opacity * 0.6, child: card)
          : AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final double t = _c.value;
                final double fade = t < 0.1
                    ? t / 0.1
                    : t > 0.82
                    ? 1 - (t - 0.82) / 0.18
                    : 1;
                return Transform.translate(
                  offset: Offset(0, -170 + (_SceneStage.bandHeight + 210) * t),
                  child: Opacity(
                    opacity: (widget.opacity * fade).clamp(0, 1),
                    child: child,
                  ),
                );
              },
              child: card,
            ),
    );
  }
}

/// Scene 2 — a pill card, its bar move and its source.
class _SceneCard extends StatelessWidget {
  const _SceneCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _SceneStage.width,
      height: _SceneStage.bandHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Pop(
            duration: const Duration(milliseconds: 750),
            delay: const Duration(milliseconds: 50),
            child: Transform.translate(
              offset: const Offset(-32, 0),
              child: Transform.rotate(
                angle: -18 * math.pi / 180,
                child: _blank(const Color(0xFF00B083), 158, 214, 20),
              ),
            ),
          ),
          _Pop(
            duration: const Duration(milliseconds: 750),
            delay: const Duration(milliseconds: 120),
            child: Transform.translate(
              offset: const Offset(28, 0),
              child: Transform.rotate(
                angle: 12 * math.pi / 180,
                child: _blank(const Color(0xFFFFC93C), 158, 214, 20),
              ),
            ),
          ),
          _Pop(
            duration: const Duration(milliseconds: 750),
            delay: const Duration(milliseconds: 200),
            child: Container(
              width: 164,
              height: 224,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF2B4BFF),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 56,
                    offset: Offset(0, 26),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned.fill(child: _Shimmer()),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ECONOMICS',
                          style: AppText.label(
                            size: 10,
                            spacing: 1.5,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        Text(
                          'Why does cinema popcorn cost more than the ticket?',
                          style: AppText.body(
                            size: 21,
                            weight: FontWeight.w600,
                            height: 1.14,
                            spacing: -0.6,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'tap to reveal',
                          style: AppText.body(
                            size: 11,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 14,
            child: _SlideIn(
              delay: const Duration(milliseconds: 460),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 190),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EE),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x8C000000),
                      blurRadius: 34,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BAR MOVE',
                      style: AppText.label(
                        size: 9.5,
                        spacing: 1.4,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The film is the loss leader. The counter is the '
                      'business.',
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w500,
                        height: 1.35,
                        color: const Color(0xFF131316),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 12,
            child: _Pop(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 620),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Source · Stanford GSB',
                  style: AppText.body(
                    size: 10.5,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blank(Color color, double w, double h, double r) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

/// The band of light that crosses the blue card.
class _Shimmer extends StatefulWidget {
  const _Shimmer();

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  // 5s of travel plus a 1.4s pause, in one period rather than a timer.
  static const double _pause = 1.4 / 6.4;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Transform.translate(
        offset: Offset(
          -140 + 460 * ((_c.value - _pause) / (1 - _pause)).clamp(0, 1),
          0,
        ),
        child: Transform(
          transform: Matrix4.skewX(-0.32),
          child: Container(
            width: 54,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00FFFFFF),
                  Color(0x66FFFFFF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Arrives from the right, straightening as it lands.
class _SlideIn extends StatefulWidget {
  const _SlideIn({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn>
    with SingleTickerProviderStateMixin {
  late final Duration _total = widget.delay + const Duration(milliseconds: 650);
  late final double _start =
      widget.delay.inMicroseconds / _total.inMicroseconds;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _total,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final double raw = ((_c.value - _start) / (1 - _start)).clamp(0, 1);
        final double t = Curves.easeOutCubic.transform(raw);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(28 * (1 - t), 0),
            child: Transform.rotate(
              angle: 6 * (1 - t) * math.pi / 180,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Scene 3 — the topic chips, half of them lit.
class _SceneChips extends StatelessWidget {
  const _SceneChips();

  static const List<String> _names = [
    'Space',
    'Psychology',
    'Economics',
    'History',
    'Language',
    'Nature',
    'Technology',
    'Philosophy',
    'Human body',
  ];

  /// One colour each, and no two the same. A grid where four are lit and
  /// five are grey reads as a form half filled in; the point of the scene is
  /// that there are twelve subjects and they are not all alike.
  static const List<Color> _palette = [
    Color(0xFF2B4BFF),
    Color(0xFFFF4E2D),
    Color(0xFFFFC93C),
    Color(0xFFC97B2E),
    Color(0xFF00C2A8),
    Color(0xFF2FA84F),
    Color(0xFF00A3FF),
    Color(0xFFC24BE0),
    Color(0xFF7A5CFF),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 334,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children: [
          for (int i = 0; i < _names.length; i++)
            _Pop(
              duration: const Duration(milliseconds: 620),
              delay: Duration(milliseconds: (120 + i * 60)),
              child: _chip(i),
            ),
        ],
      ),
    );
  }

  Widget _chip(int i) {
    final Color base = _palette[i % _palette.length];
    // Yellow and orange want dark type on them; everything else takes white.
    final bool pale = base.computeLuminance() > 0.45;
    return Container(
      // Tight enough that nine of them settle into three rows. At four rows
      // the last one reached down into the copy, which is the sort of thing
      // that reads as a mistake however good the colours are.
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        _names[i],
        style: AppText.body(
          size: 13.5,
          weight: FontWeight.w600,
          color: pale ? const Color(0xFF2B2400) : Colors.white,
        ),
      ),
    );
  }
}

/// Scene 4 — the streak ring and the week behind it.
class _SceneStreak extends StatelessWidget {
  const _SceneStreak();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 138,
          height: 138,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(138, 138),
                painter: _RingPainter(
                  // 258 of 360 degrees, as drawn on the canvas.
                  progress: 258 / 360,
                  color: const Color(0xFFFF2E9C),
                  track: Colors.white.withValues(alpha: 0.09),
                  stroke: 9,
                ),
              ),
              const _Pulse(size: 114, color: Color(0x66FF2E9C)),
              _Rise(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '13',
                      style: AppText.body(
                        size: 46,
                        weight: FontWeight.w700,
                        height: 1,
                        spacing: -2.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DAY STREAK',
                      style: AppText.label(
                        size: 10,
                        spacing: 1.7,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 56,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                _Grow(
                  delay: Duration(milliseconds: (100 + i * 70)),
                  child: Container(
                    width: 18,
                    height: i < 5 ? 18 + i * 6 : 18,
                    decoration: BoxDecoration(
                      color: i < 5
                          ? const Color(0xFFFF2E9C)
                          : Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = (Offset.zero & size).deflate(stroke / 2);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, p..color = track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      p..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Lifts and fades in — the canvas `obcCount`.
class _Rise extends StatefulWidget {
  const _Rise({required this.child});

  final Widget child;

  @override
  State<_Rise> createState() => _RiseState();
}

class _RiseState extends State<_Rise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final double t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Grows from its base — the canvas `obcGrow`.
class _Grow extends StatefulWidget {
  const _Grow({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_Grow> createState() => _GrowState();
}

class _GrowState extends State<_Grow> with SingleTickerProviderStateMixin {
  late final Duration _total = widget.delay + const Duration(milliseconds: 600);
  late final double _start =
      widget.delay.inMicroseconds / _total.inMicroseconds;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _total,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final double raw = ((_c.value - _start) / (1 - _start)).clamp(0, 1);
        final double t = Curves.easeOutCubic.transform(raw);
        return Opacity(
          opacity: t,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(1, 0.2 + 0.8 * t, 1),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
