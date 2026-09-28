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
    TreeDiagram() => const Duration(milliseconds: 3200),
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
      TreeDiagram() => _TreePainter(d, t, ink),
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
  // A true minus sign, not a hyphen.
  if (v < 0) return '−${sayNumber(-v)}';
  final a = v.abs();
  if (a >= 1e15) {
    // Past trillions, words stop helping: a power of ten.
    final e = (math.log(a) / math.ln10).floor();
    final m = v / math.pow(10.0, e);
    final sup = e.toString().split('').map((c) => _superscripts[c]).join();
    return '${_sig(m)} × 10$sup';
  }
  if (a >= 1e12) return '${_sig(v / 1e12)} trillion';
  if (a >= 1e9) return '${_sig(v / 1e9)} billion';
  if (a >= 1e6) return '${_sig(v / 1e6)} million';
  if (a >= 1000) return _commas(v.round());
  if (a >= 100) {
    // 110.7 stays 110.7: a hundred-odd with a decimal is usually the point.
    if ((v * 10).round() % 10 != 0 && a < 1000) return v.toStringAsFixed(1);
    return v.round().toString();
  }
  return _sig(v);
}

/// Two significant figures, for factors: ×18,000, ×2.7, ×8.2.
String _twoSig(double v) {
  if (v <= 0) return sayNumber(v);
  final e = (math.log(v) / math.ln10).floor();
  // A factor that is already round (×16, ×125,000) is printed as it is.
  final three = math.pow(10.0, e - 2);
  if (((v / three).round() * three - v).abs() <= v * 1e-9) return sayNumber(v);
  // Three figures for big factors (×125,000), two for small ones (×2.7).
  final unit = math.pow(10.0, v >= 100 ? e - 2 : e - 1);
  final r = (v / unit).round() * unit;
  return sayNumber(r.toDouble());
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
  '0': '⁰',
  '1': '¹',
  '2': '²',
  '3': '³',
  '4': '⁴',
  '5': '⁵',
  '6': '⁶',
  '7': '⁷',
  '8': '⁸',
  '9': '⁹',
  '-': '⁻',
};

/// A power of ten as a tick label: plain where a plain number is short,
/// 10ⁿ where it is not.
String sayPower(int k, {int lowest = 0}) {
  String sup(int n) =>
      n.toString().split('').map((c) => _superscripts[c]).join();
  // The app's fonts have no superscript minus, so a small power is written
  // as a fraction: 1/10⁶ for a millionth. When an axis goes that far down,
  // every decade below 1 is written the same way, so the notation holds.
  if (k < 0 && (k < -2 || lowest < -2)) {
    return k == -1 ? '1/10' : '1/10${sup(-k)}';
  }
  if (k >= -2 && k <= 4) return sayNumber(math.pow(10.0, k).toDouble());
  return '10${sup(k)}';
}

/// How many times bigger, as a factor to print beside a bracket.
/// An amount with its unit, the way it is written: a currency sign before
/// the number (€100), a per cent sign against it (57%), any other unit
/// after it with a space (3.14 mm²).
String sayAmount(double v, String unit, {String? said}) {
  final u = unit.trim();
  final n = said ?? sayNumber(v);
  if (u.isEmpty) return n;
  if (const {'€', r'$', '£', '¥', '₹'}.contains(u)) {
    // Money with cents shows both digits: $16.50, never $16.5.
    final cents = (v * 100).round() % 100 != 0 && v.abs() < 1000;
    return '$u${cents ? v.toStringAsFixed(2) : n}';
  }
  if (u.startsWith('%') || u == '¢' || u == '°' || u == '×') {
    return '$n$u';
  }
  return '$n $u';
}

String sayFactor(double f) => '×${_twoSig(f)}';

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
        : AppText.body(
            size: size,
            weight: weight,
            color: inkAt(alpha),
            height: 1.2,
          );
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
    final tp = layoutText(
      text,
      size: 15,
      weight: FontWeight.w600,
      alpha: 0.95,
      display: true,
    );
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
    return _rows * pitch + 22 + d.groups.length * 22 + 6;
  }

  Color _groupColour(int g) {
    if (d.groups.length == 1 || d.groups[g].highlight) return strong;
    // With a group marked, every other one recedes, whatever its place.
    final anyHighlight = d.groups.any((x) => x.highlight);
    var rank = anyHighlight ? 1 : 0;
    for (var i = 0; i < g; i++) {
      if (!d.groups[i].highlight) rank++;
    }
    return switch (rank) {
      0 => strong,
      1 => inkAt(0.48),
      _ => inkAt(0.3),
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
    final free = [
      for (var i = 0; i < d.total; i++)
        if (owner[i] < 0) i,
    ];
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
    drawText(
      canvas,
      head,
      Offset(legendX, legendY),
      opacity: phase(v, 0.2, 0.34),
    );
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
        maxWidth: math.max(60, legendW - 24 - math.max(number.width, 30)),
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
        Offset(
          legendX + 22 + math.max(number.width, 30),
          legendY + (number.height - label.height) / 2 + 1,
        ),
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

  /// A unit of more than a word or two is written once, above the bars,
  /// rather than after every figure.
  bool get _unitOnce => d.unit.length > 8;
  String _amount(double v) {
    final said = _places > 0 && v.abs() < 1000
        ? v.toStringAsFixed(_places)
        : null;
    return _unitOnce
        ? (said ?? sayNumber(v))
        : sayAmount(v, d.unit, said: said);
  }

  /// One number of decimals for every bar, so 1.0 stands beside 6.2
  /// rather than a bare 1.
  int get _places => d.items
      .map((i) {
        final s = sayNumber(i.value);
        return s.contains('.') && !s.contains(' ')
            ? s.length - s.indexOf('.') - 1
            : 0;
      })
      .fold(0, math.max);
  double get _head => _unitOnce ? 18 : 0;

  @override
  double heightFor(double width) => _head + d.items.length * _row + 2;

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
        .map((i) => layoutText(_amount(i.value), size: 14, display: true).width)
        .reduce(math.max);
    final track = size.width - widest - 10;
    if (_unitOnce) {
      final unit = layoutText(
        d.unit.toUpperCase(),
        size: 10,
        weight: FontWeight.w600,
        alpha: 0.55,
        maxWidth: size.width,
        maxLines: 1,
      );
      drawText(canvas, unit, Offset.zero, opacity: phase(v, 0, 0.14));
      canvas.save();
      canvas.translate(0, _head);
    }

    for (var i = 0; i < d.items.length; i++) {
      final item = d.items[i];
      final top = i * _row;
      final start = 0.06 + i * (0.6 / d.items.length);
      final grow = phase(v, start, start + 0.42);
      final colour = !anyHighlight || item.highlight ? strong : mid;

      final label = layoutText(
        item.label,
        size: 12,
        alpha: 0.78,
        maxWidth: size.width,
        maxLines: 1,
      );
      drawText(
        canvas,
        label,
        Offset(0, top),
        opacity: phase(v, start - 0.06, start + 0.1),
      );

      final barTop = top + label.height + 4;
      final full = math.max(3.0, track * _scaled(item.value, lo, hi));
      final w = full * grow;
      if (w > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, barTop, w, 11),
            const Radius.circular(5.5),
          ),
          fill(colour),
        );
      }
      // Counting up in the same steps as the final figure: whole numbers
      // stay whole on the way.
      final raw = item.value * grow;
      final shown = grow >= 1
          ? item.value
          : double.parse(raw.toStringAsFixed(_places));
      final value = layoutText(
        _amount(shown),
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
    if (_unitOnce) canvas.restore();
  }
}

