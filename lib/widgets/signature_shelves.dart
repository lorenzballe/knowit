import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/themed_shelves.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/explore_play.dart';
import '../theme.dart';
import 'explore/parts.dart' show upper;
import 'scaled_text.dart';
import 'subject_icon.dart';

/// The cards of Explore's always-on shelves, one drawing per kind of shelf
/// (design 132, "one signature per kind"): the figure itself for a number
/// that surprises, two halves for a debate, a sun about to set for something
/// to try before tonight. Each graphic is a darker tone of the card's own
/// colour, so it never fights the text.

/// The card's colour, a few steps darker: the tone every signature is
/// drawn in.
Color _deeper(Color c, [double by = 0.14]) => Color.lerp(c, Colors.black, by)!;

/// A horizontal shelf of signature cards.
class SignatureRow extends StatelessWidget {
  const SignatureRow({
    super.key,
    required this.shelf,
    required this.isRead,
    required this.onOpen,
    this.answerOf,
    this.onLean,
    this.onShown,
  });

  final ThemedShelf shelf;
  final bool Function(Pill) isRead;
  final void Function(List<Pill>, Pill) onOpen;

  /// For a debate: what the reader said on it, if anything.
  final Answer? Function(Pill)? answerOf;

  /// For a debate: a side leant to on the shelf — which of the two, and how
  /// sure of it, on the app's own scale (see [leanConfidence]). Without it
  /// the two sides are a picture and the whole card opens.
  final void Function(Pill, int side, int confidence)? onLean;
  final ValueChanged<Pill>? onShown;

  /// The key the day's one demonstration of the slider is kept under: the
  /// first debate on the shelf shows its "or" moving, once a day, so the
  /// reader sees it is a handle before they are told so.
  static const String nudgedKey = 'lean-nudged';

  @override
  Widget build(BuildContext context) {
    final (double h, double w) = switch (shelf.theme) {
      ShelfTheme.numbers => (210.0, 206.0),
      ShelfTheme.debates => (244.0, 300.0),
      _ => (184.0, 268.0),
    };
    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        itemCount: shelf.pills.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final pill = shelf.pills[i];
          onShown?.call(pill);
          return GestureDetector(
            key: ValueKey('explore-${pill.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onOpen(shelf.pills, pill),
            child: SizedBox(
              width: w,
              child: switch (shelf.theme) {
                ShelfTheme.numbers => _NumberCard(
                  pill: pill,
                  read: isRead(pill),
                ),
                ShelfTheme.debates => _SideCard(
                  pill: pill,
                  read: isRead(pill),
                  given: answerOf?.call(pill),
                  onLean: onLean == null
                      ? null
                      : (side, sure) => onLean!(pill, side, sure),
                  nudge:
                      i == 0 &&
                      onLean != null &&
                      ExplorePlay.instance[nudgedKey] != true,
                ),
                _ => _TryCard(pill: pill, read: isRead(pill)),
              },
            ),
          );
        },
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.ink});
  final Color ink;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.readMark,
    child: Icon(
      Icons.check_circle_rounded,
      size: 15,
      color: ink.withValues(alpha: 0.8),
    ),
  );
}

