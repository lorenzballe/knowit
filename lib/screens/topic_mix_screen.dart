import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/topics.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Pick the mix by dragging it into shape.
///
/// A list of thirteen checkboxes is a form, and nobody has ever enjoyed
/// filling one in. The same choice as a shape you pull about with a finger is
/// a thing you play with — and it says something a list cannot, which is that
/// these are proportions of one deck rather than thirteen independent
/// switches. Pulling space out pushes everything else in.
class TopicMixScreen extends StatefulWidget {
  /// Weights by topic key, each 0..1. Empty topics are simply left out.
  final void Function(Map<String, double> weights) onDone;

  const TopicMixScreen({super.key, required this.onDone});

  @override
  State<TopicMixScreen> createState() => _TopicMixScreenState();
}

/// Every subject except Thinking, which is not on offer: the puzzles are the
/// training and they come whatever the reader picks, so putting them on the
/// wheel would be asking a question with only one answer.
final List<String> kMixableTopics = [
  for (final key in kTopicOrder)
    if (key != 'thinking') key,
];

class _TopicMixScreenState extends State<TopicMixScreen> {
  /// Everything starts half-way out, so the shape opens as a wheel rather
  /// than as an empty star somebody has to fill in from nothing.
  late final Map<String, double> _weights = {
    for (final key in kMixableTopics) key: 0.5,
  };

  /// The axis under the finger, so the readout can name it.
  String? _touched;

  final GlobalKey _radarKey = GlobalKey();

  /// A floor rather than zero: at the very centre every axis is on top of
  /// every other one and the nearest-axis maths turns to noise.
  static const double _floor = 0.0;
  static const double _minKept = 0.06;

  double get _total =>
      _weights.values.fold(0.0, (sum, v) => sum + math.max(0, v));

  int _percent(String key) {
    final total = _total;
    if (total <= 0) return 0;
    return (100 * math.max(0.0, _weights[key]!) / total).round();
  }

  int get _kept => _weights.values.where((v) => v >= _minKept).length;

  void _dragTo(Offset local, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.76;
    final v = local - centre;
    if (v.distance < radius * 0.12) return;

    // Which spoke is the finger closest to, by angle.
    final step = 2 * math.pi / kMixableTopics.length;
    var angle = math.atan2(v.dy, v.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final index = (angle / step).round() % kMixableTopics.length;
    final key = kMixableTopics[index];

    final value = (v.distance / radius).clamp(_floor, 1.0);
    if (_weights[key] == value && _touched == key) return;
    if (_touched != key) HapticFeedback.selectionClick();
    setState(() {
      _weights[key] = value;
      _touched = key;
    });
  }

  void _handle(Offset global) {
    final box = _radarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _dragTo(box.globalToLocal(global), box.size);
  }

  @override
  Widget build(BuildContext context) {
    final touched = _touched;

    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What should we talk about?',
                style: AppText.display(
                  size: 29,
                  weight: FontWeight.w700,
                  height: 1.08,
                  spacing: -1.2,
                  color: context.p.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Drag the shape. Pull a subject out to see more of it, push '
                'it in to see less. The puzzles come whatever you pick — '
                'this is the reading.',
                style: AppText.body(
                  size: 14,
                  height: 1.45,
                  color: context.p.inkMuted,
                ),
              ),
              const SizedBox(height: 10),

              // The readout sits above the shape so a finger never covers it.
              SizedBox(
                height: 46,
                child: Center(
                  child: touched == null
                      ? Text(
                          'Thirteen subjects, one deck',
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: context.p.inkFaint,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TopicDot(kTopics[touched]!.color, size: 9),
                            const SizedBox(width: 8),
                            Text(
                              kTopics[touched]!.name.toUpperCase(),
                              style: AppText.label(
                                size: 12,
                                spacing: 1.2,
                                color: context.p.inkMuted,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_percent(touched)}%',
                              style: AppText.display(
                                size: 24,
                                weight: FontWeight.w700,
                                spacing: -0.7,
                                color: context.p.ink,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (d) => _handle(d.globalPosition),
                      onPanUpdate: (d) => _handle(d.globalPosition),
                      onPanEnd: (_) => setState(() {}),
                      onTapDown: (d) => _handle(d.globalPosition),
                      child: CustomPaint(
                        key: _radarKey,
                        painter: _RadarPainter(
                          weights: _weights,
                          touched: _touched,
                          line: context.p.line,
                          lineStrong: context.p.lineStrong,
                          ink: context.p.inkFaint,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _kept == 0
                    ? 'Pull at least one subject out.'
                    : '$_kept of ${kMixableTopics.length} subjects in the mix',
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: _kept == 0 ? context.p.alert : context.p.inkFaint,
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'START WITH MY FIRST CARDS',
                background: AppColors.lime,
                foreground: AppColors.limeInk,
                onPressed: _kept == 0
                    ? null
                    : () => widget.onDone({
                        for (final e in _weights.entries)
                          if (e.value >= _minKept) e.key: e.value,
                      }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> weights;
  final String? touched;
  final Color line;
  final Color lineStrong;
  final Color ink;

  _RadarPainter({
    required this.weights,
    required this.touched,
    required this.line,
    required this.lineStrong,
    required this.ink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    // The labels live outside the ring, so the ring cannot use the whole box
    // or they are clipped by its edges.
    final radius = math.min(size.width, size.height) / 2 * 0.76;
    final n = kMixableTopics.length;
    final step = 2 * math.pi / n;

    Offset at(int i, double t) {
      final angle = i * step - math.pi / 2;
      return centre + Offset(math.cos(angle), math.sin(angle)) * (radius * t);
    }

    // Rings, so distance from the middle reads as a quantity.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = line;
    for (final t in const [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = at(i, t);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), ring);
    }

    // Spokes.
    final spoke = Paint()
      ..strokeWidth = 1
      ..color = line;
    for (var i = 0; i < n; i++) {
      canvas.drawLine(centre, at(i, 1), spoke);
    }

    // The shape itself.
    final shape = Path();
    for (var i = 0; i < n; i++) {
      final t = weights[kMixableTopics[i]]!.clamp(0.0, 1.0);
      final p = at(i, t);
      i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
    }
    shape.close();

    canvas.drawPath(
      shape,
      Paint()..color = AppColors.lime.withValues(alpha: 0.32),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.limeDark,
    );

    // A handle on every axis, in that subject's own colour.
    for (var i = 0; i < n; i++) {
      final key = kMixableTopics[i];
      final t = weights[key]!.clamp(0.0, 1.0);
      final p = at(i, t);
      final live = key == touched;
      canvas.drawCircle(p, live ? 11 : 7, Paint()..color = kTopics[key]!.color);
      canvas.drawCircle(
        p,
        live ? 11 : 7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = lineStrong,
      );
    }

    // Labels just outside the ring.
    for (var i = 0; i < n; i++) {
      final key = kMixableTopics[i];
      final painter = TextPainter(
        text: TextSpan(
          text: kTopics[key]!.name,
          style: AppText.label(
            size: 8.5,
            spacing: 0.4,
            color: key == touched ? kTopics[key]!.color : ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final anchor = at(i, 1.19);
      painter.paint(
        canvas,
        anchor - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.touched != touched || !_same(old.weights, weights);

  static bool _same(Map<String, double> a, Map<String, double> b) {
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
