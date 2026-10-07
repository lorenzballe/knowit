import 'dart:math' as math;

import 'package:flutter/material.dart' hide Step;
import 'package:intl/intl.dart' hide TextDirection;

import '../data/pill_bank.dart';
import '../data/pills_repository.dart' show dateKey;
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/journey_record.dart';
import '../state/progress.dart';
import '../theme.dart';
import '../widgets/share_day.dart';
import '../widgets/subject_icon.dart';
import '../widgets/ui.dart';
import 'deck_viewer_screen.dart';
import 'path_screen.dart';
import 'progress_text.dart';
import 'week_screen.dart';

/// Your journey, as artboard 137a: tiles, two to a row.
///
/// The score first, with a point for each week since the first day and a
/// tap on a point to see that week; then the level, and everything else as
/// tiles — what the reading is worth, the days in a row, the subjects, how
/// hard and how long, how sure against how right, the moves, what stayed,
/// the days, and how far it reaches in time, in place, in topics and in
/// words.
///
/// Everything on it is counted from what the app writes down, with a date
/// where it has one ([JourneyRecord]). What it never wrote down is not
/// worked out now: a tile with nothing to go on shows a dash and says why.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key, required this.app, required this.onBack});

  final AppState app;
  final VoidCallback onBack;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  /// The week tapped on the score chart, if one was; the week in hand if
  /// not.
  int? _week;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final AppState app = widget.app;
    final JourneyRecord record = app.record;
    const gap = SizedBox(height: 8);

    return ScreenView(
      name: 'journey',
      child: Scaffold(
        backgroundColor: context.p.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
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
                          color: context.p.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  children: [
                    _ScoreTile(
                      app: app,
                      record: record,
                      chosen: _week,
                      onChoose: (i) => setState(() => _week = i),
                    ),
                    gap,
                    _LevelTile(app: app),
                    gap,
                    _Pair(
                      _WorthTile(app: app),
                      _InARowTile(app: app, record: record),
                    ),
                    gap,
                    _SubjectsTile(app: app, record: record),
                    gap,
                    _Pair(
                      _HowHardTile(record: record),
                      _ReadingTimeTile(record: record),
                    ),
                    gap,
                    _PointsOffTile(app: app, record: record),
                    gap,
                    _Pair(
                      _SureTile(record: record),
                      _MovesTile(app: app, record: record),
                    ),
                    gap,
                    _MemoryTile(app: app, record: record),
                    gap,
                    _DaysTile(record: record),
                    gap,
                    _Pair(_InTimeTile(app: app), _InPlaceTile(app: app)),
                    gap,
                    _Pair(
                      _TopicsTile(app: app),
                      _WordsTile(app: app, record: record),
                    ),
                    // The day, sent as five squares, once it is done: the
                    // way the app travels, kept at the foot of the tiles.
                    if (app.dayClosed) ...[
                      const SizedBox(height: 18),
                      Center(child: ShareDay(app: app)),
                    ],
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

// ── Shared ────────────────────────────────────────────────────────────────

/// The pink of the marker on the chart.
Color _pink(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFFF3D7F)
    : const Color(0xFFE0245E);

/// The green of a gain, and of the band the top level asks for.
Color _green(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF3BE07A)
    : const Color(0xFF0E8A3E);

const Color _greenFill = Color(0xFF00D451);

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toString();

String _number(BuildContext context, num n) =>
    NumberFormat.decimalPattern(_locale(context)).format(n);

String _percent(BuildContext context, double share) =>
    NumberFormat.percentPattern(_locale(context)).format(share);

DateFormat _format(BuildContext context, DateFormat Function(String) make) {
  try {
    return make(_locale(context));
  } catch (_) {
    return make('en');
  }
}

/// A day of a month, as the phone's language writes it: 14 July, 7月14日.
String _day(BuildContext context, DateTime d) =>
    _format(context, (l) => DateFormat.MMMMd(l)).format(d);

/// A month on its own, as it reads inside a sentence.
String _month(BuildContext context, DateTime d) =>
    _format(context, (l) => DateFormat.LLLL(l)).format(d);

/// A month as a label under a chart, short and with a capital.
String _monthLabel(BuildContext context, DateTime d) {
  final String out = _format(context, (l) => DateFormat.LLL(l)).format(d);
  return out.isEmpty ? out : out[0].toUpperCase() + out.substring(1);
}

/// Capitals, with Turkish's dotted capital I.
String _upper(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// Italian runs "del 8 luglio" together as "dell'8 luglio".
String _elided(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'it'
    ? text.replaceAllMapped(
        RegExp(r"\b(de|da|a)l (1|8|11)\b"),
        (m) => "${m[1]}ll'${m[2]}",
      )
    : text;

/// The month the reader started in, and its last day — once it is over.
({DateTime first, String last})? _firstMonth(JourneyRecord record) {
  final DateTime start = dayOfKey(record.start);
  final DateTime end = DateTime(start.year, start.month + 1, 0);
  if (!record.today.isAfter(end)) return null;
  return (first: start, last: dateKey(end));
}

/// A tile: the faint panel every number sits on.
class _Box extends StatelessWidget {
  const _Box({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: context.p.ink.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

/// Two tiles side by side, as tall as the taller.
class _Pair extends StatelessWidget {
  const _Pair(this.left, this.right);

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: left),
        const SizedBox(width: 8),
        Expanded(child: right),
      ],
    ),
  );
}

/// Small capitals over a number.
class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    _upper(context, text),
    style: AppText.body(
      size: 9.5,
      weight: FontWeight.w700,
      height: 1,
      spacing: 1.3,
      color: context.p.ink.withValues(alpha: 0.45),
    ),
  );
}

/// A number set large, shrunk rather than cut when a language runs long.
class _Big extends StatelessWidget {
  const _Big(this.text, {this.size = 30, this.valueKey});

  final String text;
  final double size;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      key: valueKey,
      maxLines: 1,
      style: AppText.display(
        size: size,
        weight: FontWeight.w600,
        height: 1,
        spacing: size >= 32 ? -1 : (size >= 30 ? -0.9 : -0.7),
        color: context.p.ink,
      ),
    ),
  );
}

