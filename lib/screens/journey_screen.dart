import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../data/genres.dart';
import '../data/pill_bank.dart';
import '../data/pills_repository.dart' show dateKey;
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/progress.dart';
import '../theme.dart';
import '../widgets/share_day.dart';
import '../widgets/subject_icon.dart';
import '../widgets/ui.dart';
import 'deck_viewer_screen.dart';
import 'path_screen.dart';
import 'week_screen.dart';
import 'progress_text.dart';

/// Your journey: the numbers first, the card to say last.
///
/// Everything on it is counted from what the app already writes down. The
/// order is the argument: at the top (artboard 134e) how sure the reader
/// says they are against how often they are right, then what the reading
/// has come to (the week, the level, the four numbers, what it is about),
/// then where it has gone (by subject), and at the foot the one thing to do
/// with it tonight — a card to say out loud to somebody. A page of
/// statistics that ends in an action.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key, required this.app, required this.onBack});

  final AppState app;
  final VoidCallback onBack;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  /// How far down the queue of things to say the reader has pressed.
  int _sayAt = 0;

  /// The subject open to its strands, if one is.
  String? _openSubject;

  /// The confidence level picked under the curve at the top, if one is.
  int? _sureLevel;

  AppState get app => widget.app;

  /// What there is to say tonight: cards already read that carry a line to
  /// bring them up with. Not said yet first, then the ones the reader
  /// liked or kept, then the rest — and the order never moves under them.
  List<Pill> get _sayable {
    final read = PillBank.cards
        .where((p) => app.seenIds.contains(p.id) && p.barMove.trim().isNotEmpty)
        .toList();
    int rank(Pill p) {
      if (app.hasSaid(p.id)) return 3;
      if (app.isLiked(p.id) || app.isSaved(p.id)) return 0;
      if (app.answerFor(p.id) != null) return 1;
      return 2;
    }

    read.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.id.compareTo(b.id);
    });
    return read;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final List<Pill> sayable = _sayable;

    return ScreenView(
      name: 'journey',
      child: Scaffold(
        backgroundColor: context.p.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Row(
                  children: [
                    BackCircle(onPressed: widget.onBack),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.yourJourney,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(
                          size: 27,
                          weight: FontWeight.w600,
                          height: 1,
                          spacing: -0.8,
                          color: ink,
                        ),
                      ),
                    ),
                    if (app.score.total > 0) _Points(app: app),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      children: [
                        _SureAndRight(
                          app: app,
                          chosen: _sureLevel,
                          onChoose: (said) => setState(() => _sureLevel = said),
                        ),
                        const SizedBox(height: 24),
                        _Week(app: app),
                        const SizedBox(height: 20),
                        _Level(app: app),
                        const SizedBox(height: 18),
                        _Tiles(app: app),
                        const SizedBox(height: 18),
                        if (app.seenIds.length >= _IsAbout.kWorthSaying) ...[
                          _IsAbout(app: app),
                          const SizedBox(height: 18),
                        ],
                        _BySubject(
                          app: app,
                          open: _openSubject,
                          onToggle: (key) => setState(() {
                            _openSubject = _openSubject == key ? null : key;
                          }),
                        ),
                        // Under what has been read, what stayed: the only
                        // number on the page that measures memory rather
                        // than reading.
                        const SizedBox(height: 18),
                        Eyebrow(l.whatStays),
                        const SizedBox(height: 8),
                        _Memory(app: app),
                        if (sayable.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Eyebrow(l.toSayTonight),
                          const SizedBox(height: 8),
                          _SayCard(
                            pill: sayable[_sayAt % sayable.length],
                            held: app.hasSaid(
                              sayable[_sayAt % sayable.length].id,
                            ),
                            onAnother: () => setState(() => _sayAt++),
                            onSaid: () async {
                              HapticFeedback.mediumImpact();
                              await app.markSaid(
                                sayable[_sayAt % sayable.length].id,
                              );
                              if (mounted) setState(() => _sayAt++);
                            },
                          ),
                        ],
                        if (app.dayClosed) ...[
                          const SizedBox(height: 18),
                          Center(child: ShareDay(app: app)),
                        ],
                      ],
                    ),
                    // The list runs under the foot of the screen rather than
                    // stopping at it, so there is always a reason to scroll.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 36,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                context.p.surface.withValues(alpha: 0),
                                context.p.surface,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The record as one number, in a pill beside the title, now that the top
/// of the page is how sure against how right.
class _Points extends StatelessWidget {
  const _Points({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    return Container(
      key: const ValueKey('journey-score'),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: context.p.inverse,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.journeyPoints(
          NumberFormat.decimalPattern(locale).format(app.score.total),
        ),
        style: AppText.body(
          size: 11.5,
          weight: FontWeight.w700,
          height: 1,
          color: context.p.onInverse,
        ),
      ),
    );
  }
}

/// Sure, and right — artboard 134e, the top of the page: how many points
/// the reader's confidence runs off their results, which way it has gone
/// since last week, and the curve level by level, with the levels under it
/// to pick one and a sentence that says how that one went.
class _SureAndRight extends StatelessWidget {
  const _SureAndRight({
    required this.app,
    required this.chosen,
    required this.onChoose,
  });

  final AppState app;

  /// The confidence level picked under the curve, or null for the default.
  final int? chosen;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final double? gap = app.confidenceGap;
    final double? before = app.confidenceGapOn(
      dateKey(app.today.subtract(const Duration(days: 7))),
    );
    final List<CalibrationBucket> buckets = app.calibration.toList();
    final int toGo = kCalibrationFloor - app.judgements.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The number and the week beside it, on one line where they fit
        // and the week under it where they do not.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  gap == null ? '—' : '${gap.round()}',
                  key: const ValueKey('journey-gap'),
                  style: AppText.display(
                    size: 80,
                    weight: FontWeight.w600,
                    height: 0.84,
                    spacing: -3.6,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    l.journeyPointsOff,
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w600,
                      height: 1.2,
                      color: ink.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            if (gap != null && before != null)
              _LastWeek(now: gap.round(), before: before.round()),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          gap == null && toGo > 0
              ? '${l.journeyOffExplain} ${l.journeyOffNotYet(toGo)}'
              : l.journeyOffExplain,
          style: AppText.body(
            size: 13.5,
            height: 1.45,
            color: ink.withValues(alpha: 0.6),
          ),
        ),
        if (buckets.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SureCurve(buckets: buckets, chosen: chosen, onChoose: onChoose),
        ],
      ],
    );
  }
}

