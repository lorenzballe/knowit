import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/ambient.dart';

/// One subject on the mix grid.
class MixSubject {
  const MixSubject(this.key, this.name, this.color);

  /// The topic key the app deals by.
  final String key;
  final String name;
  final Color color;
}

/// The twelve subjects, in spectrum order.
///
/// The canvas draws eighteen. Six of them — Medicine, Art, Sport, Cinema,
/// Music, Food — have no cards behind them yet, and a subject a reader turns
/// up and is never dealt is worse than one that is not offered. Their colours
/// are not lost: the ramp is sampled across twelve so the grid still runs the
/// whole spectrum from red to pink.
const List<MixSubject> kMixSubjects = [
  MixSubject('history', 'History', Color(0xFFFF1A1A)),
  MixSubject('economics', 'Economics', Color(0xFFFFA800)),
  MixSubject('nature', 'Nature', Color(0xFFFFD400)),
  MixSubject('language', 'Language', Color(0xFF22E551)),
  MixSubject('science', 'Science', Color(0xFF00FFC2)),
  MixSubject('technology', 'Technology', Color(0xFF00A6FF)),
  MixSubject('space', 'Space', Color(0xFF2979FF)),
  MixSubject('philosophy', 'Philosophy', Color(0xFF7C4DFF)),
  MixSubject('psychology', 'Psychology', Color(0xFF9D3FFF)),
  MixSubject('weird_facts', 'Weird facts', Color(0xFFE040FB)),
  MixSubject('pop_culture', 'Pop culture', Color(0xFFFF3D6E)),
  MixSubject('human_body', 'Human body', Color(0xFFFF5252)),
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
  final Map<String, int> _value = {
    for (final MixSubject s in kMixSubjects) s.key: 100,
  };

  int get _inMix => _value.values.where((int v) => v > kMixFloor).length;

  void _setAt(MixSubject subject, double dx, double width) {
    final int next = ((dx / width).clamp(0.0, 1.0) * 100).round();
    if (_value[subject.key] == next) return;
    setState(() => _value[subject.key] = next);
  }

  void _finish() {
    final Map<String, double> weights = {
      for (final MixSubject s in kMixSubjects)
        if (_value[s.key]! > kMixFloor) s.key: _value[s.key]! / 100,
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: AmbientBlooms(colors: kSceneBlooms[3])),
          const Positioned.fill(child: Bokeh()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _MixHeading(),
                  const SizedBox(height: 14),
                  Expanded(
                    child: GridView.builder(
                      // Never scrollable: the whole point of the grid is that
                      // the mix is one thing you see at once. If it stops
                      // fitting, a subject comes out rather than the page
                      // growing a scrollbar.
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: _tileRatio(context),
                      ),
                      itemCount: kMixSubjects.length,
                      itemBuilder: (context, i) => _MixTile(
                        subject: kMixSubjects[i],
                        value: _value[kMixSubjects[i].key]!,
                        index: i,
                        onDragAt: _setAt,
                      ),
                    ),
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
          ),
        ],
      ),
    );
  }

  /// Rows share whatever height is left, as the canvas has them do. Working
  /// it out here rather than fixing the tile height is what keeps the grid
  /// off a scrollbar on a short phone.
  double _tileRatio(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    const double chrome = 14 + 14 + 14 + 10 + 58 + 22 + 14 + 76;
    final int rows = (kMixSubjects.length / 2).ceil();
    final double free =
        screen.height - safe.top - safe.bottom - chrome - (rows - 1) * 8;
    final double tileWidth = (screen.width - 36 - 8) / 2;
    final double tileHeight = (free / rows).clamp(44.0, 96.0);
    return tileWidth / tileHeight;
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
            const _SpectrumWord('mix'),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          // The canvas says "down"; the drag is sideways, and a screen that
          // tells you the wrong direction is worse than one that says nothing.
          'Everything is in. Drag a subject left to see less of it, or all '
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
/// watched.
class _SpectrumWord extends StatefulWidget {
  const _SpectrumWord(this.text);

  final String text;

  @override
  State<_SpectrumWord> createState() => _SpectrumWordState();
}

class _SpectrumWordState extends State<_SpectrumWord>
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

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 80),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style(Color c) => AppText.display(
      size: 30,
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
        final Color colour = Color.lerp(
          _ramp[i],
          _ramp[(i + 1) % _ramp.length],
          at - at.floor(),
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
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => at(d.localPosition),
          onHorizontalDragStart: (d) => at(d.localPosition),
          onHorizontalDragUpdate: (d) => at(d.localPosition),
          child: _TileIn(
            delay: Duration(milliseconds: 30 + index * 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: live ? 0.055 : 0.028),
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
                    // How much of this subject, as a length rather than a
                    // number: there is nothing to read, only something to see.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 90),
                        widthFactor: value / 100,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                subject.color,
                                subject.color.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: live ? 1 : 0,
                            // An icon, not the ✓ character: Figtree does not
                            // carry that glyph and it came out as an empty
                            // box.
                            child: const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
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
                                  alpha: live ? 0.94 : 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
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
