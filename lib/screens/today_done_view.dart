import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/pills_repository.dart' show dateKey;
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/flip_card.dart';
import '../widgets/motion.dart';
import '../widgets/share_sheet.dart';
import '../widgets/subject_icon.dart';
import 'paywall_screen.dart';

/// The Today tab once the five are done, from artboard 66a.
///
/// At rest the tab is a shelf. The day's five come back as a real carousel —
/// swipe through them, tap one to turn it over — so "review" is the screen
/// itself and not a button. Under the card at the front a glow in its
/// colour, rather than a coloured ground. Then the one thing no earlier
/// version had: the subject that opens tomorrow, already named tonight,
/// which is the strongest return hook a daily product has. The primary
/// action goes to the Explore tab's best of today, and the extra pills sit
/// quietly under it.
///
/// Which card is at the front belongs to the screen above, because the
/// header's dot and the glow behind everything take that card's colour.
class TodayDoneView extends StatefulWidget {
  final AppState app;

  /// The card at the front, and where a new pick goes.
  final int at;
  final ValueChanged<int> onPick;

  /// Opens the Explore tab on today's best. Null where there is no tab bar
  /// to switch, in which case the button is not offered.
  final VoidCallback? onExplore;

  const TodayDoneView({
    super.key,
    required this.app,
    required this.at,
    required this.onPick,
    this.onExplore,
  });

  @override
  State<TodayDoneView> createState() => _TodayDoneViewState();
}