/// Where the gap stood a week ago, and which way it has gone since: down
/// is the good way.
class _LastWeek extends StatelessWidget {
  const _LastWeek({required this.now, required this.before});

  final int now;
  final int before;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = context.p.ink;
    final Color green = dark
        ? const Color(0xFF3BE07A)
        : const Color(0xFF0B8A3E);
    final Color pink = dark ? const Color(0xFFFF7AA8) : const Color(0xFFC2185B);
    final (Color colour, Color fill, IconData? icon, String text) = now < before
        ? (
            green,
            green.withValues(alpha: 0.14),
            Icons.arrow_downward_rounded,
            l.journeyLastWeek(before),
          )
        : now > before
        ? (
            pink,
            pink.withValues(alpha: 0.14),
            Icons.arrow_upward_rounded,
            l.journeyLastWeek(before),
          )
        : (
            ink.withValues(alpha: 0.6),
            ink.withValues(alpha: 0.07),
            null,
            l.journeyLastWeekSame,
          );
    return Container(
      key: const ValueKey('journey-last-week'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: colour),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: AppText.body(
              size: 11.5,
              weight: FontWeight.w700,
              height: 1,
              color: colour,
            ),
          ),
        ],
      ),
    );
  }
}

/// The curve, the levels under it to pick from, and what the picked one
/// came to.
class _SureCurve extends StatelessWidget {
  const _SureCurve({
    required this.buckets,
    required this.chosen,
    required this.onChoose,
  });

  final List<CalibrationBucket> buckets;
  final int? chosen;
  final ValueChanged<int> onChoose;