// ── scale: orders of magnitude on one line ────────────────────────────────

class _ScalePainter extends _DiagramPainter {
  final ScaleDiagram d;
  _ScalePainter(this.d, super.t, super.ink);

  @override
  double heightFor(double width) => 186;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final items = [...d.items]..sort((a, b) => a.value.compareTo(b.value));
    final lo = (_log10(items.first.value) + 1e-9).floor();
    final hi = (_log10(items.last.value) - 1e-9).ceil();
    final kLo = lo == hi ? lo - 1 : lo;
    final decades = math.max(1, hi - kLo);
    const pad = 14.0;
    // Room above for stacked labels; below for ticks, the bracket, its
    // factor and the unit.
    final axisY = size.height - 86;
    double xOf(double value) =>
        pad + (size.width - 2 * pad) * ((_log10(value) - kLo) / decades);

    // The axis draws itself left to right.
    final axis = Path()
      ..moveTo(pad, axisY)
      ..lineTo(size.width - pad, axisY);
    canvas.drawPath(partial(axis, phase(v, 0, 0.22)), stroke(soft, 1.6));

    // Decade ticks, thinned when there are many.
    final every = decades <= 7
        ? 1
        : decades <= 14
        ? 2
        : 3;
    for (var k = kLo; k <= kLo + decades; k++) {
      final x = pad + (size.width - 2 * pad) * ((k - kLo) / decades);
      final p = phase(
        v,
        0.08 + 0.14 * (k - kLo) / decades,
        0.2 + 0.14 * (k - kLo) / decades,
      );
      canvas.drawLine(
        Offset(x, axisY - 4 * p),
        Offset(x, axisY + 4 * p),
        stroke(soft, 1.2),
      );
      // A decade an item sits on is already labelled by the item itself.
      final taken = items.any((it) => (_log10(it.value) - k).abs() < 0.02);
      if ((k - kLo) % every == 0 && !taken) {
        final tick = layoutText(sayPower(k, lowest: kLo), size: 10, alpha: 0.5);
        drawText(
          canvas,
          tick,
          Offset(x, axisY + 8),
          anchor: const Offset(0.5, 0),
          opacity: p,
        );
      }
    }
    if (d.unit.length > 10) {
      // Only a long unit, which the items leave out, is written here, once,
      // under the tick numbers and clear of the bracket that comes later.
      final unit = layoutText(
        d.unit,
        size: 10,
        weight: FontWeight.w600,
        alpha: 0.5,
      );
      drawText(
        canvas,
        unit,
        Offset(size.width - pad, size.height),
        anchor: const Offset(1, 1),
        opacity: phase(v, 0.2, 0.34),
      );
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

      final name = layoutText(
        item.label,
        size: 11.5,
        alpha: 0.85,
        maxWidth: 140,
        maxLines: 2,
        align: TextAlign.center,
      );
      // A long unit is written once, under the axis; beside each item it
      // would wrap and read badly in the singular ("1 Earth–Sun distances").
      final said = d.unit.length <= 10
          ? sayAmount(item.value, d.unit)
          : sayNumber(item.value);
      final amount = layoutText(said, size: 10.5, alpha: 0.55, maxWidth: 110);
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
      drawText(
        canvas,
        name,
        Offset(box.center.dx, box.top),
        anchor: const Offset(0.5, 0),
        opacity: o,
        rise: 4,
      );
      drawText(
        canvas,
        amount,
        Offset(box.center.dx, box.top + name.height + 2),
        anchor: const Offset(0.5, 0),
        opacity: o,
        rise: 4,
      );
    }

