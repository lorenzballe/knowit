import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/diagram.dart';
import '../theme.dart';

/// A card's diagram, drawn live in the card's ink and animated once, the way
/// someone explaining it would draw it: the frame, then the thing, then the
/// comparison that is the point. Tapping it plays it again.
///
/// The motion borrows its manners from the best explainers of mathematics on
/// video: every stroke is drawn rather than faded in, every number counts up
/// to its value as the shape that carries it grows, one thing moves at a
/// time, and every move eases in and out, so nothing starts or stops with a
/// jolt. With reduced motion switched on the diagram is simply there.
class DiagramView extends StatefulWidget {
  final Diagram diagram;

  /// The colour everything is drawn in, and the ground it sits on.
  final Color ink;

  /// Waits this long before drawing, so a card that has just turned over is
  /// still before its picture starts moving.
  final Duration delay;

  /// Starts at the last frame, for a still (a share image, a test).
  final bool still;

  const DiagramView({
    super.key,
    required this.diagram,
    required this.ink,
    this.delay = const Duration(milliseconds: 380),
    this.still = false,
  });

  @override
  State<DiagramView> createState() => _DiagramViewState();
}

class _DiagramViewState extends State<DiagramView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: _durationOf(widget.diagram),
  );

  static Duration _durationOf(Diagram d) => switch (d) {
    DotsDiagram() => const Duration(milliseconds: 2600),
    LineDiagram() => const Duration(milliseconds: 2800),
    ScaleDiagram() => const Duration(milliseconds: 2600),
    TimelineDiagram() => const Duration(milliseconds: 2600),
    _ => const Duration(milliseconds: 2200),
  };

  @override
  void initState() {
    super.initState();
    if (widget.still) {
      _t.value = 1;
      return;
    }
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _t.value = 1;
      } else {
        _t.forward();
      }
    });
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _replay() {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _t.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diagram;
    return Semantics(
      image: true,
      label: d.caption.isEmpty ? null : d.caption,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _replay,
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth.isFinite ? box.maxWidth : 320.0;
            final painter = _painterFor(d, _t, widget.ink);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: width,
                  height: painter.heightFor(width),
                  child: CustomPaint(painter: painter),
                ),
                if (d.caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _t,
                      curve: const Interval(0.7, 1, curve: Curves.easeOut),
                    ),
                    child: Text(
                      d.caption,
                      style: AppText.body(
                        size: 12,
                        height: 1.4,
                        color: widget.ink.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

_DiagramPainter _painterFor(Diagram d, Animation<double> t, Color ink) =>
    switch (d) {
      DotsDiagram() => _DotsPainter(d, t, ink),
      BarsDiagram() => _BarsPainter(d, t, ink),
      ScaleDiagram() => _ScalePainter(d, t, ink),
      AreaDiagram() => _AreaPainter(d, t, ink),
      SplitDiagram() => _SplitPainter(d, t, ink),
      LineDiagram() => _LinePainter(d, t, ink),
      TimelineDiagram() => _TimelinePainter(d, t, ink),
    };

// ── Shared drawing ─────────────────────────────────────────────────────────

/// The part of the animation [t] that falls between [a] and [b], eased so it
/// leaves and arrives gently.
double phase(double t, double a, double b) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return Curves.easeInOutCubic.transform((t - a) / (b - a));
}

/// Like [phase], with a slight overshoot for things that pop into place.
double pop(double t, double a, double b) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return Curves.easeOutBack.transform((t - a) / (b - a));
}

/// A number the way a person would say it on a card: commas under a
/// million, words above, three significant figures at most.
String sayNumber(double v) {
  final a = v.abs();
  if (a >= 1e12) return '${_sig(v / 1e12)} trillion';
  if (a >= 1e9) return '${_sig(v / 1e9)} billion';
  if (a >= 1e6) return '${_sig(v / 1e6)} million';
  if (a >= 1000) return _commas(v.round());
  if (a >= 100) return v.round().toString();
  return _sig(v);
}

String _sig(double v) {
  if (v == 0) return '0';
  final a = v.abs();
  final digits = a >= 100
      ? 0
      : a >= 10
      ? 1
      : a >= 1
      ? 2
      : (2 - (math.log(a) / math.ln10).floor()).clamp(0, 12);
  var s = v.toStringAsFixed(digits);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}

String _commas(int n) {
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

const _superscripts = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵', '6': '⁶',
  '7': '⁷', '8': '⁸', '9': '⁹', '-': '⁻',
};

/// A power of ten as a tick label: plain where a plain number is short,
/// 10ⁿ where it is not.
String sayPower(int k) {
  if (k >= -2 && k <= 4) return sayNumber(math.pow(10, k).toDouble());
  return '10${k.toString().split('').map((c) => _superscripts[c]).join()}';
}

/// How many times bigger, as a factor to print beside a bracket.
String sayFactor(double f) => '×${sayNumber(f)}';

double _log10(double v) => math.log(v) / math.ln10;

abstract class _DiagramPainter extends CustomPainter {
  final Animation<double> t;
  final Color ink;
  _DiagramPainter(this.t, this.ink) : super(repaint: t);

  double heightFor(double width);

  Color inkAt(double alpha) => ink.withValues(alpha: alpha);

  Color get strong => inkAt(0.95);
  Color get mid => inkAt(0.5);
  Color get soft => inkAt(0.26);
  Color get faint => inkAt(0.13);

  Paint fill(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  Paint stroke(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  TextPainter layoutText(
    String text, {
    double size = 11.5,
    FontWeight weight = FontWeight.w500,
    double alpha = 0.75,
    bool display = false,
    double maxWidth = double.infinity,
    int maxLines = 2,
    TextAlign align = TextAlign.left,
  }) {
    final style = display
        ? AppText.display(size: size, weight: weight, color: inkAt(alpha))
        : AppText.body(size: size, weight: weight, color: inkAt(alpha), height: 1.2);
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
  }

  /// Draws [tp] with its anchor at [at]: (0,0) is its top-left corner,
  /// (0.5,1) the middle of its bottom edge, and so on.
  void drawText(
    Canvas canvas,
    TextPainter tp,
    Offset at, {
    Offset anchor = Offset.zero,
    double opacity = 1,
    double rise = 0,
  }) {
    if (opacity <= 0) return;
    final o = at - Offset(tp.width * anchor.dx, tp.height * anchor.dy);
    if (opacity >= 1 && rise == 0) {
      tp.paint(canvas, o);
      return;
    }
    canvas.saveLayer(
      Rect.fromLTWH(o.dx - 2, o.dy - 2 + rise, tp.width + 4, tp.height + 4),
      Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0, 1)),
    );
    tp.paint(canvas, o + Offset(0, rise * (1 - opacity)));
    canvas.restore();
  }

  /// The first [p] of [path], as if a pen were still drawing it.
  Path partial(Path path, double p) {
    if (p >= 1) return path;
    final out = Path();
    if (p <= 0) return out;
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (s, m) => s + m.length);
    var left = total * p;
    for (final m in metrics) {
      if (left <= 0) break;
      final take = math.min(left, m.length);
      out.addPath(m.extractPath(0, take), Offset.zero);
      left -= take;
    }
    return out;
  }

  /// A bracket from [a] to [b] with its factor written above it.
  void factorBracket(
    Canvas canvas,
    Offset a,
    Offset b,
    String text,
    double p, {
    double lift = 10,
  }) {
    if (p <= 0) return;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(a.dx, a.dy - lift)
      ..lineTo(b.dx, b.dy - lift)
      ..lineTo(b.dx, b.dy);
    canvas.drawPath(partial(path, phase(p, 0, 0.7)), stroke(mid, 1.3));
    final tp = layoutText(text, size: 15, weight: FontWeight.w600, alpha: 0.95, display: true);
    drawText(
      canvas,
      tp,
      Offset((a.dx + b.dx) / 2, math.min(a.dy, b.dy) - lift - 4),
      anchor: const Offset(0.5, 1),
      opacity: phase(p, 0.45, 1),
      rise: 4,
    );
  }

  @override
  bool shouldRepaint(covariant _DiagramPainter old) =>
      old.ink != ink || old.t != t;
}