  /// The level shown: the one picked, or the surest one answered — that is
  /// where being sure costs the most when it is wrong.
  CalibrationBucket get _shown {
    for (final CalibrationBucket b in buckets) {
      if (b.said == chosen) return b;
    }
    return buckets.reduce((a, b) => b.said > a.said ? b : a);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final CalibrationBucket shown = _shown;
    final Set<int> answered = {for (final b in buckets) b.said};
    final TextStyle caption = AppText.body(
      size: 10.5,
      weight: FontWeight.w600,
      height: 1,
      color: ink.withValues(alpha: 0.4),
    );
    return Container(
      key: const ValueKey('journey-curve'),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 342 / 230,
            child: CustomPaint(
              painter: _SurePainter(
                buckets: buckets,
                shown: shown.said,
                ink: ink,
                ground: Color.alphaBlend(
                  ink.withValues(alpha: 0.05),
                  context.p.surface,
                ),
                pink: dark ? const Color(0xFFFF3D7F) : const Color(0xFFE0245E),
                pinkText: dark
                    ? const Color(0xFFFF7AA8)
                    : const Color(0xFFC2185B),
                spotOn: l.journeyCurveSpotOn,
                tooSure: l.journeyTooSure,
                textStyle: AppText.body(size: 10, weight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(l.journeyAxisSure, style: caption)),
              const SizedBox(width: 10),
              Text(l.journeyAxisRight, style: caption),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (int i, int said) in kConfidenceLevels.indexed) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: _LevelChip(
                    said: said,
                    on: said == shown.said,
                    answered: answered.contains(said),
                    onTap: () => onChoose(said),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  l.journeyWhenYouSaid(
                    '${shown.said}%',
                    '${shown.actual.round()}%',
                  ),
                  key: const ValueKey('journey-when'),
                  style: AppText.display(
                    size: 17,
                    weight: FontWeight.w600,
                    height: 1.25,
                    spacing: -0.3,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l.journeyNAnswers(shown.count),
                style: AppText.body(
                  size: 11.5,
                  weight: FontWeight.w600,
                  height: 1.3,
                  color: ink.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One confidence level under the curve: picked, pickable, or never said.
class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.said,
    required this.on,
    required this.answered,
    required this.onTap,
  });

  final int said;
  final bool on;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Semantics(
      button: answered,
      selected: on,
      child: GestureDetector(
        key: ValueKey('journey-level-$said'),
        behavior: HitTestBehavior.opaque,
        onTap: answered && !on
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? context.p.inverse : ink.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$said%',
            maxLines: 1,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              height: 1,
              color: on
                  ? context.p.onInverse
                  : ink.withValues(alpha: answered ? 0.62 : 0.25),
            ),
          ),
        ),
      ),
    );
  }
}

/// The curve on the design's own grid (342 by 230), scaled to the card:
/// how sure across, from 50% to 90%, how often right up the side. Where the
/// reader was surer than right, the space between the curve and the
/// diagonal is shaded and called what it is.
class _SurePainter extends CustomPainter {
  _SurePainter({
    required this.buckets,
    required this.shown,
    required this.ink,
    required this.ground,
    required this.pink,
    required this.pinkText,
    required this.spotOn,
    required this.tooSure,
    required this.textStyle,
  });

  final List<CalibrationBucket> buckets;
  final int shown;
  final Color ink;
  final Color ground;
  final Color pink;
  final Color pinkText;
  final String spotOn;
  final String tooSure;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.width / 342;
    canvas.save();
    canvas.scale(k);
    final int lo = _floor();
    double x(num said) => 36 + (said - 50) / 40 * 294;
    double y(num right) => 200 - (right - lo) / (100 - lo) * 186;
    final List<Offset> points = [
      for (final b in buckets) Offset(x(b.said), y(b.actual)),
    ];

    final Paint grid = Paint()
      ..color = ink.withValues(alpha: 0.07)
      ..strokeWidth = 1 / k;
    for (var i = 0; i < 6; i++) {
      final double gy = 14 + i * 31.0;
      canvas.drawLine(Offset(36, gy), Offset(330, gy), grid);
    }
    canvas.drawLine(
      const Offset(36, 200),
      const Offset(330, 200),
      Paint()
        ..color = ink.withValues(alpha: 0.18)
        ..strokeWidth = 1 / k,
    );