    // The point of the picture: how many times apart the ends are.
    if (items.length >= 2) {
      // From the smallest to the one the card is about (the largest when
      // none is marked): the factor printed is the card's own comparison.
      var j = items.lastIndexWhere((i) => i.highlight);
      if (j <= 0) j = items.length - 1;
      final f = items[j].value / items.first.value;
      final a = points.first + const Offset(0, 30);
      final b = points[j] + const Offset(0, 30);
      final p = phase(v, 0.76, 1);
      if (p > 0) {
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(a.dx, a.dy + 8)
          ..lineTo(b.dx, b.dy + 8)
          ..lineTo(b.dx, b.dy);
        canvas.drawPath(partial(path, phase(p, 0, 0.7)), stroke(mid, 1.3));
        final tp = layoutText(
          sayFactor(f),
          size: 15,
          weight: FontWeight.w600,
          alpha: 0.95,
          display: true,
        );
        drawText(
          canvas,
          tp,
          Offset((a.dx + b.dx) / 2, a.dy + 12),
          anchor: const Offset(0.5, 0),
          opacity: phase(p, 0.45, 1),
          rise: -4,
        );
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
    final maxR = math.min(
      (size.height - labelRoom - 34) / 2,
      size.width / (items.length * 2.3),
    );
    final radii = [
      for (final i in items) math.max(1.6, maxR * math.sqrt(i.value / hi)),
    ];
    // Circles sit side by side, pushed apart where their labels need room.
    final natural = [
      // Name or amount, whichever is wider, plus a little air between.
      for (final i in items)
        math.max(
              layoutText(i.label, size: 11.5, maxLines: 1).width,
              layoutText(sayAmount(i.value, d.unit), size: 10.5).width,
            ) +
            12,
    ];
    final gaps = [
      for (var i = 0; i + 1 < items.length; i++)
        math.max(
          18.0,
          (natural[i] + natural[i + 1]) / 2 + 10 - radii[i] - radii[i + 1],
        ),
    ];
    var totalW =
        radii.fold<double>(0, (s, r) => s + 2 * r) +
        gaps.fold<double>(0, (s, g) => s + g);
    if (totalW > size.width) {
      // Too wide for one line each: close up, and let the labels wrap.
      for (var i = 0; i < gaps.length; i++) {
        gaps[i] = 18;
      }
      totalW = radii.fold<double>(0, (s, r) => s + 2 * r) + 18.0 * gaps.length;
    }
    var x = (size.width - totalW) / 2;
    final base = size.height - labelRoom;
    final anyHighlight = items.any((i) => i.highlight);
    final centres = <Offset>[];
    for (var i = 0; i < items.length; i++) {
      centres.add(Offset(x + radii[i], base - radii[i]));
      x += 2 * radii[i] + (i < gaps.length ? gaps[i] : 0);
    }
    // Each label may run as wide as it can without meeting its neighbour's.
    double room(int i) {
      double w = 2 * math.min(centres[i].dx, size.width - centres[i].dx);
      if (i > 0) w = math.min(w, centres[i].dx - centres[i - 1].dx - 6);
      if (i < items.length - 1) {
        w = math.min(w, centres[i + 1].dx - centres[i].dx - 6);
      }
      return math.max(w, 2 * radii[i]);
    }

    for (var i = 0; i < items.length; i++) {
      final r = radii[i];
      final c = centres[i];
      final start = 0.05 + i * (0.5 / items.length);
      final g = phase(v, start, start + 0.4);
      final strongOne = !anyHighlight || items[i].highlight;
      // The outline is drawn first, then it fills.
      final ring = Path()..addOval(Rect.fromCircle(center: c, radius: r));
      // Not until the pen has somewhere to go: a sliver of an arc reads as
      // a stray speck.
      final pen = phase(g, 0, 0.6);
      if (pen > 0.03) {
        canvas.drawPath(
          partial(ring, pen),
          stroke(strongOne ? strong : mid, 1.4),
        );
      }
      final f = phase(g, 0.4, 1);
      if (f > 0) {
        canvas.drawCircle(c, r * f, fill(inkAt((strongOne ? 0.8 : 0.35) * f)));
      }
      final name = layoutText(
        items[i].label,
        size: 11.5,
        alpha: 0.85,
        maxWidth: math.min(140, room(i)),
        maxLines: 2,
        align: TextAlign.center,
      );
      final amount = layoutText(
        sayAmount(items[i].value, d.unit),
        size: 10.5,
        alpha: 0.55,
      );
      final o = phase(v, start + 0.15, start + 0.3);
      drawText(
        canvas,
        name,
        Offset(c.dx, base + 6),
        anchor: const Offset(0.5, 0),
        opacity: o,
      );
      drawText(
        canvas,
        amount,
        Offset(c.dx, base + 7 + name.height),
        anchor: const Offset(0.5, 0),
        opacity: o,
      );
    }
    if (items.length >= 2) {
      final lo = items.map((i) => i.value).reduce(math.min);
      final a = centres.first - Offset(0, radii.first + 8);
      final b = centres.last - Offset(0, radii.last + 8);
      final top = math.min(a.dy, b.dy);
      factorBracket(
        canvas,
        Offset(a.dx, top),
        Offset(b.dx, top),
        sayFactor(hi / lo),
        phase(v, 0.72, 1),
        lift: 8,
      );
    }
  }
}

// ── split: one whole in its parts ─────────────────────────────────────────

class _SplitPainter extends _DiagramPainter {
  final SplitDiagram d;
  _SplitPainter(this.d, super.t, super.ink);

  static const _barH = 26.0;

  @override
  double heightFor(double width) => _layout(width).height;

  Color _partColour(int i) {
    final anyHighlight = d.parts.any((p) => p.highlight);
    if (anyHighlight) {
      return d.parts[i].highlight
          ? strong
          : [inkAt(0.4), inkAt(0.24), inkAt(0.16)][i % 3];
    }
    return [strong, inkAt(0.55), inkAt(0.32), inkAt(0.18)][i % 4];
  }

  String _share(DiagramItem part) =>
      d.unit == '%' ? '${_sig(part.value)}%' : sayAmount(part.value, d.unit);

