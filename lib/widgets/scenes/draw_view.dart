import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';
import '../place_it.dart' show roughNumber;

/// Plays a [DrawScene]: the reader draws the line they expect, locks it in,
/// and the real one draws itself over theirs.
///
/// Top to bottom: two numbers, YOU and TRUTH, at the column being judged;
/// the chart, taking whatever height is left; a line of text (the hint, then
/// the verdict) beside the button that locks the guess in.
///
/// Inside the chart a finger always draws. The deck around it swipes on a
/// drag and turns over on a tap, so the chart claims every pointer that
/// lands on it the moment it lands, before either can, and lets go once the
/// guess is locked: from then on the chart is a picture and the card behaves
/// as it does everywhere else.
class DrawSceneView extends StatefulWidget {
  final DrawScene scene;
  final Color ink;
  final Color ground;
  const DrawSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<DrawSceneView> createState() => _DrawSceneViewState();
}

class _DrawSceneViewState extends State<DrawSceneView>
    with TickerProviderStateMixin {
  /// The reader's line, one height per column as a share of the chart
  /// (0 at the bottom, 1 at the top), null where they have not drawn yet.
  /// Shares rather than values: a share is what the finger made, and on a
  /// log chart it is the only space where a straight stroke is straight.
  late List<double?> _guess = _empty();

  /// The finger, in the chart's own coordinates, while it is down.
  Offset? _pen;
  int? _lastCol;
  bool _locked = false;

  /// What the chart was last laid out as: the one mapping between columns,
  /// shares and pixels, read by the painter and the finger alike.
  _Chart? _chart;

  // Where to start: a dot at the start of the empty stretch sends out three
  // slow rings, then stays. Three, not forever: a hint that never stops is
  // noise, and a repeating controller never lets a test settle.
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  // The truth drawing itself, left to right, at a pace set by how much of
  // it there is to draw.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (500 + 260 * (widget.scene.count - widget.scene.anchor))
          .clamp(900, 1900),
    ),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() {});
    });
  late final CurvedAnimation _tip = CurvedAnimation(
    parent: _reveal,
    curve: Curves.easeInOutCubic,
  );
  bool _started = false;

  List<double?> _empty() {
    final s = widget.scene;
    return [
      for (var i = 0; i < s.count; i++)
        i < s.given ? s.share(s.values[i]) : null,
    ];
  }

  bool get _complete {
    for (var i = widget.scene.firstDrawn; i < widget.scene.count; i++) {
      if (_guess[i] == null) return false;
    }
    return true;
  }

  bool get _calm => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !_calm) {
      _started = true;
      _hint.forward();
    }
  }

  @override
  void dispose() {
    _tip.dispose();
    _hint.dispose();
    _reveal.dispose();
    super.dispose();
  }

  // ---- drawing --------------------------------------------------------

  /// The finger at [p]: the nearest column takes its height, and every
  /// column between it and the last one touched is filled along a straight
  /// line, so a quick sweep leaves no gaps.
  void _draw(Offset p, {required bool start}) {
    final chart = _chart;
    if (chart == null || _locked) return;
    final s = widget.scene;
    final share = chart.shareAt(p.dy);
    final col = chart.colAt(p.dx).clamp(s.firstDrawn, s.count - 1);
    final g = List<double?>.of(_guess);
    final wasComplete = _complete;

    // Where this stretch is drawn from: the last column touched, or on a
    // new stroke the end of what is already there (the given line's last
    // point, when nothing is).
    int? from = start ? null : _lastCol;
    if (from == null) {
      for (var i = col - 1; i >= 0; i--) {
        if (g[i] != null) {
          from = i;
          break;
        }
      }
    }
    if (from == null) {
      for (var i = 0; i < col; i++) {
        g[i] = share;
      }
    } else if (from != col) {
      final a = g[from] ?? share;
      final step = col > from ? 1 : -1;
      for (var i = from + step; i != col; i += step) {
        g[i] = a + (share - a) * (i - from) / (col - from);
      }
    }
    g[col] = share;

    setState(() {
      _guess = g;
      _lastCol = col;
      _pen = Offset(
        p.dx.clamp(chart.xs[s.anchor], chart.xs.last),
        chart.yAt(share),
      );
    });
    if (!wasComplete && _complete) HapticFeedback.selectionClick();
  }

  void _lift() => setState(() {
        _pen = null;
        _lastCol = null;
      });

  /// For a screen reader: the whole guess as a straight line from where the
  /// given stretch ends to [end], moved a twentieth of the chart at a time.
  List<double?> _straight(double by) {
    final s = widget.scene;
    final start = s.given > 0 ? _guess[s.anchor]! : (_guess[0] ?? 0.5);
    final end = ((_guess.last ?? start) + by).clamp(0.0, 1.0);
    final g = List<double?>.of(_guess);
    final from = s.given > 0 ? s.anchor : 0;
    for (var i = s.firstDrawn; i < s.count; i++) {
      g[i] = s.given > 0
          ? start + (end - start) * (i - from) / (s.count - 1 - from)
          : end;
    }
    return g;
  }

  void _nudgeEnd(double by) {
    final wasComplete = _complete;
    setState(() => _guess = _straight(by));
    if (!wasComplete) HapticFeedback.selectionClick();
  }

  /// What a screen reader hears for a guess: its value at the judged column.
  String _spoken(List<double?> g) {
    final s = widget.scene;
    final v = g[s.judge];
    return '${s.columns[s.judge]}: '
        '${v == null ? '?' : value(s.fromShare(v), s.decimals, s.unit)}';
  }

  void _lockIn() {
    if (!_complete || _locked) return;
    HapticFeedback.lightImpact();
    _hint.stop();
    setState(() {
      _locked = true;
      _pen = null;
    });
    if (_calm) {
      _reveal.value = 1;
    } else {
      _reveal.forward(from: 0);
    }
  }

  void _again() {
    HapticFeedback.selectionClick();
    _reveal.value = 0;
    setState(() {
      _locked = false;
      _guess = _empty();
    });
    if (!_calm) _hint.forward(from: 0);
  }

  // ---- numbers --------------------------------------------------------

  /// Money and multiples are written with their sign in front, a percentage
  /// straight after, every other unit after a space.
  static bool _prefix(String unit) =>
      const {'€', r'$', '£', '¥', '×'}.contains(unit);

  static String _withUnit(String n, String unit) {
    if (unit.isEmpty) return n;
    if (_prefix(unit)) return n.startsWith('−') ? '−$unit${n.substring(1)}' : '$unit$n';
    if (unit == '%' || unit.startsWith('°')) return '$n$unit';
    return '$n $unit';
  }

  static String _commas(String digits) => digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );

  /// A value the reader reads: exact to the card's decimals, thousands
  /// marked, in words past a million.
  static String value(double v, int decimals, String unit) {
    if (v.abs() >= 1e6) return _withUnit(roughNumber(v.abs()), unit);
    final fixed = v.abs().toStringAsFixed(decimals).split('.');
    final n = '${v < 0 ? '−' : ''}${_commas(fixed[0])}'
        '${fixed.length > 1 ? '.${fixed[1]}' : ''}';
    return _withUnit(n, unit);
  }

  // ---- build ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final ink = widget.ink;
    final l10n = context.l10n;
    final calm = _calm;

    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxHeight < 360;
        final done = _locked && _reveal.isCompleted;
        final verdict = _guess[s.judge] == null
            ? ''
            : s.verdictText(s.fromShare(_guess[s.judge]!));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _tip,
              builder: (context, _) => _Readouts(
                scene: s,
                ink: ink,
                compact: compact,
                you: _youNow(),
                truth: _truthNow(),
                youCaption: '${l10n.sceneYou} · ${s.columns[_youCol()].toUpperCase()}',
                truthCaption:
                    '${l10n.sceneTruth} · ${s.columns[s.judge].toUpperCase()}',
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
            Expanded(child: _chartArea(context)),
            SizedBox(height: compact ? 8 : 12),
            SizedBox(
              height: compact ? 46 : 58,
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: done,
                      child: AnimatedSwitcher(
                        duration: calm
                            ? Duration.zero
                            : const Duration(milliseconds: 320),
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, .2),
                              end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        ),
                        child: Align(
                          key: ValueKey(done ? verdict : 'hint'),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            done ? verdict : l10n.sceneDrawHint,
                            maxLines: compact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              size: compact ? 13 : 14,
                              weight: done ? FontWeight.w600 : FontWeight.w500,
                              height: 1.3,
                              color: ink.withValues(alpha: done ? 0.95 : 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _locked
                      ? _AgainButton(
                          ink: ink,
                          label: l10n.sceneTryAgain,
                          onTap: done ? _again : null,
                        )
                      : _LockButton(
                          ink: ink,
                          ground: widget.ground,
                          label: l10n.sceneLockIn,
                          onTap: _complete ? _lockIn : null,
                        ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// The column the YOU number speaks about: the one under the finger while
  /// it draws, the judged one otherwise.
  int _youCol() {
    final s = widget.scene;
    final chart = _chart;
    if (_pen != null && chart != null) {
      return chart.colAt(_pen!.dx).clamp(s.firstDrawn, s.count - 1);
    }
    return s.judge;
  }

  String? _youNow() {
    final g = _guess[_youCol()];
    if (g == null) return null;
    final s = widget.scene;
    return value(s.fromShare(g), s.decimals, s.unit);
  }

  /// The truth at the tip of the line as it draws, held at the judged
  /// column once the tip is past it.
  String? _truthNow() {
    if (!_locked) return null;
    final s = widget.scene;
    final chart = _chart;
    if (chart == null || _reveal.isCompleted) {
      return value(s.values[s.judge], s.decimals, s.unit);
    }
    final x = chart.tipX(_tip.value);
    if (x >= chart.xs[s.judge]) {
      return value(s.values[s.judge], s.decimals, s.unit);
    }
    final v = s.fromShare(chart.shareAt(chart.truth.at(x)));
    return value(v, s.decimals, s.unit);
  }

  Widget _chartArea(BuildContext context) {
    final s = widget.scene;
    final l10n = context.l10n;
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        var chart = _chart;
        if (chart == null ||
            chart.size != size ||
            chart.ink != widget.ink ||
            chart.scaler != scaler) {
          chart = _chart = _Chart.build(
            size: size,
            scene: s,
            ink: widget.ink,
            ground: widget.ground,
            scaler: scaler,
            you: l10n.sceneYou,
            truth: l10n.sceneTruth,
          );
        }

        final paint = RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('draw-chart'),
            size: size,
            isComplex: true,
            willChange: _pen != null || _reveal.isAnimating,
            painter: _DrawPainter(
              chart: chart,
              scene: s,
              guess: _guess,
              pen: _pen,
              locked: _locked,
              hint: _hint,
              tip: _tip,
              ink: widget.ink,
              ground: widget.ground,
            ),
          ),
        );

        return Semantics(
          container: true,
          slider: !_locked,
          label: _locked
              ? '${s.label}. ${l10n.sceneYou}: ${_youNow() ?? ''}. '
                  '${l10n.sceneTruth}: ${value(s.values[s.judge], s.decimals, s.unit)}.'
              : '${s.label}. ${l10n.sceneDrawHint}',
          value: _locked ? null : _spoken(_guess),
          increasedValue: _locked ? null : _spoken(_straight(0.05)),
          decreasedValue: _locked ? null : _spoken(_straight(-0.05)),
          onIncrease: _locked ? null : () => _nudgeEnd(0.05),
          onDecrease: _locked ? null : () => _nudgeEnd(-0.05),
          child: ExcludeSemantics(
            child: _locked
                ? paint
                : RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: {
                      _EagerPan: GestureRecognizerFactoryWithHandlers<_EagerPan>(
                        _EagerPan.new,
                        (r) => r
                          ..dragStartBehavior = DragStartBehavior.down
                          ..onStart = ((d) =>
                              _draw(d.localPosition, start: true))
                          ..onUpdate = ((d) =>
                              _draw(d.localPosition, start: false))
                          ..onEnd = ((_) => _lift())
                          ..onCancel = _lift,
                      ),
                    },
                    child: paint,
                  ),
          ),
        );
      },
    );
  }
}

