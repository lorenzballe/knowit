import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/topics.dart';
import '../l10n/l10n.dart';

import '../theme.dart';
import '../widgets/ambient.dart';
import '../widgets/fit_text.dart';
import '../widgets/ui.dart';
import '../analytics.dart';

/// The first thing the app shows: five scenes that say what Astute is, over a
/// dark ground that keeps moving.
///
/// Swipe left or tap for the next scene, swipe right for the previous, or take
/// any of the three buttons at the foot — they all lead to the same place,
/// because no account is created here. The copy on the next screen makes that
/// promise explicit: an account is asked for once there is a streak worth
/// keeping.
/// Where the words sit, scene after scene: the same place.
///
/// The copy used to be anchored by its foot, above the dots, so a title set
/// larger or a subtitle a line longer started higher — and five scenes read
/// as words drifting up and down while the picture held still. Now the
/// title's box starts a fixed distance under the picture's band, is a fixed
/// height with the title centred in it, and the subtitle starts a fixed
/// distance under that; the dots follow at a fixed distance again. Named
/// here so the layout check can hold the app to them.
const double kIntroCopyGap = 14;
// Two lines of the scene title at its full size: a title that needs both
// gets them, and one that needs one sits in the middle of the same box.
const double kIntroTitleBox = 68;
const double kIntroSubtitleGap = 12;
const double kIntroSubtitleSize = 17.5;
const double kIntroSubtitleLeading = 1.44;

/// The words, title box to the foot of a two-line subtitle. The audit holds
/// every language to two lines, so this is what the words take at most.
const double kIntroCopyHeight =
    kIntroTitleBox +
    kIntroSubtitleGap +
    2 * kIntroSubtitleSize * kIntroSubtitleLeading;
const double kIntroDotsGap = 18;
const double kIntroDotsHeight = 7 + 2 * 6;

/// Under the dots: the swipe hint on the first scene, with the room a line
/// of it takes in any language, and on every scene the least room there is
/// between the dots and the buttons.
const double kIntroHintSlot = 26;

/// How the room left over is shared, above the picture against below the
/// dots. Mostly above: the picture, the words and the dots stay close to
/// the buttons, and a taller phone shows more sky under its notch rather
/// than a wider gap over its buttons.
const int kIntroSpareAbove = 3;
const int kIntroSpareBelow = 1;

/// Where the column starts under the safe area, and where Skip does: Skip
/// sits over the picture's top right corner and takes no room of its own.
const double kIntroTop = 14;
const double kIntroSkipTop = 8;

/// The clear line kept between Skip's box and a drawing that reaches the
/// top right corner — the last scene's notification, which spans the width.
/// Sixteen points under the word itself, as the canvas has it.
const double kIntroUnderSkip = 12;