// ── dots: a share of a population ──────────────────────────────────────────

class _DotsPainter extends _DiagramPainter {
  final DotsDiagram d;
  _DotsPainter(this.d, super.t, super.ink);

  bool get _thousand => d.total > 100;
  int get _cols => _thousand ? 40 : 10;
  int get _rows => (d.total / _cols).ceil();

  @override
  double heightFor(double width) {
    if (!_thousand) return math.min(150, width * 0.46);
    final pitch = width / _cols;
    return _rows * pitch + 22 + d.groups.length * 22;
  }

  Color _groupColour(int g) {
    if (d.groups.length == 1 || d.groups[g].highlight) return strong;
    return switch (g) {
      0 => strong,
      1 => inkAt(0.55),
      _ => inkAt(0.34),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    // The grid: square for a hundred, full width for a thousand.
    final double pitch;
    final Offset origin;
    if (_thousand) {
      pitch = size.width / _cols;
      origin = Offset(pitch / 2, pitch / 2);
    } else {
      pitch = size.height / _rows;
      origin = Offset(pitch / 2, pitch / 2);
    }
    final radius = pitch * (_thousand ? 0.34 : 0.3);

    // Which group each dot belongs to, in reading order.
    // Gathered groups take the first places in reading order; spread ones
    // are scattered over what is left, the same way on every run.
    final owner = List<int>.filled(d.total, -1);
    final rank = List<int>.filled(d.total, 0);
    var at = 0;
    for (var g = 0; g < d.groups.length; g++) {
      if (d.groups[g].spread) continue;
      for (var k = 0; k < d.groups[g].n && at < d.total; k++) {
        rank[at] = k;
        owner[at++] = g;
      }
    }
    final free = [for (var i = 0; i < d.total; i++) if (owner[i] < 0) i];
    var seed = 0x2545F491;
    for (var i = free.length - 1; i > 0; i--) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final j = seed % (i + 1);
      final tmp = free[i];
      free[i] = free[j];
      free[j] = tmp;
    }
    var next = 0;
    for (var g = 0; g < d.groups.length; g++) {
      if (!d.groups[g].spread) continue;
      final taken = <int>[];
      for (var k = 0; k < d.groups[g].n && next < free.length; k++) {
        taken.add(free[next++]);
      }
      // Filled in reading order, so the scatter still sweeps across.
      taken.sort();
      for (var k = 0; k < taken.length; k++) {
        owner[taken[k]] = g;
        rank[taken[k]] = k;
      }
    }

    // Each group fills in its own window, one after the other.
    final fillStart = 0.34;
    final window = (0.9 - fillStart) / math.max(1, d.groups.length);
    for (var i = 0; i < d.total; i++) {
      final col = i % _cols;
      final row = i ~/ _cols;
      final c = origin + Offset(col * pitch, row * pitch);
      // A diagonal wave lays the population down first.
      final wave = (col + row) / (_cols + _rows);
      final appear = pop(v, wave * 0.26, wave * 0.26 + 0.1);
      if (appear <= 0) continue;
      final g = owner[i];
      canvas.drawCircle(c, radius * appear, fill(faint));
      if (g < 0) continue;
      final groupStart = fillStart + g * window;
      final k = rank[i];
      final n = d.groups[g].n;
      final local = groupStart + window * 0.8 * (n <= 1 ? 0 : k / (n - 1));
      final f = pop(v, local, local + 0.08);
      if (f > 0) canvas.drawCircle(c, radius * f, fill(_groupColour(g)));
    }

    // The legend: to the right of a hundred, under a thousand.
    final legendX = _thousand ? 0.0 : _cols * pitch + 20;
    var legendY = _thousand ? _rows * pitch + 10 : 4.0;
    final legendW = size.width - legendX;
    final head = layoutText(
      _thousand ? 'OUT OF 1,000' : 'OUT OF 100',
      size: 10,
      weight: FontWeight.w600,
      alpha: 0.55,
    );
    drawText(canvas, head, Offset(legendX, legendY), opacity: phase(v, 0.2, 0.34));
    legendY += head.height + 6;
    for (var g = 0; g < d.groups.length; g++) {
      final groupStart = fillStart + g * window;
      final p = phase(v, groupStart, groupStart + window);
      final shown = (d.groups[g].n * p).round();
      final number = layoutText(
        _commas(shown),
        size: 22,
        weight: FontWeight.w600,
        alpha: 0.95,
        display: true,
      );
      final label = layoutText(
        d.groups[g].label,
        size: 12,
        alpha: 0.78,
        maxWidth: math.max(40, legendW - 60),
      );
      final o = phase(v, groupStart - 0.04, groupStart + 0.08);
      canvas.drawCircle(
        Offset(legendX + 5, legendY + number.height / 2),
        5 * o,
        fill(_groupColour(g)),
      );
      drawText(canvas, number, Offset(legendX + 16, legendY), opacity: o);
      drawText(
        canvas,
        label,
        Offset(legendX + 22 + math.max(number.width, 30), legendY + (number.height - label.height) / 2 + 1),
        opacity: o,
      );
      legendY += math.max(number.height, label.height) + (_thousand ? 0 : 6);
    }
  }
}

