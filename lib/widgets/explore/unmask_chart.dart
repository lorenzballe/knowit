import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../analytics.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import 'parts.dart';

/// Unmask the chart — artboard 138d, drawn from the bank's own charts.
///
/// Every chart here ran somewhere, headline and all, and tells the truth in
/// its numbers and a lie in its drawing: an axis cut off, a window cropped
/// out of a longer run, totals where a rate was fair, a scale turned upside
/// down. One button turns it into its honest self from the same numbers,
/// the bars sliding to their real lengths, and the card names the trick and
/// the line that catches it next time. The card behind it plays the full
/// version, where the reader finds the trick on their own.
class UnmaskRow extends StatelessWidget {
  const UnmaskRow({
    super.key,
    required this.pills,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return SideRow(
      height: 424,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        return _ChartCard(pill: p, onOpen: () => onOpen(pills, p));
      },
    );
  }
}

class _ChartCard extends StatefulWidget {
  const _ChartCard({required this.pill, required this.onOpen});

  final Pill pill;
  final VoidCallback onOpen;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _toggle() {
    final TrickScene s = widget.pill.scene as TrickScene;
    if (_t.value < 0.5) {
      Analytics.capture('explore chart unmasked', {
        'pill_id': widget.pill.id,
        'trick': s.trick.name,
      });
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _t.value = _t.value < 0.5 ? 1 : 0;
      setState(() {});
      return;
    }
    _t.value < 0.5 ? _t.forward() : _t.reverse();
    setState(() {});
  }