/// A pan that wins the moment a finger lands, before the deck's own pan,
/// tap or long press can: inside the chart every touch is a pen stroke.
class _EagerPan extends PanGestureRecognizer {
  _EagerPan({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => 'draw';
}

// ---- the readout ------------------------------------------------------

class _Readouts extends StatelessWidget {
  final DrawScene scene;
  final Color ink;
  final bool compact;
  final String? you;
  final String? truth;
  final String youCaption;
  final String truthCaption;
  const _Readouts({
    required this.scene,
    required this.ink,
    required this.compact,
    required this.you,
    required this.truth,
    required this.youCaption,
    required this.truthCaption,
  });

  @override
  Widget build(BuildContext context) {
    Widget block(String caption, String? n, {required bool strong}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                size: 10.5,
                weight: FontWeight.w800,
                color: ink.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                n ?? '?',
                maxLines: 1,
                style: AppText.display(
                  size: compact ? 30 : 42,
                  weight: FontWeight.w800,
                  height: 1.05,
                  spacing: compact ? -0.8 : -1.4,
                  color: ink.withValues(
                    alpha: n == null ? 0.25 : (strong ? 1 : 0.62),
                  ),
                ),
              ),
            ),
          ],
        );

    return ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: block(youCaption, you, strong: truth == null)),
          const SizedBox(width: 12),
          Expanded(child: block(truthCaption, truth, strong: true)),
        ],
      ),
    );
  }
}