// ── bars: a few amounts side by side ──────────────────────────────────────

class _BarsPainter extends _DiagramPainter {
  final BarsDiagram d;
  _BarsPainter(this.d, super.t, super.ink);

  static const _row = 38.0;

  @override
  double heightFor(double width) => d.items.length * _row + 2;

  double _scaled(double v, double lo, double hi) {
    if (!d.log) return v / hi;
    final floor = _log10(lo) - 0.6;
    return ((_log10(v) - floor) / (_log10(hi) - floor)).clamp(0.02, 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final values = d.items.map((i) => i.value).toList();
    final hi = values.reduce(math.max);
    final lo = values.reduce(math.min);
    final anyHighlight = d.items.any((i) => i.highlight);
    // Room at the end of the longest bar for its number.
    final widest = d.items
        .map((i) => layoutText('${sayNumber(i.value)} ${d.unit}'.trim(), size: 14, display: true).width)
        .reduce(math.max);
    final track = size.width - widest - 10;

    for (var i = 0; i < d.items.length; i++) {
      final item = d.items[i];
      final top = i * _row;
      final start = 0.06 + i * (0.6 / d.items.length);
      final grow = phase(v, start, start + 0.42);
      final colour = !anyHighlight || item.highlight ? strong : mid;

      final label = layoutText(item.label, size: 12, alpha: 0.78, maxWidth: size.width, maxLines: 1);
      drawText(canvas, label, Offset(0, top), opacity: phase(v, start - 0.06, start + 0.1));

      final barTop = top + label.height + 4;
      final full = math.max(3.0, track * _scaled(item.value, lo, hi));
      final w = full * grow;
      if (w > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(0, barTop, w, 11), const Radius.circular(5.5)),
          fill(colour),
        );
      }
      final shown = item.value * grow;
      final value = layoutText(
        '${sayNumber(shown)} ${d.unit}'.trim(),
        size: 14,
        weight: FontWeight.w600,
        alpha: !anyHighlight || item.highlight ? 0.95 : 0.6,
        display: true,
      );
      drawText(
        canvas,
        value,
        Offset(w + 8, barTop + 5.5),
        anchor: const Offset(0, 0.5),
        opacity: phase(v, start, start + 0.12),
      );
    }
  }
}