  /// Where each part's label hangs: under its own slice where there is
  /// room, otherwise on a lower row or slid sideways, but always with the
  /// slice's leader line landing on the label and crossing no other.
  ({
    List<double> centres,
    List<Rect> boxes,
    List<TextPainter> numbers,
    List<TextPainter> labels,
    double height,
  })
  _layout(double w) {
    final total = d.parts.fold<double>(0, (s, p) => s + p.value);
    final centres = <double>[];
    var x = 0.0;
    for (final part in d.parts) {
      final pw = w * part.value / total;
      centres.add(x + pw / 2);
      x += pw;
    }
    final numbers = [
      for (final p in d.parts)
        layoutText(
          _share(p),
          size: 14,
          weight: FontWeight.w600,
          alpha: 0.95,
          display: true,
        ),
    ];
    final labels = [
      for (final p in d.parts)
        layoutText(
          p.label,
          size: 11,
          weight: p.highlight ? FontWeight.w700 : FontWeight.w500,
          alpha: 0.75,
          maxWidth: 130,
          maxLines: 1,
        ),
    ];
    final boxes = List<Rect>.filled(d.parts.length, Rect.zero);
    final placed = <Rect>[];
    final leaders = <Rect>[];
    // The biggest slices choose first: their labels matter most.
    final order = [for (var i = 0; i < d.parts.length; i++) i]
      ..sort((a, b) => d.parts[b].value.compareTo(d.parts[a].value));
    for (final i in order) {
      final bw = math.max(numbers[i].width, labels[i].width);
      final bh = numbers[i].height + labels[i].height;
      final c = centres[i];
      Rect? chosen;
      Rect? line;
      // First try to keep off every other slice's centre too, so the
      // leaders still to come have a clear way down; then relax that.
      search:
      for (final strict in [true, false]) {
        // A label that must straddle a neighbour's centre goes a row down,
        // so the neighbour's leader can still reach a label above it.
        for (var row = strict ? 0 : 1; row < 5; row++) {
          final top = _barH + 12 + row * (bh + 8);
          // Slide from centred to either side, keeping the leader on the box.
          for (final f in [0.5, 0.3, 0.7, 0.12, 0.88, 0.02, 0.98]) {
            final left = (c - bw * f)
                .clamp(0.0, math.max(0.0, w - bw))
                .toDouble();
            if (c < left + 1 || c > left + bw - 1) continue;
            final box = Rect.fromLTWH(left, top, bw, bh);
            final lead = Rect.fromLTRB(c - 1, _barH + 2, c + 1, top - 1);
            final clash =
                placed.any(
                  (r) =>
                      r.inflate(4).overlaps(box) || r.inflate(2).overlaps(lead),
                ) ||
                leaders.any((l) => l.inflate(3).overlaps(box)) ||
                (strict &&
                    [
                      for (var j = 0; j < centres.length; j++)
                        if (j != i) centres[j],
                    ].any((cj) => cj > box.left - 4 && cj < box.right + 4));
            if (!clash) {
              chosen = box;
              line = lead;
              break search;
            }
          }
        }
      }
      chosen ??= Rect.fromLTWH(
        (c - bw / 2).clamp(0.0, math.max(0.0, w - bw)),
        _barH + 12,
        bw,
        bh,
      );
      line ??= Rect.fromLTRB(c - 1, _barH + 2, c + 1, chosen.top - 1);
      boxes[i] = chosen;
      placed.add(chosen);
      leaders.add(line);
    }
    final height =
        placed.fold<double>(_barH, (m, r) => math.max(m, r.bottom)) + 8;
    return (
      centres: centres,
      boxes: boxes,
      numbers: numbers,
      labels: labels,
      height: height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final total = d.parts.fold<double>(0, (s, p) => s + p.value);
    final w = size.width;
    final layout = _layout(w);
    // The whole, as an empty track, then filled part by part.
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w * phase(v, 0, 0.2), _barH),
      const Radius.circular(8),
    );
    canvas.drawRRect(track, fill(faint));
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, _barH),
        const Radius.circular(8),
      ),
    );
    var x = 0.0;
    for (var i = 0; i < d.parts.length; i++) {
      final pw = w * d.parts[i].value / total;
      final start = 0.18 + i * (0.5 / d.parts.length);
      final g = phase(v, start, start + 0.3);
      canvas.drawRect(Rect.fromLTWH(x, 0, pw * g, _barH), fill(_partColour(i)));
      x += pw;
    }
    canvas.restore();

    for (var i = 0; i < d.parts.length; i++) {
      final box = layout.boxes[i];
      final c = layout.centres[i];
      final start = 0.18 + i * (0.5 / d.parts.length) + 0.18;
      final o = phase(v, start, start + 0.16);
      canvas.drawLine(
        Offset(c, _barH + 2),
        Offset(c, box.top - 1),
        stroke(inkAt(0.25 * o), 1),
      );
      drawText(canvas, layout.numbers[i], box.topLeft, opacity: o, rise: 4);
      drawText(
        canvas,
        layout.labels[i],
        box.topLeft + Offset(0, layout.numbers[i].height),
        opacity: o,
        rise: 4,
      );
    }
  }
}

// ── line: a quantity changing along another ───────────────────────────────

class _LinePainter extends _DiagramPainter {
  final LineDiagram d;
  _LinePainter(this.d, super.t, super.ink);

  @override
  double heightFor(double width) => 200;

  List<double> _ticks(DiagramAxis a, {bool whole = false}) {
    if (a.log) {
      final lo = (_log10(a.min) - 1e-9).ceil();
      final hi = (_log10(a.max) + 1e-9).floor();
      // Thinned when there are many decades, so the labels keep apart.
      final every = hi - lo <= 7
          ? 1
          : (hi - lo) <= 14
          ? 2
          : (hi - lo) <= 28
          ? 5
          : 10;
      return [
        for (var k = lo; k <= hi; k++)
          if ((k - lo) % every == 0) math.pow(10.0, k).toDouble(),
      ];
    }
    final span = a.max - a.min;
    final raw = span / 4;
    final mag = math.pow(10, (_log10(raw)).floor()).toDouble();
    final stepRaw = [
      1,
      2,
      5,
      10,
    ].map((m) => m * mag).firstWhere((s) => span / s <= 6);
    // Counts (siblings, days, doses) get whole-number ticks only.
    final step = whole ? math.max(1.0, stepRaw.roundToDouble()) : stepRaw;
    final first = (a.min / step).ceil() * step;
    return [for (var x = first; x <= a.max + step * 1e-9; x += step) x];
  }

  double _norm(DiagramAxis a, double v) => a.log
      ? (_log10(v) - _log10(a.min)) / (_log10(a.max) - _log10(a.min))
      : (v - a.min) / (a.max - a.min);

  String _tickLabel(DiagramAxis a, double v) {
    if (a.log) {
      return sayPower(_log10(v).round(), lowest: (_log10(a.min) - 1e-9).ceil());
    }
    // Years are written without a thousands comma.
    if (a.min >= 1000 && a.max <= 2200 && v == v.roundToDouble()) {
      return v.round().toString();
    }
    return sayNumber(v);
  }

  /// How many sample points of the polyline through [pts] fall in [r].
  static int _hits(Rect r, List<Offset> pts) {
    var n = 0;
    for (var k = 0; k + 1 < pts.length; k++) {
      final a = pts[k];
      final b = pts[k + 1];
      final m = math.max(2, ((b - a).distance / 3).ceil());
      for (var j = 0; j <= m; j++) {
        if (r.contains(Offset.lerp(a, b, j / m)!)) n++;
      }
    }
    return n;
  }

