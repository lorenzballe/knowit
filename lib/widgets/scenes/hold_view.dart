import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [HoldScene]: hold for as long as you think it lasts.
///
/// Three moments, one surface. Ready: what is being timed, a clock at zero
/// and a dial to press. Held: the dial turns to ink, its hand sweeps once a
/// second and the clock runs. Let go: the clock stops on your time, and the
/// dial gives way to a ruler where your hold, the truth and up to three
/// other durations lie as bars on one scale. "Show me" plays every bar
/// again from zero in real time, so a guess twice too long is waited
/// through, not read; "Try again" goes back to the dial.
///
/// The card is also tapped to turn, thrown to move on and long-pressed to
/// like, and all three would read a hold as theirs. The dial claims the
/// pointer the moment it lands, before the arena closes (see
/// [_PressRecognizer]), so inside it the hold is the only gesture; everywhere
/// else on the card nothing changes.
class HoldSceneView extends StatefulWidget {
  final HoldScene scene;
  final Color ink;
  final Color ground;
  const HoldSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<HoldSceneView> createState() => _HoldSceneViewState();
}

enum _Phase { ready, holding, result }

/// Past this the clock stops by itself: a finger left on the card is not a
/// guess, and the readout has two digits of seconds.
const double _cap = 99.99;

class _HoldSceneViewState extends State<HoldSceneView>
    with TickerProviderStateMixin {
  _Phase _phase = _Phase.ready;

  /// Seconds on the clock: running while held, your time once let go.
  final ValueNotifier<double> _t = ValueNotifier(0);

  /// What the reader held, once they have let go.
  double _held = 0;

  // The clock is a Ticker, not a Timer: it runs on frame time, so a widget
  // test can drive it with pump(), and nothing outlives the widget. The
  // stopwatch keeps the true length on a phone, where the last frame can
  // be up to one behind the finger; under a test it reads near zero and the
  // ticker's frame time wins.
  late final Ticker _clock = createTicker((elapsed) {
    final s = elapsed.inMicroseconds / 1e6;
    if (s >= _cap) {
      _release();
    } else {
      _t.value = s;
    }
  });
  final Stopwatch _watch = Stopwatch();

  /// The dial dipping under the finger.
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 220),
  );

  /// The bars growing in once you let go, one after another.
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// "Show me": a playhead running across the ruler in real time.
  late final AnimationController _replay = AnimationController(vsync: this)
    ..addListener(_onReplay)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _t.value = _held);
    });

  bool get _calm => MediaQuery.disableAnimationsOf(context);

  @override
  void dispose() {
    _clock.dispose();
    _press.dispose();
    _grow.dispose();
    _replay.dispose();
    _t.dispose();
    super.dispose();
  }

  void _start() {
    if (_phase != _Phase.ready) return;
    HapticFeedback.selectionClick();
    _watch
      ..reset()
      ..start();
    _t.value = 0;
    _clock.start();
    if (!_calm) _press.forward();
    setState(() => _phase = _Phase.holding);
  }

  void _release() {
    if (_phase != _Phase.holding) return;
    _watch.stop();
    final ticked = _t.value;
    _clock.stop();
    _held = math
        .max(ticked, _watch.elapsedMicroseconds / 1e6)
        .clamp(0.01, _cap);
    _t.value = _held;
    HapticFeedback.lightImpact();
    _press.reverse();
    setState(() => _phase = _Phase.result);
    if (_calm) {
      _grow.value = 1;
    } else {
      _grow.forward(from: 0);
    }
  }

  /// The pointer was taken away without a release: no guess was made.
  void _lost() {
    if (_phase != _Phase.holding) return;
    _watch.stop();
    _clock.stop();
    _press.reverse();
    _t.value = 0;
    setState(() => _phase = _Phase.ready);
  }

  void _again() {
    _replay.stop();
    _grow.value = 0;
    _t.value = 0;
    setState(() => _phase = _Phase.ready);
  }

  void _showMe() {
    final s = _Ruler.of(widget.scene, _held);
    _passed.clear();
    _grow.value = 1;
    _replay
      ..duration = Duration(microseconds: (s.max * 1e6).round())
      ..forward(from: 0);
    HapticFeedback.selectionClick();
  }

  /// Rows the replay's playhead has already gone past, so each one stopping
  /// is felt once.
  final Set<int> _passed = {};

  void _onReplay() {
    if (!_replay.isAnimating) return;
    final r = _Ruler.of(widget.scene, _held);
    final at = _replay.value * r.max;
    _t.value = at;
    for (var i = 0; i < r.rows.length; i++) {
      if (at >= r.rows[i].end && _passed.add(i)) {
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final ink = widget.ink;
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final compact = h < 360;
        final big = (h * 0.15).clamp(34.0, 62.0);
        final switchTime = _calm
            ? Duration.zero
            : const Duration(milliseconds: 280);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.what.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                size: compact ? 10 : 10.5,
                color: ink.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: compact ? 2 : 4),
            ExcludeSemantics(
              child: ValueListenableBuilder<double>(
                valueListenable: _t,
                builder: (context, t, _) => _Readout(
                  seconds: t,
                  display: s.display,
                  size: big,
                  ink: ink,
                ),
              ),
            ),
            SizedBox(height: compact ? 8 : 14),
            Expanded(
              child: AnimatedSwitcher(
                duration: switchTime,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.96, end: 1.0).animate(a),
                    child: child,
                  ),
                ),
                child: _phase == _Phase.result
                    ? _result(context, compact)
                    : _dial(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dial(BuildContext context) {
    final holding = _phase == _Phase.holding;
    final s = widget.scene;
    return Semantics(
      key: const ValueKey('dial'),
      button: true,
      label: '${s.what}. ${context.l10n.sceneHoldHint}',
      value: holding ? _say(_t.value, s.display) : null,
      // A screen reader cannot hold: the first activation starts the
      // clock and the second stops it, the same two commands a finger gives.
      onTap: holding ? _release : _start,
      excludeSemantics: true,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          _PressRecognizer:
              GestureRecognizerFactoryWithHandlers<_PressRecognizer>(
                () => _PressRecognizer(debugOwner: this),
                (r) => r
                  ..onPress = _start
                  ..onRelease = _release
                  ..onLost = _lost,
              ),
        },
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _DialPainter(
              t: _t,
              press: _press,
              holding: holding,
              sweep: !_calm,
              ink: widget.ink,
              ground: widget.ground,
            ),
            child: Center(
              child: AnimatedOpacity(
                opacity: holding ? 0 : 1,
                duration: const Duration(milliseconds: 160),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 26,
                        color: widget.ink.withValues(alpha: 0.75),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.sceneHoldHint,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: AppText.body(
                          size: 15,
                          weight: FontWeight.w700,
                          height: 1.15,
                          color: widget.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _result(BuildContext context, bool compact) {
    final s = widget.scene;
    final ink = widget.ink;
    final ruler = _Ruler.of(s, _held);
    final names = [
      context.l10n.sceneYou,
      context.l10n.sceneTruth,
      for (final c in s.comparisons) c.label,
    ];
    final values = [
      _say(_held, s.display),
      s.isBand
          ? _sayBand(s.low, s.high, s.display)
          : _say(s.seconds, s.display),
      for (final c in s.comparisons) _say(c.seconds, s.display),
    ];
    final playing = _replay.isAnimating;
    return Column(
      key: const ValueKey('result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: [
              for (var i = 0; i < names.length; i++) '${names[i]} ${values[i]}',
            ].join('. '),
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: Listenable.merge([_grow, _replay]),
                builder: (context, _) => _Bars(
                  ruler: ruler,
                  names: names,
                  values: values,
                  grow: _grow.value,
                  playhead: _replay.isAnimating
                      ? _replay.value * ruler.max
                      : null,
                  display: s.display,
                  compact: compact,
                  ink: ink,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 14),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Flexible(
                child: _Pill(
                  label: context.l10n.sceneShowMe,
                  icon: Icons.play_arrow_rounded,
                  filled: true,
                  dim: playing,
                  ink: ink,
                  ground: widget.ground,
                  onTap: _showMe,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _Pill(
                  label: context.l10n.sceneTryAgain,
                  icon: Icons.replay_rounded,
                  filled: false,
                  dim: false,
                  ink: ink,
                  ground: widget.ground,
                  onTap: _again,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Takes the pointer the moment it lands and keeps it until it lifts.
///
/// Accepting inside [addAllowedPointer] makes this the arena's eager winner:
/// when the arena closes at the end of the down event, the card's tap, its
/// pan and the long press that likes it are all turned away before any of
/// them has fired. The finger may wander while it holds; only lifting ends
/// the hold.
class _PressRecognizer extends OneSequenceGestureRecognizer {
  _PressRecognizer({super.debugOwner});

  VoidCallback? onPress;
  VoidCallback? onRelease;
  VoidCallback? onLost;

  int? _pointer;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      _pointer == null &&
      event.buttons == kPrimaryButton &&
      super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _pointer = event.pointer;
    resolve(GestureDisposition.accepted);
    onPress?.call();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerUpEvent) {
      _pointer = null;
      stopTrackingPointer(event.pointer);
      onRelease?.call();
    } else if (event is PointerCancelEvent) {
      _pointer = null;
      stopTrackingPointer(event.pointer);
      onLost?.call();
    }
  }

  @override
  void rejectGesture(int pointer) {
    // Something claimed the pointer harder still (none does today): the
    // hold did not happen.
    if (pointer == _pointer) {
      _pointer = null;
      stopTrackingPointer(pointer);
      onLost?.call();
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'hold';
}

// ---------------------------------------------------------------- numbers

/// How a duration reads in this scene's unit, short and exact enough.
String _say(double v, HoldDisplay display) {
  if (display == HoldDisplay.ms && v < 10) {
    return '${(v * 1000).round()} ms';
  }
  return '${_num(v)} s';
}

String _sayBand(double lo, double hi, HoldDisplay display) {
  if (display == HoldDisplay.ms && hi < 10) {
    return '${(lo * 1000).round()}–${(hi * 1000).round()} ms';
  }
  return '${_num(lo)}–${_num(hi)} s';
}

/// Two decimals under a second, one under a hundred, none beyond, without
/// trailing zeros: 0.13, 2.3, 10.
String _num(double v) {
  final fixed = v.toStringAsFixed(v < 1 ? 2 : (v < 100 ? 1 : 0));
  return fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
      : fixed;
}

/// The running clock, big, with its unit.
class _Readout extends StatelessWidget {
  final double seconds;
  final HoldDisplay display;
  final double size;
  final Color ink;
  const _Readout({
    required this.seconds,
    required this.display,
    required this.size,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final (String digits, String unit) = switch (display) {
      HoldDisplay.timecode => (
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
            '${(seconds.floor() % 60).toString().padLeft(2, '0')}:'
            '${((seconds % 1) * 24).floor().toString().padLeft(2, '0')}',
        '',
      ),
      HoldDisplay.ms when seconds < 10 => (
        (seconds * 1000).floor().toString(),
        'ms',
      ),
      _ => (seconds.toStringAsFixed(2), 's'),
    };
    // A number this big can meet a narrow card at a large text size: it
    // shrinks as one piece rather than wrapping or spilling.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            digits,
            maxLines: 1,
            style: AppText.display(
              size: size,
              weight: FontWeight.w800,
              height: 1,
              spacing: -size * 0.02,
              color: ink,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              unit,
              style: AppText.body(
                size: (size * 0.34).clamp(14.0, 20.0),
                weight: FontWeight.w700,
                color: ink.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ dial

/// A stopwatch face. Ready, it is drawn in outline; held, it fills with ink
/// and a hand in the card's colour sweeps once a second.
class _DialPainter extends CustomPainter {
  final ValueNotifier<double> t;
  final Animation<double> press;
  final bool holding;
  final bool sweep;
  final Color ink;
  final Color ground;
  _DialPainter({
    required this.t,
    required this.press,
    required this.holding,
    required this.sweep,
    required this.ink,
    required this.ground,
  }) : super(repaint: Listenable.merge([t, press]));

  final Paint _fill = Paint();
  final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  final Paint _tick = Paint()..strokeCap = StrokeCap.round;
  final Paint _hand = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3.5;
  final Paint _trail = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r =
        (math.min(size.width, size.height) / 2 - 4) *
        (1 - 0.035 * Curves.easeOut.transform(press.value));
    if (r <= 10) return;

    _fill.color = holding ? ink : ink.withValues(alpha: 0.07);
    canvas.drawCircle(c, r, _fill);
    if (!holding) {
      _ring.color = ink.withValues(alpha: 0.55);
      canvas.drawCircle(c, r, _ring);
    }

    final on = holding ? ground : ink;
    for (var i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      final a = i / 60 * 2 * math.pi - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      final outer = r - r * 0.07;
      final inner = outer - (major ? r * 0.11 : r * 0.05);
      _tick
        ..strokeWidth = major ? 2.6 : 1.4
        ..color = on.withValues(alpha: major ? 0.7 : 0.32);
      canvas.drawLine(c + dir * inner, c + dir * outer, _tick);
    }

    if (!holding) return;
    final frac = t.value % 1;
    if (sweep) {
      // The part of this second already gone, as a faint wedge behind the
      // hand, so the turn reads as time spent rather than a spinner.
      final hr = r * 0.78;
      _trail.color = ground.withValues(alpha: 0.16);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: hr),
        -math.pi / 2,
        frac * 2 * math.pi,
        true,
        _trail,
      );
      final a = frac * 2 * math.pi - math.pi / 2;
      _hand.color = ground;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * hr, _hand);
    }
    _trail.color = ground;
    canvas.drawCircle(c, 5.5, _trail);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.holding != holding ||
      old.sweep != sweep ||
      old.ink != ink ||
      old.ground != ground;
}

// ----------------------------------------------------------------- ruler

/// One bar: where it ends, and where its solid part ends (the truth's band
/// is solid to its low end and pale to its high one).
class _Row {
  final double solid;
  final double end;
  final double weight; // ink alpha of the solid part
  const _Row(this.solid, this.end, this.weight);
}

/// The shared scale every bar and the replay are drawn on.
class _Ruler {
  final double max;
  final double step;
  final List<_Row> rows;
  final double truthLow;
  final double truthHigh;
  const _Ruler(this.max, this.step, this.rows, this.truthLow, this.truthHigh);

  static _Ruler of(HoldScene s, double held) {
    final rows = [
      _Row(held, held, 1),
      _Row(s.low, s.high, 0.85),
      for (final c in s.comparisons) _Row(c.seconds, c.seconds, 0.38),
    ];
    final top = rows.map((r) => r.end).reduce(math.max) * 1.06;
    // A round step that gives two to four ticks, and a scale that ends on
    // one of them.
    final mag = math
        .pow(10, (math.log(top / 4) / math.ln10).floor())
        .toDouble();
    var step = mag;
    for (final m in const [1.0, 2.0, 5.0, 10.0]) {
      step = m * mag;
      if (top / step <= 4) break;
    }
    final max = (top / step).ceil() * step;
    return _Ruler(max, step, rows, s.low, s.high);
  }
}

/// The rows: a name and a value over each bar, the truth's band ghosted
/// down through all of them, and a scale underneath.
class _Bars extends StatelessWidget {
  final _Ruler ruler;
  final List<String> names;
  final List<String> values;
  final double grow;
  final double? playhead;
  final HoldDisplay display;
  final bool compact;
  final Color ink;
  const _Bars({
    required this.ruler,
    required this.names,
    required this.values,
    required this.grow,
    required this.playhead,
    required this.display,
    required this.compact,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    const axis = 20.0;
    return LayoutBuilder(
      builder: (context, box) {
        final n = names.length;
        final rowH = ((box.maxHeight - axis) / n).clamp(0.0, 74.0);
        final labelSize = rowH < 34 ? 10.0 : 11.0;
        final labelLine = labelSize * 1.3;
        final bar = (rowH - labelLine - 6).clamp(5.0, 24.0);
        final rows = <Widget>[];
        for (var i = 0; i < n; i++) {
          final row = ruler.rows[i];
          // Each bar starts a little after the one above it.
          final g = Curves.easeOutCubic.transform(
            ((grow * (1 + 0.18 * (n - 1)) - 0.18 * i)).clamp(0.0, 1.0),
          );
          final shown = playhead == null
              ? g
              : (playhead! / row.end).clamp(0.0, 1.0);
          final arrived = playhead == null ? g : (shown >= 1 ? 1.0 : 0.35);
          rows.add(
            SizedBox(
              height: labelLine + 4 + bar,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: labelLine,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            names[i].toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label(
                              size: labelSize,
                              weight: i < 2 ? FontWeight.w800 : FontWeight.w600,
                              height: 1.2,
                              color: ink.withValues(alpha: i < 2 ? 0.9 : 0.65),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Opacity(
                          opacity: arrived,
                          child: Text(
                            values[i],
                            maxLines: 1,
                            style:
                                AppText.body(
                                  size: labelSize + 2.5,
                                  weight: FontWeight.w800,
                                  height: 1.1,
                                  color: ink,
                                ).copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: bar,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _BarPainter(
                        solid: row.solid / ruler.max,
                        end: row.end / ruler.max,
                        shown: shown,
                        weight: row.weight,
                        ink: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return CustomPaint(
          painter: _GuidePainter(
            ruler: ruler,
            playhead: playhead,
            axis: axis,
            display: display,
            ink: ink,
            textScaler: MediaQuery.textScalerOf(context),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: axis),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: rows,
            ),
          ),
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  final double solid;
  final double end;
  final double shown;
  final double weight;
  final Color ink;
  _BarPainter({
    required this.solid,
    required this.end,
    required this.shown,
    required this.weight,
    required this.ink,
  });

  final Paint _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final rad = Radius.circular(math.min(size.height / 2, 6));
    // The track: where the scale runs, so a short bar still sits on a line.
    _p.color = ink.withValues(alpha: 0.08);
    canvas.drawRRect(RRect.fromLTRBR(0, 0, size.width, size.height, rad), _p);
    final reach = end * shown;
    if (reach <= 0) return;
    // Never thinner than a sliver: a 48 ms beat beside a minute still shows.
    final w = math.max(reach * size.width, 3.0);
    if (end > solid) {
      _p.color = ink.withValues(alpha: weight * 0.4);
      canvas.drawRRect(RRect.fromLTRBR(0, 0, w, size.height, rad), _p);
    }
    _p.color = ink.withValues(alpha: weight);
    final sw = math.max(math.min(solid, reach) * size.width, 3.0);
    canvas.drawRRect(RRect.fromLTRBR(0, 0, sw, size.height, rad), _p);
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.shown != shown ||
      old.solid != solid ||
      old.end != end ||
      old.weight != weight ||
      old.ink != ink;
}

/// Behind the rows: the truth as a pale band (or a line) through all of
/// them, the replay's playhead, and the scale along the foot.
class _GuidePainter extends CustomPainter {
  final _Ruler ruler;
  final double? playhead;
  final double axis;
  final HoldDisplay display;
  final Color ink;
  final TextScaler textScaler;
  _GuidePainter({
    required this.ruler,
    required this.playhead,
    required this.axis,
    required this.display,
    required this.ink,
    required this.textScaler,
  });

  final Paint _p = Paint();

  String _tick(double v, bool last) {
    final ms = display == HoldDisplay.ms && ruler.max < 10;
    final n = ms ? '${(v * 1000).round()}' : _num(v);
    if (!last) return n;
    return ms ? '$n ms' : '$n s';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final base = size.height - axis;
    double x(double v) => v / ruler.max * w;

    if (ruler.truthHigh > ruler.truthLow) {
      _p.color = ink.withValues(alpha: 0.07);
      canvas.drawRect(
        Rect.fromLTRB(x(ruler.truthLow), 0, x(ruler.truthHigh), base),
        _p,
      );
    } else {
      _p
        ..color = ink.withValues(alpha: 0.28)
        ..strokeWidth = 1.2;
      final tx = x(ruler.truthLow);
      for (var y = 0.0; y < base; y += 7) {
        canvas.drawLine(Offset(tx, y), Offset(tx, math.min(y + 3.5, base)), _p);
      }
    }

    // The scale.
    _p
      ..color = ink.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, base + 1), Offset(w, base + 1), _p);
    final count = (ruler.max / ruler.step).round();
    for (var i = 0; i <= count; i++) {
      final v = i * ruler.step;
      final tx = x(v);
      canvas.drawLine(Offset(tx, base + 1), Offset(tx, base + 5), _p);
      final tp = TextPainter(
        text: TextSpan(
          text: _tick(v, i == count),
          style: AppText.label(
            size: 10,
            weight: FontWeight.w700,
            spacing: 0.4,
            color: ink.withValues(alpha: 0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      final left = i == 0
          ? 0.0
          : i == count
          ? w - tp.width
          : tx - tp.width / 2;
      tp.paint(canvas, Offset(left, base + 7));
      tp.dispose();
    }

    final ph = playhead;
    if (ph != null) {
      _p
        ..color = ink
        ..strokeWidth = 2;
      final px = x(ph);
      canvas.drawLine(Offset(px, 0), Offset(px, base + 5), _p);
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.playhead != playhead ||
      old.ruler.max != ruler.max ||
      old.ink != ink ||
      old.textScaler != textScaler;
}

// -------------------------------------------------------------- controls

/// A rounded, thumb-sized button in the card's own colours.
class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool dim;
  final Color ink;
  final Color ground;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.icon,
    required this.filled,
    required this.dim,
    required this.ink,
    required this.ground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? ground : ink;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: dim ? 0.55 : 1,
          duration: const Duration(milliseconds: 160),
          child: Container(
            height: 44,
            padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
            decoration: BoxDecoration(
              color: filled ? ink : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: filled
                  ? null
                  : Border.all(color: ink.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w800,
                      color: fg,
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