// ── scale: orders of magnitude on one line ────────────────────────────────

class _ScalePainter extends _DiagramPainter {
  final ScaleDiagram d;
  _ScalePainter(this.d, super.t, super.ink);

  @override
  double heightFor(double width) => 168;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final items = [...d.items]..sort((a, b) => a.value.compareTo(b.value));
    final lo = _log10(items.first.value).floor();
    final hi = _log10(items.last.value).ceil();
    final kLo = lo == hi ? lo - 1 : lo;
    final decades = math.max(1, hi - kLo);
    const pad = 14.0;
    final axisY = size.height * 0.56;
    double xOf(double value) =>
        pad + (size.width - 2 * pad) * ((_log10(value) - kLo) / decades);

    // The axis draws itself left to right.
    final axis = Path()
      ..moveTo(pad, axisY)
      ..lineTo(size.width - pad, axisY);
    canvas.drawPath(partial(axis, phase(v, 0, 0.22)), stroke(soft, 1.6));

    // Decade ticks, thinned when there are many.
    final every = decades <= 7 ? 1 : decades <= 14 ? 2 : 3;
    for (var k = kLo; k <= kLo + decades; k++) {
      final x = pad + (size.width - 2 * pad) * ((k - kLo) / decades);
      final p = phase(v, 0.08 + 0.14 * (k - kLo) / decades, 0.2 + 0.14 * (k - kLo) / decades);
      canvas.drawLine(Offset(x, axisY - 4 * p), Offset(x, axisY + 4 * p), stroke(soft, 1.2));
      if ((k - kLo) % every == 0) {
        final tick = layoutText(sayPower(k), size: 10, alpha: 0.5);
        drawText(canvas, tick, Offset(x, axisY + 8), anchor: const Offset(0.5, 0), opacity: p);
      }
    }
    if (d.unit.isNotEmpty) {
      final unit = layoutText(d.unit, size: 10, weight: FontWeight.w600, alpha: 0.5);
      drawText(canvas, unit, Offset(size.width - pad, axisY + 22), anchor: const Offset(1, 0), opacity: phase(v, 0.2, 0.34));
    }

    // Items drop onto the line one by one, labels alternating above.
    final anyHighlight = items.any((i) => i.highlight);
    final placed = <Rect>[];
    final points = <Offset>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final x = xOf(item.value);
      final start = 0.34 + i * (0.36 / items.length);
      final p = pop(v, start, start + 0.16);
      final colour = !anyHighlight || item.highlight ? strong : mid;
      canvas.drawCircle(Offset(x, axisY), 5.5 * p, fill(colour));
      points.add(Offset(x, axisY));

