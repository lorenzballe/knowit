import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// One subject on the mix grid.
class MixSubject {
  const MixSubject(this.key, this.name, this.color);

  /// The topic key the app deals by.
  final String key;
  final String name;
  final Color color;
}

/// The eighteen subjects of artboard 50a, in the canvas's own order and
/// hues: the second pass at the palette, which walks the wheel from pure
/// yellow all the way round to amber and stops the two greens colliding.
///
/// Every one of them can be chosen. Six have nothing written for them yet
/// and simply stay quiet until they do — offering a subject and then
/// refusing it is worse than offering one that has not arrived.
const List<MixSubject> kMixSubjects = [
  MixSubject('economics', 'Economics', Color(0xFFFFE600)),
  MixSubject('sport', 'Sport', Color(0xFFA6FF00)),
  MixSubject('nature', 'Nature', Color(0xFF00D451)),
  MixSubject('science', 'Science', Color(0xFF00E5A0)),
  MixSubject('language', 'Language', Color(0xFF00D9D9)),
  MixSubject('technology', 'Technology', Color(0xFF00A6FF)),
  MixSubject('space', 'Space', Color(0xFF2B5CFF)),
  MixSubject('philosophy', 'Philosophy', Color(0xFF4C6FFF)),
  MixSubject('cinema', 'Cinema', Color(0xFF6E3AFF)),
  MixSubject('psychology', 'Psychology', Color(0xFF9B5CFF)),
  MixSubject('music', 'Music', Color(0xFFC13AFF)),
  MixSubject('weird_facts', 'Weird facts', Color(0xFFE040FB)),
  MixSubject('art', 'Art', Color(0xFFFF00A8)),
  MixSubject('pop_culture', 'Pop culture', Color(0xFFFF3D7F)),
  MixSubject('human_body', 'Human body', Color(0xFFFF2D5F)),
  MixSubject('medicine', 'Medicine', Color(0xFFFF3B30)),
  MixSubject('food', 'Food', Color(0xFFFF7A1A)),
  MixSubject('history', 'History', Color(0xFFFFB000)),
];

/// Below this a subject is out of the mix rather than merely quiet.
const int kMixFloor = 6;

/// The second and last step of the onboarding: how much of each subject.
///
/// Everything starts all the way in, so the reader is turning things down
/// rather than building a deck from nothing — an empty grid asks somebody who
/// has never used the app to decide what they like about it.
class MixScreen extends StatefulWidget {
  const MixScreen({super.key, required this.onDone});

  /// Weights by topic key, 0..1. A subject dragged to nothing is absent.
  final ValueChanged<Map<String, double>> onDone;

  @override
  State<MixScreen> createState() => _MixScreenState();
}

class _MixScreenState extends State<MixScreen> {
  /// Keyed by name, as the canvas keys it: the six subjects without cards
  /// have no topic key to hold a value under.
  final Map<String, int> _value = {
    for (final MixSubject s in kMixSubjects) s.name: 100,
  };

  int get _inMix => _value.values.where((int v) => v > kMixFloor).length;

  void _setAt(MixSubject subject, double dx, double width) {
    final int next = ((dx / width).clamp(0.0, 1.0) * 100).round();
    final int was = _value[subject.name]!;
    if (was == next) return;
    // A detent every twentieth, so the bar clicks under the thumb like a
    // wheel instead of sliding in silence. Fired on the crossing rather than
    // on every pixel, or it would buzz continuously and mean nothing.
    if (next ~/ _detent != was ~/ _detent) HapticFeedback.selectionClick();
    setState(() => _value[subject.name] = next);
  }

  /// How far the bar travels between clicks.
  static const int _detent = 5;

  void _finish() {
    final Map<String, double> weights = {
      for (final MixSubject s in kMixSubjects)
        if (_value[s.name]! > kMixFloor) s.key: _value[s.name]! / 100,
    };
    // Thinking is not on the grid and never off the deck, so it is not here
    // either: setTopicMix adds it.
    widget.onDone(
      weights.isEmpty
          ? {for (final MixSubject s in kMixSubjects) s.key: 1}
          : weights,
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    return Scaffold(
      // 49a has nothing behind it. The tiles are the colour on this screen,
      // and blooms behind them would only mute what they are being chosen for.
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          // The canvas clears its own status bar with 54. A real notch is
          // taller than the one it draws, so take whichever is bigger —
          // never less, or the title runs under the clock.
          safe.top > 54 ? safe.top : 54,
          18,
          // 22, as the canvas has it. The artboard is already a phone with a
          // home indicator and the designer put the button here; only a
          // device whose bar is deeper than an iPhone's gets pushed further
          // up.
          22 + (safe.bottom > 34 ? safe.bottom - 34 : 0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _MixHeading(),
            const SizedBox(height: 14),
            // grid-auto-rows:1fr — the nine rows share whatever height is
            // left, so a shorter phone gets shorter tiles instead of a
            // scrollbar. The mix is one thing you see at once or it is not
            // a mix.
            Expanded(
              child: _MixGrid(value: _value, onDragAt: _setAt),
            ),
            const SizedBox(height: 14),
            Text(
              '$_inMix of ${kMixSubjects.length} subjects in the mix',
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.38),
              ),
            ),
            const SizedBox(height: 10),
            _StartButton(onTap: _finish),
          ],
        ),
      ),
    );
  }
}

class _MixGrid extends StatelessWidget {
  const _MixGrid({required this.value, required this.onDragAt});

  final Map<String, int> value;
  final void Function(MixSubject, double dx, double width) onDragAt;