  /// The first of [candidates] (top-left corners) where a box of [w]×[h]
  /// stays inside [area] and clear of every curve and every placed box.
  static Rect _place(
    List<Offset> candidates,
    double w,
    double h,
    Rect area,
    List<List<Offset>> curves,
    List<Rect> placed,
  ) {
    // Every candidate is also tried further out; the first clean one wins,
    // or else the one the curves touch least.
    final all = <Offset>[
      ...candidates,
      for (final dx in [0.0, -w * 0.6, w * 0.6])
        for (final dy in const [-16.0, 16.0, -32.0, 32.0, 0.0])
          if (dx != 0 || dy != 0)
            for (final c in candidates) c + Offset(dx, dy),
    ];
    Rect? best;
    var bestScore = 1 << 30;
    for (final c in all) {
      final r = Rect.fromLTWH(
        c.dx.clamp(area.left, math.max(area.left, area.right - w)),
        c.dy.clamp(area.top, math.max(area.top, area.bottom - h)),
        w,
        h,
      );
      final score =
          (placed.any((p) => p.inflate(2).overlaps(r)) ? 100000 : 0) +
          curves.fold<int>(0, (n, pts) => n + _hits(r.inflate(2), pts));
      if (score == 0) return r;
      if (score < bestScore) {
        bestScore = score;
        best = r;
      }
    }
    return best ??
        Rect.fromLTWH(candidates.first.dx, candidates.first.dy, w, h);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final yTicks = _ticks(d.y);
    final yLabelW = yTicks
        .map((y) => layoutText(_tickLabel(d.y, y), size: 10).width)
        .fold<double>(0, math.max);
    final left = yLabelW + 8;
    const top = 24.0;
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
      if (y != d.y.min) {
        canvas.drawLine(
          Offset(left, p.dy),
          Offset(left + (right - left) * tickP, p.dy),
          stroke(inkAt(0.08), 1),
        );
      }
      drawText(
        canvas,
        layoutText(_tickLabel(d.y, y), size: 10, alpha: 0.5),
        Offset(left - 6, p.dy),
        anchor: const Offset(1, 0.5),
        opacity: tickP,
      );
    }
    final wholeX = d.series.every(
      (s) => s.points.every((p) => p.$1 == p.$1.roundToDouble()),
    );
    for (final x in _ticks(d.x, whole: wholeX)) {
      final p = at(x, d.y.min);
      drawText(
        canvas,
        layoutText(_tickLabel(d.x, x), size: 10, alpha: 0.5),
        Offset(p.dx, bottom + 5),
        anchor: const Offset(0.5, 0),
        opacity: tickP,
      );
    }
    if (d.x.label.isNotEmpty) {
      drawText(
        canvas,
        layoutText(d.x.label, size: 10, weight: FontWeight.w600, alpha: 0.55),
        Offset(right, size.height),
        anchor: const Offset(1, 1),
        opacity: tickP,
      );
    }
    if (d.y.label.isNotEmpty) {
      drawText(
        canvas,
        layoutText(d.y.label, size: 10, weight: FontWeight.w600, alpha: 0.55),
        Offset(left + 6, top - 20),
        opacity: tickP,
      );
    }

    // Where everything goes is settled before anything is drawn, so no label
    // lands on a curve, a mark or another label.
    final order = [...d.series]
      ..sort((a, b) => (a.highlight ? 1 : 0) - (b.highlight ? 1 : 0));
    final anyHighlight = d.series.any((s) => s.highlight);
    final curves = [
      for (final s in order) [for (final pt in s.points) at(pt.$1, pt.$2)],
    ];
    // The wash under a curve reaches down to zero, not to an axis that
    // starts below it: negative values must not read as area.
    final floor = d.y.log || d.y.min >= 0 || d.y.max <= 0
        ? bottom
        : at(d.x.min, 0).dy;
    // Labels may use the strip above the plot, beside the y-axis title.
    final plot = Rect.fromLTRB(left + 4, 0, right, bottom - 2);
    final placed = <Rect>[
      // The y-axis title sits in the top-left corner.
      if (d.y.label.isNotEmpty)
        Rect.fromLTWH(
          left + 6,
          top - 20,
          layoutText(d.y.label, size: 10, weight: FontWeight.w600).width,
          14,
        ),
    ];
    final dots = [for (final m in d.marks) at(m.x, m.y)];
    for (final o in dots) {
      placed.add(Rect.fromCircle(center: o, radius: 6));
    }

    // The dashed guides from each mark to the axes are obstacles too.
    final obstacles = [
      ...curves,
      for (final o in dots) [Offset(o.dx, bottom), o],
      for (final o in dots) [Offset(left, o.dy), o],
    ];
    final markText = <TextPainter>[];
    final markBox = <Rect>[];
    for (var i = 0; i < d.marks.length; i++) {
      final o = dots[i];
      final tp = layoutText(
        d.marks[i].label,
        size: 11.5,
        weight: FontWeight.w600,
        alpha: 0.92,
        maxWidth: 170,
        maxLines: 2,
      );
      final w = tp.width;
      final h = tp.height;
      final box = _place(
        [
          o + Offset(8, -8 - h), // above right
          o + Offset(-8 - w, -8 - h), // above left
          o + const Offset(8, 8), // below right
          o + Offset(-8 - w, 8), // below left
          o + Offset(-w / 2, -14 - h), // above
          o + Offset(-w / 2, 12), // below
          o + Offset(8, -30 - h), // higher still
          o + Offset(-8 - w, -30 - h),
        ],
        w,
        h,
        plot,
        obstacles,
        placed,
      );
      placed.add(box);
      markText.add(tp);
      markBox.add(box);
    }

    // Each series is drawn by a moving pen, the highlighted one last.
    for (var i = 0; i < order.length; i++) {
      final s = order[i];
      final start = 0.26 + i * (0.4 / order.length);
      final p = phase(v, start, start + 0.42);
      final pts = curves[i];
      final path = Path();
      for (var k = 0; k < pts.length; k++) {
        k == 0
            ? path.moveTo(pts[k].dx, pts[k].dy)
            : path.lineTo(pts[k].dx, pts[k].dy);
      }
      final strongOne = !anyHighlight || s.highlight;
      final drawn = partial(path, p);
      if (strongOne && order.length == 1 && p > 0) {
        // A faint wash under the one curve, following the pen.
        final tip = drawn.computeMetrics().fold<Offset?>(
          null,
          (_, m) => m.getTangentForOffset(m.length)?.position,
        );
        if (tip != null) {
          final wash = Path.from(drawn)
            ..lineTo(tip.dx, floor)
            ..lineTo(pts.first.dx, floor)
            ..close();
          // It fades in as the pen gets going, so its first sliver is not a bar.
          canvas.drawPath(wash, fill(inkAt(0.07 * phase(p, 0.08, 0.4))));
        }
      }
      canvas.drawPath(
        drawn,
        stroke(strongOne ? strong : mid, strongOne ? 2.6 : 1.8),
      );
      if (p > 0 && p < 1) {
        // The pen itself, while it is still drawing.
        final tip = drawn.computeMetrics().fold<Offset?>(
          null,
          (_, m) => m.getTangentForOffset(m.length)?.position,
        );
        if (tip != null) {
          canvas.drawCircle(
            tip,
            strongOne ? 4.2 : 3.2,
            fill(strongOne ? strong : mid),
          );
          canvas.drawCircle(tip, strongOne ? 8 : 6, fill(inkAt(0.14)));
        }
      }
      if (s.label.isNotEmpty) {
        final tp = layoutText(
          s.label,
          size: 11,
          weight: FontWeight.w600,
          alpha: strongOne ? 0.9 : 0.6,
          maxWidth: 200,
          maxLines: 1,
        );
        final w = tp.width;
        final h = tp.height;
        // Beside the curve somewhere along its second half, above it or below.
        final cands = <Offset>[];
        for (final f in [0.72, 0.55, 0.88, 0.4, 0.25]) {
          final q = _along(
            pts,
            pts.first.dx + (pts.last.dx - pts.first.dx) * f,
          );
          cands
            ..add(q + Offset(4, -8 - h))
            ..add(q + const Offset(4, 8))
            ..add(q + Offset(-w - 4, -8 - h))
            ..add(q + Offset(-w - 4, 8));
        }
        final box = _place(cands, w, h, plot, obstacles, placed);
        placed.add(box);
        drawText(
          canvas,
          tp,
          box.topLeft,
          opacity: phase(v, start + 0.34, start + 0.46),
        );
      }
    }