/// The margin down each side of the screen: the words and the buttons keep
/// it, and the last scene's drawing lines up on it.
const double kIntroSide = 22;

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

  /// When the scene now showing came up, for how long it held the reader.
  final Stopwatch _sceneClock = Stopwatch()..start();

  void _go(int i, {required String by}) {
    final int to = i % _sceneCount;
    // The intro, scene by scene: which one was left for which, how, and
    // after how long. Five scenes is a lot to ask before a card, and this
    // is what says whether it is too many.
    Analytics.capture('intro scene changed', {
      'from': _scene + 1,
      'to': to + 1,
      'by': by,
      'ms_on_scene': _sceneClock.elapsedMilliseconds,
    });
    _sceneClock
      ..reset()
      ..start();
    setState(() => _scene = to);
  }

  void _next({String by = 'tap'}) => _go(_scene + 1, by: by);

  void _prev() =>
      _go(_scene == 0 ? _sceneCount - 1 : _scene - 1, by: 'swipe back');

  /// Skip, from the corner: said with the scene it left from.
  void _skipIntro() {
    Analytics.capture('intro skipped', {
      'at_scene': _scene + 1,
      'ms_on_scene': _sceneClock.elapsedMilliseconds,
    });
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.paddingOf(context);
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
            _next(by: 'swipe');
          } else if (_dragX > 50) {
            _prev();
          }
        },
        onTap: () {
          if (_moved < 8) _next();
        },
        child: Stack(
          children: [
            Positioned.fill(child: AmbientBlooms(colors: _blooms)),
            const Positioned.fill(child: Bokeh()),
            const Positioned(left: 0, right: 0, top: 0, child: LightSweep()),

            // What makes the words readable: the blooms go dark under them.
            const Positioned.fill(child: _Scrim()),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, kIntroTop, 0, 26),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, room) {
                          // The picture's band is as tall as the screen's
                          // width wants it, or as tall as the room above the
                          // buttons allows once the words, the dots and the
                          // hint have taken theirs: a short phone gets a
                          // smaller picture, never a picture over the words.
                          final double wanted =
                              room.maxWidth * _SceneStage.ratio;
                          final double spare =
                              room.maxHeight -
                              kIntroCopyGap -
                              kIntroCopyHeight -
                              kIntroDotsGap -
                              kIntroDotsHeight -
                              kIntroHintSlot;
                          final double band = math.max(
                            0,
                            math.min(wanted, spare),
                          );
                          // How much of the band's top a drawing that
                          // spans the width has to leave under Skip, in the
                          // band's own units: Skip's foot is a fixed height
                          // down this column, and the band starts under the
                          // share of the spare room that goes above it.
                          final double over =
                              math.max(0, spare - band) *
                              kIntroSpareAbove /
                              (kIntroSpareAbove + kIntroSpareBelow);
                          final double skipFoot =
                              kIntroSkipTop + SkipCorner.height - kIntroTop;
                          final double underSkip = band <= 0
                              ? 0
                              : math.max(0, skipFoot + kIntroUnderSkip - over) /
                                    (band / _SceneStage.bandHeight);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Spacer(flex: kIntroSpareAbove),
                              // The picture runs off both sides, so there
                              // is nothing to see the end of, and keeps the
                              // same size whatever the words under it say.
                              SizedBox(
                                height: band,
                                child: _SceneStage(
                                  key: const ValueKey('intro-stage'),
                                  child: _Swap(
                                    scene: _scene,
                                    child: _IntroScene(
                                      index: _scene,
                                      underSkip: underSkip,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: kIntroCopyGap),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: kIntroSide,
                                ),
                                // Pinned by the top: the copy going out and
                                // the copy coming in share a top edge, so
                                // nothing jumps.
                                child: _Swap(
                                  scene: _scene,
                                  alignment: Alignment.topCenter,
                                  child: _SceneCopy(index: _scene),
                                ),
                              ),
                              const SizedBox(height: kIntroDotsGap),
                              _Dots(
                                key: const ValueKey('intro-dots'),
                                count: _sceneCount,
                                active: _scene,
                                onTap: (i) => _go(i, by: 'dot'),
                              ),
                              SizedBox(
                                height: kIntroHintSlot,
                                child: AnimatedOpacity(
                                  opacity: _moved == 0 && _scene == 0 ? 1 : 0,
                                  duration: const Duration(milliseconds: 350),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      context.l10n.swipeToSeeMore,
                                      textAlign: TextAlign.center,
                                      style: AppText.body(
                                        size: 12.5,
                                        weight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(flex: kIntroSpareBelow),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kIntroSide,
                      ),
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

            // Skip, over the top right corner of the picture. It takes no
            // room: the picture starts where it would if the word were not
            // there, and the drawings keep out of that corner.
            Positioned(
              left: 0,
              right: 0,
              top: safe.top + kIntroSkipTop,
              child: SkipCorner(onTap: _skipIntro, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Darkens the lower half of the blooms, so the words sit on black rather
/// than on a wash of colour.
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
            // Fully dark by the row the copy starts on.
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
/// The scenes are drawn on a band 344 by 252, and the stage is given a band
/// of the same shape as wide as the screen. The drawing is laid out at the
/// size it was drawn for and then fitted to the stage, so it lands exactly
/// on it: the top of the drawing on the top of the band, the bottom on the
/// bottom. On a phone too short for that band the stage is shallower, and
/// the drawing is fitted to its height instead, smaller and centred.
///
/// It used to be scaled in place instead, and the box it was scaled from
/// took the stage's size, not the drawing's — so the drawing sat at the top
/// of a box larger than itself and the scale, running from the middle of
/// that box, pushed it twenty points above the band on every phone. Cards
/// and the streak ring ran off under the notch, and the mark rode high.
class _SceneStage extends StatelessWidget {
  const _SceneStage({super.key, required this.child});

  /// The band the scenes are drawn for.
  static const double width = 344;
  static const double bandHeight = 252;
  static const double ratio = bandHeight / width;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      // Contain, not fill: the stage is the band's shape to within a
      // rounding, or shallower on a short phone, and contain never
      // stretches a drawing over either.
      fit: BoxFit.contain,
      child: SizedBox(width: width, height: bandHeight, child: child),
    );
  }
}

/// Fades and lifts whatever changes when the scene does.
class _Swap extends StatelessWidget {
  const _Swap({
    required this.scene,
    required this.child,
    this.alignment = Alignment.center,
  });

  final int scene;
  final Widget child;

  /// Where the one going out and the one coming in are held together. The
  /// drawings sit in the middle of their band, and the words hang from the
  /// top of theirs.
  final Alignment alignment;

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
      // Unclipped: the falling cards come in from above the band, and the
      // words never reach the edge of theirs.
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        clipBehavior: Clip.none,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(scene), child: child),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    super.key,
    required this.count,
    required this.active,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    // From the translations, like every other word in the app. The titles
    // and lines were sitting in the language files in every language while
    // the screen showed its own English copy.
    final l = context.l10n;
    final (String title, String sub) = switch (index) {
      0 => (l.appName, l.tagline),
      1 => (l.introTopicsTitle, l.introTopicsLine),
      2 => (l.introQuestionTitle, l.introQuestionLine),
      3 => (l.introMixTitle, l.introMixLine),
      _ => (l.introThirtyTitle, l.introThirtyLine),
    };
    final bool wordmark = index == 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A box of one height with the title centred in it: the wordmark is
        // Fraunces at 46 and the rest are Figtree at 30, and centred in the
        // same box their middles land on the same line. A title takes two
        // lines when it needs them, and a size smaller before a third.
        SizedBox(
          height: kIntroTitleBox,
          child: Center(
            child: FitText(
              title,
              textAlign: TextAlign.center,
              maxLines: wordmark ? 1 : 2,
              minSize: 24,
              style: wordmark
                  ? AppText.display(
                      size: 46,
                      weight: FontWeight.w600,
                      height: 1,
                      spacing: -1.6,
                      color: Colors.white,
                    )
                  // The canvas sets the scene titles in Outfit, which the app
                  // does not ship. Figtree at 700 is the closest face already
                  // bundled; adding a third family for five lines is not
                  // worth the weight.
                  : AppText.body(
                      size: 30,
                      weight: FontWeight.w700,
                      height: 1.12,
                      spacing: -1.2,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
        const SizedBox(height: kIntroSubtitleGap),
        // Two lines, in whatever size two lines take: the same style on
        // every scene, so the second line lands where it did on the last.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 302),
          child: FitText(
            sub,
            maxLines: 2,
            minSize: 14,
            textAlign: TextAlign.center,
            style: AppText.body(
              size: kIntroSubtitleSize,
              height: kIntroSubtitleLeading,
              color: Colors.white.withValues(alpha: 0.58),
            ),
          ),
        ),
      ],
    );
  }
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
          label: context.l10n.continueWithApple,
          onTap: onApple,
          leading: const Icon(Icons.apple, size: 21, color: Colors.black),
        ),
        const SizedBox(height: 11),
        _WhiteButton(
          label: context.l10n.continueWithGoogle,
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
              context.l10n.continueWithEmail,
              style: AppText.body(
                size: 16,
                weight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.74),
              ),
            ),
          ),
        ),
        Text(
          context.l10n.termsLine,
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
    // Google's own mark, keyed off its plate and scaled down — not a drawing
    // of it. Four arcs and a bar never quite become a G at nineteen pixels.
    return Image.asset(
      'assets/brand/google-g.png',
      width: 19,
      height: 19,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// The five scenes.
class _IntroScene extends StatelessWidget {
  const _IntroScene({required this.index, this.underSkip = 0});

  final int index;

  /// The top of the band a drawing across the whole width must leave for
  /// Skip, in the band's units. See [kIntroUnderSkip].
  final double underSkip;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => const _SceneOrbits(),
      1 => const _SceneRain(),
      2 => const _SceneCard(),
      3 => const _SceneChips(),
      _ => _SceneTomorrow(underSkip: underSkip),
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
///
/// Its box reaches [above] the band, to the top edge of the screen and past
/// it: a card enters the picture from behind the status bar, whole, rather
/// than appearing on the line the band starts on — which on a phone with
/// a notch is a line drawn just under the clock. At the foot of the box
/// each card fades itself out before it gets there, so no card is ever cut
/// on the line the box ends on. A gradient mask over the box did that job
/// before, and on the phone it did not: the cards reached the line at a
/// third of their colour and stopped dead on it.
class _SceneRain extends StatelessWidget {
  const _SceneRain();

  /// How far above the band the box reaches, in the band's own units.
  /// Deeper than a phone's status bar and the sky under it once scaled, on
  /// the tallest phone, so the top of the box is off the screen.
  static const double above = 130;
  static const double boxHeight = _SceneStage.bandHeight + above;

  /// Over how much of the box's foot a card goes from whole to gone.
  static const double fadeLength = 90;

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
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        minHeight: boxHeight,
        maxHeight: boxHeight,
        // Clipped to the box: its top is off the screen, and no card
        // reaches its foot while it can still be seen.
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
                final double y = -170 + (_SceneRain.boxHeight + 210) * t;
                // Gone before its foot reaches the foot of the box, which
                // is where the clip is: a card cut on a straight line is
                // the edge of a container. The foot allows for the turn.
                final double foot =
                    y +
                    widget.height +
                    widget.width * math.sin(widget.turns.abs() * 2 * math.pi);
                final double leaving =
                    ((_SceneRain.boxHeight - foot) / _SceneRain.fadeLength)
                        .clamp(0.0, 1.0);
                final double arriving = t < 0.1 ? t / 0.1 : 1.0;
                return Transform.translate(
                  offset: Offset(0, y),
                  child: Opacity(
                    opacity: (widget.opacity * arriving * leaving).clamp(0, 1),
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
                child: _blank(const Color(0xFF00B083), 152, 178, 18),
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
                child: _blank(const Color(0xFFFFC93C), 152, 178, 18),
              ),
            ),
          ),
          _Pop(
            duration: const Duration(milliseconds: 750),
            delay: const Duration(milliseconds: 200),
            child: Container(
              width: 168,
              height: 186,
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
                            size: 15.5,
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
            // In from the edge by the same margin the source keeps on the
            // left. Four points off it, it read as cut.
            right: 14,
            bottom: 2,
            child: _SlideIn(
              delay: const Duration(milliseconds: 460),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 152),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
            // Bottom left, beside the bar move and below the card. Above the
            // deck it sat higher than Skip, which made a caption look like a
            // control; and it keeps a margin, because a label touching the
            // glass reads as something that did not fit.
            left: 16,
            bottom: 8,
            child: _Pop(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 620),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  // Solid, not glass. Translucent it took the colour of
                  // whatever card was behind it and stopped being readable —
                  // a caption has to be legible wherever it lands.
                  color: const Color(0xFF131316).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  'Source · Stanford GSB',
                  style: AppText.body(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
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

/// Scene 3 — the topic chips, a dozen of them lit.
class _SceneChips extends StatelessWidget {
  const _SceneChips();

  /// In the order the rows take them: three to a row, four rows. Nine in
  /// three rows filled little more than half the band and left a hole
  /// between the last row and the title.
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
    'Science',
    'Music',
    'Cinema',
  ];

  /// One colour each, and no two the same. A grid where some are lit and
  /// the rest grey reads as a form half filled in; the point of the scene
  /// is that there are many subjects and they are not all alike.
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
    Color(0xFFA6FF00),
    Color(0xFFFF2E9C),
    Color(0xFFFF9500),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 334,
      // Four rows sit in the middle of the band, which puts the first row
      // level with Skip in the corner; this much lower and the row clears
      // it, with the last row still short of the band's foot.
      child: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Wrap(
          spacing: 10,
          runSpacing: 12,
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
      ),
    );
  }

  Widget _chip(int i) {
    final Color base = _palette[i % _palette.length];
    // Yellow and orange want dark type on them; everything else takes white.
    final bool pale = base.computeLuminance() > 0.45;
    return Container(
      // Tight enough that three settle into each row.
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

/// Scene 4 — tomorrow morning and the fortnight it starts: the notification
/// that brings the five, the first of them, and the next fourteen days with
/// day one lit and the first week marked.
///
/// The three are one column, and the column is the buttons' width: where the
/// band is as wide as the screen, which is every phone tall enough to give
/// it its full height, the notification, the card and the days start and
/// end on the lines the buttons do. On a phone short enough to shrink the
/// band the column shrinks with it, centred, which keeps it clear of Skip.
///
/// It stands on the band's foot and leaves [underSkip] at the top, which
/// puts the notification sixteen points under Skip on every phone, as the
/// canvas has it. Whatever the band has above that, the card and the days
/// grow into: from the sizes that fit the phone whose band starts right
/// under the corner, up towards the canvas's own.
class _SceneTomorrow extends StatelessWidget {
  const _SceneTomorrow({this.underSkip = 0});

  /// The top of the band left for Skip, in the band's units.
  final double underSkip;

  /// Each height the drawing is made of, as short as it goes and as the
  /// canvas drew it: the room under Skip decides where between the two.
  static const (double, double) _noticePad = (7.5, 10.3);
  static const (double, double) _gapToCard = (8.0, 10.3);
  static const (double, double) _cardHeight = (92.0, 118.0);
  static const (double, double) _cardPad = (12.5, 13.7);
  static const (double, double) _gapToDays = (11.0, 20.5);
  static const (double, double) _dayHeight = (25.0, 34.2);
  static const (double, double) _gapToFoot = (6.0, 6.8);

  /// What does not grow: the notification's words, the gap between the
  /// two rows of days, and the captions under them.
  static const double _noticeWords = 30;
  static const double _dayGap = 4.3;
  static const double _footLine = 8.6;

  static double _grown((double, double) size, double t) =>
      size.$1 + (size.$2 - size.$1) * t;

  /// The whole drawing's height, [t] of the way from short to the canvas's.
  static double _heightAt(double t) =>
      _noticeWords +
      2 * _grown(_noticePad, t) +
      _grown(_gapToCard, t) +
      _grown(_cardHeight, t) +
      _grown(_gapToDays, t) +
      2 * _grown(_dayHeight, t) +
      _dayGap +
      _grown(_gapToFoot, t) +
      _footLine;

  /// The first card: a real subject, in its own colour.
  static final TopicStyle _subject = kTopics['economics']!;

  /// The five of day one, one colour for each card's subject.
  static final List<Color> _five = [
    kSpectrum[2],
    kSpectrum[0],
    kSpectrum[14],
    kSpectrum[12],
    kSpectrum[6],
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final double screen = MediaQuery.sizeOf(context).width;
    // The band is drawn [_SceneStage.width] wide and shown as wide as the
    // screen, so the buttons' margin, in the band's units, is the margin
    // over the scale.
    final double column = screen <= 0
        ? 306
        : (_SceneStage.width * (1 - 2 * kIntroSide / screen)).clamp(
            240.0,
            _SceneStage.width,
          );
    final String time = MaterialLocalizations.of(context).formatTimeOfDay(
      const TimeOfDay(hour: 8, minute: 30),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    // Two points to spare: the words' own lines round a little over the
    // heights added up here.
    final double room = _SceneStage.bandHeight - underSkip - 2;
    final double short = _heightAt(0);
    final double t = ((room - short) / (_heightAt(1) - short)).clamp(0.0, 1.0);
    double at((double, double) size) => _grown(size, t);
    return SizedBox(
      width: _SceneStage.width,
      height: _SceneStage.bandHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: column,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Rise(
                key: const ValueKey('intro-notice'),
                child: _notice(
                  l.introNotifyWhen(time),
                  l.introNotifyLine,
                  pad: at(_noticePad),
                ),
              ),
              SizedBox(height: at(_gapToCard)),
              _Rise(
                key: const ValueKey('intro-first-card'),
                delay: const Duration(milliseconds: 550),
                child: _card(
                  '${_subject.name.toUpperCase()} · ${l.introOneOfFive}',
                  l.introDayOne,
                  l.introTapTomorrow,
                  height: at(_cardHeight),
                  pad: at(_cardPad),
                ),
              ),
              SizedBox(height: at(_gapToDays)),
              KeyedSubtree(
                key: const ValueKey('intro-fortnight'),
                child: Column(
                  children: [
                    for (int row = 0; row < 2; row++) ...[
                      if (row > 0) const SizedBox(height: _dayGap),
                      Row(
                        children: [
                          for (int col = 0; col < 7; col++) ...[
                            if (col > 0) const SizedBox(width: 4.3),
                            Expanded(
                              child: _Rise(
                                delay: Duration(
                                  milliseconds: 40 * (row * 7 + col + 1),
                                ),
                                duration: const Duration(milliseconds: 500),
                                child: _DayTile(
                                  day: row * 7 + col + 1,
                                  five: _five,
                                  height: at(_dayHeight),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: at(_gapToFoot)),
              // One caption under each end of the days: the first is short
              // in every language, and the second takes what is left.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _foot(l.introDayOneTomorrow),
                  const SizedBox(width: 12),
                  Flexible(
                    child: _foot(l.introDaySevenStreak, align: TextAlign.right),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The morning's notification, as the lock screen shows it.
  Widget _notice(String when, String line, {required double pad}) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, pad, 12, pad),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7.7),
            child: Image.asset(
              'assets/brand/mark-light.png',
              width: 29,
              height: 29,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(width: 9.4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Astute',
                      style: AppText.body(
                        size: 10.7,
                        weight: FontWeight.w600,
                        height: 1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        when,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppText.body(
                          size: 9,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3.4),
                FitText(
                  line,
                  maxLines: 1,
                  minSize: 8,
                  style: AppText.body(
                    size: 10.7,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The first of the five, face up, the way the deck deals it.
  Widget _card(
    String eyebrow,
    String day,
    String foot, {
    required double height,
    required double pad,
  }) {
    final Color ink = _subject.ink;
    final TextStyle meta = AppText.label(
      size: 7.7,
      weight: FontWeight.w700,
      spacing: 1.55,
      height: 1,
      color: ink.withValues(alpha: 0.55),
    );
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(15.4, pad, 15.4, pad),
      decoration: BoxDecoration(
        color: _subject.color,
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 34,
            offset: Offset(0, 17),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: meta,
                ),
              ),
              const SizedBox(width: 8),
              Text(day, style: meta),
            ],
          ),
          Text(
            'Why does cinema popcorn cost more than the ticket?',
            maxLines: 2,
            style: AppText.display(
              size: 16,
              weight: FontWeight.w600,
              height: 1.15,
              spacing: -0.35,
              color: ink,
            ),
          ),
          FitText(
            foot,
            maxLines: 1,
            minSize: 6,
            style: AppText.label(
              size: 8.1,
              spacing: 1.2,
              height: 1,
              color: ink.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// A caption under the days, one at each end.
  Widget _foot(String text, {TextAlign align = TextAlign.left}) {
    return FitText(
      text,
      maxLines: 1,
      minSize: 6,
      textAlign: align,
      style: AppText.label(
        size: 8.6,
        spacing: 0.7,
        height: 1,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }
}

/// One of the fourteen days: the first lit, with its five in their
/// subjects' colours; the seventh and the fourteenth marked with a dashed
/// edge; the rest still dark.
class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.five, this.height = 25});

  final int day;
  final List<Color> five;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool lit = day == 1;
    final bool marked = day == 7 || day == 14;
    final Color ink = lit
        ? Colors.white
        : Colors.white.withValues(alpha: marked ? 0.55 : 0.28);
    final Widget tile = Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(4.3, 3.4, 4.3, 3.4),
      decoration: BoxDecoration(
        // The lit day is solid: a glow is drawn under the whole box, and
        // through a see-through one it greyed the day it was meant to ring.
        color: lit
            ? Color.alphaBlend(
                Colors.white.withValues(alpha: 0.1),
                const Color(0xFF09090C),
              )
            : Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(7.7),
        border: lit ? Border.all(color: Colors.white, width: 1.3) : null,
        boxShadow: lit
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.6),
                  blurRadius: 22,
                  spreadRadius: -3.4,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$day',
            style: AppText.body(
              size: 6.8,
              weight: FontWeight.w600,
              height: 1,
              color: ink,
            ),
          ),
          Row(
            children: [
              for (int k = 0; k < five.length; k++) ...[
                if (k > 0) const SizedBox(width: 1.7),
                Container(
                  width: 3.85,
                  height: 3.85,
                  decoration: BoxDecoration(
                    color: lit ? five[k] : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(1.3),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
    if (!marked) return tile;
    return CustomPaint(
      foregroundPainter: _DashedEdge(
        color: Colors.white.withValues(alpha: 0.3),
        width: 1.3,
        radius: 7.7,
      ),
      child: tile,
    );
  }
}

/// A dashed rounded edge, drawn just inside the box — the canvas's
/// `1.5px dashed`, which a border in Flutter has no way of saying.
class _DashedEdge extends CustomPainter {
  const _DashedEdge({
    required this.color,
    required this.width,
    required this.radius,
  });

  final Color color;
  final double width;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = (Offset.zero & size).deflate(width / 2);
    final Path edge = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final double dash = width * 2.4;
    final double gap = width * 1.8;
    for (final metric in edge.computeMetrics()) {
      for (double at = 0; at < metric.length; at += dash + gap) {
        canvas.drawPath(
          metric.extractPath(at, math.min(at + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedEdge old) =>
      old.color != color || old.width != width || old.radius != radius;
}

/// Rises into place and fades in, after [delay] — the canvas `obRise`.
class _Rise extends StatefulWidget {
  const _Rise({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<_Rise> createState() => _RiseState();
}

class _RiseState extends State<_Rise> with SingleTickerProviderStateMixin {
  // The delay is an interval inside one controller rather than a timer, as
  // in [_Pop]: a pending Future.delayed outlives a disposed widget.
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
        final double raw = ((_c.value - _start) / (1 - _start)).clamp(0, 1);
        final double t = Curves.ease.transform(raw);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