    // Too sure: between the curve and the diagonal, wherever the curve
    // runs under it — the space between the two, kept below the diagonal.
    final Offset from = Offset(x(50), y(50));
    final Offset to = Offset(x(90), y(90));
    if (points.length > 1) {
      final Path between = Path()..moveTo(points.first.dx, points.first.dy);
      for (final Offset p in points.skip(1)) {
        between.lineTo(p.dx, p.dy);
      }
      for (final b in buckets.reversed) {
        between.lineTo(x(b.said), y(b.said));
      }
      between.close();
      final Path under = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy)
        ..lineTo(to.dx, 230)
        ..lineTo(from.dx, 230)
        ..close();
      canvas.save();
      canvas.clipPath(under);
      canvas.drawPath(between, Paint()..color = pink.withValues(alpha: 0.17));
      canvas.restore();
    }

    // Spot on: right as often as sure.
    final Paint dash = Paint()
      ..color = ink.withValues(alpha: 0.38)
      ..strokeWidth = 1.5;
    final double length = (to - from).distance;
    final Offset unit = (to - from) / length;
    for (double d = 0; d < length; d += 9) {
      canvas.drawLine(
        from + unit * d,
        from + unit * math.min(d + 4, length),
        dash,
      );
    }
    final Offset spotAt =
        from + unit * (length * 0.8) + Offset(unit.dy, -unit.dx) * 7;
    final double angle = math.atan2(unit.dy, unit.dx);
    final Rect spotRect = _text(
      canvas,
      spotOn,
      ink.withValues(alpha: 0.45),
      at: spotAt,
      angle: angle,
      align: 0.5,
    );

    // The words for the shading: inside it, beside the level where it is
    // widest, clear of the diagonal's own label — or not at all.
    if (points.length > 1) {
      final TextPainter words = _measure(
        tooSure,
        pinkText,
        weight: FontWeight.w700,
        scale: 1.1,
      );
      double? curveAt(double px) {
        for (var i = 0; i + 1 < points.length; i++) {
          final Offset a = points[i], b = points[i + 1];
          if (px >= a.dx && px <= b.dx) {
            return a.dy + (px - a.dx) / (b.dx - a.dx) * (b.dy - a.dy);
          }
        }
        return null;
      }

      double diagonalAt(double px) =>
          from.dy + (px - from.dx) / (to.dx - from.dx) * (to.dy - from.dy);
      Offset? ring;
      for (final b in buckets) {
        if (b.said == shown) ring = Offset(x(b.said), y(b.actual));
      }

      // Every place along the band where the words fit between the
      // diagonal above and the curve below; the roomiest one wins.
      Rect? place;
      double best = -1;
      for (double left = 40; left + words.width <= 326; left += 4) {
        final double right = left + words.width;
        final List<double> xs = [
          left,
          left + words.width / 2,
          right,
          for (final Offset p in points)
            if (p.dx > left && p.dx < right) p.dx,
        ];
        final List<double?> under = [for (final px in xs) curveAt(px)];
        if (under.contains(null)) continue;
        final double top = xs.map(diagonalAt).reduce(math.max) + 3;
        final double bottom = under.whereType<double>().reduce(math.min) - 3;
        final double slack = bottom - top - words.height;
        if (slack < 0 || slack <= best) continue;
        final Rect r = Rect.fromLTWH(
          left,
          top + slack / 2,
          words.width,
          words.height,
        );
        if (r.overlaps(spotRect.inflate(3))) continue;
        if (ring != null &&
            r.overlaps(Rect.fromCircle(center: ring, radius: 14))) {
          continue;
        }
        best = slack;
        place = r;
      }
      if (place != null) words.paint(canvas, place.topLeft);
      words.dispose();
    }

    final Paint stroke = Paint()
      ..color = ink
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    if (points.length > 1) {
      final Path curve = Path()..moveTo(points.first.dx, points.first.dy);
      for (final Offset p in points.skip(1)) {
        curve.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(curve, stroke);
    }
    for (final Offset p in points) {
      canvas.drawCircle(p, 3.5, Paint()..color = ground);
      canvas.drawCircle(p, 3.5, stroke..strokeWidth = 2);
    }

    // The level picked, ringed.
    for (final b in buckets) {
      if (b.said != shown) continue;
      final Offset at = Offset(x(b.said), y(b.actual));
      canvas.drawCircle(at, 12, Paint()..color = pink);
      canvas.drawCircle(at, 10, Paint()..color = ground);
      canvas.drawCircle(at, 6, Paint()..color = pink);
    }

    final Color label = ink.withValues(alpha: 0.4);
    for (final said in [50, 70, 90]) {
      _text(canvas, '$said%', label, at: Offset(x(said), 219), align: 0.5);
    }
    _text(canvas, '100', label, at: const Offset(28, 17.5), align: 1);
    _text(
      canvas,
      '${(lo + 100) ~/ 2}',
      label,
      at: const Offset(28, 110.5),
      align: 1,
    );
    _text(canvas, '$lo', label, at: const Offset(28, 203.5), align: 1);
    canvas.restore();
  }

  /// The bottom of the scale: 40, unless a level went lower.
  int _floor() {
    if (buckets.isEmpty) return 40;
    final double least = buckets.map((b) => b.actual).reduce(math.min);
    if (least >= 40) return 40;
    return (least / 10).floor() * 10;
  }

  /// A label laid out in the chart's type.
  TextPainter _measure(
    String text,
    Color colour, {
    FontWeight? weight,
    double scale = 1,
  }) => TextPainter(
    text: TextSpan(
      text: text,
      style: textStyle.copyWith(
        color: colour,
        fontWeight: weight,
        fontSize: (textStyle.fontSize ?? 10) * scale,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  /// A label with its baseline at [at]; [align] 0 starts it there, 0.5
  /// centres it, 1 ends it. Returns the box it covers, turned or not.
  Rect _text(
    Canvas canvas,
    String text,
    Color colour, {
    required Offset at,
    double align = 0,
    double angle = 0,
  }) {
    final TextPainter painter = _measure(text, colour);
    final double baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final Offset origin = Offset(-painter.width * align, -baseline);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    painter.paint(canvas, origin);
    canvas.restore();
    final double c = math.cos(angle), sn = math.sin(angle);
    final corners = [
      for (final Offset o in [
        origin,
        origin + Offset(painter.width, 0),
        origin + Offset(0, painter.height),
        origin + Offset(painter.width, painter.height),
      ])
        at + Offset(o.dx * c - o.dy * sn, o.dx * sn + o.dy * c),
    ];
    painter.dispose();
    return Rect.fromLTRB(
      corners.map((o) => o.dx).reduce(math.min),
      corners.map((o) => o.dy).reduce(math.min),
      corners.map((o) => o.dx).reduce(math.max),
      corners.map((o) => o.dy).reduce(math.max),
    );
  }

  @override
  bool shouldRepaint(_SurePainter old) =>
      old.shown != shown ||
      old.ink != ink ||
      old.ground != ground ||
      old.buckets != buckets;
}

/// The rung as a level: where the reader stands, what stands between them
/// and the next one, and a bar. Tapping it opens the whole path.
class _Level extends StatelessWidget {
  const _Level({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final Standing standing = app.standing;
    final Rung? next = standing.next;
    final String? step = stepText(context, standing);

    return Semantics(
      button: true,
      key: const ValueKey('journey-level'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (routeContext) => PathScreen(
              app: app,
              onBack: () => Navigator.of(routeContext).pop(),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l.levelNamed(
                      standing.at + 1,
                      rungName(context, standing.rung),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(color: ink.withValues(alpha: 0.1)),
                    FractionallySizedBox(
                      widthFactor: standing.toNext.clamp(0.02, 1.0),
                      child: Container(color: ink),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    next == null
                        ? l.topLevel
                        : (step == null
                              ? l.nextRung(rungName(context, next))
                              : l.stepThenRung(step, rungName(context, next))),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 11.5,
                      weight: FontWeight.w500,
                      height: 1.35,
                      color: ink.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: ink.withValues(alpha: 0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The week: seven bars and how many were kept, under the score and above
/// the level — the day is too close to see a direction from, and the level
/// too far. Tapping opens the week read back in full.
class _Week extends StatelessWidget {
  const _Week({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final WeekReport week = app.thisWeek;

    return Semantics(
      button: true,
      key: const ValueKey('journey-week'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (routeContext) => WeekScreen(
              app: app,
              onBack: () => Navigator.of(routeContext).pop(),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l.yourWeek,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l.nOfSeven(week.days),
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: ink.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            WeekStrip(week: app.weekCompletion(), barHeight: 26),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    week.empty
                        ? l.nothingThisWeekYet
                        : week.kept
                        ? l.keptDaysOfSeven(week.days)
                        : l.daysOfSevenFiveKeeps(week.days),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 11.5,
                      weight: FontWeight.w500,
                      height: 1.35,
                      color: ink.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: ink.withValues(alpha: 0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The four numbers, two by two.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final int answered = app.answers.length;
    final int held = app.heldCards;
    final double? gap = app.confidenceGap;
    final int moves = app.movesDown;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  value: answered == 0
                      ? '—'
                      : '${(held / answered * 100).round()}%',
                  label: answered == 0
                      ? l.stillWithYouNothing
                      : l.stillWithYouOf(held, answered),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Tile(
                  value: gap == null ? '—' : '${gap.round()}',
                  label: gap == null
                      ? l.calibrationNotMeasured
                      : l.calibrationPointsOff,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  value: '${app.liveStreak}',
                  label: l.inARowBest(app.bestStreak),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Tile(value: '$moves', label: l.movesYouCanSpot(moves)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            style: AppText.body(
              size: 26,
              weight: FontWeight.w700,
              height: 1,
              spacing: -1,
              color: ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppText.body(
              size: 10.5,
              weight: FontWeight.w500,
              height: 1.2,
              color: ink.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the pile of cards amounts to in things a person can picture. The
/// conversions are stated rather than hidden — it is "about", and the
/// eyebrow says so.
class _IsAbout extends StatelessWidget {
  const _IsAbout({required this.app});

  final AppState app;

  /// Seconds a card takes to read, for the hours line.
  static const int kSecondsACard = 40;

  /// Below this the comparison says nothing — "five cards is about zero
  /// books" is worse than not asking the question yet.
  static const int kWorthSaying = 25;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final int n = app.seenIds.length;
    final int minutes = (n * kSecondsACard / 60).round();
    final int books = (n / 50).round();
    final int hours = (n * 3 / 60).round();
    final int lectures = (n / 25).round();
    final parts = <(String, String)>[
      ('$books', l.nonFictionBooks(books)),
      ('$hours', l.hoursOfDocumentaries(hours)),
      ('$lectures', l.lectures(lectures)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(l.nCardsIsAbout(n)),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < parts.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parts[i].$1,
                          style: AppText.body(
                            size: 22,
                            weight: FontWeight.w700,
                            height: 1,
                            spacing: -0.8,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          parts[i].$2,
                          style: AppText.body(
                            size: 10.5,
                            weight: FontWeight.w500,
                            height: 1.25,
                            color: ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.inTotalACard(
            minutes < 60
                ? l.justMinutes(minutes)
                : l.hoursMinutes(minutes ~/ 60, minutes % 60),
          ),
          style: AppText.body(
            size: 11,
            height: 1.35,
            color: ink.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

/// Where the reading has actually gone, subject by subject: how much of
/// each shelf has been read, most-read first.
class _BySubject extends StatelessWidget {
  const _BySubject({
    required this.app,
    required this.open,
    required this.onToggle,
  });

  final AppState app;

  /// The subject open to its strands, by topic key, if one is.
  final String? open;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;

    final total = <String, int>{};
    final read = <String, int>{};
    for (final pill in PillBank.cards) {
      total[pill.topic] = (total[pill.topic] ?? 0) + 1;
      if (app.seenIds.contains(pill.id)) {
        read[pill.topic] = (read[pill.topic] ?? 0) + 1;
      }
    }
    final rows = kTopicOrder
        .where((key) => (total[kTopics[key]!.name] ?? 0) > 0)
        .toList();
    double share(String key) {
      final String name = kTopics[key]!.name;
      return (read[name] ?? 0) / (total[name] ?? 1).clamp(1, 1 << 30);
    }

    rows.sort((a, b) {
      final byShare = share(b).compareTo(share(a));
      if (byShare != 0) return byShare;
      return (read[kTopics[b]!.name] ?? 0).compareTo(
        read[kTopics[a]!.name] ?? 0,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Both ends give way: a long translation of either wraps or
        // trails off rather than pushing the row past its edge.
        Row(
          children: [
            Flexible(child: Eyebrow(l.bySubject)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l.readOfTheShelf,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppText.body(
                  size: 10.5,
                  weight: FontWeight.w500,
                  color: ink.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        for (final key in rows)
          _SubjectRow(
            key: ValueKey('subject-$key'),
            app: app,
            topicKey: key,
            style: kTopics[key]!,
            read: read[kTopics[key]!.name] ?? 0,
            of: total[kTopics[key]!.name] ?? 0,
            open: open == key,
            onToggle: () => onToggle(key),
          ),
      ],
    );
  }
}

/// One subject: its bar, and — open — the genres and strands inside it
/// with how much of each has been read, and the way back into the cards
/// of it that were read.
class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    super.key,
    required this.app,
    required this.topicKey,
    required this.style,
    required this.read,
    required this.of,
    required this.open,
    required this.onToggle,
  });

  final AppState app;
  final String topicKey;
  final TopicStyle style;
  final int read;
  final int of;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final double share = of == 0 ? 0 : read / of;
    final bool any = read > 0;
    // Thinking is not a subject and has no strands; unread, it is a row
    // and not a button.
    final List<Genre> genres = kGenres[topicKey] ?? const [];
    final bool opens = genres.isNotEmpty || any;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: opens,
          expanded: opens ? open : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: opens ? onToggle : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                children: [
                  SubjectIcon(subject: style.name, size: 13, ink: style.color),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 84,
                    child: Text(
                      style.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: ink.withValues(alpha: any ? 0.82 : 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: SizedBox(
                        height: 7,
                        child: Stack(
                          children: [
                            Container(color: ink.withValues(alpha: 0.06)),
                            FractionallySizedBox(
                              widthFactor: share.clamp(0.0, 1.0),
                              child: Container(color: style.color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 36,
                    child: Text(
                      any ? '${(share * 100).round()}%' : '—',
                      textAlign: TextAlign.right,
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w700,
                        color: ink.withValues(alpha: any ? 0.82 : 0.3),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 18,
                    child: opens
                        ? Icon(
                            open
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 16,
                            color: ink.withValues(alpha: 0.35),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(31, 0, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final genre in genres)
                  _GenreLines(genre: genre, seenIds: app.seenIds),
                if (any)
                  // What was read of it, to read again.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final deck = PillBank.cards
                          .where(
                            (p) =>
                                p.topic == style.name &&
                                app.seenIds.contains(p.id),
                          )
                          .toList();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DeckViewerScreen(
                            app: app,
                            deck: deck,
                            title: style.name,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${l.nCards(read)} \u2192',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: context.p.link,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One genre's strands, each with how much of it has been read — only the
/// strands the bank has written something under, so a reader sees what is
/// there to know rather than a list of empty rooms.
class _GenreLines extends StatelessWidget {
  const _GenreLines({required this.genre, required this.seenIds});

  final Genre genre;
  final Set<String> seenIds;

  @override
  Widget build(BuildContext context) {
    final lines = <(Strand, int, int)>[];
    for (final strand in genre.strands) {
      var total = 0;
      var read = 0;
      for (final Pill pill in PillBank.cards) {
        if (!pill.strands.contains(strand.id)) continue;
        total++;
        if (seenIds.contains(pill.id)) read++;
      }
      if (total > 0) lines.add((strand, read, total));
    }
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            genre.label,
            style: AppText.body(
              size: 11.5,
              weight: FontWeight.w600,
              color: context.p.inkMuted,
            ),
          ),
          const SizedBox(height: 3),
          for (final (strand, read, total) in lines)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strand.label,
                      style: AppText.body(
                        size: 12.5,
                        color: read > 0 ? context.p.ink : context.p.inkFaint,
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.nReadOfN(read, total),
                    style: AppText.body(size: 11.5, color: context.p.inkFaint),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// What stayed: of the cards answered, how many came back, and how many
/// were still right when they did. That last number is the only one in the
/// app that measures memory rather than reading.
class _Memory extends StatelessWidget {
  const _Memory({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Judgements are appended, never rewritten, so a card judged twice is a
    // card that came back — and the last judgement on it is whether it
    // stayed.
    final runs = <String, List<Judgement>>{};
    for (final j in app.judgements) {
      final String? id = j.pillId;
      if (id == null) continue;
      runs.putIfAbsent(id, () => []).add(j);
    }
    final int answered = runs.length;
    final returned = runs.values.where((run) => run.length > 1).toList();
    final int kept = returned.where((run) => run.last.correct).length;

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: returned.isEmpty
          ? Text(
              l.nothingBackYet,
              style: AppText.body(
                size: 13.5,
                height: 1.45,
                color: context.p.inkMuted,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MemoryLine(
                  icon: Icons.check_circle_outline_rounded,
                  text: l.nAnswered(answered),
                ),
                const SizedBox(height: 8),
                _MemoryLine(
                  icon: Icons.replay_rounded,
                  text: l.nCameBackAgain(returned.length),
                ),
                const SizedBox(height: 8),
                _MemoryLine(
                  icon: Icons.psychology_alt_rounded,
                  text: l.nKeptOnReturn(kept),
                  strong: true,
                ),
              ],
            ),
    );
  }
}

class _MemoryLine extends StatelessWidget {
  const _MemoryLine({
    required this.icon,
    required this.text,
    this.strong = false,
  });

  final IconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: strong ? context.p.ink : context.p.inkFaint,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppText.body(
              size: 13.5,
              weight: strong ? FontWeight.w600 : FontWeight.w500,
              height: 1.35,
              color: strong ? context.p.ink : context.p.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// The card to say out loud tonight: the question, the answer, and the
/// line to bring it up with — the one thing on this page that is not a
/// number, and the only one that leaves the phone.
class _SayCard extends StatelessWidget {
  const _SayCard({
    required this.pill,
    required this.held,
    required this.onAnother,
    required this.onSaid,
  });

  final Pill pill;

  /// True once this one has been said. The card stays sayable — a good
  /// line is worth telling twice — but it says so.
  final bool held;
  final VoidCallback onAnother;
  final VoidCallback onSaid;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = pill.ink;
    final bool darkInk = ink.computeLuminance() < 0.5;
    final Color sub = ink.withValues(alpha: darkInk ? 0.6 : 0.66);
    final Color strong = ink.withValues(alpha: darkInk ? 0.8 : 0.86);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: pill.color,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SubjectIcon(subject: pill.topic, size: 14, ink: sub),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pill.topic.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 9.5,
                    weight: FontWeight.w700,
                    spacing: 1.4,
                    color: sub,
                  ),
                ),
              ),
              if (held)
                Text(
                  l.saidAlready,
                  style: AppText.body(
                    size: 10,
                    weight: FontWeight.w600,
                    color: sub,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pill.question,
            style: AppText.display(
              size: 24,
              weight: FontWeight.w600,
              height: 1.1,
              spacing: -0.9,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pill.answer,
            style: AppText.body(size: 14.5, height: 1.4, color: strong),
          ),
          const SizedBox(height: 12),
          Text(
            pill.barMove,
            style: AppText.body(
              size: 11,
              weight: FontWeight.w600,
              height: 1.3,
              color: sub,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SayButton(
                  label: l.anotherOne,
                  onTap: onAnother,
                  fill: null,
                  ink: ink,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SayButton(
                  label: l.saidIt,
                  onTap: onSaid,
                  fill: ink,
                  ink: pill.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SayButton extends StatelessWidget {
  const _SayButton({
    required this.label,
    required this.onTap,
    required this.fill,
    required this.ink,
  });

  final String label;
  final VoidCallback onTap;

  /// Null draws the outlined one, in the card's own ink.
  final Color? fill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: fill == null ? Border.all(color: ink, width: 1.5) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}