  @override
  Widget build(BuildContext context) {
    const int columns = 2;
    final int rows = (kMixSubjects.length / columns).ceil();
    return Column(
      children: [
        for (int r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                for (int c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: 8),
                  Expanded(
                    child: r * columns + c < kMixSubjects.length
                        ? _MixTile(
                            subject: kMixSubjects[r * columns + c],
                            value: value[kMixSubjects[r * columns + c].name]!,
                            index: r * columns + c,
                            onDragAt: onDragAt,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MixHeading extends StatelessWidget {
  const _MixHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your ',
              style: AppText.display(
                size: 30,
                weight: FontWeight.w600,
                height: 1.04,
                spacing: -1,
                color: Colors.white,
              ),
            ),
            const SpectrumWord('mix'),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'Everything is in. Drag a subject down to see less of it, or all '
          'the way to zero to drop it.',
          style: AppText.body(
            size: 13.5,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.48),
          ),
        ),
      ],
    );
  }
}

/// A word that walks the spectrum, slowly enough to be noticed rather than
/// watched. Eight colours over eighty seconds, each held most of its turn and
/// then crossed to the next, as the canvas's mixColor keyframes have it.
class SpectrumWord extends StatefulWidget {
  const SpectrumWord(this.text, {super.key, this.size = 30});

  final String text;
  final double size;

  @override
  State<SpectrumWord> createState() => _SpectrumWordState();
}

class _SpectrumWordState extends State<SpectrumWord>
    with SingleTickerProviderStateMixin {
  static const List<Color> _ramp = [
    Color(0xFFFFE600),
    Color(0xFFA6FF00),
    Color(0xFF00D451),
    Color(0xFF00D9D9),
    Color(0xFF2B5CFF),
    Color(0xFF9B5CFF),
    Color(0xFFFF00A8),
    Color(0xFFFF7A1A),
  ];

  /// Each colour holds for 9 of its 12.5 per cent, then crosses over.
  static const double _hold = 9 / 12.5;

  // The canvas walks the eight over eighty seconds, which on a screen nobody
  // sits on for eighty seconds means the word looks fixed. Twenty is a colour
  // you can watch move without it becoming a flicker.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style(Color c) => AppText.display(
      size: widget.size,
      weight: FontWeight.w600,
      height: 1.04,
      spacing: -1,
      color: c,
    );

    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(widget.text, style: style(_ramp.first));
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final double at = _c.value * _ramp.length;
        final int i = at.floor() % _ramp.length;
        final double into = at - at.floor();
        final double t = into <= _hold ? 0 : (into - _hold) / (1 - _hold);
        final Color colour = Color.lerp(
          _ramp[i],
          _ramp[(i + 1) % _ramp.length],
          t,
        )!;
        return Text(widget.text, style: style(colour));
      },
    );
  }
}

class _MixTile extends StatelessWidget {
  const _MixTile({
    required this.subject,
    required this.value,
    required this.index,
    required this.onDragAt,
  });

  final MixSubject subject;
  final int value;
  final int index;
  final void Function(MixSubject, double dx, double width) onDragAt;

  @override
  Widget build(BuildContext context) {
    final bool live = value > kMixFloor;
    return LayoutBuilder(
      builder: (context, box) {
        void at(Offset local) => onDragAt(subject, local.dx, box.maxWidth);
        // A raw Listener, as the canvas has it: once the pointer goes down on
        // a tile every move belongs to that tile, whichever way it travels.
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => at(e.localPosition),
          onPointerMove: (e) => at(e.localPosition),
          child: _TileIn(
            delay: Duration(milliseconds: 30 + index * 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Opaque, not translucent white. A CSS outer glow is clipped
                // out from under its own element; Flutter paints the shadow
                // straight through a see-through fill, which washed the empty
                // half of a turned-down tile in a dim version of its colour.
                // The canvas leaves that half black.
                color: Color.alphaBlend(
                  Colors.white.withValues(alpha: live ? 0.055 : 0.028),
                  Colors.black,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: live
                    ? [
                        BoxShadow(
                          color: subject.color.withValues(alpha: 0.27),
                          blurRadius: 22,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // The inset top highlight. It sits under the fill, the
                    // way an inset shadow sits under an element's children,
                    // so it shows on whatever part of the tile is still empty.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 1,
                      child: ColoredBox(
                        color: Colors.white.withValues(
                          alpha: live ? 0.28 : 0.05,
                        ),
                      ),
                    ),
                    // How much of this subject, as a length rather than a
                    // number: there is nothing to read, only something to see.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 90),
                        curve: Curves.linear,
                        widthFactor: value / 100,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                subject.color,
                                subject.color.withValues(alpha: 0.851),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // inset:0 — the row has to fill the tile, or an
                    // unpositioned Stack child takes only the height it needs
                    // and the label rides at the top instead of the middle.
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: live ? 1 : 0,
                              // An icon, not the ✓ character: Figtree does not
                              // carry that glyph and it came out as an empty
                              // box.
                              // The canvas sets a plain check glyph at
                              // 10.5px; Figtree has no such glyph, and the
                              // rounded icon came out far heavier than the
                              // mark it stands in for.
                              child: const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                subject.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  height: 1.1,
                                  spacing: -0.3,
                                  color: Colors.white.withValues(
                                    alpha: live ? 0.95 : 0.3,
                                  ),
                                ),
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
          ),
        );
      },
    );
  }
}

/// Rises and settles as the grid fills in.
class _TileIn extends StatefulWidget {
  const _TileIn({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_TileIn> createState() => _TileInState();
}

class _TileInState extends State<_TileIn> with SingleTickerProviderStateMixin {
  late final Duration _total = widget.delay + const Duration(milliseconds: 500);
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
            offset: Offset(0, 14 * (1 - t)),
            child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _StartButton extends StatefulWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
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
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            'Start with my first cards',
            style: AppText.body(
              size: 16,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