  String _button(BuildContext context, TrickScene s) {
    final l = context.l10n;
    return switch (s.trick) {
      TrickSceneKind.truncated => l.unmaskTruncated,
      TrickSceneKind.stretched => l.unmaskStretched,
      TrickSceneKind.window => l.unmaskWindow,
      TrickSceneKind.flipped => l.unmaskFlipped,
      _ => l.unmaskTotals,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Pill p = widget.pill;
    final TrickScene s = p.scene as TrickScene;
    final l = context.l10n;
    return CardTap(
      pill: p,
      onTap: widget.onOpen,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final bool honest = _t.value >= 0.5;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHead(
                  pill: p,
                  label: s.outlet.isEmpty ? null : '${p.topic} · ${s.outlet}',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topLeft,
                      children: [...previous, ?current],
                    ),
                    child: Align(
                      key: ValueKey(honest),
                      alignment: Alignment.topLeft,
                      child: CardQuestion(
                        text: honest ? s.honest : s.headline,
                        color: p.ink,
                        min: 13,
                        max: 20,
                        height: 1.12,
                        tracking: -0.03,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  honest && s.honestLabel.isNotEmpty ? s.honestLabel : s.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 11.5,
                    weight: FontWeight.w600,
                    height: 1.2,
                    color: subOn(p),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _ChartPainter(
                      scene: s,
                      t: Curves.easeInOutCubic.transform(_t.value),
                      ink: p.ink,
                      faint: hairOn(p),
                      tone: shade(p.color, 0.82),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 70,
                  child: honest
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: p.ink,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                upper(context, s.name),
                                style: AppText.label(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  spacing: 1,
                                  height: 1,
                                  color: p.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Expanded(
                              child: Text(
                                s.lesson,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  height: 1.3,
                                  color: p.ink,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          l.lookFirst,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w500,
                            height: 1.35,
                            color: p.ink,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                FlatButton(
                  key: ValueKey('unmask-${p.id}'),
                  label: honest ? l.unmaskBack : _button(context, s),
                  background: p.ink,
                  foreground: p.color,
                  height: 36,
                  size: 12.5,
                  onTap: _toggle,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The chart, published at t = 0 and honest at t = 1, everything in between
/// a slide from one to the other: the axis's ends, the window's edges, a
/// bar's length, a scale turning over.
class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.scene,
    required this.t,
    required this.ink,
    required this.faint,
    required this.tone,
  });

  final TrickScene scene;
  final double t;
  final Color ink;
  final Color faint;
  final Color tone;

  String _fmt(double v, {required bool honest}) {
    final TrickScene s = scene;
    final bool rate = honest && s.trick == TrickSceneKind.totals;
    final int dp = rate ? s.honestDecimals : s.decimals;
    final String unit = rate ? s.honestUnit : s.unit;
    final String n = v.toStringAsFixed(dp);
    if (unit.isEmpty) return n;
    if (const {'€', r'$', '£', '¥'}.contains(unit)) return '$unit$n';
    if (unit == '%') return '$n%';
    return '$n $unit';
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    double size = 9.5,
    FontWeight weight = FontWeight.w600,
    Color? color,
    TextAlign align = TextAlign.left,
    double? maxWidth,
  }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: AppText.body(
          size: size,
          weight: weight,
          height: 1,
          color: color ?? ink.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final double dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy));
    tp.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final TrickScene s = scene;
    final int n = s.count;
    final bool honest = t >= 0.5;

    // The value axis, sliding from the published range to the fair one.
    final double lo = lerpDouble(s.shown.lo, s.fair.lo, t)!;
    final double hi = lerpDouble(s.shown.hi, s.fair.hi, t)!;

    // As wide as its widest number, so "43.0 °C" is not cut to "43.0 …".
    double widest = 0;
    for (int k = 0; k <= 2; k++) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: _fmt(lo + (hi - lo) * k / 2, honest: honest),
          style: AppText.body(size: 9, weight: FontWeight.w600, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      widest = math.max(widest, tp.width);
      tp.dispose();
    }
    final double axisW = (widest + 10).clamp(26.0, 72.0);
    const double bottomH = 16;
    final Rect plot = Rect.fromLTWH(
      axisW,
      14,
      size.width - axisW,
      size.height - 14 - bottomH,
    );

    // The columns in view, opening from the window to the whole run.
    final double firstCol = lerpDouble(s.first.toDouble(), 0, t)!;
    final double lastCol = lerpDouble(
      s.last.toDouble(),
      (n - 1).toDouble(),
      t,
    )!;
    final double span = math.max(1e-6, lastCol - firstCol);

    final bool flipped = s.trick == TrickSceneKind.flipped;
    double norm(double v, double a, double b) =>
        ((v - a) / math.max(1e-9, b - a)).clamp(0, 1);
    double y(double nv) {
      final double up = plot.bottom - nv * plot.height;
      if (!flipped) return up;
      final double down = plot.top + nv * plot.height;
      return lerpDouble(down, up, t)!;
    }

    // Gridlines and the axis's numbers: bottom, middle, top.
    final Paint grid = Paint()
      ..color = faint
      ..strokeWidth = 1;
    for (int k = 0; k <= 2; k++) {
      final double nv = k / 2;
      final double gy = y(nv);
      canvas.drawLine(Offset(plot.left, gy), Offset(plot.right, gy), grid);
      final double value = lo + (hi - lo) * nv;
      _text(
        canvas,
        _fmt(value, honest: honest),
        Offset(axisW - 6, gy - 5),
        align: TextAlign.right,
        maxWidth: axisW - 4,
        size: 9,
      );
    }

    canvas.save();
    canvas.clipRect(plot.inflate(2));
    final bool bars = s.form == TrickSceneForm.bars;
    final List<double> published = s.values;
    final List<double> fair = s.honestValues;
    double heightOf(int i) {
      final double a = norm(published[i], s.shown.lo, s.shown.hi);
      final double b = norm(fair[i], s.fair.lo, s.fair.hi);
      // A total turns into its rate; everything else keeps its value and
      // only the axis under it moves.
      if (s.trick == TrickSceneKind.totals) return lerpDouble(a, b, t)!;
      return norm(published[i], lo, hi);
    }

    double xOf(double col) => plot.left + (col - firstCol) / span * plot.width;

    if (bars) {
      final double slot = plot.width / (span + 1);
      final double bw = math.min(46, slot * 0.58);
      for (int i = 0; i < n; i++) {
        final double cx =
            plot.left + (i - firstCol + 0.5) / (span + 1) * plot.width;
        if (cx < plot.left - bw || cx > plot.right + bw) continue;
        final double top = y(heightOf(i));
        final double base = y(0);
        final Rect r = Rect.fromLTRB(
          cx - bw / 2,
          math.min(top, base),
          cx + bw / 2,
          math.max(top, base),
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            r,
            topLeft: const Radius.circular(6),
            topRight: const Radius.circular(6),
          ),
          Paint()..color = i == n - 1 || i == s.last ? ink : tone,
        );
        _text(
          canvas,
          _fmt(honest ? fair[i] : published[i], honest: honest),
          Offset(cx, r.top - 12),
          align: TextAlign.center,
          size: 10,
          weight: FontWeight.w700,
          color: ink,
        );
      }
    } else {
      final Path path = Path();
      bool started = false;
      for (int i = 0; i < n; i++) {
        final Offset o = Offset(xOf(i.toDouble()), y(heightOf(i)));
        if (!started) {
          path.moveTo(o.dx, o.dy);
          started = true;
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      final int every = math.max(1, (n / 12).ceil());
      for (int i = 0; i < n; i += every) {
        canvas.drawCircle(
          Offset(xOf(i.toDouble()), y(heightOf(i))),
          2.6,
          Paint()..color = ink,
        );
      }
    }
    canvas.restore();

    // The columns' names along the bottom: all of them for bars, the two
    // ends for a line.
    final double ly = plot.bottom + 4;
    if (bars) {
      for (int i = 0; i < n; i++) {
        final double cx =
            plot.left + (i - firstCol + 0.5) / (span + 1) * plot.width;
        if (cx < plot.left || cx > plot.right) continue;
        _text(
          canvas,
          s.columns[i],
          Offset(cx, ly),
          align: TextAlign.center,
          size: 9,
          maxWidth: plot.width / (span + 1) + 6,
        );
      }
    } else {
      final int a = firstCol.round().clamp(0, n - 1);
      final int b = lastCol.round().clamp(0, n - 1);
      _text(canvas, s.columns[a], Offset(plot.left, ly), size: 9);
      _text(
        canvas,
        s.columns[b],
        Offset(plot.right, ly),
        align: TextAlign.right,
        size: 9,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.t != t || old.scene != scene || old.ink != ink;
}