class _TodayDoneViewState extends State<TodayDoneView>
    with SingleTickerProviderStateMixin {
  /// The artboard's card, and the distance between one card and the next.
  static const double _artWidth = 324;
  static const double _artHeight = 452;

  /// How far a card's shadow may spill past the room it sits in before the
  /// fade takes it. The canvas pads the shelf by this and pulls the padding
  /// straight back off with a negative margin.
  static const double _bleed = 90;

  /// Settles the cards after a drag. The curve overshoots a touch, so a
  /// card lands rather than stops.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..addListener(_tick);
  Animation<double>? _settling;

  /// How far the shelf has been pulled from rest, in points.
  double _dx = 0;
  bool _flipped = false;

  /// The pick this widget asked for, so the parent handing it back is not
  /// mistaken for the deck being reset under it.
  int? _pendingAt;

  /// Set by the layout, read by the gestures.
  double _cardWidth = _artWidth;
  double _cardHeight = _artHeight;

  /// Tomorrow's opening card, dealt once per state of the record rather
  /// than on every frame of a drag. The deal depends on the date, what has
  /// been read and answered, today's deck and the mix, so those are the key.
  Pill? _lead;
  String? _leadKey;

  Pill? _tomorrowsLead(AppState app) {
    final key = [
      dateKey(app.today),
      app.todaysDeck.length,
      app.seenIds.length,
      app.answers.length,
      app.pickedTopics.join(','),
      identityHashCode(app.topicWeights),
    ].join('|');
    if (key != _leadKey) {
      _leadKey = key;
      _lead = app.tomorrowsDeck.firstOrNull;
    }
    return _lead;
  }

  double get _step => _cardWidth - 2;

  @override
  void didUpdateWidget(covariant TodayDoneView old) {
    super.didUpdateWidget(old);
    if (old.at == widget.at) return;
    if (widget.at == _pendingAt) {
      _pendingAt = null;
      return;
    }
    // Moved from outside: a new day, or a reset. Nothing to carry over.
    _settle.stop();
    _settling = null;
    _dx = 0;
    _flipped = false;
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _tick() {
    final anim = _settling;
    if (anim == null) return;
    setState(() => _dx = anim.value);
  }

  void _onDragStart(DragStartDetails d) {
    _settle.stop();
    _settling = null;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _dx += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d) {
    final deck = widget.app.todaysDeck;
    final int at = widget.at;
    final double thrown = d.velocity.pixelsPerSecond.dx;
    // Either carried far enough or thrown hard enough: distance alone makes
    // a quick flick do nothing, and the flick is the gesture people make.
    int target = at;
    if ((_dx < -60 || thrown < -500) && at < deck.length - 1) {
      target = at + 1;
    } else if ((_dx > 60 || thrown > 500) && at > 0) {
      target = at - 1;
    }
    _goTo(target);
  }

  /// Brings [target] to the front from wherever the shelf is now. The cards
  /// keep their place on screen across the change of index, so what the
  /// finger left is exactly what the settle starts from.
  void _goTo(int target) {
    final int at = widget.at;
    if (target != at) {
      HapticFeedback.selectionClick();
      _dx += (target - at) * _step;
      _flipped = false;
      _pendingAt = target;
      widget.onPick(target);
    }
    _home();
  }

  void _home() {
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _dx = 0);
      return;
    }
    final anim = Tween<double>(begin: _dx, end: 0).animate(
      CurvedAnimation(parent: _settle, curve: const Cubic(0.3, 1.14, 0.3, 1)),
    );
    _settling = anim;
    _settle
      ..reset()
      ..forward();
  }

  void _flip() {
    HapticFeedback.selectionClick();
    setState(() => _flipped = !_flipped);
  }

  /// A tap on the card at the front turns it over; on a card beside it,
  /// brings that one to the front.
  void _onTapUp(TapUpDetails d, Size stage) {
    final deck = widget.app.todaysDeck;
    final int at = widget.at;
    final Offset centre = stage.center(Offset.zero);
    for (final off in const [0, -1, 1]) {
      final int k = at + off;
      if (k < 0 || k >= deck.length) continue;
      final double x = off * _step + _dx;
      final double scale = 1 - math.min(x.abs() / _step, 1) * 0.07;
      final Rect box = Rect.fromCenter(
        center: centre.translate(x, 0),
        width: _cardWidth * scale,
        height: _cardHeight * scale,
      );
      if (!box.contains(d.localPosition)) continue;
      if (off == 0) {
        _flip();
      } else {
        _goTo(k);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final deck = app.todaysDeck;
    if (deck.isEmpty) return const SizedBox.shrink();
    final int at = widget.at.clamp(0, deck.length - 1);
    final Color ink = context.p.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  "TODAY'S ${spellCount(deck.length)} · SWIPE TO REVIEW",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 10.5,
                    weight: FontWeight.w700,
                    spacing: 1.6,
                    color: ink.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_two(at + 1)} / ${_two(deck.length)}',
                style: AppText.label(
                  size: 10.5,
                  weight: FontWeight.w700,
                  spacing: 1.2,
                  color: ink.withValues(alpha: 0.28),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _shelf(context, deck, at)),
        _Dots(deck: deck, at: at, onPick: _goTo),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
          child: _Tomorrow(lead: _tomorrowsLead(app)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: _Actions(app: app, onExplore: widget.onExplore),
        ),
        // What the canvas leaves between the last line and the tab bar.
        const SizedBox(height: 16),
      ],
    );
  }

  /// The carousel: the card at the front full size and solid, its
  /// neighbours a step to either side, smaller and half faded, and the
  /// edges of the shelf dissolving into the ground.
  Widget _shelf(BuildContext context, List<Pill> deck, int at) {
    return LayoutBuilder(
      builder: (context, box) {
        // The artboard's 324 by 452, or as much of that as the phone has:
        // the card keeps its proportion and everything on it scales with
        // its width, so a smaller card is the same card, smaller.
        final double height = math.min(_artHeight, box.maxHeight);
        final double width = math.min(
          math.min(_artWidth, box.maxWidth - 78),
          height * _artWidth / _artHeight,
        );
        _cardWidth = width;
        _cardHeight = width * _artHeight / _artWidth;
        final Size stage = Size(box.maxWidth, box.maxHeight);

        // Painted furthest-from-the-front first, so the front card is on
        // top, and only what could actually be on screen.
        final order = List<int>.generate(deck.length, (k) => k)
          ..sort((a, b) => (b - at).abs().compareTo((a - at).abs()));
        final layers = <Widget>[];
        for (final k in order) {
          final double x = (k - at) * _step + _dx;
          if (x.abs() > stage.width / 2 + _cardWidth / 2) continue;
          final double dist = math.min(x.abs() / _step, 1);
          final bool front = k == at;
          layers.add(
            Transform.translate(
              offset: Offset(x, 0),
              child: Transform.scale(
                scale: 1 - dist * 0.07,
                child: Opacity(
                  opacity: 1 - dist * 0.5,
                  child: front
                      ? _card(k, deck[k], glow: 1 - dist, front: true)
                      : ExcludeSemantics(
                          child: IgnorePointer(
                            child: _card(
                              k,
                              deck[k],
                              glow: 1 - dist,
                              front: false,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _onTapUp(d, stage),
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: SizedBox.fromSize(
            size: stage,
            child: OverflowBox(
              maxWidth: stage.width,
              maxHeight: stage.height + _bleed * 2,
              child: _Fade(
                child: SizedBox(
                  width: stage.width,
                  height: stage.height + _bleed * 2,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: layers,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _card(int k, Pill pill, {required double glow, required bool front}) {
    final app = widget.app;
    final bool saved = app.isSaved(pill.id);
    Widget face(bool back) => _CardFace(
      pill: pill,
      number: k + 1,
      width: _cardWidth,
      height: _cardHeight,
      back: back,
      glow: glow,
      saved: saved,
      onSave: () {
        HapticFeedback.mediumImpact();
        app.toggleSaved(pill.id);
      },
      onShare: () => showShareSheet(context, pill),
    );
    if (!front) return face(false);
    return FlipCard(showBack: _flipped, front: face(false), back: face(true));
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

/// A count as a word, for the labels that say "today's five".
String spellCount(int n) {
  const words = [
    'NONE',
    'ONE',
    'TWO',
    'THREE',
    'FOUR',
    'FIVE',
    'SIX',
    'SEVEN',
    'EIGHT',
    'NINE',
    'TEN',
  ];
  return n < words.length ? words[n] : '$n';
}

/// The shelf dissolves at its sides, and a little at the foot, so the
/// cards read as passing behind the frame rather than being cut off by it.
class _Fade extends StatelessWidget {
  const _Fade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        colors: [
          Color(0x00000000),
          Colors.black,
          Colors.black,
          Color(0x00000000),
        ],
        stops: [0, 0.08, 0.92, 1],
      ).createShader(rect),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black, Color(0x8C000000)],
          stops: [0, 0.88, 1],
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

/// One face of a card on the shelf.
///
/// The front carries the question and the line to bring it up with; the
/// back the question small and the whole reveal under it. Both keep the
/// subject's mark at the top and the two things you do to a card at the
/// foot, so turning it over changes what you read and not where things are.
class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.pill,
    required this.number,
    required this.width,
    required this.height,
    required this.back,
    required this.glow,
    required this.saved,
    required this.onSave,
    required this.onShare,
  });

  final Pill pill;
  final int number;
  final double width;
  final double height;
  final bool back;

  /// How much of the card's own colour is thrown on the ground under it,
  /// 0 to 1. Full at the front, gone a step away.
  final double glow;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final double s = width / _TodayDoneViewState._artWidth;
    final Color ink = pill.ink;
    // The card's own second and third colours: the ink let down for the
    // small print, and let down further for a panel. A pale card's dark
    // ink needs a touch less of both than white does on a saturated one.
    final bool darkInk = ink.computeLuminance() < 0.5;
    final Color sub = ink.withValues(alpha: darkInk ? 0.6 : 0.66);
    final Color soft = ink.withValues(alpha: darkInk ? 0.10 : 0.14);

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(28 * s),
      decoration: BoxDecoration(
        color: pill.color,
        borderRadius: BorderRadius.circular(36 * s),
        boxShadow: [
          if (glow > 0)
            BoxShadow(
              color: pill.color.withValues(alpha: 0.55 * glow),
              offset: Offset(0, 30 * s),
              blurRadius: 80 * s,
              spreadRadius: -22 * s,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42 + 0.08 * glow),
            offset: const Offset(0, 16),
            blurRadius: 36,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SubjectIcon(subject: pill.topic, size: 16 * s, ink: ink),
              SizedBox(width: 8 * s),
              Expanded(
                child: Text(
                  pill.topic.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 9.5 * s,
                    weight: FontWeight.w700,
                    spacing: 1.4,
                    color: sub,
                  ),
                ),
              ),
              Text(
                number.toString().padLeft(2, '0'),
                style: AppText.label(
                  size: 9.5 * s,
                  weight: FontWeight.w700,
                  color: sub,
                ),
              ),
            ],
          ),
          SizedBox(height: 22 * s),
          Expanded(
            child: back
                ? _Back(pill: pill, scale: s, sub: sub)
                : _Front(pill: pill, scale: s, sub: sub),
          ),
          SizedBox(height: 22 * s),
          Row(
            children: [
              Expanded(
                child: Text(
                  'TAP TO FLIP',
                  style: AppText.label(
                    size: 10 * s,
                    weight: FontWeight.w600,
                    spacing: 1.1,
                    color: sub,
                  ),
                ),
              ),
              _HeartButton(
                saved: saved,
                ink: ink,
                fill: soft,
                size: 42 * s,
                onTap: onSave,
              ),
              SizedBox(width: 12 * s),
              _CardButton(
                label: 'Share this card',
                icon: Icons.ios_share_rounded,
                ink: ink,
                fill: soft,
                size: 42 * s,
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The question, set as large as the card will take it, and the line to
/// bring it up with under a rule.
class _Front extends StatelessWidget {
  const _Front({required this.pill, required this.scale, required this.sub});

  final Pill pill;
  final double scale;
  final Color sub;

  TextStyle _question(double size) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: 1.1,
    spacing: -size * 0.035,
    color: pill.ink,
  );

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    final TextStyle line = AppText.body(
      size: 15.5 * s,
      weight: FontWeight.w500,
      height: 1.42,
      color: sub,
    );
    return LayoutBuilder(
      builder: (context, box) {
        // The artboard sets the question at 31 and the line follows it
        // directly. A question that would not fit at 31 comes down until it
        // does, and one that would not fit at all is cut with an ellipsis
        // rather than spilling — the whole of it is on the back.
        //
        // Measured once per card and box. A drag rebuilds the shelf every
        // frame, and laying text out seven times over for three cards on
        // each of them is work nobody asked for.
        final String key = '${pill.id}|${box.maxWidth}|${box.maxHeight}|$s';
        final (double size, double room) = _fits.putIfAbsent(key, () {
          if (_fits.length > 64) _fits.clear();
          final double lineHeight = _measure(
            pill.barMove,
            line,
            box.maxWidth,
            maxLines: 3,
          );
          final double room = box.maxHeight - lineHeight - 1 - 36 * s;
          return (
            _fit(
              pill.question,
              _question,
              box.maxWidth,
              room,
              min: 19 * s,
              max: 31 * s,
            ),
            room,
          );
        });
        final int lines = math.max(1, (room / (size * 1.1)).floor());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pill.question,
              maxLines: lines,
              overflow: TextOverflow.ellipsis,
              style: _question(size),
            ),
            SizedBox(height: 18 * s),
            Container(height: 1, color: pill.ink.withValues(alpha: 0.2)),
            SizedBox(height: 18 * s),
            Text(
              pill.barMove,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: line,
            ),
          ],
        );
      },
    );
  }

  static final Map<String, (double, double)> _fits = {};

  static double _measure(
    String text,
    TextStyle style,
    double width, {
    int? maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    )..layout(maxWidth: width);
    return painter.height;
  }

  /// The largest size in the band at which [text] fits the box.
  static double _fit(
    String text,
    TextStyle Function(double) styleFor,
    double width,
    double height, {
    required double min,
    required double max,
  }) {
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return min;
    }
    bool fits(double size) => _measure(text, styleFor(size), width) <= height;
    if (fits(max)) return max;
    var lo = min;
    var hi = max;
    while (hi - lo > 0.25) {
      final mid = (lo + hi) / 2;
      if (fits(mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

/// The back of a card, as the canvas draws it: the question again small
/// and quiet, the answer, a hairline, and the line to bring it up with.
///
/// Not the deck's full reveal — no hint, no worked steps, no counterpoint.
/// Those belong to the card being answered for the first time; this is a
/// shelf, and what a person wants off a shelf at the end of the day is the
/// one thing the card said.
///
/// The canvas was drawn around a four-line answer. Real ones run longer, so
/// the whole block is set down a size or two until it fits — the same move
/// the front makes with the question, and it keeps the canvas's
/// proportions rather than clipping its last line in half.
class _Back extends StatelessWidget {
  const _Back({required this.pill, required this.scale, required this.sub});

  final Pill pill;
  final double scale;
  final Color sub;

  /// How far the block may be set down before it is left to scroll.
  static const double _floor = 0.76;

  TextStyle _questionStyle(double s) => AppText.display(
    size: 15 * s,
    weight: FontWeight.w600,
    height: 1.3,
    spacing: -0.3,
    color: sub,
  );

  TextStyle _answerStyle(double s) =>
      AppText.body(size: 16.5 * s, height: 1.44, color: pill.ink);

  TextStyle _lineStyle(double s) => AppText.body(
    size: 14.5 * s,
    weight: FontWeight.w500,
    height: 1.4,
    color: sub,
  );

  double _height(String text, TextStyle style, double width) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    return painter.height;
  }

  /// The block's height at scale [s].
  double _blockHeight(double s, double width) =>
      _height(pill.question, _questionStyle(s), width) +
      32 * s +
      _height(pill.answer, _answerStyle(s), width) +
      1 +
      _height(pill.barMove, _lineStyle(s), width);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double full = scale;
        double s = full;
        if (_blockHeight(s, box.maxWidth) > box.maxHeight) {
          var lo = full * _floor;
          var hi = full;
          while (hi - lo > full * 0.01) {
            final mid = (lo + hi) / 2;
            if (_blockHeight(mid, box.maxWidth) <= box.maxHeight) {
              lo = mid;
            } else {
              hi = mid;
            }
          }
          s = lo;
        }

        final Widget body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pill.question, style: _questionStyle(s)),
            SizedBox(height: 16 * s),
            Text(pill.answer, style: _answerStyle(s)),
            SizedBox(height: 16 * s),
            Container(height: 1, color: pill.ink.withValues(alpha: 0.2)),
            SizedBox(height: 16 * s),
            Text(pill.barMove, style: _lineStyle(s)),
          ],
        );

        // Past the floor it scrolls, and the foot of it dissolves rather
        // than being cut: text sliced through the middle of a line reads as
        // a fault, text fading out reads as more below.
        final bool fits = _blockHeight(s, box.maxWidth) <= box.maxHeight;
        final Widget rising = RiseIn(
          duration: const Duration(milliseconds: 300),
          distance: 8,
          child: body,
        );
        if (fits) {
          return SizedBox(
            width: box.maxWidth,
            height: box.maxHeight,
            child: rising,
          );
        }
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black, Color(0x00000000)],
            stops: [0, 0.9, 1],
          ).createShader(rect),
          child: SingleChildScrollView(child: rising),
        );
      },
    );
  }
}

/// A square control drawn on the card, in the card's own ink on a panel of
/// the card's own colour let down.
class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.icon,
    required this.ink,
    required this.fill,
    required this.size,
    required this.onTap,
    this.child,
  });

  final String label;
  final IconData icon;
  final Color ink;
  final Color fill;
  final double size;
  final VoidCallback onTap;

  /// Something to draw instead of [icon].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(size / 3),
          ),
          alignment: Alignment.center,
          child: child ?? Icon(icon, size: size * 17 / 42, color: ink),
        ),
      ),
    );
  }
}

