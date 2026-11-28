import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../widgets/fit_text.dart';

import 'package:flutter/services.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../data/subject_icons.dart';
import '../theme.dart';

/// One subject on the mix grid.
class MixSubject {
  const MixSubject(this.key, this.name, this.color);

  /// The topic key the app deals by.
  final String key;
  final String name;
  final Color color;
}

/// The subjects in the canvas's own order and hues (artboard 50a): the wheel
/// from pure yellow all the way round to amber, with the two greens kept
/// apart. Two came later and sit where their hues fall: Maths, a deeper
/// blackboard jade, between Science and Language; Life, pale peach, after
/// History at the end.
///
/// Twenty, ten rows of two, so the grid is full to its last tile.
const List<MixSubject> kMixSubjects = [
  MixSubject('economics', 'Economics', Color(0xFFFFE600)),
  MixSubject('sport', 'Sport', Color(0xFFA6FF00)),
  MixSubject('nature', 'Nature', Color(0xFF00D451)),
  MixSubject('science', 'Science', Color(0xFF00E5A0)),
  // Blackboard jade (kMathsJade), where its hue falls on the wheel.
  MixSubject('maths', 'Maths', Color(0xFF0E9A70)),
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
  MixSubject('life', 'Life', Color(0xFFFFC49B)),
];

/// Below this a subject is out of the mix rather than merely quiet.
const int kMixFloor = 6;

/// The second step of the first run, after the intro: how much of each
/// subject. The three the reader loves come after it
/// (lib/screens/loves_screen.dart).
///
/// Everything starts all the way in, so the reader is turning things down
/// rather than building a deck from nothing — an empty grid asks somebody who
/// has never used the app to decide what they like about it.
///
/// A tap on a subject takes it out of the mix, and a second puts it back as
/// it was; a slide sideways sets how much of it. The line under the title
/// says both, and as the grid comes in the first subject's bar shows the
/// slide once: down to about half, and back. A tester tapped a subject, saw
/// nothing happen, and never found the slide — nothing had said there was
/// one, and the tap did nothing at all.
class MixScreen extends StatefulWidget {
  const MixScreen({super.key, required this.onDone});

  /// Weights by topic key, 0..1. A subject taken out is absent.
  final ValueChanged<Map<String, double>> onDone;

  @override
  State<MixScreen> createState() => _MixScreenState();
}