/// The word after a large number, on its baseline.
class _Unit extends StatelessWidget {
  const _Unit(this.text, {this.size = 12});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: AppText.body(
      size: size,
      weight: FontWeight.w600,
      height: 1.2,
      color: context.p.ink.withValues(alpha: 0.5),
    ),
  );
}

/// A half tile: what it is, the number, a line under it, and a picture at
/// the foot.
class _Half extends StatelessWidget {
  const _Half({
    required this.label,
    required this.value,
    this.unit,
    this.sub,
    this.foot,
    this.size = 30,
  });

  final String label;
  final String value;
  final String? unit;
  final String? sub;
  final Widget? foot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 11.5,
              weight: FontWeight.w600,
              height: 1,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          if (unit == null)
            _Big(value, size: size)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(child: _Big(value, size: size)),
                const SizedBox(width: 6),
                _Unit(unit!),
              ],
            ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(
              sub!,
              style: AppText.body(
                size: 11,
                weight: FontWeight.w500,
                height: 1.3,
                color: ink.withValues(alpha: 0.45),
              ),
            ),
          ],
          if (foot != null) ...[
            const Spacer(),
            const SizedBox(height: 16),
            foot!,
          ],
        ],
      ),
    );
  }
}

/// A run of numbers as a line, [lo] at the foot and [hi] at the top.
class _Spark extends StatelessWidget {
  const _Spark({
    required this.values,
    required this.height,
    this.lo,
    this.hi,
    this.steps = false,
  });

  final List<double> values;
  final double height;
  final double? lo;
  final double? hi;