/// The heart, which swells for a moment when it fills. Keeping a card is
/// the one thing a reader does here that is worth marking.
class _HeartButton extends StatefulWidget {
  const _HeartButton({
    required this.saved,
    required this.ink,
    required this.fill,
    required this.size,
    required this.onTap,
  });

  final bool saved;
  final Color ink;
  final Color fill;
  final double size;
  final VoidCallback onTap;

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(covariant _HeartButton old) {
    super.didUpdateWidget(old);
    if (!old.saved && widget.saved) {
      _pop
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return _CardButton(
      label: widget.saved ? 'Remove from saved' : 'Save this pill',
      icon: widget.saved
          ? Icons.favorite_rounded
          : Icons.favorite_border_rounded,
      ink: widget.ink,
      fill: widget.fill,
      size: widget.size,
      onTap: widget.onTap,
      child: still
          ? null
          : AnimatedBuilder(
              animation: _pop,
              builder: (context, child) {
                // Up to 1.35 by two fifths of the way, and back.
                final double t = Curves.easeOut.transform(_pop.value);
                final double scale = 1 + 0.35 * math.sin(math.pi * t);
                return Transform.scale(scale: scale, child: child);
              },
              child: Icon(
                widget.saved
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: widget.size * 17 / 42,
                color: widget.ink,
              ),
            ),
    );
  }
}

/// One dot a card, the front one drawn long and in its colour.
class _Dots extends StatelessWidget {
  const _Dots({required this.deck, required this.at, required this.onPick});