    // Marks: the points the card is about, with their guide lines.
    for (var i = 0; i < d.marks.length; i++) {
      final start = 0.74 + i * (0.18 / d.marks.length);
      final p = pop(v, start, start + 0.12);
      if (p <= 0) continue;
      final o = dots[i];
      _dashed(canvas, Offset(o.dx, bottom), o, phase(v, start, start + 0.1));
      _dashed(canvas, Offset(left, o.dy), o, phase(v, start, start + 0.1));
      canvas.drawCircle(o, 4.5 * p, fill(strong));
      drawText(
        canvas,
        markText[i],
        markBox[i].topLeft,
        opacity: phase(v, start + 0.04, start + 0.14),
        rise: 4,
      );
    }
  }

  /// The point on the drawn polyline [pts] at screen x [x].
  static Offset _along(List<Offset> pts, double x) {
    for (var k = 0; k + 1 < pts.length; k++) {
      final a = pts[k];
      final b = pts[k + 1];
      if (x >= a.dx && x <= b.dx) {
        return Offset.lerp(
          a,
          b,
          b.dx == a.dx ? 0 : (x - a.dx) / (b.dx - a.dx),
        )!;
      }
    }
    return pts.last;
  }

  void _dashed(Canvas canvas, Offset a, Offset b, double p) {
    if (p <= 0) return;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(a.dx + (b.dx - a.dx) * p, a.dy + (b.dy - a.dy) * p);
    for (final m in path.computeMetrics()) {
      for (var s = 0.0; s < m.length; s += 6) {
        canvas.drawPath(
          m.extractPath(s, math.min(s + 3, m.length)),
          stroke(inkAt(0.35), 1),
        );
      }
    }
  }
}

// ── timeline: when ────────────────────────────────────────────────────────

class _TimelinePainter extends _DiagramPainter {
  final TimelineDiagram d;
  _TimelinePainter(this.d, super.t, super.ink);

  static const _pad = 10.0;

  @override
  double heightFor(double width) {
    final l = _layout(width);
    return l.rise + l.fall;
  }

  double _xOf(double y, double width) =>
      _pad + (width - 2 * _pad) * ((y - d.from) / (d.to - d.from));

  /// Where every label goes, as boxes whose y is measured from the axis
  /// (negative above it). Event labels sit above the line where they fit
  /// and below it where they would collide, on a stalk that never crosses
  /// another label; span labels and the end years sit just under the line.
  ({
    List<Rect> boxes,
    List<TextPainter> whats,
    List<TextPainter> whens,
    List<Rect> spanBoxes,
    List<TextPainter> spanText,
    double rise,
    double fall,
  })
  _layout(double width) {
    final placed = <Rect>[];
    final stalks = <Rect>[];
    // The end years.
    final a = layoutText(year(d.from), size: 10, alpha: 0.5);
    final b = layoutText(year(d.to), size: 10, alpha: 0.5);
    placed
      ..add(Rect.fromLTWH(_pad, 8, a.width, a.height))
      ..add(Rect.fromLTWH(width - _pad - b.width, 8, b.width, b.height));
    final events = [...d.events]..sort((a, b) => a.at.compareTo(b.at));
    final boxes = <Rect>[];
    final whats = <TextPainter>[];
    final whens = <TextPainter>[];
    for (final e in events) {
      final x = _xOf(e.at, width);
      final when = layoutText(
        year(e.at),
        size: 10.5,
        weight: FontWeight.w600,
        alpha: 0.6,
      );
      final what = layoutText(
        e.label,
        size: 11.5,
        weight: e.highlight ? FontWeight.w700 : FontWeight.w500,
        alpha: e.highlight ? 0.95 : 0.8,
        maxWidth: 150,
        maxLines: 2,
        align: TextAlign.center,
      );
      final w = math.max(when.width, what.width);
      final h = when.height + what.height;
      Rect? chosen;
      Rect? stalk;
      // Nearest first: just above, just below, then further out each way;
      // at each height the label may also slide, as long as its own stalk
      // still lands on it.
      for (var k = 0; k < 16 && chosen == null; k++) {
        for (final f in const [0.5, 0.3, 0.7, 0.1, 0.9]) {
          if (chosen != null) break;
          final left = (x - w * f).clamp(0.0, width - w).toDouble();
          if (x < left + 2 || x > left + w - 2) continue;
          final above = k.isEven;
          final step = (k ~/ 2) * 10.0;
          final box = above
              ? Rect.fromLTWH(left, -14 - step - h, w, h)
              : Rect.fromLTWH(left, 14 + step, w, h);
          final line = above
              ? Rect.fromLTRB(x - 1, box.bottom, x + 1, -6)
              : Rect.fromLTRB(x - 1, 6, x + 1, box.top);
          final clash =
              placed.any(
                (p) =>
                    p.inflate(3).overlaps(box) || p.inflate(2).overlaps(line),
              ) ||
              stalks.any((s) => s.inflate(3).overlaps(box));
          if (!clash) {
            chosen = box;
            stalk = line;
          }
        }
      }
      chosen ??= Rect.fromLTWH(
        (x - w / 2).clamp(0.0, width - w).toDouble(),
        -14 - h,
        w,
        h,
      );
      stalk ??= Rect.fromLTRB(x - 1, chosen.bottom, x + 1, -6);
      placed.add(chosen);
      stalks.add(stalk);
      boxes.add(chosen);
      whats.add(what);
      whens.add(when);
    }

    // Span labels last, in whatever room is left nearest their bands: under
    // the band, over it, nudged sideways, never across a stalk.
    final spanBoxes = <Rect>[];
    final spanText = <TextPainter>[];
    for (final s in d.spans) {
      final x0 = _xOf(s.from, width);
      final x1 = _xOf(s.to, width);
      final tp = layoutText(
        s.label,
        size: 11,
        weight: FontWeight.w600,
        alpha: 0.8,
        maxWidth: math.max(80, x1 - x0 + 40),
        maxLines: 1,
      );
      final centre = (x0 + x1) / 2 - tp.width / 2;
      Rect? chosen;
      search:
      for (var row = 0; row < 8; row++) {
        final ys = [12.0 + 14 * row, -12.0 - tp.height - 14 * row];
        for (final y in ys) {
          for (final dx in [0.0, 30, -30, 60, -60, 90, -90]) {
            final r = Rect.fromLTWH(
              (centre + dx).clamp(0.0, width - tp.width),
              y,
              tp.width,
              tp.height,
            );
            if (!placed.any((p) => p.inflate(3).overlaps(r)) &&
                !stalks.any((l) => l.inflate(2).overlaps(r))) {
              chosen = r;
              break search;
            }
          }
        }
      }
      chosen ??= Rect.fromLTWH(
        centre.clamp(0.0, width - tp.width),
        12,
        tp.width,
        tp.height,
      );
      placed.add(chosen);
      spanBoxes.add(chosen);
      spanText.add(tp);
    }

    final rise = placed.fold<double>(20, (m, r) => math.max(m, -r.top)) + 6;
    // Room for descenders and for the small drift a label makes as it lands.
    final fall = placed.fold<double>(24, (m, r) => math.max(m, r.bottom)) + 10;
    return (
      boxes: boxes,
      whats: whats,
      whens: whens,
      spanBoxes: spanBoxes,
      spanText: spanText,
      rise: rise,
      fall: fall,
    );
  }