      final name = layoutText(item.label, size: 11.5, alpha: 0.85, maxWidth: 110, maxLines: 2, align: TextAlign.center);
      final amount = layoutText('${sayNumber(item.value)} ${d.unit}'.trim(), size: 10.5, alpha: 0.55, maxWidth: 110);
      final h = name.height + amount.height + 2;
      // Stack labels upwards until they clear what is already placed.
      var level = 0;
      Rect box;
      do {
        final bottom = axisY - 16 - level * (h + 4);
        final w = math.max(name.width, amount.width);
        final left = (x - w / 2).clamp(0.0, size.width - w);
        box = Rect.fromLTWH(left, bottom - h, w, h);
        level++;
      } while (placed.any((r) => r.inflate(3).overlaps(box)) && level < 4);
      placed.add(box);
      final o = phase(v, start + 0.04, start + 0.16);
      canvas.drawLine(
        Offset(x, axisY - 7),
        Offset(x, box.bottom + 2),
        stroke(inkAt(0.22 * o), 1),
      );
      drawText(canvas, name, Offset(box.center.dx, box.top), anchor: const Offset(0.5, 0), opacity: o, rise: 4);
      drawText(canvas, amount, Offset(box.center.dx, box.top + name.height + 2), anchor: const Offset(0.5, 0), opacity: o, rise: 4);
    }

    // The point of the picture: how many times apart the ends are.
    if (items.length >= 2) {
      final f = items.last.value / items.first.value;
      final a = points.first + const Offset(0, 30);
      final b = points.last + const Offset(0, 30);
      final p = phase(v, 0.76, 1);
      if (p > 0) {
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(a.dx, a.dy + 8)
          ..lineTo(b.dx, b.dy + 8)
          ..lineTo(b.dx, b.dy);
        canvas.drawPath(partial(path, phase(p, 0, 0.7)), stroke(mid, 1.3));
        final tp = layoutText(sayFactor(f), size: 15, weight: FontWeight.w600, alpha: 0.95, display: true);
        drawText(canvas, tp, Offset((a.dx + b.dx) / 2, a.dy + 12), anchor: const Offset(0.5, 0), opacity: phase(p, 0.45, 1), rise: -4);
      }
    }
  }
}

// ── area: how much bigger, as the eye judges it ───────────────────────────

class _AreaPainter extends _DiagramPainter {
  final AreaDiagram d;
  _AreaPainter(this.d, super.t, super.ink);

  @override
  double heightFor(double width) => 178;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final items = d.items;
    final hi = items.map((i) => i.value).reduce(math.max);
    final labelRoom = 40.0;
    final maxR = math.min((size.height - labelRoom - 34) / 2, size.width / (items.length * 2.3));
    final radii = [for (final i in items) math.max(1.6, maxR * math.sqrt(i.value / hi))];
    final gap = 18.0;
    final totalW = radii.fold<double>(0, (s, r) => s + 2 * r) + gap * (items.length - 1);
    var x = (size.width - totalW) / 2;
    final base = size.height - labelRoom;
    final anyHighlight = items.any((i) => i.highlight);
    final centres = <Offset>[];
    for (var i = 0; i < items.length; i++) {
      final r = radii[i];
      final c = Offset(x + r, base - r);
      centres.add(c);
      final start = 0.05 + i * (0.5 / items.length);
      final g = phase(v, start, start + 0.4);
      final strongOne = !anyHighlight || items[i].highlight;
      // The outline is drawn first, then it fills.
      final ring = Path()..addOval(Rect.fromCircle(center: c, radius: r));
      canvas.drawPath(partial(ring, phase(g, 0, 0.6)), stroke(strongOne ? strong : mid, 1.4));
      final f = phase(g, 0.4, 1);
      if (f > 0) {
        canvas.drawCircle(c, r * f, fill(inkAt((strongOne ? 0.8 : 0.35) * f)));
      }
      final name = layoutText(items[i].label, size: 11.5, alpha: 0.85, maxWidth: math.max(70, 2 * r + gap), maxLines: 2, align: TextAlign.center);
      final amount = layoutText('${sayNumber(items[i].value)} ${d.unit}'.trim(), size: 10.5, alpha: 0.55);
      final o = phase(v, start + 0.15, start + 0.3);
      drawText(canvas, name, Offset(c.dx, base + 6), anchor: const Offset(0.5, 0), opacity: o);
      drawText(canvas, amount, Offset(c.dx, base + 7 + name.height), anchor: const Offset(0.5, 0), opacity: o);
      x += 2 * r + gap;
    }
    if (items.length >= 2) {
      final lo = items.map((i) => i.value).reduce(math.min);
      final a = centres.first - Offset(0, radii.first + 8);
      final b = centres.last - Offset(0, radii.last + 8);
      final top = math.min(a.dy, b.dy);
      factorBracket(canvas, Offset(a.dx, top), Offset(b.dx, top), sayFactor(hi / lo), phase(v, 0.72, 1), lift: 8);
    }
  }
}

// ── split: one whole in its parts ─────────────────────────────────────────