class _MixScreenState extends State<MixScreen>
    with SingleTickerProviderStateMixin {
  /// Keyed by name, as the canvas keys it: the six subjects without cards
  /// have no topic key to hold a value under.
  final Map<String, int> _value = {
    for (final MixSubject s in kMixSubjects) s.name: 100,
  };

  /// Where each subject's bar stood before a tap took it out, so a second
  /// tap puts it back as it was rather than all the way in.
  final Map<String, int> _beforeOut = {};

  /// The subject a tap moved last: its bar goes the whole way in one
  /// settled movement, where a dragged bar follows the finger.
  String? _tapped;

  int get _inMix => _value.values.where((int v) => v > kMixFloor).length;

  /// The slide, shown once on the first subject as the grid comes in.
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// How long the grid takes to rise before the slide is shown on it.
  static const Duration _showAfter = Duration(milliseconds: 1100);

  /// Waits for the grid to rise; a timer, so a screen gone before it
  /// leaves nothing behind.
  Timer? _showTimer;

  @override
  void initState() {
    super.initState();
    _show.addListener(() => setState(() {}));
    _showTimer = Timer(_showAfter, () {
      if (!mounted || _touched) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      _show.forward();
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _show.dispose();
    super.dispose();
  }

  /// Whether the reader has put a finger on the grid: the slide is not
  /// shown over their own hand, and stops where it was if it is showing.
  bool _touched = false;

  void _touch() {
    _touched = true;
    _showTimer?.cancel();
    if (_show.isAnimating) _show.reset();
  }

  /// What [subject]'s bar shows: its value, or, while the slide is shown on
  /// the first subject, down to a little over half and back — the value
  /// itself untouched, since nobody chose it.
  int _shown(MixSubject subject) {
    final int v = _value[subject.name]!;
    if (subject != kMixSubjects.first || !_show.isAnimating) return v;
    final double t = _show.value;
    // Down for the first part, a beat at the bottom, back up for the rest.
    // Clamped: (1 - 0.58) / 0.42 is a hair over one in floating point.
    final double depth = t < 0.42
        ? Curves.easeInOutCubic.transform((t / 0.42).clamp(0.0, 1.0))
        : t < 0.58
        ? 1
        : 1 -
              Curves.easeInOutCubic.transform(
                ((t - 0.58) / 0.42).clamp(0.0, 1.0),
              );
    return (v * (1 - 0.45 * depth)).round();
  }

  /// The bar of [subject] set to where the finger is, [dx] along a tile
  /// [width] wide: anything left of the tile is zero, right of it all in.
  void _setAt(MixSubject subject, double dx, double width) {
    _touch();
    final int next = ((dx / width).clamp(0.0, 1.0) * 100).round();
    final int was = _value[subject.name]!;
    if (was == next) return;
    // A detent every twentieth, so the bar clicks under the thumb like a
    // wheel instead of sliding in silence. Fired on the crossing rather than
    // on every pixel, or it would buzz continuously and mean nothing.
    if (next ~/ _detent != was ~/ _detent) HapticFeedback.selectionClick();
    setState(() {
      _tapped = null;
      _value[subject.name] = next;
    });
  }

  /// A tap: a subject in the mix goes out of it, one out of it comes back
  /// where it was before the tap took it out — all the way in, if a tap
  /// never did.
  void _toggle(MixSubject subject) {
    _touch();
    HapticFeedback.selectionClick();
    setState(() {
      _tapped = subject.name;
      final int was = _value[subject.name]!;
      if (was > kMixFloor) {
        _beforeOut[subject.name] = was;
        _value[subject.name] = 0;
      } else {
        _value[subject.name] = _beforeOut.remove(subject.name) ?? 100;
      }
    });
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
    // Up to a little past the default text size the mix is one screen, the
    // rows sharing what the heading and the button leave. Set larger, ten
    // rows of named tiles no longer fit a phone, so the page scrolls: the
    // tiles keep the height their names need and the text keeps the size
    // the reader asked for.
    final bool large = MediaQuery.textScalerOf(context).scale(10) > 11.5;
    return Scaffold(
      // 49a has nothing behind it. The tiles are the colour on this screen,
      // and blooms behind them would only mute what they are being chosen for.
      backgroundColor: Colors.black,
      body: large
          ? LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: _page(context, safe, scrolls: true),
                ),
              ),
            )
          : _page(context, safe, scrolls: false),
    );
  }

  Widget _page(BuildContext context, EdgeInsets safe, {required bool scrolls}) {
    final Widget top = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [_MixHeading(), SizedBox(height: 14)],
    );
    final Widget bottom = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Text(
          context.l10n.subjectsInTheMix(_inMix, kMixSubjects.length),
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 12,
            weight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.38),
          ),
        ),
        const SizedBox(height: 10),
        // The three the reader loves come one screen on.
        FirstRunButton(
          key: const ValueKey('mix-next'),
          label: context.l10n.next,
          onTap: _finish,
        ),
      ],
    );
    final Widget grid = _MixGrid(
      value: {for (final MixSubject s in kMixSubjects) s.name: _shown(s)},
      tapped: _tapped,
      showing: _show.isAnimating ? kMixSubjects.first.name : null,
      onDragAt: _setAt,
      onTap: _toggle,
      fixed: scrolls,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        // Right under the notch, where the loves screen puts its heading
        // too. The canvas's 54 was its own drawn status bar: added on a
        // screen that has none (the web app, most Android phones) it left
        // a band of nothing above the title.
        safe.top > 14 ? safe.top : 14,
        18,
        // 22, as the canvas has it. The artboard is already a phone with a
        // home indicator and the designer put the button here; only a
        // device whose bar is deeper than an iPhone's gets pushed further
        // up.
        22 + (safe.bottom > 34 ? safe.bottom - 34 : 0),
      ),
      child: scrolls
          // The button still ends the page when everything fits.
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [top, grid],
                ),
                bottom,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                top,
                // grid-auto-rows:1fr — the ten rows share whatever height
                // is left, so a shorter phone gets shorter tiles instead of
                // a scrollbar. The mix is one thing you see at once or it
                // is not a mix.
                Expanded(child: grid),
                bottom,
              ],
            ),
    );
  }
}