  /// A point on the line as a reader says it: a year by default, or a
  /// number of the diagram's own unit (12 min, day 3) when it has one.
  String year(double y) {
    if (d.unit.isNotEmpty) return sayAmount(y, d.unit);
    return _year(y);
  }

  static String _year(double y) {
    // August 2029 is still 2029.
    final n = y.floor();
    if (n < 0) return '${_commas(-n)} BC';
    if (n < 1000) return 'AD $n';
    return n.toString();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    const pad = _pad;
    final layout = _layout(size.width);
    final axisY = layout.rise;
    double xOf(double y) =>
        pad + (size.width - 2 * pad) * ((y - d.from) / (d.to - d.from));

    canvas.drawPath(
      partial(
        Path()
          ..moveTo(pad, axisY)
          ..lineTo(size.width - pad, axisY),
        phase(v, 0, 0.24),
      ),
      stroke(soft, 1.6),
    );
    final ends = phase(v, 0.12, 0.28);
    drawText(
      canvas,
      layoutText(year(d.from), size: 10, alpha: 0.5),
      Offset(pad, axisY + 8),
      opacity: ends,
    );
    drawText(
      canvas,
      layoutText(year(d.to), size: 10, alpha: 0.5),
      Offset(size.width - pad, axisY + 8),
      anchor: const Offset(1, 0),
      opacity: ends,
    );

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
      final box = layout.spanBoxes[i].shift(Offset(0, axisY));
      final so = phase(v, start + 0.2, start + 0.34);
      final from = Offset(
        (box.center.dx).clamp(x0 + 3, math.max(x0 + 3, x1 - 3)),
        box.top > axisY ? axisY + 6 : axisY - 6,
      );
      final to = Offset(
        from.dx.clamp(box.left + 4, box.right - 4),
        box.top > axisY ? box.top - 2 : box.bottom + 2,
      );
      // A label that had to move away from its band keeps a thread to it.
      if ((to - from).distance > 14) {
        canvas.drawLine(from, to, stroke(inkAt(0.22 * so), 1));
      }
      drawText(canvas, layout.spanText[i], box.topLeft, opacity: so);
    }

    // Moments drop in, one after another, each with its label on a stalk.
    final anyHighlight = d.events.any((e) => e.highlight);
    final events = [...d.events]..sort((a, b) => a.at.compareTo(b.at));
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      final x = xOf(e.at);
      final start = 0.38 + i * (0.44 / math.max(1, events.length));
      final p = pop(v, start, start + 0.14);
      final strongOne = !anyHighlight || e.highlight;
      canvas.drawCircle(
        Offset(x, axisY),
        5 * p,
        fill(strongOne ? strong : mid),
      );
      final when = layout.whens[i];
      final what = layout.whats[i];
      final box = layout.boxes[i].shift(Offset(0, axisY));
      final o = phase(v, start + 0.04, start + 0.16);
      if (box.bottom <= axisY) {
        // Above the line: what happened, then the year, then the stalk.
        canvas.drawLine(
          Offset(x, axisY - 6),
          Offset(x, box.bottom + 2),
          stroke(inkAt(0.2 * o), 1),
        );
        drawText(
          canvas,
          what,
          Offset(box.center.dx, box.top),
          anchor: const Offset(0.5, 0),
          opacity: o,
          rise: 4,
        );
        drawText(
          canvas,
          when,
          Offset(box.center.dx, box.top + what.height),
          anchor: const Offset(0.5, 0),
          opacity: o,
          rise: 4,
        );
      } else {
        // Below it, mirrored: the year nearest the line.
        canvas.drawLine(
          Offset(x, axisY + 6),
          Offset(x, box.top - 2),
          stroke(inkAt(0.2 * o), 1),
        );
        drawText(
          canvas,
          when,
          Offset(box.center.dx, box.top),
          anchor: const Offset(0.5, 0),
          opacity: o,
          rise: -4,
        );
        drawText(
          canvas,
          what,
          Offset(box.center.dx, box.top + when.height),
          anchor: const Offset(0.5, 0),
          opacity: o,
          rise: -4,
        );
      }
    }
  }
}

// ── tree: a crowd split, and split again, in counts ───────────────────────

class _TreePainter extends _DiagramPainter {
  final TreeDiagram d;
  _TreePainter(this.d, super.t, super.ink);

  static const _levelH = 96.0;
  static const _blockH = 50.0;

  @override
  double heightFor(double width) => d.root.depth * _levelH + _blockH + 6;