class _SplitPainter extends _DiagramPainter {
  final SplitDiagram d;
  _SplitPainter(this.d, super.t, super.ink);

  static const _barH = 26.0;

  @override
  double heightFor(double width) => _barH + 16 + 2 * 38;

  Color _partColour(int i) {
    final anyHighlight = d.parts.any((p) => p.highlight);
    if (anyHighlight) return d.parts[i].highlight ? strong : [inkAt(0.4), inkAt(0.24), inkAt(0.16)][i % 3];
    return [strong, inkAt(0.55), inkAt(0.32), inkAt(0.18)][i % 4];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final total = d.parts.fold<double>(0, (s, p) => s + p.value);
    final w = size.width;
    // The whole, as an empty track, then filled part by part.
    final track = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w * phase(v, 0, 0.2), _barH), const Radius.circular(8));
    canvas.drawRRect(track, fill(faint));
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, _barH), const Radius.circular(8)));
    var x = 0.0;
    final centres = <double>[];
    for (var i = 0; i < d.parts.length; i++) {
      final pw = w * d.parts[i].value / total;
      final start = 0.18 + i * (0.5 / d.parts.length);
      final g = phase(v, start, start + 0.3);
      canvas.drawRect(Rect.fromLTWH(x, 0, pw * g, _barH), fill(_partColour(i)));
      centres.add(x + pw / 2);
      x += pw;
    }
    canvas.restore();

    // Labels hang below on leader lines, in two rows where they would touch.
    final rowEnds = [double.negativeInfinity, double.negativeInfinity];
    for (var i = 0; i < d.parts.length; i++) {
      final part = d.parts[i];
      final share = d.unit == '%' ? '${_sig(part.value)}%' : '${sayNumber(part.value)} ${d.unit}'.trim();
      final number = layoutText(share, size: 14, weight: FontWeight.w600, alpha: 0.95, display: true);
      final label = layoutText(part.label, size: 11, alpha: 0.72, maxWidth: 120, maxLines: 1);
      final bw = math.max(number.width, label.width);
      var left = (centres[i] - bw / 2).clamp(0.0, w - bw);
      var row = left > rowEnds[0] + 8 ? 0 : 1;
      if (row == 1 && left <= rowEnds[1] + 8) left = rowEnds[1] + 8;
      rowEnds[row] = left + bw;
      final top = _barH + 12 + row * 38;
      final start = 0.18 + i * (0.5 / d.parts.length) + 0.18;
      final o = phase(v, start, start + 0.16);
      canvas.drawLine(
        Offset(centres[i], _barH + 2),
        Offset(centres[i], top - 1),
        stroke(inkAt(0.25 * o), 1),
      );
      drawText(canvas, number, Offset(left, top), opacity: o, rise: 4);
      drawText(canvas, label, Offset(left, top + number.height), opacity: o, rise: 4);
    }
  }
}

// ── line: a quantity changing along another ───────────────────────────────

class _LinePainter extends _DiagramPainter {
  final LineDiagram d;
  _LinePainter(this.d, super.t, super.ink);

  @override
  double heightFor(double width) => 200;

  List<double> _ticks(DiagramAxis a) {
    if (a.log) {
      final lo = _log10(a.min).ceil();
      final hi = _log10(a.max).floor();
      return [for (var k = lo; k <= hi; k++) math.pow(10, k).toDouble()];
    }
    final span = a.max - a.min;
    final raw = span / 4;
    final mag = math.pow(10, (_log10(raw)).floor()).toDouble();
    final step = [1, 2, 2.5, 5, 10].map((m) => m * mag).firstWhere((s) => span / s <= 5);
    final first = (a.min / step).ceil() * step;
    return [for (var x = first; x <= a.max + step * 1e-9; x += step) x];
  }

  double _norm(DiagramAxis a, double v) => a.log
      ? (_log10(v) - _log10(a.min)) / (_log10(a.max) - _log10(a.min))
      : (v - a.min) / (a.max - a.min);

  String _tickLabel(DiagramAxis a, double v) => a.log ? sayPower(_log10(v).round()) : sayNumber(v);

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final yTicks = _ticks(d.y);
    final yLabelW = yTicks
        .map((y) => layoutText(_tickLabel(d.y, y), size: 10).width)
        .fold<double>(0, math.max);
    final left = yLabelW + 8;
    const top = 14.0;
    final bottom = size.height - 30;
    final right = size.width - 8;
    Offset at(double x, double y) => Offset(
      left + (right - left) * _norm(d.x, x).clamp(-0.02, 1.02),
      bottom - (bottom - top) * _norm(d.y, y).clamp(-0.02, 1.02),
    );

