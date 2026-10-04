import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/scene.dart';
import '../theme.dart';
import 'place_it.dart' show roughNumber;

/// Draws a [Scene] and lets the reader play with it.
///
/// It fills the height it is given: a readout on top, the picture in the
/// middle taking whatever is left, the control and its line at the bottom.
class SceneView extends StatelessWidget {
  final Scene scene;
  final Color ink;
  final Color ground;
  const SceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => switch (scene) {
    final SliderScene s => _SliderSceneView(scene: s, ink: ink, ground: ground),
  };
}

class _SliderSceneView extends StatefulWidget {
  final SliderScene scene;
  final Color ink;
  final Color ground;
  const _SliderSceneView({
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<_SliderSceneView> createState() => _SliderSceneViewState();
}

class _SliderSceneViewState extends State<_SliderSceneView>
    with SingleTickerProviderStateMixin {
  late double _x = widget.scene.start;
  bool _touched = false;

  // A short hint of movement when the card arrives, so the control is seen
  // to be a control: the knob leans a little way along and comes back.
  // The wait is the first third of one controller rather than a Timer: a
  // pending Timer outlives a disposed widget and hangs a widget test.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _nudge.addListener(() {
      if (_touched) return;
      final s = widget.scene;
      final p = ((_nudge.value * 3) - 1).clamp(0.0, 2.0) / 2;
      final v = Curves.easeInOut.transform(p < .5 ? p * 2 : 2 - p * 2);
      setState(() => _x = s.start + (s.to - s.from) * 0.12 * v);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _nudge.forward();
    }
  }

  @override
  void dispose() {
    _nudge.dispose();
    super.dispose();
  }

  /// Exact, with thousands marked: a readout is a measurement, not a guess.
  String _fmt(double v, int decimals) {
    if (v.abs() >= 1e6) return roughNumber(v);
    final fixed = v.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '${v < 0 ? '−' : ''}$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
  }

  /// Money is written with its sign in front; every other unit follows.
  static bool _prefix(String unit) =>
      const {'€', r'$', '£', '¥'}.contains(unit);