// ---- the buttons ------------------------------------------------------

class _LockButton extends StatelessWidget {
  final Color ink;
  final Color ground;
  final String label;
  final VoidCallback? onTap;
  const _LockButton({
    required this.ink,
    required this.ground,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      child: GestureDetector(
        // Taken even while it cannot be pressed, so a tap that misses the
        // moment does not turn the card over instead.
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () {},
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? ink : ink.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              label,
              style: AppText.label(
                size: 12,
                weight: FontWeight.w800,
                spacing: 1.1,
                color: on ? ground : ink.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgainButton extends StatelessWidget {
  final Color ink;
  final String label;
  final VoidCallback? onTap;
  const _AgainButton({
    required this.ink,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () {},
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ink.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Icon(
            Icons.refresh_rounded,
            size: 22,
            color: ink.withValues(alpha: onTap == null ? 0.35 : 0.85),
          ),
        ),
      ),
    );
  }
}

// ---- geometry ---------------------------------------------------------

/// A smooth curve through points that never overshoots them (monotone
/// cubic, Fritsch and Carlson): a reader's line that rises and then holds
/// must not dip on the way, and a truth that never falls must not seem to.
class _Curve {
  final List<double> xs;
  final List<double> ys;
  final List<double> ms;

  _Curve._(this.xs, this.ys, this.ms);

  factory _Curve(List<Offset> pts) {
    final n = pts.length;
    final xs = [for (final p in pts) p.dx];
    final ys = [for (final p in pts) p.dy];
    if (n < 2) return _Curve._(xs, ys, List.filled(n, 0));
    final d = [
      for (var i = 0; i < n - 1; i++)
        (ys[i + 1] - ys[i]) / math.max(1e-6, xs[i + 1] - xs[i]),
    ];
    final m = List<double>.filled(n, 0);
    m[0] = d[0];
    m[n - 1] = d[n - 2];
    for (var i = 1; i < n - 1; i++) {
      m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      if (d[i] == 0) {
        m[i] = 0;
        m[i + 1] = 0;
        continue;
      }
      final a = m[i] / d[i], b = m[i + 1] / d[i];
      final h = a * a + b * b;
      if (h > 9) {
        final t = 3 / math.sqrt(h);
        m[i] = t * a * d[i];
        m[i + 1] = t * b * d[i];
      }
    }
    return _Curve._(xs, ys, m);
  }

  double get start => xs.first;
  double get end => xs.last;

  double at(double x) {
    if (xs.length == 1) return ys.first;
    if (x <= xs.first) return ys.first;
    if (x >= xs.last) return ys.last;
    var i = 0;
    while (i < xs.length - 2 && x > xs[i + 1]) {
      i++;
    }
    final h = xs[i + 1] - xs[i];
    final t = (x - xs[i]) / h;
    final t2 = t * t, t3 = t2 * t;
    return (2 * t3 - 3 * t2 + 1) * ys[i] +
        (t3 - 2 * t2 + t) * h * ms[i] +
        (-2 * t3 + 3 * t2) * ys[i + 1] +
        (t3 - t2) * h * ms[i + 1];
  }

  /// The curve from [from] to [to] as a path, a point every few pixels.
  Path path(double from, double to, {Path? onto}) {
    final p = onto ?? Path();
    final a = math.max(from, start), b = math.min(to, end);
    if (b <= a) return p;
    p.moveTo(a, at(a));
    for (var x = a + 3; x < b; x += 3) {
      p.lineTo(x, at(x));
    }
    p.lineTo(b, at(b));
    return p;
  }
}

/// The chart laid out at one size: where the plot sits, the columns' x,
/// the mapping between a share of the height and a pixel, and every label
/// measured once. The painter draws it and the finger reads it.
class _Chart {
  final Size size;
  final Color ink;
  final TextScaler scaler;
  final Rect plot;
  final List<double> xs;
  final TextPainter label;
  final List<(double, TextPainter)> ticks;
  final List<TextPainter?> cols;
  final List<TextPainter> notes;
  final TextPainter you;
  final TextPainter truthTag;
  final _Curve truth;
  final double anchorX;

  _Chart._({
    required this.size,
    required this.ink,
    required this.scaler,
    required this.plot,
    required this.xs,
    required this.label,
    required this.ticks,
    required this.cols,
    required this.notes,
    required this.you,
    required this.truthTag,
    required this.truth,
    required this.anchorX,
  });

  static const double pad = 14;

  double yAt(double share) => plot.bottom - share * plot.height;
  double shareAt(double y) =>
      ((plot.bottom - y) / plot.height).clamp(0.0, 1.0);

  int colAt(double x) {
    final step = xs.length > 1 ? xs[1] - xs[0] : 1;
    return ((x - xs.first) / step).round().clamp(0, xs.length - 1);
  }

  double get colWidth => xs.length > 1 ? xs[1] - xs[0] : plot.width;

  /// Where the tip of the truth is at reveal progress [t].
  double tipX(double t) => anchorX + (xs.last - anchorX) * t;

  static TextPainter _text(
    String s,
    TextStyle style,
    TextScaler scaler, {
    double? width,
    int? lines,
  }) =>
      TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: lines,
        ellipsis: lines == null ? null : '…',
      )..layout(maxWidth: width ?? double.infinity);

  factory _Chart.build({
    required Size size,
    required DrawScene scene,
    required Color ink,
    required Color ground,
    required TextScaler scaler,
    required String you,
    required String truth,
  }) {
    final s = scene;
    final label = _text(
      s.label.toUpperCase(),
      AppText.label(
        size: 10.5,
        weight: FontWeight.w800,
        color: ink.withValues(alpha: 0.72),
      ),
      scaler,
      width: size.width - pad * 2,
      lines: 1,
    );

    // Round ticks: a handful on a straight scale, the powers of ten on a
    // log one.
    final tickValues = <double>[];
    if (s.log) {
      final a = (math.log(s.min) / math.ln10).ceil();
      final b = (math.log(s.max) / math.ln10 + 1e-9).floor();
      final every = (b - a) > 5 ? 2 : 1;
      for (var k = a; k <= b; k += every) {
        tickValues.add(math.pow(10, k).toDouble());
      }
    } else {
      final raw = (s.max - s.min) / 4;
      final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
      final step = [1.0, 2.0, 2.5, 5.0, 10.0]
              .firstWhere((k) => k * mag >= raw - 1e-9) *
          mag;
      for (var v = (s.min / step).ceil() * step; v <= s.max + 1e-9; v += step) {
        tickValues.add(v);
      }
    }
    final tickStyle = AppText.label(
      size: 10.5,
      weight: FontWeight.w700,
      spacing: 0.3,
      color: ink.withValues(alpha: 0.55),
    );
    final tickText = [
      for (final v in tickValues) _text(_tick(v, s.unit), tickStyle, scaler),
    ];
    final tickWidth = tickText.fold(0.0, (w, t) => math.max(w, t.width));

    final colStyle = AppText.label(
      size: 10.5,
      weight: FontWeight.w700,
      spacing: 0.5,
      color: ink.withValues(alpha: 0.62),
    );
    final colText = [for (final c in s.columns) _text(c, colStyle, scaler)];
    final colH = colText.first.height;

    final plot = Rect.fromLTRB(
      pad + tickWidth + 10,
      pad + label.height + 14,
      size.width - pad - 4,
      math.max(
        pad + label.height + 40,
        size.height - pad - colH - 8,
      ),
    );
    const inset = 10.0;
    final n = s.count;
    final xs = [
      for (var i = 0; i < n; i++)
        plot.left + inset + (plot.width - inset * 2) * i / (n - 1),
    ];

    // Column labels, thinned until they no longer touch. The last stays,
    // since it is usually the one the card is about.
    final step = xs[1] - xs[0];
    var every = 1;
    bool fits(int k) {
      for (var i = k; i < n; i += k) {
        final gap = step * k - (colText[i - k].width + colText[i].width) / 2;
        if (gap < 8) return false;
      }
      return true;
    }

    while (every < n - 1 && !fits(every)) {
      every++;
    }
    final cols = <TextPainter?>[
      for (var i = 0; i < n; i++) i % every == 0 ? colText[i] : null,
    ];
    if (cols.last == null) {
      final prev = (n - 1) ~/ every * every;
      final gap = (xs.last - xs[prev]) -
          (colText[prev].width + colText.last.width) / 2;
      if (gap < 8) cols[prev] = null;
      cols[n - 1] = colText.last;
    }

    double yAt(double share) => plot.bottom - share * plot.height;
    final truthCurve = _Curve([
      for (var i = 0; i < n; i++) Offset(xs[i], yAt(s.share(s.values[i]))),
    ]);

    final noteStyle = AppText.body(
      size: 12,
      weight: FontWeight.w700,
      height: 1.2,
      color: ink,
    );
    final notes = [
      for (final m in s.notes)
        _text(m.text, noteStyle, scaler, width: plot.width * 0.58, lines: 2),
    ];

    TextPainter tag(String t, Color c) => _text(
          t,
          AppText.label(size: 9.5, weight: FontWeight.w800, spacing: 1, color: c),
          scaler,
        );

    return _Chart._(
      size: size,
      ink: ink,
      scaler: scaler,
      plot: plot,
      xs: xs,
      label: label,
      ticks: [
        for (var i = 0; i < tickValues.length; i++)
          (yAt(s.share(tickValues[i])), tickText[i]),
      ],
      cols: cols,
      notes: notes,
      you: tag(you, ink),
      truthTag: tag(truth, ground),
      truth: truthCurve,
      anchorX: xs[s.anchor],
    );
  }

  /// Short on the axis: 1,500 · 20k · 3M, with a one-sign unit attached.
  static String _tick(double v, String unit) {
    String n;
    final a = v.abs();
    String trim(double x) {
      final s = x.toStringAsFixed(x >= 10 || x == x.roundToDouble() ? 0 : 1);
      return s;
    }

    if (a >= 1e12) {
      n = '${trim(a / 1e12)}T';
    } else if (a >= 1e9) {
      n = '${trim(a / 1e9)}B';
    } else if (a >= 1e6) {
      n = '${trim(a / 1e6)}M';
    } else if (a >= 1e4) {
      n = '${trim(a / 1e3)}k';
    } else if (a == a.roundToDouble()) {
      n = _DrawSceneViewState._commas(a.toStringAsFixed(0));
    } else {
      n = a < 1 ? a.toStringAsPrecision(1) : a.toStringAsFixed(1);
    }
    if (v < 0) n = '−$n';
    if (unit.length == 1 || unit.startsWith('°')) {
      return _DrawSceneViewState._withUnit(n, unit);
    }
    return n;
  }
}

// ---- the picture ------------------------------------------------------

class _DrawPainter extends CustomPainter {
  final _Chart chart;
  final DrawScene scene;
  final List<double?> guess;
  final Offset? pen;
  final bool locked;
  final Animation<double> hint;
  final Animation<double> tip;
  final Color ink;
  final Color ground;

  _DrawPainter({
    required this.chart,
    required this.scene,
    required this.guess,
    required this.pen,
    required this.locked,
    required this.hint,
    required this.tip,
    required this.ink,
    required this.ground,
  }) : super(repaint: Listenable.merge([hint, tip]));

  final Paint _fill = Paint();
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _stroke(Color c, double w) => _line
    ..color = c
    ..strokeWidth = w;

  Paint _solid(Color c) => _fill..color = c;

  /// The reader's line through the columns they have set, starting where
  /// the given line ends, with the finger slotted in while it is down so the
  /// line stays under it rather than a column behind.
  List<Offset> _guessPoints() {
    final s = scene;
    final xs = chart.xs;
    final pts = <Offset>[];
    if (s.given > 0) pts.add(Offset(xs[s.anchor], chart.yAt(guess[s.anchor]!)));
    final p = pen;
    var penIn = false;
    for (var i = s.firstDrawn; i < s.count; i++) {
      final g = guess[i];
      if (g == null) continue;
      final x = xs[i];
      if (p != null && !penIn && x >= p.dx - 0.5) {
        if (p.dx > (pts.isEmpty ? -1 : pts.last.dx + 0.5)) pts.add(p);
        penIn = true;
        // The column just set, half a step ahead of the finger, would put
        // a little flat hook in front of it.
        if (x <= p.dx + chart.colWidth * 0.5) continue;
      }
      pts.add(Offset(x, chart.yAt(g)));
    }
    if (p != null && !penIn && (pts.isEmpty || p.dx > pts.last.dx + 0.5)) {
      pts.add(p);
    }
    return pts;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = scene;
    final c = chart;
    final plot = c.plot;
    final xs = c.xs;
    final t = locked ? tip.value : 0.0;
    final tipX = locked ? c.tipX(t) : c.anchorX;

    // The panel, and what the chart measures.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      _solid(ink.withValues(alpha: 0.07)),
    );
    c.label.paint(canvas, const Offset(_Chart.pad, _Chart.pad));

    // The stretch still to draw, faintly shaded until the truth fills it.
    final shade = (1 - t) * 0.06;
    if (shade > 0) {
      canvas.drawRect(
        Rect.fromLTRB(c.anchorX, plot.top, plot.right, plot.bottom),
        _solid(ink.withValues(alpha: shade)),
      );
    }

    // Grid: round values across, a hairline down each column.
    for (final (y, tp) in c.ticks) {
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        _stroke(ink.withValues(alpha: 0.13), 1),
      );
      tp.paint(canvas, Offset(plot.left - 10 - tp.width, y - tp.height / 2));
    }
    for (var i = 0; i < xs.length; i++) {
      canvas.drawLine(
        Offset(xs[i], plot.top),
        Offset(xs[i], plot.bottom),
        _stroke(ink.withValues(alpha: 0.06), 1),
      );
      final tp = c.cols[i];
      if (tp == null) continue;
      final left = (xs[i] - tp.width / 2)
          .clamp(4.0, size.width - 4 - tp.width)
          .toDouble();
      tp.paint(canvas, Offset(left, plot.bottom + 8));
    }
    canvas.drawLine(
      Offset(plot.left, plot.bottom),
      Offset(plot.right, plot.bottom),
      _stroke(ink.withValues(alpha: 0.3), 1.5),
    );

    final pts = _guessPoints();
    final mine = pts.length >= 2 ? _Curve(pts) : null;
    final truth = c.truth;
    final shown = s.given > 0 ? c.anchorX : (locked ? xs.first : -1.0);

    // The gap between the two, filled as the truth draws past it.
    if (locked && mine != null && tipX > c.anchorX) {
      final a = c.anchorX, b = math.min(tipX, mine.end);
      final gap = truth.path(a, b);
      for (var x = b; x > a; x -= 3) {
        gap.lineTo(x, mine.at(x));
      }
      gap
        ..lineTo(a, mine.at(a))
        ..close();
      canvas.drawPath(gap, _solid(ink.withValues(alpha: 0.1)));
    }

    // The truth: the given stretch from the start, the rest as it reveals.
    final reach = locked ? tipX : shown;
    if (reach >= xs.first) {
      final line = truth.path(xs.first, reach);
      if (locked) {
        canvas.drawPath(line, _stroke(ink.withValues(alpha: 0.16), 13));
      }
      canvas.drawPath(line, _stroke(ink, 4.5));
    }
    for (var i = 0; i < s.given; i++) {
      canvas.drawCircle(
        Offset(xs[i], truth.at(xs[i])),
        i == s.anchor ? 6 : 4,
        _solid(ink),
      );
    }

    // The reader's line: solid while it is theirs, dashed once it is set
    // beside the truth.
    if (mine != null) {
      final path = mine.path(mine.start, mine.end);
      if (locked) {
        _dashed(canvas, path, _stroke(ink.withValues(alpha: 0.7), 3));
      } else {
        canvas.drawPath(path, _stroke(ink, 4));
      }
    } else if (pts.length == 1 && !locked) {
      canvas.drawCircle(pts.first, 3, _solid(ink));
    }

    if (pen != null) {
      canvas.drawCircle(pen!, 13, _solid(ink.withValues(alpha: 0.18)));
      canvas.drawCircle(pen!, 7, _solid(ink));
      canvas.drawCircle(pen!, 2.8, _solid(ground));
    }

    if (!locked && pen == null && _blank) _paintHint(canvas);

    if (!locked) return;

    // Notes on the truth: the given ones from the start, the rest as the
    // tip passes them.
    for (var k = 0; k < s.notes.length; k++) {
      final x = xs[s.notes[k].at];
      final o = x <= c.anchorX + 0.5
          ? 1.0
          : ((tipX - x) / (c.colWidth * 0.6)).clamp(0.0, 1.0);
      if (o > 0) _paintNote(canvas, c.notes[k], Offset(x, truth.at(x)), o);
    }

    // The tip, travelling.
    if (t < 1) {
      final p = Offset(tipX, truth.at(tipX));
      canvas.drawCircle(p, 12, _solid(ink.withValues(alpha: 0.2)));
      canvas.drawCircle(p, 6.5, _solid(ink));
    }

    // At the judged column: the two ends, the miss between them, and
    // which is which.
    final end = ((t - 0.82) / 0.18).clamp(0.0, 1.0);
    if (end > 0 && mine != null) {
      final x = xs[s.judge];
      final ty = truth.at(x), my = mine.at(x);
      canvas.drawLine(
        Offset(x, ty),
        Offset(x, my),
        _stroke(ink.withValues(alpha: 0.55 * end), 2),
      );
      canvas.drawCircle(
        Offset(x, my),
        6,
        _solid(ground.withValues(alpha: end)),
      );
      canvas.drawCircle(
        Offset(x, my),
        6,
        _stroke(ink.withValues(alpha: end), 2.5),
      );
      canvas.drawCircle(Offset(x, ty), 7, _solid(ink.withValues(alpha: end)));
      _paintTags(canvas, x, ty, my, end);
    }
  }