  final List<Pill> deck;
  final int at;
  final ValueChanged<int> onPick;

  /// 14 above the dots and 8 below them, on the canvas.
  static const double height = 28;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int k = 0; k < deck.length; k++)
            Semantics(
              button: true,
              selected: k == at,
              label: 'Card ${k + 1} of ${deck.length}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(k),
                // A six-point dot is not a target. Each one takes a slice
                // of the whole row instead — which is the height the
                // canvas gives the row anyway, so nothing grows.
                child: SizedBox(
                  width: (k == at ? 22 : 6) + 7,
                  height: height,
                  child: Center(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: still ? 0 : 350),
                      curve: Curves.easeOut,
                      width: k == at ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: k == at
                            ? deck[k].color
                            : context.p.ink.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// What opens tomorrow, and when.
///
/// Tomorrow's deck is dealt from the date and the reading history, both of
/// which are settled by tonight, so the subject named here is the one that
/// will actually be on top in the morning.
class _Tomorrow extends StatelessWidget {
  const _Tomorrow({required this.lead});

  /// The card on top of tomorrow's deck, or null if there is somehow none.
  final Pill? lead;

  @override
  Widget build(BuildContext context) {
    final Pill? lead = this.lead;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final left = tomorrow.difference(now);
    final int hours = left.inHours;
    final int minutes = left.inMinutes % 60;
    final String when = hours >= 1 ? '${hours}h ${minutes}m' : '${minutes}m';

    // A subject's colour is its mark's colour, unless the ground is the same
    // colour — Thinking's white on paper is a mark nobody can see.
    Color tint = lead?.color ?? context.p.ink;
    if ((tint.computeLuminance() - context.p.surface.computeLuminance()).abs() <
        0.15) {
      tint = context.p.ink;
    }

    return Row(
      children: [
        if (lead != null) ...[
          SubjectIcon(subject: lead.topic, size: 20, ink: tint),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            lead == null
                ? "Tomorrow's five open in $when"
                : "${lead.topic} opens tomorrow's five, in $when",
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w500,
              height: 1.35,
              color: context.p.ink.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// The canvas's button: flat, 52 by 18, the label and an arrow behind it.
///
/// Not the app's chunky button, which is right where a press is a
/// commitment — an answer, a purchase — and too heavy for a door out of a
/// screen that is finished. It still gives under the finger.
class _ExploreButton extends StatefulWidget {
  const _ExploreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ExploreButton> createState() => _ExploreButtonState();
}

class _ExploreButtonState extends State<_ExploreButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.onInverse;
    return Semantics(
      button: true,
      label: "Explore today's best",
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: context.p.inverse,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    "Explore today's best",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 14.5,
                      weight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  '\u2192',
                  style: AppText.body(
                    size: 14,
                    color: ink.withValues(alpha: 0.45),
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

/// The way on: everyone's best of today, and under it the second set —
/// as an offer on the free plan, as a deal on Astuto+, and not at all once
/// it has been dealt.
class _Actions extends StatelessWidget {
  const _Actions({required this.app, required this.onExplore});

  final AppState app;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    final String? extra = app.isPlus
        ? (app.canOpenExtraSet ? 'Five more' : null)
        : 'Unlock five extra pills';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onExplore != null) _ExploreButton(onPressed: onExplore!),
        if (extra != null)
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                if (app.canOpenExtraSet) {
                  await app.openExtraSet();
                } else {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PaywallScreen(app: app)),
                  );
                }
              },
              child: Padding(
                padding: EdgeInsets.only(top: onExplore != null ? 11 : 0),
                child: Text(
                  extra,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: context.p.ink.withValues(alpha: 0.42),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