    // Axes, then their ticks and gridlines.
    final axes = Path()
      ..moveTo(left, top)
      ..lineTo(left, bottom)
      ..lineTo(right, bottom);
    canvas.drawPath(partial(axes, phase(v, 0, 0.2)), stroke(soft, 1.5));
    final tickP = phase(v, 0.12, 0.3);
    for (final y in yTicks) {
      final p = at(d.x.min, y);
      if (y != d.y.min) canvas.drawLine(Offset(left, p.dy), Offset(left + (right - left) * tickP, p.dy), stroke(inkAt(0.08), 1));
      drawText(canvas, layoutText(_tickLabel(d.y, y), size: 10, alpha: 0.5), Offset(left - 6, p.dy), anchor: const Offset(1, 0.5), opacity: tickP);
    }
    for (final x in _ticks(d.x)) {
      final p = at(x, d.y.min);
      drawText(canvas, layoutText(_tickLabel(d.x, x), size: 10, alpha: 0.5), Offset(p.dx, bottom + 5), anchor: const Offset(0.5, 0), opacity: tickP);
    }
    if (d.x.label.isNotEmpty) {
      drawText(canvas, layoutText(d.x.label, size: 10, weight: FontWeight.w600, alpha: 0.55), Offset(right, size.height), anchor: const Offset(1, 1), opacity: tickP);
    }
    if (d.y.label.isNotEmpty) {
      drawText(canvas, layoutText(d.y.label, size: 10, weight: FontWeight.w600, alpha: 0.55), Offset(left + 6, top - 12), opacity: tickP);
    }

    // Each series is drawn by a moving pen, the highlighted one last.
    final order = [...d.series]..sort((a, b) => (a.highlight ? 1 : 0) - (b.highlight ? 1 : 0));
    final anyHighlight = d.series.any((s) => s.highlight);
    for (var i = 0; i < order.length; i++) {
      final s = order[i];
      final start = 0.26 + i * (0.4 / order.length);
      final p = phase(v, start, start + 0.42);
      final path = Path();
      for (var k = 0; k < s.points.length; k++) {
        final o = at(s.points[k].$1, s.points[k].$2);
        k == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      final strongOne = !anyHighlight || s.highlight;
      canvas.drawPath(partial(path, p), stroke(strongOne ? strong : mid, strongOne ? 2.6 : 1.8));
      if (s.label.isNotEmpty) {
        final end = at(s.points.last.$1, s.points.last.$2);
        final tp = layoutText(s.label, size: 11, weight: FontWeight.w600, alpha: strongOne ? 0.9 : 0.6, maxWidth: 120, maxLines: 1);
        final x = (end.dx - tp.width).clamp(left + 4, right - tp.width);
        drawText(canvas, tp, Offset(x, end.dy - 6), anchor: const Offset(0, 1), opacity: phase(v, start + 0.34, start + 0.46));
      }
    }

    // Marks: the points the card is about, with their guide lines.
    for (var i = 0; i < d.marks.length; i++) {
      final m = d.marks[i];
      final start = 0.74 + i * (0.18 / d.marks.length);
      final p = pop(v, start, start + 0.12);
      if (p <= 0) continue;
      final o = at(m.x, m.y);
      _dashed(canvas, Offset(o.dx, bottom), o, phase(v, start, start + 0.1));
      _dashed(canvas, Offset(left, o.dy), o, phase(v, start, start + 0.1));
      canvas.drawCircle(o, 4.5 * p, fill(strong));
      final tp = layoutText(m.label, size: 11.5, weight: FontWeight.w600, alpha: 0.92, maxWidth: 140, maxLines: 2);
      final rightSide = o.dx + 8 + tp.width < right;
      drawText(
        canvas,
        tp,
        o + Offset(rightSide ? 8 : -8, -6),
        anchor: Offset(rightSide ? 0 : 1, 1),
        opacity: phase(v, start + 0.04, start + 0.14),
        rise: 4,
      );
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, double p) {
    if (p <= 0) return;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(a.dx + (b.dx - a.dx) * p, a.dy + (b.dy - a.dy) * p);
    for (final m in path.computeMetrics()) {
      for (var s = 0.0; s < m.length; s += 6) {
        canvas.drawPath(m.extractPath(s, math.min(s + 3, m.length)), stroke(inkAt(0.35), 1));
      }
    }
  }
}

// ── timeline: when ────────────────────────────────────────────────────────

class _TimelinePainter extends _DiagramPainter {
  final TimelineDiagram d;
  _TimelinePainter(this.d, super.t, super.ink);

  @override
  double heightFor(double width) => 172;

