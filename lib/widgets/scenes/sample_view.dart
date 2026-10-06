import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [SampleScene]: the sample grows, the pattern goes.
///
/// From the top: how many have been drawn and the rate they show, in big
/// figures; the sample itself as a pile of dots, hits solid at the bottom,
/// with a dashed line where the truth would put them; a gauge where the
/// running rate swings and leaves a mark at every step; the line for the
/// step; and the button that grows it.
///
/// The reader grows it a step at a time with the button (or a tap on the
/// dots), or drags across the dots to scrub the size up and down: the draws
/// are fixed, so dragging back shows the same small sample as before.
class SampleSceneView extends StatefulWidget {
  final SampleScene scene;
  final Color ink;
  final Color ground;
  const SampleSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<SampleSceneView> createState() => _SampleSceneViewState();
}

class _SampleSceneViewState extends State<SampleSceneView>
    with SingleTickerProviderStateMixin {
  late SampleDraws _draws = widget.scene.draw();

  /// The sample size on screen. A double so it can travel smoothly; the
  /// dots and figures read it rounded.
  double _n = 0;

  // Growth runs along a log scale, so the jump from 2,000 to 20,000 takes
  // as long as the one from 20 to 200 and every step is watched at the
  // same pace. One controller serves the arrival and every step after.
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..addListener(_tick);
  double _from = 0;
  double _to = 0;
  bool _started = false;

  /// The width the drag scrubs across, from the last layout.
  double _width = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // The first sample pours in when the card arrives; with motion off it
    // is simply there.
    if (_calm) {
      _n = widget.scene.steps.first.toDouble();
    } else {
      _go(widget.scene.steps.first.toDouble(), from: 0);
    }
  }

  @override
  void didUpdateWidget(SampleSceneView old) {
    super.didUpdateWidget(old);
    if (!identical(old.scene, widget.scene)) {
      _draws = widget.scene.draw();
      _run.stop();
      _n = widget.scene.steps.first.toDouble();
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  bool get _calm => MediaQuery.disableAnimationsOf(context);

  void _tick() {
    final t = Curves.easeInOutCubic.transform(_run.value);
    final lo = math.log(math.max(_from, 1));
    final hi = math.log(_to);
    // From nothing, the first sample counts up in plain steps: a log scale
    // from zero would hold on the first few dots and then burst.
    final n = _from < 1 ? _to * t : math.exp(lo + (hi - lo) * t);
    setState(() => _n = n);
  }

  void _go(double to, {double? from}) {
    _from = from ?? _n;
    _to = to;
    if (_calm || _from == _to) {
      _run.stop();
      setState(() => _n = to);
      return;
    }
    _run.forward(from: 0);
  }

  int get _step => widget.scene.stepAt(_n.round());

  bool get _atEnd =>
      _step == widget.scene.steps.length - 1 && !_run.isAnimating;

  /// The button and a tap on the dots: the next step, or from the start
  /// once the last is reached.
  void _advance() {
    final s = widget.scene;
    HapticFeedback.lightImpact();
    if (_atEnd) {
      _go(s.steps.first.toDouble());
      return;
    }
    // While a step is still growing, the next one is counted from where it
    // is headed, so two quick taps go two steps.
    final at = s.stepAt(_run.isAnimating ? _to : _n.round());
    _go(s.steps[math.min(at + 1, s.steps.length - 1)].toDouble());
  }

  void _back() {
    final s = widget.scene;
    final at = _step;
    if (at <= 0) return;
    HapticFeedback.lightImpact();
    _go(s.steps[at - 1].toDouble());
  }

  /// A drag scrubs the size along the same log scale: the width of the
  /// dots runs from the first step to the last.
  void _scrub(double dx) {
    final s = widget.scene;
    _run.stop();
    final lo = math.log(s.steps.first);
    final hi = math.log(s.steps.last);
    final now = math.log(math.max(_n, s.steps.first.toDouble()));
    final next = math.exp((now + dx / _width * (hi - lo)).clamp(lo, hi));
    if (s.stepAt(next.round()) != s.stepAt(_n.round())) {
      HapticFeedback.selectionClick();
    }
    setState(() => _n = next);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final ink = widget.ink;
    final n = _n.round();
    final step = _step;
    final k = s.groups.length;

    return LayoutBuilder(
      builder: (context, box) {
        // Under about 330 points (the back of a card that asked first) the
        // figures shrink and the gauge goes: the dots already show the rate,
        // and they need the room more.
        final compact = box.maxHeight < 330;
        final gauge = box.maxHeight >= 360;
        final big = compact ? 30.0 : 42.0;
        _width = math.max(1, box.maxWidth);

        final shares = [for (var g = 0; g < k; g++) _draws.shareOf(n, g)];
        final unit = _unitFor(s, n, box, compact, gauge);

        final field = Expanded(
          child: _Field(
            scene: s,
            draws: _draws,
            n: n,
            unit: unit,
            ink: ink,
            ground: widget.ground,
          ),
        );

        // Inside the scene a tap is the scene's: on the dots it grows the
        // sample, elsewhere it does nothing rather than flip the card from
        // under a thumb aimed at the button. A sideways drag anywhere scrubs.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          onHorizontalDragUpdate: (d) => _scrub(d.delta.dx),
          child: Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  scene: s,
                  n: n,
                  unit: unit,
                  shares: shares,
                  ink: ink,
                  size: big,
                ),
                SizedBox(height: compact ? 8 : 12),
                // The dots and the gauge are one surface for the hand: a tap
                // grows the sample, a sideways drag scrubs it. Claiming the
                // horizontal drag here is what keeps the deck still.
                Expanded(
                  child: Semantics(
                    slider: true,
                    label: s.dots,
                    value: _spoken(s, n, shares),
                    increasedValue: step < s.steps.length - 1
                        ? _fmtInt(s.steps[step + 1])
                        : null,
                    decreasedValue: step > 0
                        ? _fmtInt(s.steps[step - 1])
                        : null,
                    onIncrease: step < s.steps.length - 1 ? _advance : null,
                    onDecrease: step > 0 ? _back : null,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _advance,
                      onHorizontalDragUpdate: (d) => _scrub(d.delta.dx),
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (s.compares) ...[
                              _GroupHeads(
                                scene: s,
                                shares: shares,
                                ink: ink,
                                ground: widget.ground,
                                size: compact ? 20 : 26,
                              ),
                              const SizedBox(height: 6),
                            ],
                            field,
                            if (gauge) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 34,
                                child: _Gauge(
                                  scene: s,
                                  draws: _draws,
                                  n: n,
                                  ink: ink,
                                  ground: widget.ground,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 8 : 12),
                SizedBox(
                  height: 40,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: _calm ? 0 : 280),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, .25),
                          end: Offset.zero,
                        ).animate(a),
                        child: child,
                      ),
                    ),
                    child: Align(
                      key: ValueKey(math.max(step, 0)),
                      alignment: Alignment.topLeft,
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          s.notes[math.max(step, 0)],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w600,
                            height: 1.35,
                            color: ink.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 6 : 10),
                Row(
                  children: [
                    Expanded(
                      child: _GrowButton(
                        label: _atEnd ? context.l10n.sceneTryAgain : s.button,
                        filled: !_atEnd,
                        ink: ink,
                        ground: widget.ground,
                        onTap: _advance,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      context.l10n.sceneNOfM(
                        math.max(step, 0) + 1,
                        s.steps.length,
                      ),
                      style: AppText.label(
                        size: 11,
                        weight: FontWeight.w800,
                        color: ink.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// What a screen reader hears for the dots: the size and each rate.
  String _spoken(SampleScene s, int n, List<double?> shares) {
    final rates = [
      for (var g = 0; g < s.groups.length; g++)
        if (shares[g] != null)
          '${s.groups[g].label.isEmpty ? s.hit : s.groups[g].label} '
              '${s.percent(shares[g]!)}',
    ];
    return [_fmtInt(n), ...rates].join(', ');
  }

  /// How many draws one dot stands for. Few enough dots to stay big and
  /// countable, and a round number a reader can multiply in their head.
  int _unitFor(
    SampleScene s,
    int n,
    BoxConstraints box,
    bool compact,
    bool gauge,
  ) {
    final k = s.groups.length;
    // A rough share of the height the pile gets; it only sets how fine the
    // dots may go, so it need not be exact.
    final h = box.maxHeight * (compact ? 0.3 : (gauge ? 0.42 : 0.5));
    final w = (box.maxWidth - _Field.gap * (k - 1)) / k;
    final fits = (w * h / (_Field.finest * _Field.finest)).floor();
    final cap = math.max(40, math.min(k == 1 ? 400 : 220, fits));
    final most = _draws.sizeOf(n, 0);
    for (var u = 1; ; u *= 10) {
      for (final m in const [1, 2, 5]) {
        if ((most / (u * m)).ceil() <= cap) return u * m;
      }
    }
  }
}

/// Thousands marked, the way the slider writes a measurement.
String _fmtInt(int v) =>
    v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// The count on the left, the rate on the right (or, comparing, the key to
/// what one dot stands for).
class _Header extends StatelessWidget {
  final SampleScene scene;
  final int n;
  final int unit;
  final List<double?> shares;
  final Color ink;
  final double size;
  const _Header({
    required this.scene,
    required this.n,
    required this.unit,
    required this.shares,
    required this.ink,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final figure = AppText.display(
      size: size,
      weight: FontWeight.w800,
      height: 1,
      spacing: -0.035 * size,
      color: ink,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final label = AppText.label(size: 10.5, color: ink.withValues(alpha: 0.7));
    final key = _UnitKey(unit: unit, ink: ink);

    final count = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_fmtInt(n), maxLines: 1, style: figure),
        const SizedBox(height: 5),
        Text(
          scene.dots.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: label,
        ),
      ],
    );

    if (scene.compares) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: count),
          const SizedBox(width: 12),
          Padding(padding: const EdgeInsets.only(bottom: 1), child: key),
        ],
      );
    }
    final share = shares.first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [count, const SizedBox(height: 4), key],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                share == null ? '–' : scene.percent(share),
                maxLines: 1,
                style: figure,
              ),
              const SizedBox(height: 5),
              Text(
                scene.hit.toUpperCase(),
                maxLines: 2,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: label,
              ),
              const SizedBox(height: 4),
              _TruthTag(text: scene.percent(scene.groups.first.rate), ink: ink),
            ],
          ),
        ),
      ],
    );
  }
}