  /// Drawn as steps: flat, then up, as a count goes.
  final bool steps;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: CustomPaint(
      size: Size.infinite,
      painter: _SparkPainter(
        values: values,
        lo: lo,
        hi: hi,
        steps: steps,
        ink: context.p.ink,
      ),
    ),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.lo,
    required this.hi,
    required this.steps,
    required this.ink,
  });

  final List<double> values;
  final double? lo;
  final double? hi;
  final bool steps;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final double bottom = lo ?? values.reduce(math.min);
    final double top = hi ?? values.reduce(math.max);
    final double span = (top - bottom).abs() < 1e-9 ? 1 : top - bottom;
    final int n = values.length;
    double x(int i) =>
        n == 1 ? size.width - 2 : 2 + i / (n - 1) * (size.width - 4);
    double y(double v) =>
        size.height -
        2 -
        ((v - bottom) / span).clamp(0.0, 1.0) * (size.height - 4);
    final Path path = Path();
    if (steps) {
      path.moveTo(2, y(values.first));
      for (var i = 1; i < n; i++) {
        path
          ..lineTo(x(i), y(values[i - 1]))
          ..lineTo(x(i), y(values[i]));
      }
      path.lineTo(size.width - 2, y(values.last));
    } else {
      path.moveTo(x(0), y(values.first));
      for (var i = 1; i < n; i++) {
        path.lineTo(x(i), y(values[i]));
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = ink,
    );
    if (n == 1 && !steps) {
      canvas.drawCircle(
        Offset(x(0), y(values.first)),
        2.5,
        Paint()..color = ink,
      );
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.ink != ink || old.lo != lo || old.hi != hi;
}

/// [source] cut into dashes.
Path _dashed(Path source, {double dash = 4, double gap = 3}) {
  final Path out = Path();
  for (final metric in source.computeMetrics()) {
    var d = 0.0;
    while (d < metric.length) {
      out.addPath(
        metric.extractPath(d, math.min(d + dash, metric.length)),
        Offset.zero,
      );
      d += dash + gap;
    }
  }
  return out;
}

/// A label on a chart, placed by its baseline as an SVG text is.
void _label(
  Canvas canvas,
  String text,
  Offset at, {
  required Color color,
  TextAlign anchor = TextAlign.center,
  double size = 10,
}) {
  final TextPainter tp = TextPainter(
    text: TextSpan(
      text: text,
      style: AppText.body(size: size, weight: FontWeight.w600, color: color),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final double ascent = tp.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  double x = at.dx;
  if (anchor == TextAlign.right) x -= tp.width;
  if (anchor == TextAlign.center) x -= tp.width / 2;
  tp.paint(canvas, Offset(x, at.dy - ascent));
}

// ── The score ─────────────────────────────────────────────────────────────

/// The score set large, what the last four weeks added to it, and a point
/// for each week since the first day: tap one to see that week.
class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.app,
    required this.record,
    required this.chosen,
    required this.onChoose,
  });

  final AppState app;
  final JourneyRecord record;
  final int? chosen;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final int total = app.score.total;
    final List<JourneyWeek> weeks = record.weeks();
    final List<int> scores = [for (final w in weeks) record.scoreOn(w.last)];
    final int at = (chosen ?? weeks.length - 1).clamp(0, weeks.length - 1);
    final JourneyWeek week = weeks[at];
    final int earned = record.earnedIn(week);
    final int cards = record.readBetween(week.first, week.last).length;
    final int gained = record.gainedIn(28);

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Kicker(l.journeyYourScore),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _number(context, total),
                          key: const ValueKey('journey-score'),
                          maxLines: 1,
                          style: AppText.display(
                            size: 56,
                            weight: FontWeight.w600,
                            height: 0.88,
                            spacing: -2.4,
                            color: ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Unit(l.journeyPointsUnit(total), size: 14),
                  ],
                ),
              ),
              if (gained > 0) ...[
                const SizedBox(width: 8),
                Container(
                  key: const ValueKey('journey-gained'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _greenFill.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    l.journeyGainedIn(_number(context, gained)),
                    maxLines: 1,
                    style: AppText.body(
                      size: 11.5,
                      weight: FontWeight.w700,
                      height: 1,
                      color: _green(context),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _ScoreChart(weeks: weeks, scores: scores, at: at, onChoose: onChoose),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  week.current
                      ? l.journeyWeekSoFar(earned)
                      : _elided(
                          context,
                          l.journeyWeekOf(
                            earned,
                            _day(context, dayOfKey(week.first)),
                          ),
                        ),
                  key: const ValueKey('journey-say'),
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
                l.journeyCards(cards),
                style: AppText.body(
                  size: 11.5,
                  weight: FontWeight.w600,
                  height: 1.3,
                  color: ink.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _elided(
              context,
              l.journeyScoreCaption(_day(context, dayOfKey(weeks.first.first))),
            ),
            style: AppText.body(
              size: 11,
              weight: FontWeight.w500,
              height: 1.35,
              color: ink.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// A round top for the score axis: the half of it a round number, so the
/// three labels read 0, a half and the whole.
int _niceTop(int most) {
  if (most <= 0) return 10;
  final double half = most / 2;
  final double mag = math
      .pow(10, (math.log(half) / math.ln10).floor())
      .toDouble();
  for (final double m in const [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]) {
    if (m * mag >= half) return (2 * m * mag).round();
  }
  return (20 * mag).round();
}

class _ScoreChart extends StatelessWidget {
  const _ScoreChart({
    required this.weeks,
    required this.scores,
    required this.at,
    required this.onChoose,
  });

  final List<JourneyWeek> weeks;
  final List<int> scores;
  final int at;
  final ValueChanged<int> onChoose;

  static const double height = 230;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final Color ground = context.p.surface;
    final int top = _niceTop(scores.fold(0, math.max));
    final String locale = _locale(context);
    String axis(int v) => v >= 10000
        ? NumberFormat.compact(locale: locale).format(v)
        : NumberFormat.decimalPattern(locale).format(v);
    final labels = <(int, String)>[];
    for (var i = 0; i < weeks.length; i++) {
      final DateTime d = dayOfKey(weeks[i].first);
      if (i == 0 || dayOfKey(weeks[i - 1].first).month != d.month) {
        labels.add((i, _monthLabel(context, d)));
      }
    }

    return LayoutBuilder(
      builder: (context, box) {
        final double w = box.maxWidth;
        final geo = _ScoreGeometry(w, weeks.length, top);
        final Offset mark = Offset(geo.x(at), geo.y(scores[at]));
        return GestureDetector(
          key: const ValueKey('journey-chart'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onChoose(geo.nearest(d.localPosition.dx)),
          child: SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ScorePainter(
                      geo: geo,
                      scores: scores,
                      ink: ink,
                      ground: ground,
                      yLabels: [axis(top), axis(top ~/ 2), axis(0)],
                      xLabels: labels,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  left: mark.dx - 12,
                  top: mark.dy - 12,
                  width: 24,
                  height: 24,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _RingPainter(
                        pink: _pink(context),
                        ground: ground,
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < weeks.length; i++)
                  Positioned(
                    left: geo.x(i) - 13,
                    top: geo.y(scores[i]) - 13,
                    width: 26,
                    height: 26,
                    child: Semantics(
                      button: true,
                      selected: i == at,
                      child: GestureDetector(
                        key: ValueKey('journey-week-$i'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChoose(i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Where the score chart puts things: the design's 338 by 230, with the
/// width taken from the phone.
class _ScoreGeometry {
  _ScoreGeometry(this.width, this.n, this.top);

  final double width;
  final int n;
  final int top;

  static const double left = 36;
  static const double base = 200;
  static const double rise = 186;

  double get right => width - 8;

  double x(int i) => n <= 1 ? right : left + i / (n - 1) * (right - left);
  double y(int v) => base - (v / top).clamp(0.0, 1.0) * rise;

  int nearest(double dx) {
    var best = 0;
    for (var i = 1; i < n; i++) {
      if ((x(i) - dx).abs() < (x(best) - dx).abs()) best = i;
    }
    return best;
  }
}

class _ScorePainter extends CustomPainter {
  _ScorePainter({
    required this.geo,
    required this.scores,
    required this.ink,
    required this.ground,
    required this.yLabels,
    required this.xLabels,
  });

  final _ScoreGeometry geo;
  final List<int> scores;
  final Color ink;
  final Color ground;
  final List<String> yLabels;
  final List<(int, String)> xLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..color = ink.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final double y = 14 + 31.0 * i;
      canvas.drawLine(
        Offset(_ScoreGeometry.left, y),
        Offset(geo.right + 0, y),
        grid,
      );
    }
    canvas.drawLine(
      const Offset(_ScoreGeometry.left, _ScoreGeometry.base),
      Offset(geo.right, _ScoreGeometry.base),
      Paint()
        ..color = ink.withValues(alpha: 0.18)
        ..strokeWidth = 1,
    );
    final Color faint = ink.withValues(alpha: 0.4);
    _label(
      canvas,
      yLabels[0],
      const Offset(28, 17.5),
      color: faint,
      anchor: TextAlign.right,
    );
    _label(
      canvas,
      yLabels[1],
      const Offset(28, 110.5),
      color: faint,
      anchor: TextAlign.right,
    );
    _label(
      canvas,
      yLabels[2],
      const Offset(28, 203.5),
      color: faint,
      anchor: TextAlign.right,
    );

    double lastRight = -1e9;
    for (final (int i, String text) in xLabels) {
      final bool end = i == geo.n - 1 && geo.n > 1 || geo.n == 1;
      final double x = geo.x(i);
      if (x - lastRight < 30) continue;
      _label(
        canvas,
        text,
        Offset(x, 219),
        color: faint,
        anchor: end ? TextAlign.right : TextAlign.center,
      );
      lastRight = x;
    }

    final Path line = Path();
    for (var i = 0; i < scores.length; i++) {
      final Offset p = Offset(geo.x(i), geo.y(scores[i]));
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
    final Paint fill = Paint()..color = ground;
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ink;
    for (var i = 0; i < scores.length; i++) {
      final Offset p = Offset(geo.x(i), geo.y(scores[i]));
      canvas
        ..drawCircle(p, 3.5, fill)
        ..drawCircle(p, 3.5, ring);
    }
  }

  @override
  bool shouldRepaint(_ScorePainter old) => true;
}

/// The marker on the week picked: a pink dot, ringed in the ground and
/// again in pink.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.pink, required this.ground});

  final Color pink;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    canvas
      ..drawCircle(c, 12, Paint()..color = pink)
      ..drawCircle(c, 10, Paint()..color = ground)
      ..drawCircle(c, 6, Paint()..color = pink);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.pink != pink || old.ground != ground;
}

// ── The level ─────────────────────────────────────────────────────────────

/// The level by name, how far the next one is, and the ladder as seven bars
/// that grow: the ones climbed, this one, and the next dashed. Tapping it
/// opens the whole path.
class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.app});

  final AppState app;

  static const List<double> _heights = [14, 22, 30, 38, 46, 56, 70];

  String _toGo(AppLocalizations l, Step step) => switch (step.kind) {
    StepKind.read => l.journeyToGoCards(step.n),
    StepKind.answer => l.journeyToGoAnswers(step.n),
    StepKind.judge => l.journeyToGoSure(step.n),
    StepKind.hold => l.journeyToGoHeld(step.n),
    StepKind.gap => l.journeyToGoPoints(math.max(1, step.n - step.target)),
    StepKind.beforeJudged => l.journeyToGoSure(step.n),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final Standing standing = app.standing;
    final int at = standing.at;
    final Rung? next = standing.next;
    final Step? step = standing.step;
    final String right = next == null
        ? l.topLevel
        : step == null
        ? l.nextRung(rungName(context, next))
        : l.journeyStepFrom(_toGo(l, step), rungName(context, next));

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
        child: _Box(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Kicker(l.journeyLevelOf(at + 1, kRungs.length)),
                        const SizedBox(height: 6),
                        _Big(rungName(context, standing.rung), size: 32),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      right,
                      textAlign: TextAlign.right,
                      style: AppText.body(
                        size: 11.5,
                        weight: FontWeight.w600,
                        height: 1.3,
                        color: ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < kRungs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Expanded(
                      child: SizedBox(
                        height: _heights[math.min(i, _heights.length - 1)],
                        child: i == at + 1
                            ? CustomPaint(
                                painter: _DashedBarPainter(
                                  color: ink.withValues(alpha: 0.4),
                                ),
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: i == at
                                      ? ink
                                      : ink.withValues(
                                          alpha: i < at ? 0.38 : 0.08,
                                        ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The next step on the ladder: an outline, dashed, not yet filled.
class _DashedBarPainter extends CustomPainter {
  _DashedBarPainter({required this.color, this.radius = 5, this.fill = 0});

  final Color color;
  final double radius;

  /// How much of it is filled from the foot, 0 to 1.
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      Radius.circular(radius),
    );
    if (fill > 0) {
      canvas
        ..save()
        ..clipRRect(r)
        ..drawRect(
          Rect.fromLTRB(0, size.height * (1 - fill), size.width, size.height),
          Paint()..color = color.withValues(alpha: 1),
        )
        ..restore();
    }
    canvas.drawPath(
      _dashed(Path()..addRRect(r), dash: 3.5, gap: 2.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_DashedBarPainter old) =>
      old.color != color || old.fill != fill;
}

// ── Worth, and the days in a row ──────────────────────────────────────────

/// The cards read as books, fifty to a book, with the book under way drawn
/// as far as it has got.
class _WorthTile extends StatelessWidget {
  const _WorthTile({required this.app});

  final AppState app;

  static const int perBook = 50;
  static const List<double> _spines = [34, 30, 36, 31, 35, 32, 33];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final int n = app.seenIds.length;
    final int books = n ~/ perBook;
    final int full = math.min(books, 6);
    final double part = (n % perBook) / perBook;

    return _Half(
      label: l.journeyWorth,
      value: books == 0 ? l.journeyCards(n) : l.journeyBooks(books),
      sub: books == 0
          ? l.journeyToFirstBook(perBook - n)
          : l.journeyOrDocumentaries((n * 3 / 60).round()),
      foot: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < full; i++) ...[
            Container(
              width: 14,
              height: _spines[i],
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i.isEven ? ink : ink.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
          ],
          SizedBox(
            width: 14,
            height: _spines[full],
            child: CustomPaint(
              painter: _DashedBarPainter(
                color: ink.withValues(alpha: 0.5),
                radius: 3,
                fill: part,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Days in a row, the best run, and the last two weeks as squares.
class _InARowTile extends StatelessWidget {
  const _InARowTile({required this.app, required this.record});

  final AppState app;
  final JourneyRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final int active = record.activeDays
        .where(
          (d) =>
              d.compareTo(record.start) >= 0 &&
              d.compareTo(record.todayKey) <= 0,
        )
        .length;
    final List<bool> last14 = [
      for (var i = 13; i >= 0; i--)
        record.activeDays.contains(record.daysBefore(i)),
    ];

    Widget row(int from) => Row(
      children: [
        for (var i = from; i < from + 7; i++) ...[
          if (i > from) const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: last14[i] ? ink : ink.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ],
    );

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
        child: _Half(
          label: l.journeyInARow,
          value: l.journeyDays(app.liveStreak),
          sub: l.journeyBestActive(app.bestStreak, active, record.daysIn),
          foot: Column(children: [row(0), const SizedBox(height: 3), row(7)]),
        ),
      ),
    );
  }
}

// ── The subjects ──────────────────────────────────────────────────────────

/// The subjects round the wheel in the order of their colours, Thinking,
/// which has none, last.
List<String> get _wheel {
  int rank(String key) {
    final TopicStyle s = kTopics[key]!;
    final int i = kSpectrum.indexOf(s.color);
    if (i >= 0) return i;
    return key == 'thinking' ? 1000 : 500;
  }

  return [
    for (final key in kTopicOrder)
      if (kTopics.containsKey(key)) key,
  ]..sort((a, b) => rank(a).compareTo(rank(b)));
}

/// How far the reading reaches into each subject, as a shape: the cards
/// read in each, round the wheel, with the first month dashed under it.
class _SubjectsTile extends StatelessWidget {
  const _SubjectsTile({required this.app, required this.record});

  final AppState app;
  final JourneyRecord record;

  /// The cards read of a subject, from its mark on the wheel.
  void _open(BuildContext context, String key) {
    final TopicStyle style = kTopics[key]!;
    final List<Pill> deck = PillBank.cards
        .where((p) => p.topic == style.name && app.seenIds.contains(p.id))
        .toList();
    if (deck.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DeckViewerScreen(app: app, deck: deck, title: style.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final List<String> keys = _wheel;
    final Map<String, Pill> byId = {for (final p in PillBank.cards) p.id: p};
    Map<String, int> countIn(Iterable<String> ids) {
      final out = <String, int>{};
      for (final id in ids) {
        final String? topic = byId[id]?.topic;
        if (topic != null) out[topic] = (out[topic] ?? 0) + 1;
      }
      return out;
    }

    final Map<String, int> now = countIn(app.seenIds);
    final month = _firstMonth(record);
    final Map<String, int>? then = month == null
        ? null
        : countIn(record.readBy(month.last));
    final List<int> values = [for (final k in keys) now[kTopics[k]!.name] ?? 0];
    final List<int>? ghost = then == null
        ? null
        : [for (final k in keys) then[kTopics[k]!.name] ?? 0];
    final int opened = values.where((v) => v > 0).length;

    return _Box(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _Big(l.journeySubjectsOf(opened, keys.length)),
                const SizedBox(width: 8),
                Flexible(
                  child: _Unit(
                    month == null
                        ? l.journeySubjects
                        : l.journeySubjectsDashed(_month(context, month.first)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, box) {
              final double k = 0.94 * math.min(1.0, box.maxWidth / 362);
              final double h = 300 * k + 2;
              return SizedBox(
                key: const ValueKey('journey-radar'),
                width: box.maxWidth,
                height: h,
                child: _Radar(
                  keys: keys,
                  values: values,
                  ghost: ghost,
                  scale: k,
                  onOpen: (key) => _open(context, key),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Radar extends StatelessWidget {
  const _Radar({
    required this.keys,
    required this.values,
    required this.ghost,
    required this.scale,
    required this.onOpen,
  });

  final List<String> keys;
  final List<int> values;
  final List<int>? ghost;
  final double scale;

  /// Opens the cards read of a subject, by key.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final Offset c = Offset(box.maxWidth / 2, box.maxHeight / 2);
        final double r = 112 * scale;
        final int most = math.max(1, values.fold(0, math.max));
        Offset at(int i, double f) {
          final double a = (-90 + i * 360 / keys.length) * math.pi / 180;
          return c + Offset(math.cos(a), math.sin(a)) * r * f;
        }

        final double icon = 24 * scale;
        final double dot = 8 * scale;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RadarPainter(
                  n: keys.length,
                  at: at,
                  values: values,
                  ghost: ghost,
                  most: most,
                  ink: context.p.ink,
                ),
              ),
            ),
            for (var i = 0; i < keys.length; i++)
              if (values[i] > 0)
                Positioned(
                  left: at(i, math.sqrt(values[i] / most)).dx - dot / 2,
                  top: at(i, math.sqrt(values[i] / most)).dy - dot / 2,
                  width: dot,
                  height: dot,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kTopics[keys[i]]!.color,
                    ),
                  ),
                ),
            for (var i = 0; i < keys.length; i++)
              Positioned(
                left: at(i, 1.2).dx - icon / 2,
                top: at(i, 1.2).dy - icon / 2,
                width: icon,
                height: icon,
                child: Semantics(
                  button: values[i] > 0,
                  label: kTopics[keys[i]]!.name,
                  child: GestureDetector(
                    key: ValueKey('subject-${keys[i]}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: values[i] > 0 ? () => onOpen(keys[i]) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kTopics[keys[i]]!.color,
                      ),
                      alignment: Alignment.center,
                      child: SubjectIcon(
                        subject: kTopics[keys[i]]!.name,
                        size: 13 * scale,
                        ink: kTopics[keys[i]]!.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.n,
    required this.at,
    required this.values,
    required this.ghost,
    required this.most,
    required this.ink,
  });

  final int n;
  final Offset Function(int, double) at;
  final List<int> values;
  final List<int>? ghost;
  final int most;
  final Color ink;

  Path _shape(double Function(int) f) {
    final Path p = Path();
    for (var i = 0; i < n; i++) {
      final Offset o = at(i, f(i));
      if (i == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ink.withValues(alpha: 0.09);
    for (final double f in const [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawPath(_shape((_) => f), rings);
    }
    final Paint spokes = Paint()
      ..strokeWidth = 1
      ..color = ink.withValues(alpha: 0.06);
    for (var i = 0; i < n; i++) {
      canvas.drawLine(at(i, 0), at(i, 1), spokes);
    }
    final List<int>? was = ghost;
    if (was != null) {
      canvas.drawPath(
        _dashed(_shape((i) => math.sqrt(was[i] / most)), dash: 3, gap: 4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..color = ink.withValues(alpha: 0.4),
      );
    }
    final Path shape = _shape((i) => math.sqrt(values[i] / most));
    canvas
      ..drawPath(shape, Paint()..color = ink.withValues(alpha: 0.12))
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = ink,
      );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => true;
}

// ── How hard, and how long ────────────────────────────────────────────────

double _level(Difficulty d) => switch (d) {
  Difficulty.easy => 1,
  Difficulty.medium => 2,
  Difficulty.hard => 3,
};

/// How hard the cards the reader opens are, easy one to hard three: the
/// last four weeks, the first month, and every week between as a line.
class _HowHardTile extends StatelessWidget {
  const _HowHardTile({required this.record});

  final JourneyRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Map<String, Pill> byId = {for (final p in PillBank.cards) p.id: p};
    double? mean(Iterable<String> ids) {
      var n = 0;
      var sum = 0.0;
      for (final id in ids) {
        final Pill? p = byId[id];
        if (p == null) continue;
        n++;
        sum += _level(p.difficulty);
      }
      return n == 0 ? null : sum / n;
    }

    final String from = record.daysBefore(27);
    final double? now =
        mean(record.readBetween(from, record.todayKey)) ?? mean(record.seen);
    final month = _firstMonth(record);
    final double? then = month == null
        ? null
        : mean(record.readBetween(record.start, month.last));
    final List<double> weekly = [
      for (final w in record.weeks())
        ?mean(record.readBetween(w.first, w.last)),
    ];
    final NumberFormat one = NumberFormat('0.0', _locale(context));

    return _Half(
      label: l.journeyHowHard,
      value: now == null ? '—' : one.format(now),
      unit: l.journeyOfThree,
      sub: then == null
          ? l.journeyHardNow
          : l.journeyHardThen(one.format(then), _month(context, month!.first)),
      foot: _Spark(values: weekly, height: 34, lo: 1, hi: 3),
    );
  }
}

/// Time on the cards, as far as the app has timed it: the total, minutes a
/// week lately against the start, and the last weeks as bars.
class _ReadingTimeTile extends StatelessWidget {
  const _ReadingTimeTile({required this.record});

  final JourneyRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final String? timed = record.firstTimed;
    final int seconds = record.secondsBetween('0000-00-00', '9999-99-99');
    final int minutes = (seconds / 60).round();
    final List<JourneyWeek> weeks = record.weeks(most: 13);
    final List<int> perWeek = [
      for (final w in weeks)
        (record.secondsBetween(w.first, w.last) / 60).round(),
    ];
    final List<int> full = [
      for (final w in record.weeks())
        if (!w.current && timed != null && w.last.compareTo(timed) >= 0)
          (record.secondsBetween(w.first, w.last) / 60).round(),
    ];
    final int most = math.max(1, perWeek.fold(0, math.max));

    final String value;
    if (timed == null) {
      value = '—';
    } else if (minutes < 60) {
      value = l.journeyMinutes(minutes);
    } else {
      value = l.journeyHoursMinutes(
        minutes ~/ 60,
        (minutes % 60).toString().padLeft(2, '0'),
      );
    }
    final String sub;
    if (timed == null) {
      sub = l.journeyTimedFromToday;
    } else if (full.length >= 2) {
      final int span = math.min(4, full.length ~/ 2);
      int mean(Iterable<int> m) => (m.fold(0, (a, b) => a + b) / span).round();
      sub = l.journeyMinAWeek(
        mean(full.sublist(full.length - span)),
        mean(full.take(span)),
      );
    } else {
      sub = l.journeyMinThisWeek(perWeek.isEmpty ? 0 : perWeek.last);
    }

    return _Half(
      label: l.journeyReadingTime,
      value: value,
      sub: sub,
      foot: SizedBox(
        height: 34,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < perWeek.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: math.max(3, perWeek[i] / most * 34),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i == perWeek.length - 1
                        ? ink.withValues(alpha: 0.25)
                        : i >= perWeek.length - 5
                        ? ink
                        : ink.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sure, and right ───────────────────────────────────────────────────────

/// How many points the reader's confidence runs off their results, from
/// the first week it could be measured, against the band the top level
/// asks for.
class _PointsOffTile extends StatelessWidget {
  const _PointsOffTile({required this.app, required this.record});

  final AppState app;
  final JourneyRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final double? gap = app.confidenceGap;
    final List<JourneyWeek> weeks = record.weeks();
    final List<double?> weekly = [
      for (final w in weeks) w.current ? gap : app.confidenceGapOn(w.last),
    ];
    final double? first = weekly.whereType<double>().firstOrNull;
    final int measured = weekly.whereType<double>().length;
    final Rung top = kRungs.last;
    final int sharp = (top.gap ?? 10).round();
    final int toGo = kCalibrationFloor - app.judgements.length;

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _Big(
                gap == null ? '—' : '${gap.round()}',
                valueKey: const ValueKey('journey-gap'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Unit(
                  first != null && measured >= 2
                      ? l.journeyPointsOffFrom(first.round())
                      : l.journeyPointsOff,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _upper(
                  context,
                  l.journeyRungOrLess(rungName(context, top), sharp),
                ),
                style: AppText.body(
                  size: 9.5,
                  weight: FontWeight.w700,
                  height: 1,
                  spacing: 1.2,
                  color: _green(context),
                ),
              ),
            ],
          ),
          if (gap == null && toGo > 0) ...[
            const SizedBox(height: 8),
            Text(
              l.journeyOffNotYet(toGo),
              style: AppText.body(
                size: 11,
                weight: FontWeight.w500,
                height: 1.35,
                color: ink.withValues(alpha: 0.45),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: CustomPaint(
              painter: _OffPainter(
                weekly: weekly,
                sharp: sharp.toDouble(),
                ink: ink,
                ground: context.p.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffPainter extends CustomPainter {
  _OffPainter({
    required this.weekly,
    required this.sharp,
    required this.ink,
    required this.ground,
  });

  final List<double?> weekly;
  final double sharp;
  final Color ink;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final double most = weekly.whereType<double>().fold(35.0, math.max);
    final double top = most <= 35 ? 35 : (most / 5).ceil() * 5.0;
    double y(double v) => 127 - (v / top).clamp(0.0, 1.0) * 122;
    final int n = weekly.length;
    double x(int i) =>
        n <= 1 ? size.width - 6 : 6 + i / (n - 1) * (size.width - 12);

    canvas.drawRect(
      Rect.fromLTRB(0, y(sharp), size.width, 130),
      Paint()..color = _greenFill.withValues(alpha: 0.13),
    );
    final Paint grid = Paint()
      ..strokeWidth = 1
      ..color = ink.withValues(alpha: 0.08);
    for (final double v in const [10, 20, 30]) {
      canvas.drawLine(Offset(0, y(v)), Offset(size.width, y(v)), grid);
    }
    final points = <Offset>[
      for (var i = 0; i < n; i++)
        if (weekly[i] != null) Offset(x(i), y(weekly[i]!)),
    ];
    if (points.isEmpty) return;
    final Path line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
    final Paint fill = Paint()..color = ground;
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ink;
    for (final p in points) {
      canvas
        ..drawCircle(p, 3.2, fill)
        ..drawCircle(p, 3.2, ring);
    }
  }

  @override
  bool shouldRepaint(_OffPainter old) => true;
}

/// Sure answers before a week is drawn on the line.
const int _sureFloor = 5;

/// How often the reader was right when they said 80% sure or more.
class _SureTile extends StatelessWidget {
  const _SureTile({required this.record});

  final JourneyRecord record;

  /// The four weeks up to [day], as the tile counts "now".
  Tally _window(String day) =>
      record.sureBetween(JourneyRecord.before(day, 27), day);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Tally lately = _window(record.todayKey);
    final Tally ever = record.sureBy(record.todayKey);
    final Tally now = lately.of >= _sureFloor ? lately : ever;
    // A week is drawn once there are a few sure answers in the four weeks
    // up to it: one sure answer, wrong, is not "right 0% of the time".
    final weekly = <(JourneyWeek, double)>[
      for (final w in record.weeks())
        if (_window(w.last) case Tally(:final double share, :final int of)
            when of >= _sureFloor)
          (w, share),
    ];
    final List<double> values = [for (final w in weekly) w.$2 * 100];
    final double lo = values.isEmpty
        ? 40
        : math.min(40, (values.reduce(math.min) / 10).floor() * 10.0);
    final double hi = values.isEmpty
        ? 80
        : math.max(80, (values.reduce(math.max) / 10).ceil() * 10.0);

    String? sub;
    if (now.share == null) {
      sub = l.journeySureNone;
    } else if (weekly.length >= 2) {
      sub = l.journeyFromIn(
        _percent(context, weekly.first.$2),
        _month(context, dayOfKey(weekly.first.$1.last)),
      );
    }

    return _Half(
      label: l.journeyRightWhenSure,
      value: now.share == null ? '—' : _percent(context, now.share!),
      sub: sub,
      foot: _Spark(values: values, height: 40, lo: lo, hi: hi),
    );
  }
}

/// The moves the reader can spot, out of all of them, the newest, and how
/// the count has climbed week by week.
class _MovesTile extends StatelessWidget {
  const _MovesTile({required this.app, required this.record});

  final AppState app;
  final JourneyRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Set<Principle> have = {
      for (final m in app.masteryByWeakness)
        if (m.isSettled && m.share >= 0.5) m.principle,
    };
    final int all = Principle.values.where((p) => p.isReal).length;
    final Principle? newest = record.newestMove(have);
    final List<JourneyWeek> weeks = record.weeks();
    final List<double> weekly = [
      for (final w in weeks)
        (w.current ? have.length : record.movesOn(w.last)).toDouble(),
    ];
    final double top = math.max(10, weekly.fold(0.0, math.max));

    return _Half(
      label: l.journeyMovesTitle,
      value: '${have.length}',
      unit: l.journeyOfN(all),
      sub: have.isEmpty
          ? l.journeyNoneYet
          : newest == null
          ? null
          : l.journeyNewest(newest.label),
      foot: _Spark(values: weekly, height: 40, lo: 0, hi: top, steps: true),
    );
  }
}

// ── What stayed ───────────────────────────────────────────────────────────

/// The cards still with the reader, and how the cards went when they came
/// back — after each wait on the review ladder — now against four weeks
/// ago.
class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.app, required this.record});

  final AppState app;
  final JourneyRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final int held = app.heldCards;
    final String before = record.daysBefore(28);

    Widget column(int wait) {
      final Tally now = record.recall(wait);
      final Tally was = record.recall(wait, by: before);
      final int days = kReviewLadder[wait];
      final String after = days % 7 == 0
          ? l.journeyRecallWeeks(now.right, now.of, days ~/ 7)
          : l.journeyRecallDays(now.right, now.of, days);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 1,
                    color: ink.withValues(alpha: 0.16),
                  ),
                ),
                Positioned.fill(
                  bottom: 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _Bar(
                          height: (was.share ?? 0) * 110,
                          color: ink.withValues(alpha: 0.22),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _Bar(height: (now.share ?? 0) * 110, color: ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            now.share == null ? '—' : _percent(context, now.share!),
            style: AppText.display(
              size: 17,
              weight: FontWeight.w600,
              height: 1,
              color: ink,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            after,
            style: AppText.body(
              size: 10.5,
              weight: FontWeight.w500,
              height: 1.3,
              color: ink.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _Big('$held', valueKey: const ValueKey('journey-held')),
              const SizedBox(width: 8),
              Flexible(child: _Unit(l.journeyStillWithYou(held))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var w = 0; w < kReviewLadder.length; w++) ...[
                if (w > 0) const SizedBox(width: 12),
                Expanded(child: column(w)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A bar standing on the line, allowed to rise past the top of its box as
/// the design's do.
class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => OverflowBox(
    alignment: Alignment.bottomCenter,
    maxHeight: math.max(height, 0),
    minHeight: 0,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    ),
  );
}

// ── The days ──────────────────────────────────────────────────────────────

/// The last thirteen weeks, a square a day, as dark as the cards read on it.
class _DaysTile extends StatelessWidget {
  const _DaysTile({required this.record});

  final JourneyRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final int active = record.activeDays
        .where(
          (d) =>
              d.compareTo(record.start) >= 0 &&
              d.compareTo(record.todayKey) <= 0,
        )
        .length;
    final DayPart? part = record.mostlyIn();
    final String? mostly = switch (part) {
      DayPart.morning => l.journeyMostlyMorning,
      DayPart.afternoon => l.journeyMostlyAfternoon,
      DayPart.evening => l.journeyMostlyEvening,
      DayPart.night => l.journeyMostlyNight,
      null => null,
    };
    final DateTime first = record.monday.subtract(const Duration(days: 7 * 12));

    Color shade(DateTime day) {
      final String key = dateKey(day);
      if (key.compareTo(record.todayKey) > 0 ||
          key.compareTo(record.start) < 0) {
        return const Color(0x00000000);
      }
      int n = record.readOnDay(key).length;
      if (n == 0 && record.activeDays.contains(key)) n = 1;
      if (n == 0) return ink.withValues(alpha: 0.07);
      if (n <= 3) return ink.withValues(alpha: 0.3);
      if (n == 4) return ink.withValues(alpha: 0.52);
      if (n == 5) return ink.withValues(alpha: 0.78);
      return ink;
    }

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  l.journeyActiveDays(active, record.daysIn),
                  key: const ValueKey('journey-days'),
                  style: AppText.body(
                    size: 15,
                    weight: FontWeight.w600,
                    height: 1.2,
                    color: ink,
                  ),
                ),
              ),
              if (mostly != null)
                Text(
                  mostly,
                  style: AppText.body(
                    size: 11.5,
                    weight: FontWeight.w600,
                    height: 1,
                    color: ink.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final double cell = (box.maxWidth - 12 * 3) / 13;
              return Row(
                children: [
                  for (var w = 0; w < 13; w++) ...[
                    if (w > 0) const SizedBox(width: 3),
                    Column(
                      children: [
                        for (var d = 0; d < 7; d++) ...[
                          if (d > 0) const SizedBox(height: 3),
                          Container(
                            width: cell,
                            height: cell,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: shade(
                                first.add(Duration(days: w * 7 + d)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── How far it reaches ────────────────────────────────────────────────────

/// When each era the cards are set in starts, by tag.
const Map<String, int> _eraStarts = {
  'ancient': -3000,
  'medieval': 500,
  'early_modern': 1500,
  'nineteenth': 1800,
  'twentieth': 1900,
  'recent': 2000,
};

Iterable<Pill> _readCards(AppState app) =>
    PillBank.cards.where((p) => app.seenIds.contains(p.id));

/// How far back in time the cards read reach: from the oldest era one is
/// set in to this year.
class _InTimeTile extends StatelessWidget {
  const _InTimeTile({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String? oldest;
    for (final p in _readCards(app)) {
      final int? from = _eraStarts[p.era];
      if (from == null) continue;
      if (oldest == null || from < _eraStarts[oldest]!) oldest = p.era;
    }
    if (oldest == null) {
      return _Half(
        label: l.journeyInTime,
        value: '—',
        sub: l.journeyNothingDated,
        size: 24,
      );
    }
    final int years = app.today.year - _eraStarts[oldest]!;
    final int shown = years >= 100 ? (years / 100).round() * 100 : years;
    final String era = switch (oldest) {
      'ancient' => l.journeyEraAncient,
      'medieval' => l.journeyEraMedieval,
      'early_modern' => l.journeyEraEarlyModern,
      'nineteenth' => l.journeyEraNineteenth,
      'twentieth' => l.journeyEraTwentieth,
      _ => l.journeyEraRecent,
    };
    return _Half(
      label: l.journeyInTime,
      value: l.journeyYears(shown),
      sub: l.journeyFromEra(era),
      size: 24,
    );
  }
}

/// Where in the world the cards read are set: how many regions, the ones
/// read most, and space.
class _InPlaceTile extends StatelessWidget {
  const _InPlaceTile({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final counts = <String, int>{};
    var space = false;
    for (final p in _readCards(app)) {
      if (p.topic == 'Space') space = true;
      if (p.region.isEmpty || p.region == 'none' || p.region == 'world') {
        continue;
      }
      counts[p.region] = (counts[p.region] ?? 0) + 1;
    }
    String? name(String region) => switch (region) {
      'americas' => l.journeyRegionAmericas,
      'europe' => l.journeyRegionEurope,
      'asia' => l.journeyRegionAsia,
      'oceania' => l.journeyRegionOceania,
      'africa' => l.journeyRegionAfrica,
      'middle_east' => l.journeyRegionMiddleEast,
      _ => null,
    };
    final List<String> named = [
      for (final e
          in counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
        ?name(e.key),
    ];
    if (named.isEmpty) {
      return _Half(
        label: l.journeyInPlace,
        value: '—',
        sub: l.journeyNoPlace,
        size: 24,
      );
    }
    final String joined = named.take(3).join(', ');
    final String list = joined[0].toUpperCase() + joined.substring(1);
    return _Half(
      label: l.journeyInPlace,
      value: l.journeyRegions(named.length),
      sub: space ? l.journeyPlacesAndSpace(list) : list,
      size: 24,
    );
  }
}

/// The topics inside the subjects that the reader has met, and the subject
/// with most of them.
class _TopicsTile extends StatelessWidget {
  const _TopicsTile({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final strands = <String>{};
    final bySubject = <String, Set<String>>{};
    for (final p in _readCards(app)) {
      if (p.strand.isEmpty) continue;
      strands.add(p.strand);
      bySubject.putIfAbsent(p.topic, () => {}).add(p.strand);
    }
    if (strands.isEmpty) {
      return _Half(
        label: l.journeyTopics,
        value: '—',
        sub: l.journeyNoneYet,
        size: 24,
      );
    }
    final MapEntry<String, Set<String>> most = bySubject.entries.reduce(
      (a, b) => b.value.length > a.value.length ? b : a,
    );
    return _Half(
      label: l.journeyTopics,
      value: l.journeyMet(strands.length),
      sub: l.journeyTopicsMost(most.value.length, most.key),
      size: 24,
    );
  }
}

/// The terms the reader has met in the cards — the handles the bank uses
/// on three cards or more — and the three met last.
class _WordsTile extends StatelessWidget {
  const _WordsTile({required this.app, required this.record});

  final AppState app;
  final JourneyRecord record;

  static Map<String, int>? _inBank;
  static int _bankSize = -1;

  /// How many cards in the bank carry each handle, worked out again when
  /// the bank grows.
  static Map<String, int> get inBank {
    if (_inBank == null || _bankSize != PillBank.cards.length) {
      final out = <String, int>{};
      for (final p in PillBank.cards) {
        for (final k in p.keywords) {
          out[k] = (out[k] ?? 0) + 1;
        }
      }
      _inBank = out;
      _bankSize = PillBank.cards.length;
    }
    return _inBank!;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Map<String, int> bank = inBank;
    final Map<String, Pill> byId = {for (final p in PillBank.cards) p.id: p};
    bool term(String k) => (bank[k] ?? 0) >= 3;
    final met = <String>{
      for (final p in _readCards(app))
        for (final k in p.keywords)
          if (term(k)) k,
    };
    if (met.isEmpty) {
      return _Half(
        label: l.journeyWords,
        value: '—',
        sub: l.journeyNoneYet,
        size: 24,
      );
    }
    final latest = <String>[];
    for (final day
        in record.readDays.keys.toList()..sort((a, b) => b.compareTo(a))) {
      for (final id in record.readDays[day]!.reversed) {
        for (final k in byId[id]?.keywords ?? const <String>[]) {
          if (term(k) && !latest.contains(k)) latest.add(k);
        }
        if (latest.length >= 3) break;
      }
      if (latest.length >= 3) break;
    }
    if (latest.isEmpty) latest.addAll(met.take(3));
    final String joined = latest.take(3).join(', ');
    final String words = joined[0].toUpperCase() + joined.substring(1);
    return _Half(
      label: l.journeyWords,
      value: l.journeyNew(met.length),
      sub: '$words…',
      size: 24,
    );
  }
}