  static String year(double y) {
    final n = y.round();
    if (n < 0) return '${_commas(-n)} BC';
    if (n < 1000) return 'AD $n';
    return n.toString();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    const pad = 10.0;
    final axisY = size.height * 0.52;
    double xOf(double y) => pad + (size.width - 2 * pad) * ((y - d.from) / (d.to - d.from));

    canvas.drawPath(
      partial(Path()..moveTo(pad, axisY)..lineTo(size.width - pad, axisY), phase(v, 0, 0.24)),
      stroke(soft, 1.6),
    );
    final ends = phase(v, 0.12, 0.28);
    drawText(canvas, layoutText(year(d.from), size: 10, alpha: 0.5), Offset(pad, axisY + 8), opacity: ends);
    drawText(canvas, layoutText(year(d.to), size: 10, alpha: 0.5), Offset(size.width - pad, axisY + 8), anchor: const Offset(1, 0), opacity: ends);

    // Stretches of time grow along the line as bands.
    for (var i = 0; i < d.spans.length; i++) {
      final s = d.spans[i];
      final start = 0.24 + i * 0.1;
      final g = phase(v, start, start + 0.3);
      final x0 = xOf(s.from);
      final x1 = xOf(s.to);
      final band = RRect.fromRectAndRadius(
        Rect.fromLTWH(x0, axisY - 5, (x1 - x0) * g, 10),
        const Radius.circular(5),
      );
      canvas.drawRRect(band, fill(s.highlight ? inkAt(0.7) : inkAt(0.3)));
      final tp = layoutText(s.label, size: 11, weight: FontWeight.w600, alpha: 0.8, maxWidth: math.max(60, x1 - x0 + 40), maxLines: 1);
      drawText(canvas, tp, Offset((x0 + x1) / 2, axisY + 22 + i * 16), anchor: const Offset(0.5, 0), opacity: phase(v, start + 0.2, start + 0.34));
    }

    // Moments drop in, labels alternating above the line.
    final placed = <Rect>[];
    final anyHighlight = d.events.any((e) => e.highlight);
    final events = [...d.events]..sort((a, b) => a.at.compareTo(b.at));
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      final x = xOf(e.at);
      final start = 0.38 + i * (0.44 / math.max(1, events.length));
      final p = pop(v, start, start + 0.14);
      final strongOne = !anyHighlight || e.highlight;
      canvas.drawCircle(Offset(x, axisY), 5 * p, fill(strongOne ? strong : mid));
      final when = layoutText(year(e.at), size: 10.5, weight: FontWeight.w600, alpha: 0.6);
      final what = layoutText(e.label, size: 11.5, alpha: 0.88, maxWidth: 120, maxLines: 2, align: TextAlign.center);
      final w = math.max(when.width, what.width);
      final h = when.height + what.height;
      var level = 0;
      Rect box;
      do {
        final bottom = axisY - 14 - level * (h + 4);
        box = Rect.fromLTWH((x - w / 2).clamp(0.0, size.width - w), bottom - h, w, h);
        level++;
      } while (placed.any((r) => r.inflate(3).overlaps(box)) && level < 3);
      placed.add(box);
      final o = phase(v, start + 0.04, start + 0.16);
      canvas.drawLine(Offset(x, axisY - 6), Offset(x, box.bottom + 2), stroke(inkAt(0.2 * o), 1));
      drawText(canvas, what, Offset(box.center.dx, box.top), anchor: const Offset(0.5, 0), opacity: o, rise: 4);
      drawText(canvas, when, Offset(box.center.dx, box.top + what.height), anchor: const Offset(0.5, 0), opacity: o, rise: 4);
    }
  }
}

/// Paints a diagram's last frame into an image, for previews and share
/// cards: the same painter the card uses, at a fixed width.
///
/// [at] picks the moment of the animation, 1 being its end; [ground] fills
/// behind it, as the card would.
Future<ui.Image> renderDiagramStill(
  Diagram d,
  Color ink,
  double width, {
  double pixelRatio = 2,
  double at = 1,
  Color? ground,
  double margin = 0,
}) async {
  final painter = _painterFor(d, AlwaysStoppedAnimation(at), ink);
  final h = painter.heightFor(width);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(pixelRatio);
  final full = Size(width + 2 * margin, h + 2 * margin);
  if (ground != null) canvas.drawRect(Offset.zero & full, Paint()..color = ground);
  canvas.translate(margin, margin);
  painter.paint(canvas, Size(width, h));
  return recorder.endRecording().toImage(
    (full.width * pixelRatio).ceil(),
    (full.height * pixelRatio).ceil(),
  );
}

/// The height a diagram takes at [width], without its caption.
double diagramHeight(Diagram d, double width) =>
    _painterFor(d, const AlwaysStoppedAnimation(1), const Color(0xFF000000)).heightFor(width);