  /// Every node with where it sits: leaves share the width evenly, in
  /// order; a parent sits over the middle of its children.
  List<({TreeNode node, TreeNode? parent, int depth, double x})> _layout(
    double width,
  ) {
    final leaves = <TreeNode>[];
    void collect(TreeNode n) =>
        n.children.isEmpty ? leaves.add(n) : n.children.forEach(collect);
    collect(d.root);
    final slot = width / leaves.length;
    final out = <({TreeNode node, TreeNode? parent, int depth, double x})>[];
    double place(TreeNode n, TreeNode? parent, int depth) {
      final double x;
      if (n.children.isEmpty) {
        x = (leaves.indexOf(n) + 0.5) * slot;
      } else {
        final xs = [for (final c in n.children) place(c, n, depth + 1)];
        x = (xs.first + xs.last) / 2;
      }
      out.add((node: n, parent: parent, depth: depth, x: x));
      return x;
    }

    place(d.root, null, 0);
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final nodes = _layout(size.width);
    final xOf = {for (final e in nodes) e.node: e.x};
    final leafCount = nodes.where((e) => e.node.children.isEmpty).length;
    final slot = size.width / leafCount;
    final total = d.root.n;
    // Which nodes lie on the way to something highlighted, so the eye can
    // follow the path down to it.
    final onPath = <TreeNode>{};
    bool mark(TreeNode n) {
      var hit = n.highlight;
      for (final c in n.children) {
        if (mark(c)) hit = true;
      }
      if (hit) onPath.add(n);
      return hit;
    }

    final anyHighlight = mark(d.root);
    final depthMax = math.max(1, d.root.depth);
    double linkStart(int depth) => 0.12 + (0.62 / depthMax) * (depth - 1);
    final linkLen = 0.62 / depthMax * 0.8;

    // Links first, beneath the numbers: each drawn from parent to child by
    // the pen, as thick as the share of the crowd it carries.
    for (final e in nodes) {
      final parent = e.parent;
      if (parent == null) continue;
      final a = Offset(xOf[parent]!, (e.depth - 1) * _levelH + _blockH + 2);
      final b = Offset(e.x, e.depth * _levelH - 4);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, a.dy + 26, b.dx, b.dy - 26, b.dx, b.dy);
      final start = linkStart(e.depth);
      final p = phase(v, start, start + linkLen);
      final w = 1.3 + 7 * math.sqrt(e.node.n / total);
      final emphasised = !anyHighlight || onPath.contains(e.node);
      final colour = emphasised ? inkAt(0.42) : inkAt(0.16);
      canvas.drawPath(
        partial(path, p),
        stroke(colour, w)..strokeCap = StrokeCap.butt,
      );
    }

    // The nodes: a number that counts up as it arrives, and what it counts.
    for (final e in nodes) {
      final n = e.node;
      final top = e.depth * _levelH;
      final start = e.depth == 0 ? 0.0 : linkStart(e.depth) + linkLen * 0.7;
      final o = phase(v, start, start + 0.14);
      if (o <= 0) continue;
      // A split is a fixed partition, so each count arrives whole rather
      // than rising past its own parent.
      final count = n.n;
      final strongOne = !anyHighlight || n.highlight || e.depth == 0;
      final alpha = strongOne
          ? 0.95
          : onPath.contains(n)
          ? 0.75
          : 0.5;
      final maxW = e.depth == 0 ? size.width * 0.7 : slot - 6;
      final number = layoutText(
        sayNumber(count),
        size: 19,
        weight: FontWeight.w600,
        alpha: alpha,
        display: true,
      );
      final label = layoutText(
        n.label,
        size: 11,
        weight: n.highlight ? FontWeight.w700 : FontWeight.w500,
        alpha: alpha * 0.85,
        maxWidth: maxW,
        maxLines: 2,
        align: TextAlign.center,
      );
      final x = e.x.clamp(maxW / 2, size.width - maxW / 2);
      if (n.highlight) {
        // The count the card is about gets a ground of its own.
        final g = phase(v, 0.78, 0.94);
        final w = math.max(number.width, label.width) + 14;
        final box = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, top + (number.height + label.height) / 2),
            width: w,
            height: number.height + label.height + 8,
          ),
          const Radius.circular(8),
        );
        if (g > 0) canvas.drawRRect(box, fill(inkAt(0.12 * g)));
        if (g > 0) canvas.drawRRect(box, stroke(inkAt(0.5 * g), 1.2));
      }
      drawText(
        canvas,
        number,
        Offset(x, top),
        anchor: const Offset(0.5, 0),
        opacity: o,
        rise: 5,
      );
      drawText(
        canvas,
        label,
        Offset(x, top + number.height),
        anchor: const Offset(0.5, 0),
        opacity: o,
        rise: 5,
      );
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
  bool caption = false,
}) async {
  final painter = _painterFor(d, AlwaysStoppedAnimation(at), ink);
  final h = painter.heightFor(width);
  // The caption as the card sets it: under the picture, fading in at the end.
  TextPainter? words;
  if (caption && d.caption.isNotEmpty) {
    words = TextPainter(
      text: TextSpan(
        text: d.caption,
        style: AppText.body(
          size: 12,
          height: 1.4,
          color: ink.withValues(alpha: 0.62),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
  }
  final extra = words == null ? 0.0 : 8 + words.height;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(pixelRatio);
  final full = Size(width + 2 * margin, h + extra + 2 * margin);
  if (ground != null) {
    canvas.drawRect(Offset.zero & full, Paint()..color = ground);
  }
  canvas.translate(margin, margin);
  painter.paint(canvas, Size(width, h));
  if (words != null) {
    final o = Curves.easeOut.transform(((at - 0.7) / 0.3).clamp(0.0, 1.0));
    if (o > 0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, h, width, extra + 4),
        Paint()..color = Color.fromRGBO(0, 0, 0, o),
      );
      words.paint(canvas, Offset(0, h + 8));
      canvas.restore();
    }
  }
  return recorder.endRecording().toImage(
    (full.width * pixelRatio).ceil(),
    (full.height * pixelRatio).ceil(),
  );
}

/// How long a diagram's animation runs on the card.
Duration diagramDuration(Diagram d) => _DiagramViewState._durationOf(d);

/// The height a diagram takes at [width], without its caption.
double diagramHeight(Diagram d, double width) => _painterFor(
  d,
  const AlwaysStoppedAnimation(1),
  const Color(0xFF000000),
).heightFor(width);