/// "- - TRUTH 50%": the rate built into the simulation, marked with the
/// same dashes that cross the pile and the gauge where that rate would be.
class _TruthTag extends StatelessWidget {
  final String text;
  final Color ink;
  const _TruthTag({required this.text, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: const Size(17, 10), painter: _DashPainter(ink)),
        const SizedBox(width: 6),
        Text(
          '${context.l10n.sceneTruth} $text',
          maxLines: 1,
          style: AppText.label(size: 10.5, weight: FontWeight.w800, color: ink),
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color ink;
  _DashPainter(this.ink)
    : _paint = Paint()
        ..color = ink
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawLine(Offset(1, y), Offset(6, y), _paint);
    canvas.drawLine(Offset(11, y), Offset(16, y), _paint);
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.ink != ink;
}

/// "● = 50": one dot, and how many draws it holds. Drawn rather than
/// written, so it reads the same in every language.
class _UnitKey extends StatelessWidget {
  final int unit;
  final Color ink;
  const _UnitKey({required this.unit, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '= ${_fmtInt(unit)}',
          style: AppText.label(
            size: 10.5,
            weight: FontWeight.w800,
            color: ink.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Over each half of a compared sample: its name, its mark on the gauge
/// (a ring for the first, a disc for the second) and its rate.
class _GroupHeads extends StatelessWidget {
  final SampleScene scene;
  final List<double?> shares;
  final Color ink;
  final Color ground;
  final double size;
  const _GroupHeads({
    required this.scene,
    required this.shares,
    required this.ink,
    required this.ground,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    Widget head(int g) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: g == 0 ? ground : ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: ink, width: 2),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  scene.groups[g].label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: ink.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            shares[g] == null ? '–' : scene.percent(shares[g]!),
            maxLines: 1,
            style: AppText.display(
              size: size,
              weight: FontWeight.w800,
              height: 1,
              spacing: -0.03 * size,
              color: ink,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: 5),
          _TruthTag(text: scene.percent(scene.groups[g].rate), ink: ink),
        ],
      ),
    );
    return Row(
      children: [
        head(0),
        const SizedBox(width: _Field.gap),
        head(1),
      ],
    );
  }
}

/// The sample as dots, one pile per group.
class _Field extends StatelessWidget {
  /// Between the two piles of a compared sample.
  static const gap = 18.0;

  /// The tightest the dots may pack, centre to centre.
  static const finest = 7.0;

  final SampleScene scene;
  final SampleDraws draws;
  final int n;
  final int unit;
  final Color ink;
  final Color ground;
  const _Field({
    required this.scene,
    required this.draws,
    required this.n,
    required this.unit,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final k = scene.groups.length;
    final piles = [
      for (var g = 0; g < k; g++)
        _Pile(
          dots: (draws.sizeOf(n, g) / unit).round(),
          solid: (draws.hitsOf(n, g) / unit).round(),
          truth: scene.groups[g].rate,
        ),
    ];
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FieldPainter(piles: piles, ink: ink, ground: ground),
      ),
    );
  }
}

@immutable
class _Pile {
  final int dots;
  final int solid;
  final double truth;
  const _Pile({required this.dots, required this.solid, required this.truth});

  @override
  bool operator ==(Object other) =>
      other is _Pile &&
      other.dots == dots &&
      other.solid == solid &&
      other.truth == truth;

  @override
  int get hashCode => Object.hash(dots, solid, truth);
}

/// Each pile fills from the bottom, row by row: the hits first, solid, then
/// the misses, faint. So the top of the solid part is the rate, and the
/// dashed line across the pile is where the truth would have put it.
class _FieldPainter extends CustomPainter {
  final List<_Pile> piles;
  final Color ink;
  final Color ground;
  _FieldPainter({required this.piles, required this.ink, required this.ground})
    : _solid = Paint()
        ..color = ink
        ..strokeCap = StrokeCap.round,
      _faint = Paint()
        ..color = ink.withValues(alpha: 0.2)
        ..strokeCap = StrokeCap.round,
      _halo = Paint()
        ..color = ground
        ..strokeWidth = 5,
      _dash = Paint()
        ..color = ink
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

  final Paint _solid;
  final Paint _faint;
  final Paint _halo;
  final Paint _dash;

  /// Biggest dots that lay [count] of them in a [w] × [h] box, full rows,
  /// no bigger than [most] apart.
  static double pitchFor(int count, double w, double h, {double most = 52}) {
    if (count <= 0) return most;
    for (var p = most; p > 2; p -= 0.5) {
      final cols = (w / p).floor();
      if (cols < 1) continue;
      if ((count / cols).ceil() * p <= h) return p;
    }
    return 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = piles.length;
    final w = (size.width - _Field.gap * (k - 1)) / k;
    // Leave room over the pile for the truth's label.
    final h = size.height - 2;
    // One pitch for both piles, so equal counts stand equally high.
    final most = piles.map((p) => p.dots).reduce(math.max);
    final p = pitchFor(most, w, h);
    final cols = math.max(1, (w / p).floor());
    final r = p * (p > 14 ? 0.82 : 0.78);

    for (var g = 0; g < k; g++) {
      final pile = piles[g];
      final left = g * (w + _Field.gap);
      final x0 = left + (w - cols * p) / 2;
      final solid = Float32List(pile.solid * 2);
      final faint = Float32List((pile.dots - pile.solid) * 2);
      for (var i = 0; i < pile.dots; i++) {
        final row = i ~/ cols;
        final col = i % cols;
        final x = x0 + (col + 0.5) * p;
        final y = size.height - (row + 0.5) * p;
        if (i < pile.solid) {
          solid[i * 2] = x;
          solid[i * 2 + 1] = y;
        } else {
          final j = i - pile.solid;
          faint[j * 2] = x;
          faint[j * 2 + 1] = y;
        }
      }
      _faint.strokeWidth = r;
      _solid.strokeWidth = r;
      canvas.drawRawPoints(PointMode.points, faint, _faint);
      canvas.drawRawPoints(PointMode.points, solid, _solid);

      if (pile.dots == 0) continue;
      // The truth: as high as the solid dots would stand if the sample hit
      // the true rate exactly.
      final y = size.height - pile.truth * pile.dots / cols * p;
      final x1 = x0 - 4;
      final x2 = x0 + cols * p + 4;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), _halo);
      const dash = 7.0;
      for (var x = x1; x < x2; x += dash * 2) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, x2), y), _dash);
      }
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) =>
      !_same(old.piles, piles) || old.ink != ink || old.ground != ground;

  static bool _same(List<_Pile> a, List<_Pile> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The running rate on a scale from nothing to [SampleScene.top]: a marker
/// that swings while the sample is small, a dashed tick at the truth, and a
/// small mark left behind at every step reached, so the swings can be seen
/// narrowing onto the tick.
class _Gauge extends StatelessWidget {
  final SampleScene scene;
  final SampleDraws draws;
  final int n;
  final Color ink;
  final Color ground;
  const _Gauge({
    required this.scene,
    required this.draws,
    required this.n,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final k = scene.groups.length;
    final reached = scene.stepAt(n);
    final label = AppText.label(
      size: 9.5,
      weight: FontWeight.w700,
      color: ink.withValues(alpha: 0.6),
    );
    return Row(
      children: [
        Text('0%', style: label),
        const SizedBox(width: 8),
        Expanded(
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _GaugePainter(
                top: scene.top,
                truths: [for (final g in scene.groups) g.rate],
                now: [for (var g = 0; g < k; g++) draws.shareOf(n, g)],
                marks: [
                  for (var i = 0; i <= reached; i++)
                    for (var g = 0; g < k; g++)
                      draws.shareOf(scene.steps[i], g) ?? 0,
                ],
                ink: ink,
                ground: ground,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(scene.top * 100).round()}%', style: label),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double top;
  final List<double> truths;
  final List<double?> now;
  final List<double> marks;
  final Color ink;
  final Color ground;
  _GaugePainter({
    required this.top,
    required this.truths,
    required this.now,
    required this.marks,
    required this.ink,
    required this.ground,
  }) : _track = Paint()..color = ink.withValues(alpha: 0.16),
       _mark = Paint()
         ..color = ink.withValues(alpha: 0.38)
         ..strokeWidth = 2
         ..strokeCap = StrokeCap.round,
       _truth = Paint()
         ..color = ink
         ..strokeWidth = 2
         ..strokeCap = StrokeCap.round,
       _ink = Paint()..color = ink,
       _ground = Paint()..color = ground;

  final Paint _track;
  final Paint _mark;
  final Paint _truth;
  final Paint _ink;
  final Paint _ground;

  @override
  void paint(Canvas canvas, Size size) {
    const r = 8.0;
    final y = size.height / 2;
    double x(double share) =>
        r + (share / top).clamp(0.0, 1.0) * (size.width - r * 2);

    canvas.drawRRect(
      RRect.fromLTRBR(0, y - 3, size.width, y + 3, const Radius.circular(3)),
      _track,
    );
    // Where each step left the rate: short ticks, fainter than the truth.
    for (final m in marks) {
      canvas.drawLine(Offset(x(m), y - 7), Offset(x(m), y + 7), _mark);
    }
    // The truth, dashed, standing above and below the track.
    for (final t in truths) {
      final tx = x(t);
      for (var dy = -size.height / 2 + 1; dy < size.height / 2; dy += 6) {
        canvas.drawLine(
          Offset(tx, y + dy),
          Offset(tx, y + math.min(dy + 3, size.height / 2 - 1)),
          _truth,
        );
      }
    }
    // Where the rate is now: a disc, or a ring for the first of two.
    for (var g = 0; g < now.length; g++) {
      final v = now[g];
      if (v == null) continue;
      final c = Offset(x(v), y);
      canvas.drawCircle(c, r, _ink);
      if (now.length == 2 && g == 0) {
        canvas.drawCircle(c, r - 2.5, _ground);
      } else {
        canvas.drawCircle(c, 2.5, _ground);
      }
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.top != top ||
      old.ink != ink ||
      old.ground != ground ||
      !_listEq(old.now, now) ||
      !_listEq(old.marks, marks) ||
      !_listEq(old.truths, truths);

  static bool _listEq(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A big round button the width of the thumb's reach. Filled while there
/// is more to grow; an outline once the sample is whole and it starts over.
class _GrowButton extends StatefulWidget {
  final String label;
  final bool filled;
  final Color ink;
  final Color ground;
  final VoidCallback onTap;
  const _GrowButton({
    required this.label,
    required this.filled,
    required this.ink,
    required this.ground,
    required this.onTap,
  });

  @override
  State<_GrowButton> createState() => _GrowButtonState();
}

class _GrowButtonState extends State<_GrowButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 46,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: widget.filled ? ink : Colors.transparent,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: ink, width: 2),
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                size: 15,
                weight: FontWeight.w800,
                color: widget.filled ? widget.ground : ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