class _MixGrid extends StatelessWidget {
  const _MixGrid({
    required this.value,
    required this.onDragAt,
    required this.onTap,
    required this.fixed,
    this.tapped,
    this.showing,
  });

  final Map<String, int> value;
  final void Function(MixSubject, double dx, double width) onDragAt;
  final ValueChanged<MixSubject> onTap;

  /// The subject a tap moved last, whose bar settles rather than follows.
  final String? tapped;

  /// The subject the slide is being shown on, whose bar follows the show.
  final String? showing;

  /// Rows of their own height, on a page that scrolls, instead of rows
  /// sharing the height the screen leaves.
  final bool fixed;

  Widget _tile(MixSubject subject, int index) => MixTile(
    key: ValueKey('mix-${subject.key}'),
    subject: subject,
    value: value[subject.name]!,
    index: index,
    onDragAt: onDragAt,
    onTap: () => onTap(subject),
    duration: subject.name == showing
        ? Duration.zero
        : subject.name == tapped
        ? MixTile.settle
        : MixTile.follow,
  );

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    // Two columns while a name fits half the width; at a large text size,
    // one, so that no subject is known only by its first few letters.
    final int columns = fixed && scaler.scale(10) > 14 ? 1 : 2;
    final int rows = (kMixSubjects.length / columns).ceil();
    // A row on a scrolling page: the name's line at the reader's text size,
    // with the air a tile has around it at the default size.
    final double height = scaler.scale(13.5) * 1.1 + 22;
    Widget row(int r) => Row(
      children: [
        for (int c = 0; c < columns; c++) ...[
          if (c > 0) const SizedBox(width: 8),
          Expanded(
            child: r * columns + c < kMixSubjects.length
                ? _tile(kMixSubjects[r * columns + c], r * columns + c)
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
    return Column(
      mainAxisSize: fixed ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (int r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: 8),
          if (fixed)
            SizedBox(height: height, child: row(r))
          else
            Expanded(child: row(r)),
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
        // White, all of it, as the loves screen has it. The second word
        // used to walk the spectrum, which made the screens that share this
        // heading look like different things. No Skip beside it: Next is
        // the one way on, and a mix left as it starts is a mix all the same.
        Text(
          context.l10n.yourMix,
          style: AppText.display(
            size: 30,
            weight: FontWeight.w600,
            height: 1.04,
            spacing: -1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          context.l10n.everythingIsInDrag,
          style: AppText.body(
            size: 13.5,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.48),
          ),
        ),
        // Said once, where the subjects are chosen, to a reader whose phone
        // is in another language: everything around the cards speaks it,
        // and the cards themselves are written in English for now. Found out
        // on the first card instead, it reads as a promise broken.
        if (Localizations.localeOf(context).languageCode != 'en') ...[
          const SizedBox(height: 6),
          Text(
            context.l10n.cardsInEnglishNote,
            key: const ValueKey('mix-cards-in-english'),
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w600,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ],
    );
  }
}

/// One subject's bar: dragged sideways, it says how much of the subject;
/// tapped, it goes out of the mix or comes back. The onboarding's grid is
/// made of these, and so is the fine-tuning under the topics editor
/// ([TuneScreen]).
class MixTile extends StatelessWidget {
  const MixTile({
    super.key,
    required this.subject,
    required this.value,
    required this.index,
    required this.onDragAt,
    this.onTap,
    this.duration = follow,
    this.mark,
  });

  final MixSubject subject;
  final int value;
  final int index;
  final void Function(MixSubject, double dx, double width) onDragAt;

  /// A tap: out of the mix, or back in.
  final VoidCallback? onTap;

  /// How long the bar takes to reach [value]: [follow] under a finger,
  /// [settle] after a tap, which moves it the whole way at once.
  final Duration duration;

  static const Duration follow = Duration(milliseconds: 90);
  static const Duration settle = Duration(milliseconds: 280);

  /// Where the reader last set the bar themselves, 0 to 100, when the app
  /// has since moved it: a thin line on the tile, so what was learned and
  /// what was asked for can be told apart. Null where the two agree.
  final int? mark;

  @override
  Widget build(BuildContext context) {
    final bool live = value > kMixFloor;
    return LayoutBuilder(
      builder: (context, box) {
        void at(Offset local) => onDragAt(subject, local.dx, box.maxWidth);
        // Only a sideways drag moves the bar to the finger. It used to
        // follow the finger from the moment it touched, so a reader tapping
        // a subject's name to choose it quietly turned that subject down to
        // a quarter: the first decision in the app, undone by the gesture
        // every other picker uses to say yes. Then a tap did nothing at
        // all, which a tester read as broken. Now a tap is out or in, the
        // whole way and plainly — the bar empties, the name dims, the count
        // under the grid says so — and once the finger has travelled
        // sideways the bar follows it, wherever it goes, the whole way to
        // zero.
        return Semantics(
          slider: true,
          label: subject.name,
          value: '$value%',
          increasedValue: '${(value + 20).clamp(0, 100)}%',
          decreasedValue: '${(value - 20).clamp(0, 100)}%',
          onIncrease: () => at(Offset((value + 20) / 100 * box.maxWidth, 0)),
          onDecrease: () => at(Offset((value - 20) / 100 * box.maxWidth, 0)),
          onTap: onTap,
          onTapHint: onTap == null
              ? null
              : live
              ? context.l10n.mixLeaveOut
              : context.l10n.mixPutBack,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: onTap,
            onHorizontalDragStart: (d) => HapticFeedback.selectionClick(),
            onHorizontalDragUpdate: (d) => at(d.localPosition),
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
                          duration: duration,
                          curve: duration == settle
                              ? Curves.easeOutCubic
                              : Curves.linear,
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
                      // What the reader asked for, where the app has since
                      // moved the bar away from it.
                      // Two notches, at the tile's top and bottom edges,
                      // rather than a line through it: a line crossed the
                      // subject's name.
                      if (mark != null)
                        for (final bool top in const [true, false])
                          Positioned(
                            left: (mark! / 100 * box.maxWidth - 1.5).clamp(
                              0.0,
                              box.maxWidth - 3,
                            ),
                            top: top ? 0 : null,
                            bottom: top ? null : 0,
                            width: 3,
                            height: 8,
                            child: DecoratedBox(
                              key: ValueKey(
                                'mix-mark-${subject.key}-${top ? 'top' : 'bottom'}',
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ),
                      // inset:0 — the row has to fill the tile, or an
                      // unpositioned Stack child takes only the height it needs
                      // and the label rides at the top instead of the middle.
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          child: Row(
                            children: [
                              // The subject's own mark, not a tick. Every
                              // tile carried the same check, which told you a
                              // tile was on and nothing about what it was.
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: live ? 0.92 : 0.34,
                                child: SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: SvgPicture.string(
                                    subjectIconSvg(subject.name),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: FitText(
                                  context.l10n.subjectOf(subject.name),
                                  maxLines: 1,
                                  minSize: 10,
                                  style: AppText.body(
                                    size: 13.5,
                                    weight: FontWeight.w700,
                                    height: 1.1,
                                    spacing: -0.3,
                                    // Dark on a pale fill, but only once the
                                    // fill is under it; a dimmed tile's label
                                    // sits on black either way.
                                    color:
                                        (live &&
                                                    kPaleSubjects.contains(
                                                      subject.name,
                                                    )
                                                ? const Color(0xFF10100C)
                                                : Colors.white)
                                            .withValues(
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

/// The white button at the foot of the first run's questions: Your mix's
/// Next, and the loves' Start reading.
class FirstRunButton extends StatefulWidget {
  const FirstRunButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<FirstRunButton> createState() => _FirstRunButtonState();
}

class _FirstRunButtonState extends State<FirstRunButton> {
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
            widget.label,
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
