import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
import '../theme.dart';

/// A guess made by putting a mark on a ruler rather than by typing.
///
/// An estimate is a feel for size, and a ruler is where that feel lives:
/// dragging past "a hundred" towards "a thousand" is the judgement itself,
/// where a keyboard asks for digits the reader does not have. The ruler is
/// logarithmic, four powers of ten long, and placed so the true answer is
/// never at its middle — the layout must not give the answer away.
class EstimateRuler {
  final double low;
  final double high;

  const EstimateRuler(this.low, this.high);

  /// Four decades around [answer], shifted by an amount fixed per card.
  factory EstimateRuler.around(num answer, String seed) {
    final a = answer.toDouble().abs().clamp(1e-9, double.infinity);
    // A stable offset from the card id: the same card gets the same ruler
    // on every phone and every visit, and different cards get different
    // ones, so "the answer sits a third of the way along" is not a pattern.
    final h = seed.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff);
    final below = 1.25 + (h % 1000) / 1000 * 1.5; // decades under the answer
    return EstimateRuler(
      a / math.pow(10, below).toDouble(),
      a * math.pow(10, 4 - below).toDouble(),
    );
  }

  double get _l => math.log(low) / math.ln10;
  double get _h => math.log(high) / math.ln10;

  /// 0..1 along the ruler for a value, and back.
  double at(num v) =>
      ((math.log(math.max(v.toDouble(), 1e-12)) / math.ln10 - _l) / (_h - _l))
          .clamp(0.0, 1.0);
  double valueAt(double t) =>
      math.pow(10, _l + (_h - _l) * t.clamp(0.0, 1.0)).toDouble();

  /// The powers of ten that fall on the ruler, for the ticks.
  List<double> get decades => [
    for (var e = _l.ceil(); e <= _h.floor(); e++) math.pow(10, e).toDouble(),
  ];
}

/// Two significant figures, said the way a person would: 5.6, 560, 5,600,
/// 5.6 million. A guess is not a measurement and should not look like one.
String roughNumber(double v) {
  if (v <= 0) return '0';
  final mag = (math.log(v) / math.ln10).floor();
  final rounded = (v / math.pow(10, mag - 1)).round() * math.pow(10, mag - 1);
  String plain(double x) {
    if (x >= 100) {
      final s = x.round().toString();
      final out = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
        out.write(s[i]);
      }
      return out.toString();
    }
    final s = x.toStringAsFixed(x >= 10 ? 0 : (x >= 1 ? 1 : (-mag + 1)));
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  for (final (size, word) in [
    (1e12, 'trillion'),
    (1e9, 'billion'),
    (1e6, 'million'),
  ]) {
    if (rounded >= size) return '${plain(rounded / size)} $word';
  }
  return plain(rounded.toDouble());
}

String _tick(double v) {
  if (v >= 1e12) return '${(v / 1e12).round()}T';
  if (v >= 1e9) return '${(v / 1e9).round()}B';
  if (v >= 1e6) return '${(v / 1e6).round()}M';
  if (v >= 1e3) return '${(v / 1e3).round()}k';
  return roughNumber(v);
}

/// The input: a big readout, the ruler, and a button to lock the guess.
class PlaceItInput extends StatefulWidget {
  final Pill pill;
  final Estimate estimate;
  final ValueChanged<String>? onAnswer;

  const PlaceItInput({
    super.key,
    required this.pill,
    required this.estimate,
    required this.onAnswer,
  });

  @override
  State<PlaceItInput> createState() => _PlaceItInputState();
}

class _PlaceItInputState extends State<PlaceItInput> {
  late final EstimateRuler _ruler = EstimateRuler.around(
    widget.estimate.answer,
    widget.pill.id,
  );
  double _t = 0.5;
  bool _moved = false;
  int _lastDecade = 0;