  bool get _blank {
    for (var i = scene.firstDrawn; i < scene.count; i++) {
      if (guess[i] != null) return false;
    }
    return true;
  }

  /// Where to start: the end of the given line (or the middle of the first
  /// column), three slow rings, and an arrow pointing the way.
  void _paintHint(Canvas canvas) {
    final s = scene;
    final c = chart;
    final p = Offset(
      c.anchorX,
      s.given > 0 ? c.truth.at(c.anchorX) : c.yAt(0.5),
    );
    final v = hint.value;
    if (v > 0 && v < 1) {
      final k = (v * 3) % 1;
      final e = Curves.easeOut.transform(k);
      canvas.drawCircle(
        p,
        7 + 20 * e,
        _stroke(ink.withValues(alpha: 0.5 * (1 - e)), 2),
      );
    }
    canvas.drawCircle(p, 7, _solid(ink));
    canvas.drawCircle(p, 2.8, _solid(ground));
    final a = p.dx + 16;
    final b = math.min(p.dx + 52, c.plot.right - 4);
    final arrow = _stroke(ink.withValues(alpha: 0.7), 2.2);
    for (var x = a; x < b - 8; x += 7) {
      canvas.drawLine(Offset(x, p.dy), Offset(math.min(x + 3, b), p.dy), arrow);
    }
    canvas.drawLine(Offset(b, p.dy), Offset(b - 6, p.dy - 5), arrow);
    canvas.drawLine(Offset(b, p.dy), Offset(b - 6, p.dy + 5), arrow);
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 11) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
      }
    }
  }

  /// A note pinned to [p]: a small ring on the line, the words in a tag on
  /// whichever side has room, and a hairline between them.
  void _paintNote(Canvas canvas, TextPainter tp, Offset p, double o) {
    final plot = chart.plot;
    const px = 7.0, py = 4.0, gap = 14.0;
    final w = tp.width + px * 2, h = tp.height + py * 2;
    final above = p.dy - plot.top > plot.bottom - p.dy;
    final top = above ? p.dy - gap - h : p.dy + gap;
    var left = p.dx - 12;
    if (left + w > chart.size.width - 6) left = p.dx + 12 - w;
    left = left.clamp(6.0, math.max(6.0, chart.size.width - 6 - w)).toDouble();
    final box = Rect.fromLTWH(left, top, w, h);

    canvas.drawLine(
      p,
      Offset(p.dx, above ? box.bottom : box.top),
      _stroke(ink.withValues(alpha: 0.5 * o), 1.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(7)),
      _solid(ground.withValues(alpha: 0.94 * o)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(7)),
      _stroke(ink.withValues(alpha: 0.22 * o), 1),
    );
    canvas.drawCircle(p, 5.5, _solid(ground.withValues(alpha: o)));
    canvas.drawCircle(p, 5.5, _stroke(ink.withValues(alpha: o), 2));
    if (o < 1) {
      canvas.saveLayer(box.inflate(2), _solid(Color.fromRGBO(0, 0, 0, o)));
      tp.paint(canvas, box.topLeft + const Offset(px, py));
      canvas.restore();
    } else {
      tp.paint(canvas, box.topLeft + const Offset(px, py));
    }
  }

  /// TRUTH, filled, beside the real end; YOU, outlined, beside the
  /// reader's. On the inward side of the column, pushed apart when the two
  /// ends nearly meet.
  void _paintTags(Canvas canvas, double x, double ty, double my, double o) {
    final plot = chart.plot;
    final inward = x > plot.center.dx ? -1.0 : 1.0;
    final tt = chart.truthTag, yt = chart.you;
    const px = 7.0, py = 3.5;
    final th = tt.height + py * 2, yh = yt.height + py * 2;
    var a = ty, b = my;
    final need = (th + yh) / 2 + 4;
    if ((a - b).abs() < need) {
      final mid = (a + b) / 2;
      final up = a <= b ? -1.0 : 1.0;
      a = mid + up * need / 2;
      b = mid - up * need / 2;
    }
    a = a.clamp(plot.top + th / 2, plot.bottom - th / 2).toDouble();
    b = b.clamp(plot.top + yh / 2, plot.bottom - yh / 2).toDouble();

    Rect at(double cy, TextPainter tp, double h) {
      final w = tp.width + px * 2;
      final left = inward < 0 ? x - 14 - w : x + 14;
      return Rect.fromLTWH(left, cy - h / 2, w, h);
    }

    final rt = at(a, tt, th), ry = at(b, yt, yh);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rt, Radius.circular(th / 2)),
      _solid(ink.withValues(alpha: o)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(ry, Radius.circular(yh / 2)),
      _solid(ground.withValues(alpha: o)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(ry, Radius.circular(yh / 2)),
      _stroke(ink.withValues(alpha: o), 1.5),
    );
    canvas.saveLayer(
      rt.expandToInclude(ry).inflate(2),
      _solid(Color.fromRGBO(0, 0, 0, o)),
    );
    tt.paint(canvas, rt.topLeft + const Offset(px, py));
    yt.paint(canvas, ry.topLeft + const Offset(px, py));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DrawPainter old) =>
      old.chart != chart ||
      old.guess != guess ||
      old.pen != pen ||
      old.locked != locked ||
      old.ink != ink ||
      old.ground != ground;
}