/// Numbers that surprise: the figure, as big as the card allows, then the
/// question it belongs to.
class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.pill, required this.read});
  final Pill pill;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final figure = shelfFigure(pill) ?? '?';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: pill.color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 74,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      figure,
                      maxLines: 1,
                      style: AppText.display(
                        size: 72,
                        weight: FontWeight.w800,
                        height: 1,
                        spacing: -3,
                        color: _deeper(pill.color, 0.42),
                      ),
                    ),
                  ),
                ),
                if (read) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _Tick(ink: pill.ink),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ScaledText(
              text: pill.question,
              min: 10.5,
              max: 15,
              alignment: Alignment.bottomLeft,
              styleFor: (size) => AppText.display(
                size: size,
                weight: FontWeight.w600,
                height: 1.15,
                spacing: -0.4 * size / 15,
                color: pill.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pick a side: the card split down the middle in two tones, the question
/// across both, and the two sides at the foot with "or" between them.
///
/// The "or" is a handle. A debate is seldom all one way, so it slides: drag
/// it towards a side and that side fills from the middle as far as it is
/// taken, its name giving way to the line above, which says the lean as it
/// moves, while the other side lets go of its colour. Four steps a side,
/// from a little to all the way, kept as how sure the reader is of the side
/// (see [leanConfidence]). Let go past the first step and that is the
/// card's answer: said under the question, and at the foot the side solid
/// with a dot for each step and the "or" turned to point at it. Let go in
/// the middle and it slides back, nothing kept. Everywhere else the card
/// still opens.
class _SideCard extends StatefulWidget {
  const _SideCard({
    required this.pill,
    required this.read,
    this.given,
    this.onLean,
    this.nudge = false,
  });

  final Pill pill;
  final bool read;

  /// What the reader said on the card, if anything.
  final Answer? given;

  /// A side leant to: 0 the first, 1 the second, and how sure of it.
  final void Function(int side, int confidence)? onLean;

  /// Whether this card shows its handle moving, once, to say it is one.
  final bool nudge;

  /// "Yes, require the record" reads as Yes on a button: the word before the
  /// comma when there is one and it is short, the whole side otherwise.
  static String _short(String side) {
    final head = side.split(',').first.trim();
    return head.length <= 14 ? head : side;
  }

  @override
  State<_SideCard> createState() => _SideCardState();
}

class _SideCardState extends State<_SideCard> with TickerProviderStateMixin {
  /// Where the handle is while it is held, from -1 at the far end of the
  /// first side to 1 at the far end of the second.
  double? _held;

  /// Where it was let go, and where it is going: to the step it was let go
  /// nearest, or back to the middle.
  double _from = 0;
  double _to = 0;

  /// A side leant to here, and how far, until the app has the answer.
  (int, int)? _said;

  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// The one demonstration: towards the first side, across to the second,
  /// home again. Driven by a controller rather than a timer, so nothing is
  /// left pending when the shelf is scrolled away.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  static final Animatable<double> _nudgePath = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 22),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: -0.34,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 20,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: -0.34,
        end: 0.34,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 28,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.34,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 22,
    ),
    TweenSequenceItem(tween: ConstantTween(0), weight: 8),
  ]);

  @override
  void initState() {
    super.initState();
    // Come to rest, a lean that was let go becomes the answer it is.
    _settle.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() {});
    });
    if (widget.nudge && widget.given == null && widget.onLean != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
        ExplorePlay.instance.put(SignatureRow.nudgedKey, true);
        _nudge.forward();
      });
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    _nudge.dispose();
    super.dispose();
  }

  /// Whether the handle can still be moved: an answer stands.
  bool get _open =>
      widget.onLean != null && widget.given == null && _said == null;

  /// The step a lean is at: 0 in the middle, which is no side, then 1 to 4.
  static int _step(double v) =>
      v.abs() < 0.125 ? 0 : (v.abs() * 4).round().clamp(1, 4);

  /// The step with its direction: negative towards the first side.
  static int _signed(double v) => v < 0 ? -_step(v) : _step(v);

  /// The side and the step of the lean that stands, if one does and it was
  /// given here or on another shelf with a slider rather than a button.
  (int, int)? get _kept {
    final Answer? given = widget.given;
    if (given == null) return _said;
    final int? side = int.tryParse(given.response);
    final int? level = leanLevel(given);
    if (side == null || level == null) return null;
    return (side, level);
  }

  /// The side taken with a button, on the card itself: no lean to show.
  int? get _tapped {
    final Answer? given = widget.given;
    if (given == null || leanLevel(given) != null) return null;
    return int.tryParse(given.response);
  }

  double get _shown {
    if (_held case final double held) return held;
    if (_settle.isAnimating) {
      final double t = Curves.easeOutBack.transform(_settle.value);
      return _from + (_to - _from) * t;
    }
    if (_kept case (final int side, final int level)) {
      return (side == 0 ? -level : level) / 4;
    }
    return _nudge.isAnimating ? _nudgePath.evaluate(_nudge) : 0;
  }

  void _grab(DragStartDetails _) {
    if (!_open) return;
    _nudge.stop();
    _settle.stop();
    setState(() => _held = _shown);
  }

  void _drag(DragUpdateDetails d, double travel) {
    final double? held = _held;
    if (held == null || travel <= 0) return;
    final double next = (held + d.delta.dx / travel).clamp(-1.0, 1.0);
    // A click at every step, so the steps can be felt without looking.
    if (_signed(next) != _signed(held)) HapticFeedback.selectionClick();
    setState(() => _held = next);
  }

  void _letGo([DragEndDetails? _]) {
    final double? v = _held;
    if (v == null) return;
    final int step = _step(v);
    final int side = v < 0 ? 0 : 1;
    _from = v;
    _to = step == 0 ? 0 : (side == 0 ? -step : step) / 4;
    setState(() {
      _held = null;
      if (step > 0) _said = (side, step);
    });
    _settle.forward(from: 0);
    if (step == 0) return;
    HapticFeedback.mediumImpact();
    widget.onLean?.call(side, leanConfidence(step));
  }

  /// A screen reader moves the handle a step at a time, and a double tap
  /// lets go of it where it is.
  void _nudgeBy(int by) {
    if (!_open) return;
    final int at = (_signed(_held ?? 0) + by).clamp(-4, 4);
    HapticFeedback.selectionClick();
    setState(() => _held = at / 4);
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final read = widget.read;
    final positions = switch (pill.challenge) {
      TakeASide(:final positions) => positions,
      _ => const <String>[],
    };
    final deep = _deeper(pill.color);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: pill.color,
        child: Stack(
          children: [
            // The two halves.
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 150,
              child: ColoredBox(color: deep),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SubjectIcon(subject: pill.topic, size: 15, ink: pill.ink),
                      const SizedBox(width: 7),
                      Text(
                        pill.topic.toUpperCase(),
                        style: AppText.label(
                          size: 10,
                          spacing: 1.6,
                          color: pill.ink.withValues(alpha: 0.75),
                        ),
                      ),
                      const Spacer(),
                      if (read) _Tick(ink: pill.ink),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ScaledText(
                      text: pill.question,
                      min: 13,
                      max: 20,
                      alignment: Alignment.topLeft,
                      styleFor: (size) => AppText.display(
                        size: size,
                        weight: FontWeight.w600,
                        height: 1.12,
                        spacing: -0.4 * size / 15,
                        color: pill.ink,
                      ),
                    ),
                  ),
                  if (positions.length >= 2)
                    AnimatedBuilder(
                      animation: Listenable.merge([_settle, _nudge]),
                      builder: (context, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: _line(context, positions),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _foot(context, positions),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What the lean says, under the question: how to move the handle before
  /// anything is held, the side and how far while it is, and once it is let
  /// go the answer that stands and the way to the other side's case.
  Widget _line(BuildContext context, List<String> positions) {
    final pill = widget.pill;
    final l = context.l10n;
    String side(int i) => _SideCard._short(positions[i.clamp(0, 1)]);
    String says(int i, int step) => l.leanSays(side(i), l.leanHow('$step'));

    final String? text;
    if (_tapped case final int i) {
      text = l.leanVerdict(l.leanTook(side(i)));
    } else if (_kept case (final int i, final int step)) {
      text = l.leanVerdict(says(i, step));
    } else if (_held case final double v when _step(v) > 0) {
      text = says(v < 0 ? 0 : 1, _step(v));
    } else {
      text = null;
    }
    if (text != null) {
      return Text(
        text,
        key: ValueKey('lean-said-${pill.id}'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppText.body(
          size: 12.5,
          weight: FontWeight.w700,
          height: 1.25,
          color: pill.ink,
        ),
      );
    }
    if (widget.onLean == null) return const SizedBox.shrink();
    return Text(
      upper(context, l.leanHint(l.sideOr)),
      key: ValueKey('lean-hint-${pill.id}'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppText.label(
        size: 9.5,
        weight: FontWeight.w700,
        spacing: 1.2,
        height: 1.3,
        color: pill.ink.withValues(alpha: 0.66),
      ),
    );
  }

  /// The two sides with the handle between them. The sides are the track:
  /// the handle runs from the far end of one to the far end of the other,
  /// and the side it is in fills behind it while its name gives way to the
  /// line above, which says the lean as it moves. Once the answer stands
  /// the foot says it in one piece: the side taken, solid, with a dot for
  /// each step of how far, and the "or" turned to point at it.
  Widget _foot(BuildContext context, List<String> positions) {
    final pill = widget.pill;
    final l = context.l10n;
    // A word of a letter or two is set larger: the Italian "o" at the size
    // of "oder" is a dot, not a word. A single small letter sits on the
    // line, below the middle of the disc, so it is lifted to it.
    final int letters = l.sideOr.length;
    final TextStyle orStyle = AppText.display(
      size: letters == 1
          ? 18
          : letters == 2
          ? 14
          : 12.5,
      weight: FontWeight.w700,
      color: pill.color,
    );
    final double lift = letters == 1 ? -1.5 : 0;
    final TextPainter measure = TextPainter(
      text: TextSpan(text: l.sideOr, style: orStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    // Round where the word allows, a pill where it is longer: または, ya da.
    final double handle = math.max(30, measure.width + 16);
    measure.dispose();

    return LayoutBuilder(
      builder: (context, box) {
        final double w = box.maxWidth;
        final double sideW = (w - handle - 12) / 2;
        final double travel = w / 2 - handle / 2;
        final double v = _shown.clamp(-1.0, 1.0);
        final double at = w / 2 + v * travel;
        final int? chosen = _tapped ?? _kept?.$1;
        final bool holding = _held != null;
        final bool moving = holding || _settle.isAnimating;

        // The answer that stands, once the handle has come to rest on it.
        if (chosen != null && !moving) {
          return _answered(positions, chosen, sideW);
        }

        // How much of each side is filled: from its inner end to the handle.
        (double, double) band(int i) => i == 0
            ? (math.min(at, sideW), sideW)
            : (0, math.max(0, at - (w - sideW)));

        // The side leant away from lets go of its colour as the lean grows.
        double faded(int i) {
          final bool away = i == 0 ? v > 0 : v < 0;
          return away ? 1 - 0.5 * (v.abs() * 1.6).clamp(0.0, 1.0) : 1;
        }

        // The name of the side leant into gives way to the handle coming
        // through it: the line above is saying the lean by then. Shown
        // moving by itself, as a demonstration, the names stay.
        double named(int i) {
          final bool into = i == 0 ? v < 0 : v > 0;
          return into && moving ? 1 - (v.abs() * 3).clamp(0.0, 1.0) : 1;
        }

        // The word on the handle is for the middle, where it is between
        // the sides; out on one of them it is only a handle.
        final double word = 1 - (v.abs() * 8).clamp(0.0, 1.0);
        // What a screen reader says of the handle at a step, and of the
        // steps either side of it: the middle is both sides, "Yes or No".
        String say(int signed) => signed == 0
            ? '${_SideCard._short(positions[0])} ${l.sideOr} '
                  '${_SideCard._short(positions[1])}'
            : l.leanSays(
                _SideCard._short(positions[signed < 0 ? 0 : 1]),
                l.leanHow('${signed.abs()}'),
              );
        final int step = _signed(_held ?? 0);

        return SizedBox(
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: sideW,
                height: 40,
                child: _side(positions[0], band(0), faded(0), named(0)),
              ),
              Positioned(
                right: 0,
                top: 0,
                width: sideW,
                height: 40,
                child: _side(positions[1], band(1), faded(1), named(1)),
              ),
              // The handle. Its ring is the card's own colour, so on the
              // card it is the "or" it always was, and on the fill behind
              // it, which is the same ink, it still reads as the thing
              // being held.
              Positioned(
                left: at - handle / 2,
                top: 5,
                width: handle,
                height: 30,
                child: IgnorePointer(
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    scale: holding ? 1.1 : 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: pill.ink,
                        borderRadius: BorderRadius.circular(15),
                        // Only once it is off the middle, where it sits
                        // across the card's two tones and a ring of one of
                        // them would show on the other.
                        border: Border.all(
                          color: pill.color.withValues(
                            alpha: (v.abs() * 20).clamp(0.0, 1.0),
                          ),
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: word,
                          child: Transform.translate(
                            offset: Offset(0, lift),
                            child: Text(l.sideOr, maxLines: 1, style: orStyle),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Where a finger takes hold of it: a little wider than the
              // handle, so it is not a thing to aim for, and no wider, so
              // a swipe along the sides still scrolls the shelf.
              if (_open || holding)
                Positioned(
                  left: at - handle / 2 - 13,
                  top: 0,
                  width: handle + 26,
                  height: 40,
                  child: Semantics(
                    slider: true,
                    label: l.leanHint(l.sideOr),
                    value: say(step),
                    increasedValue: say((step + 1).clamp(-4, 4)),
                    decreasedValue: say((step - 1).clamp(-4, 4)),
                    onIncrease: () => _nudgeBy(1),
                    onDecrease: () => _nudgeBy(-1),
                    onTap: _letGo,
                    child: GestureDetector(
                      key: ValueKey('lean-${pill.id}'),
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: true,
                      dragStartBehavior: DragStartBehavior.down,
                      onTap: _settle.isAnimating || _nudge.isAnimating
                          ? null
                          : () => _nudge.forward(from: 0),
                      onHorizontalDragStart: _grab,
                      onHorizontalDragUpdate: (d) => _drag(d, travel),
                      onHorizontalDragEnd: _letGo,
                      onHorizontalDragCancel: _letGo,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// One side as a stretch of the track: its name on a fill of the card's
  /// ink, and the [band] the lean has reached in solid ink over it.
  Widget _side(
    String label,
    (double, double) band,
    double opacity,
    double named,
  ) {
    final pill = widget.pill;
    final (double from, double to) = band;
    return Opacity(
      opacity: opacity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: pill.ink.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Opacity(
              opacity: named,
              child: Text(
                _SideCard._short(label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: pill.ink,
                ),
              ),
            ),
          ),
          if (to > from)
            ClipRect(
              clipper: _Band(from, to),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: pill.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The answer that stands: the side taken, solid, with a dot for each of
  /// the four steps and as many filled as it was leant; the other side let
  /// go; and in the middle, where the "or" was, an arrow to the side taken.
  /// A side taken with a button on the card has no dots: it was not leant.
  Widget _answered(List<String> positions, int chosen, double sideW) {
    final pill = widget.pill;
    final int? step = _kept?.$2;
    Widget side(int i) {
      final bool mine = i == chosen;
      return Opacity(
        opacity: mine ? 1 : 0.42,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: mine ? pill.ink : pill.ink.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _SideCard._short(positions[i]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: mine ? pill.color : pill.ink,
                  ),
                ),
              ),
              if (mine && step != null) ...[
                const SizedBox(width: 8),
                for (int k = 1; k <= 4; k++)
                  Container(
                    width: 5,
                    height: 5,
                    margin: EdgeInsets.only(left: k == 1 ? 0 : 3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pill.color.withValues(alpha: k <= step ? 1 : 0.3),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(
      key: ValueKey('lean-kept-${pill.id}'),
      height: 40,
      child: Row(
        children: [
          SizedBox(width: sideW, child: side(0)),
          Expanded(
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: pill.ink,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  chosen == 0
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: pill.color,
                ),
              ),
            ),
          ),
          SizedBox(width: sideW, child: side(1)),
        ],
      ),
    );
  }
}

/// The stretch of a side the lean has filled, left to right.
class _Band extends CustomClipper<Rect> {
  const _Band(this.from, this.to);

  final double from;
  final double to;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    from.clamp(0, size.width),
    0,
    to.clamp(0, size.width),
    size.height,
  );

  @override
  bool shouldReclip(_Band old) => old.from != from || old.to != to;
}

/// Use it today: the question, a sun going down behind it in the corner,
/// and a foot that says when and how long.
class _TryCard extends StatelessWidget {
  const _TryCard({required this.pill, required this.read});
  final Pill pill;
  final bool read;

  /// About how long the card takes to read and try, at a reading pace.
  static int minutes(Pill p) {
    final words = '${p.question} ${p.answer}'.split(RegExp(r'\s+')).length;
    return (words / 60).ceil().clamp(1, 3);
  }

  @override
  Widget build(BuildContext context) {
    final soft = pill.ink.withValues(alpha: 0.82);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: pill.color,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SunsetPainter(_deeper(pill.color, 0.1)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SubjectIcon(
                              subject: pill.topic,
                              size: 15,
                              ink: pill.ink,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                pill.topic.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.label(
                                  size: 10,
                                  spacing: 1.6,
                                  color: pill.ink.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (read) _Tick(ink: pill.ink),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ScaledText(
                            text: pill.question,
                            min: 11.5,
                            max: 17,
                            alignment: Alignment.topLeft,
                            styleFor: (size) => AppText.display(
                              size: size,
                              weight: FontWeight.w600,
                              height: 1.14,
                              spacing: -0.4 * size / 15,
                              color: pill.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: pill.ink.withValues(alpha: 0.18)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 11, 18, 12),
                  child: Row(
                    children: [
                      Text(
                        context.l10n.tryToday,
                        style: AppText.label(
                          size: 10.5,
                          spacing: 1.8,
                          color: soft,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        context.l10n.minutesShort(minutes(pill)),
                        style: AppText.label(
                          size: 10.5,
                          spacing: 1.8,
                          color: soft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A sun half under the horizon, low in the right-hand corner.
class _SunsetPainter extends CustomPainter {
  _SunsetPainter(this.tone);
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * 0.62;
    final c = Offset(size.width * 0.78, size.height - 44 + r * 0.35);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height - 44));
    canvas.drawCircle(c, r, Paint()..color = tone);
    // Two thin rays, so it reads as a sun and not a stain.
    final ray = Paint()
      ..color = tone
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final a in [-2.2, -1.57, -0.95]) {
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (r + 8), c + d * (r + 18), ray);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SunsetPainter old) => old.tone != tone;
}