  void _set(double dx, double width) {
    final s = widget.scene;
    var x = s.from + (dx / width).clamp(0.0, 1.0) * (s.to - s.from);
    x = (x / s.step).round() * s.step;
    if (x != _x) {
      for (final n in s.notes) {
        if ((_x < n.at) != (x < n.at)) HapticFeedback.selectionClick();
      }
    }
    _nudge.stop();
    setState(() {
      _x = x.clamp(s.from, s.to);
      _touched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final ink = widget.ink;
    final y = s.valueAt(_x);
    final note = s.noteAt(_x);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.readout.isNotEmpty)
          Text(
            s.readout.toUpperCase(),
            style: AppText.label(size: 10.5, color: ink.withValues(alpha: 0.6)),
          ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _prefix(s.readoutUnit)
                  ? '${s.readoutUnit}${_fmt(y, s.decimals)}'
                  : _fmt(y, s.decimals),
              style: AppText.display(
                size: 44,
                weight: FontWeight.w800,
                height: 1,
                spacing: -1.4,
                color: ink,
              ),
            ),
            if (s.readoutUnit.isNotEmpty && !_prefix(s.readoutUnit)) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  s.readoutUnit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 16,
                    weight: FontWeight.w600,
                    color: ink.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _CurvePainter(
              scene: s,
              x: _x,
              ink: ink,
              ground: widget.ground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                s.control.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  size: 10.5,
                  color: ink.withValues(alpha: 0.6),
                ),
              ),
            ),
            Text(
              _prefix(s.controlUnit)
                  ? '${s.controlUnit}${_fmt(_x, s.step < 1 ? 1 : 0)}'
                  : '${_fmt(_x, s.step < 1 ? 1 : 0)}${s.controlUnit.isEmpty ? '' : ' ${s.controlUnit}'}',
              style: AppText.label(
                size: 11,
                weight: FontWeight.w800,
                color: ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, box) => Semantics(
            slider: true,
            label: s.control,
            value: _fmt(_x, 1),
            increasedValue: _fmt(
              (_x + (s.to - s.from) / 20).clamp(s.from, s.to),
              1,
            ),
            decreasedValue: _fmt(
              (_x - (s.to - s.from) / 20).clamp(s.from, s.to),
              1,
            ),
            onIncrease: () => _set(
              (_x - s.from + (s.to - s.from) / 20) /
                  (s.to - s.from) *
                  box.maxWidth,
              box.maxWidth,
            ),
            onDecrease: () => _set(
              (_x - s.from - (s.to - s.from) / 20) /
                  (s.to - s.from) *
                  box.maxWidth,
              box.maxWidth,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) =>
                  _set(d.localPosition.dx, box.maxWidth),
              onHorizontalDragUpdate: (d) =>
                  _set(d.localPosition.dx, box.maxWidth),
              onTapDown: (d) => _set(d.localPosition.dx, box.maxWidth),
              child: SizedBox(
                height: 40,
                width: box.maxWidth,
                child: CustomPaint(
                  painter: _TrackPainter(
                    t: (_x - s.from) / (s.to - s.from),
                    ink: ink,
                    ground: widget.ground,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
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
              key: ValueKey(note),
              alignment: Alignment.topLeft,
              child: Text(
                note,
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
      ],
    );
  }
}

/// The whole curve faint, the part already travelled solid, and a dot on
/// where the reader is.
class _CurvePainter extends CustomPainter {
  final SliderScene scene;
  final double x;
  final Color ink;
  final Color ground;
  _CurvePainter({
    required this.scene,
    required this.x,
    required this.ink,
    required this.ground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lo = scene.low < 0 ? scene.low : 0.0;
    final hi = scene.high == lo ? lo + 1 : scene.high;
    Offset at(double cx) => Offset(
      (cx - scene.from) / (scene.to - scene.from) * size.width,
      size.height -
          (scene.valueAt(cx) - lo) / (hi - lo) * (size.height - 8) -
          4,
    );

    Path line(double upTo) {
      final p = Path()..moveTo(at(scene.from).dx, at(scene.from).dy);
      const n = 80;
      for (var i = 1; i <= n; i++) {
        final cx = scene.from + (upTo - scene.from) * i / n;
        p.lineTo(at(cx).dx, at(cx).dy);
      }
      return p;
    }

    // Base line and the notes' moments, as hairlines.
    final hair = Paint()
      ..color = ink.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      hair,
    );
    for (final n in scene.notes) {
      final px = (n.at - scene.from) / (scene.to - scene.from) * size.width;
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), hair);
    }

    final whole = line(scene.to);
    canvas.drawPath(
      whole,
      Paint()
        ..color = ink.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final done = line(x);
    final fill = Path.from(done)
      ..lineTo(at(x).dx, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = ink.withValues(alpha: 0.12));
    canvas.drawPath(
      done,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = at(x);
    canvas.drawLine(
      Offset(dot.dx, dot.dy),
      Offset(dot.dx, size.height),
      Paint()
        ..color = ink.withValues(alpha: 0.4)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(dot, 9, Paint()..color = ink);
    canvas.drawCircle(dot, 3.5, Paint()..color = ground);
  }

  @override
  bool shouldRepaint(_CurvePainter old) => old.x != x || old.ink != ink;
}

class _TrackPainter extends CustomPainter {
  final double t;
  final Color ink;
  final Color ground;
  _TrackPainter({required this.t, required this.ink, required this.ground});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const r = 13.0;
    final w = size.width - r * 2;
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - 4, size.width, y + 4, const Radius.circular(4)),
      Paint()..color = ink.withValues(alpha: 0.18),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - 4, r + w * t, y + 4, const Radius.circular(4)),
      Paint()..color = ink,
    );
    final c = Offset(r + w * t, y);
    canvas.drawCircle(
      c + const Offset(0, 2),
      r,
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawCircle(c, r, Paint()..color = ink);
    canvas.drawCircle(c, 5, Paint()..color = ground);
  }

  @override
  bool shouldRepaint(_TrackPainter old) => old.t != t || old.ink != ink;
}