  void _drag(double x, double width) {
    final t = (x / width).clamp(0.0, 1.0);
    final decade = (math.log(_ruler.valueAt(t)) / math.ln10).floor();
    if (decade != _lastDecade) {
      // A click at every power of ten: the hand feels the scale change.
      HapticFeedback.selectionClick();
      _lastDecade = decade;
    }
    setState(() {
      _t = t;
      _moved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final value = _ruler.valueAt(_t);
    final unit = widget.estimate.unit;
    final canLock = _moved && widget.onAnswer != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _moved ? 1 : 0.4,
                child: Text(
                  _moved ? roughNumber(value) : '?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(
                    size: 34,
                    weight: FontWeight.w800,
                    height: 1,
                    spacing: -1,
                    color: pill.ink,
                  ),
                ),
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 15,
                    weight: FontWeight.w600,
                    color: pill.ink.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) => Semantics(
            slider: true,
            label: 'Your estimate',
            value: _moved ? roughNumber(value) : 'not set',
            increasedValue: roughNumber(_ruler.valueAt(_t + 0.05)),
            decreasedValue: roughNumber(_ruler.valueAt(_t - 0.05)),
            onIncrease: () => setState(() {
              _t = (_t + 0.05).clamp(0, 1);
              _moved = true;
            }),
            onDecrease: () => setState(() {
              _t = (_t - 0.05).clamp(0, 1);
              _moved = true;
            }),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: widget.onAnswer == null
                  ? null
                  : (d) => _drag(d.localPosition.dx, box.maxWidth),
              onHorizontalDragUpdate: widget.onAnswer == null
                  ? null
                  : (d) => _drag(d.localPosition.dx, box.maxWidth),
              onTapDown: widget.onAnswer == null
                  ? null
                  : (d) => _drag(d.localPosition.dx, box.maxWidth),
              child: SizedBox(
                height: 64,
                width: box.maxWidth,
                child: CustomPaint(
                  painter: RulerPainter(
                    ruler: _ruler,
                    ink: pill.ink,
                    ground: pill.color,
                    marks: [RulerMark(_t, pill.ink, big: true, faint: !_moved)],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                _moved ? 'Happy with that?' : 'Drag along the ruler.',
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w500,
                  color: pill.ink.withValues(alpha: 0.6),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Lock in my estimate',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canLock
                    ? () {
                        HapticFeedback.mediumImpact();
                        widget.onAnswer!(value.toStringAsPrecision(3));
                      }
                    : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: canLock ? 1 : 0.35,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: pill.ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'LOCK IT IN',
                      style: AppText.label(
                        size: 11.5,
                        weight: FontWeight.w800,
                        spacing: 1.1,
                        color: pill.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A mark on the ruler: where it sits, how it is drawn, and its label.
class RulerMark {
  final double t;
  final Color color;
  final bool big;
  final bool faint;
  final String label;

  /// Label under the ruler rather than over it, so two marks close together
  /// do not print their names on top of each other.
  final bool below;

  const RulerMark(
    this.t,
    this.color, {
    this.big = false,
    this.faint = false,
    this.label = '',
    this.below = false,
  });
}

/// The ruler itself: a baseline, a tick and a number at every power of
/// ten, minor ticks between, an optional band, and the marks on top.
class RulerPainter extends CustomPainter {
  final EstimateRuler ruler;
  final Color ink;

  /// The card's own colour, for the eye of the big mark.
  final Color ground;
  final List<RulerMark> marks;

  /// A stretch to shade, as 0..1 along the ruler: the "close enough" zone.
  final (double, double)? band;
  final double bandOpacity;

  const RulerPainter({
    required this.ruler,
    required this.ink,
    required this.ground,
    this.marks = const [],
    this.band,
    this.bandOpacity = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = math.min(size.height * 0.42, 34.0);
    final line = Paint()
      ..color = ink.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (band != null) {
      final (a, b) = band!;
      canvas.drawRRect(
        RRect.fromLTRBR(
          a * size.width,
          y - 11,
          b * size.width,
          y + 11,
          const Radius.circular(8),
        ),
        Paint()..color = ink.withValues(alpha: 0.16 * bandOpacity),
      );
    }

    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);

    // Minor ticks at 2..9 of each decade, so the log scale is visible.
    final minor = Paint()
      ..color = ink.withValues(alpha: 0.28)
      ..strokeWidth = 1.2;
    for (final d in [ruler.low / 10, ...ruler.decades]) {
      for (var k = 2; k < 10; k++) {
        final t = ruler.at(d * k);
        if (t <= 0 || t >= 1) continue;
        canvas.drawLine(
          Offset(t * size.width, y - 5),
          Offset(t * size.width, y + 5),
          minor,
        );
      }
    }

    for (final d in ruler.decades) {
      final x = ruler.at(d) * size.width;
      canvas.drawLine(Offset(x, y - 10), Offset(x, y + 10), line);
      final tp = TextPainter(
        text: TextSpan(
          text: _tick(d),
          style: AppText.label(
            size: 10.5,
            spacing: 0.4,
            color: ink.withValues(alpha: 0.62),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(left, y + 15));
    }

    for (final m in marks) {
      final x = m.t * size.width;
      final c = m.color.withValues(alpha: m.faint ? 0.45 : 1);
      if (m.big) {
        canvas.drawLine(
          Offset(x, y - 20),
          Offset(x, y + 4),
          Paint()
            ..color = c
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(Offset(x, y), 11, Paint()..color = c);
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = ground);
      } else {
        canvas.drawRRect(
          RRect.fromLTRBR(
            x - 2.5,
            y - 16,
            x + 2.5,
            y + 16,
            const Radius.circular(3),
          ),
          Paint()..color = c,
        );
      }
      if (m.label.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: m.label,
            style: AppText.label(size: 10, spacing: 0.8, color: c),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final left = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(
          canvas,
          Offset(left, m.below ? y + 32 : y - 22 - tp.height - (m.big ? 4 : 0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(RulerPainter old) =>
      old.marks != marks || old.band != band || old.bandOpacity != bandOpacity;
}

/// The reveal: the same ruler, the "close enough" band, the truth and the
/// reader's guess, arriving in that order.
class PlaceItReveal extends StatelessWidget {
  final Pill pill;
  final Estimate estimate;
  final String response;

  const PlaceItReveal({
    super.key,
    required this.pill,
    required this.estimate,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    final ruler = EstimateRuler.around(estimate.answer, pill.id);
    final guess = TypeNumber.parse(response)?.toDouble();
    final truth = estimate.answer.toDouble();
    final f = estimate.withinFactor.toDouble();
    final still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        double phase(double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);
        return SizedBox(
          height: 84,
          width: double.infinity,
          child: CustomPaint(
            painter: RulerPainter(
              ruler: ruler,
              ink: pill.ink,
              ground: pill.color,
              band: (ruler.at(truth / f), ruler.at(truth * f)),
              bandOpacity: phase(0, 0.35),
              marks: [
                if (guess != null && guess > 0)
                  RulerMark(
                    ruler.at(guess),
                    pill.ink.withValues(alpha: 0.45 + 0.55 * phase(0.6, 1)),
                    label: 'YOU',
                    below: true,
                  ),
                RulerMark(
                  ruler.at(truth),
                  pill.ink,
                  big: true,
                  faint: phase(0.25, 0.6) < 1,
                  label: 'TRUTH',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
