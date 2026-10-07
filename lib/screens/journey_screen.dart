import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../data/genres.dart';
import '../data/pills_repository.dart' show dateKey;
import '../data/pill_bank.dart';
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
import 'week_screen.dart';
import 'progress_text.dart';

/// Your journey: the numbers first, the card to say last.
///
/// Everything on it is counted from what the app already writes down. The
/// order is the argument. At the top (artboard 134b) what the reading has
/// come to — the level with what it claims about the reader, the ladder it
/// stands on, five numbers and how sure the reader says they are against
/// how often they are right — and, once there is a past to show, the same
/// reader two weeks in, a tap away. Then where the reading has gone (by
/// subject), and at the foot the one thing to do with it tonight: a card
/// to say out loud to somebody. A page of statistics that ends in an
/// action.
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

  /// Whether the top shows the reader two weeks in rather than today.
  bool _then = false;

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
                        _Top(
                          app: app,
                          then: _then,
                          onThen: (then) => setState(() => _then = then),
                        ),
                        const SizedBox(height: 22),
                        _Week(app: app),
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

/// The record as one number, in a pill beside the title: what the score
/// is, without taking the page from what it is made of.
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

/// The top of the journey: the reader today — or, once there is a past to
/// show, two weeks in — as a level, the ladder, five numbers and the curve
/// of how sure against how right.
class _Top extends StatelessWidget {
  const _Top({required this.app, required this.then, required this.onThen});

  final AppState app;

  /// Showing two weeks in rather than today.
  final bool then;
  final ValueChanged<bool> onThen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    final String start =
        journeyStart(app.rungDates, app.completedDates) ?? dateKey(app.today);
    final bool compare = canCompare(start, app.today);
    final String thenDay = twoWeeksIn(start);
    final String thenLabel = DateFormat.MMMMd(locale)
        .format(DateTime.parse(thenDay));
    final RecordAt now = recordNow(app);
    final RecordAt? past = compare ? recordOn(app, thenDay) : null;
    final bool showingThen = then && past != null;
    final RecordAt shown = showingThen ? past : now;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (past != null) ...[
          _When(
            thenLabel: thenLabel,
            nowLabel: l.journeyNow,
            then: showingThen,
            onThen: onThen,
          ),
          const SizedBox(height: 22),
        ],
        _Standing(
          app: app,
          level: shown.level,
          kicker: showingThen
              ? l.journeyKickerThen(shown.level + 1, kRungs.length)
              : l.journeyKickerNow(
                  dayOf(start, app.today),
                  shown.level + 1,
                  kRungs.length,
                ),
        ),
        const SizedBox(height: 20),
        _Rows(now: now, past: past, then: showingThen),
        if (now.gap != null) ...[
          const SizedBox(height: 14),
          _Curve(
            now: now,
            past: past?.gap == null ? null : past,
            then: showingThen,
            thenLabel: thenLabel,
          ),
        ],
      ],
    );
  }
}

/// Two weeks in, or today: one switch, two halves.
class _When extends StatelessWidget {
  const _When({
    required this.thenLabel,
    required this.nowLabel,
    required this.then,
    required this.onThen,
  });

  final String thenLabel;
  final String nowLabel;
  final bool then;
  final ValueChanged<bool> onThen;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    Widget half(String label, bool on, bool value, String key) => Expanded(
      child: Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          key: ValueKey(key),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (on) return;
            HapticFeedback.selectionClick();
            onThen(value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? context.p.inverse : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w600,
                height: 1,
                color: on ? context.p.onInverse : ink.withValues(alpha: 0.62),
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          half(thenLabel, then, true, 'journey-then'),
          half(nowLabel, !then, false, 'journey-now'),
        ],
      ),
    );
  }
}

/// The level, set large, what it says about the reader, and the ladder it
/// stands on — first rung to last, the one they are on lit. Tapping it
/// opens the whole path.
class _Standing extends StatelessWidget {
  const _Standing({
    required this.app,
    required this.level,
    required this.kicker,
  });

  final AppState app;
  final int level;
  final String kicker;

  /// The ladder's steps, first to last, in points: they climb.
  static const List<double> steps = [14, 22, 30, 38, 46, 56, 70];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final Rung rung = kRungs[level.clamp(0, kRungs.length - 1)];
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
            Text(
              kicker,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                size: 10,
                weight: FontWeight.w700,
                spacing: 1.4,
                color: ink.withValues(alpha: 0.42),
              ),
            ),
            const SizedBox(height: 12),
            // One line, however long the level's name is in this language:
            // a long one comes down in size rather than over two lines.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                rungName(context, rung),
                maxLines: 1,
                style: AppText.display(
                  size: 58,
                  weight: FontWeight.w600,
                  height: 0.95,
                  spacing: -2.6,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.rungClaim(rung.id),
              style: AppText.body(
                size: 15,
                height: 1.4,
                color: ink.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: steps.last,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < kRungs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        height: steps[i.clamp(0, steps.length - 1)],
                        decoration: BoxDecoration(
                          color: i == level
                              ? ink
                              : ink.withValues(alpha: i < level ? 0.4 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    rungName(context, kRungs.first),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: ink.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  rungName(context, kRungs.last),
                  style: AppText.body(
                    size: 10.5,
                    weight: FontWeight.w600,
                    color: ink.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Five numbers, today's with how far each has come since two weeks in —
/// or, switched, as they stood then.
class _Rows extends StatelessWidget {
  const _Rows({required this.now, required this.past, required this.then});

  final RecordAt now;
  final RecordAt? past;
  final bool then;

  static String _signed(int n) => n > 0 ? '+$n' : '−${n.abs()}';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    final NumberFormat number = NumberFormat.decimalPattern(locale);
    String percent(double? v) => v == null ? '—' : '${v.round()}%';
    String points(double? v) => v == null ? '—' : '${v.round()}';
    String count(int? v) => v == null ? '—' : number.format(v);
    int? diff(num? a, num? b) =>
        a == null || b == null ? null : a.round() - b.round();

    final RecordAt shown = then && past != null ? past! : now;
    final rows = <(String, String, String, int?)>[
      (
        'sure',
        l.journeyRowSure,
        percent(shown.sureRight),
        diff(now.sureRight, past?.sureRight),
      ),
      ('off', l.journeyRowOff, points(shown.gap), diff(now.gap, past?.gap)),
      (
        'moves',
        l.journeyRowMoves,
        count(shown.moves),
        diff(now.moves, past?.moves),
      ),
      ('held', l.journeyRowHeld, count(shown.held), diff(now.held, past?.held)),
      ('read', l.journeyRowRead, count(shown.read), diff(now.read, past?.read)),
    ];
    final Color ink = context.p.ink;
    return Column(
      children: [
        for (final (key, label, value, delta) in rows)
          Container(
            key: ValueKey('journey-row-$key'),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: ink.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppText.body(
                      size: 13.5,
                      weight: FontWeight.w500,
                      height: 1.3,
                      color: ink.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                // How far it has come, on today only: then is where it
                // came from.
                if (!then && past != null && delta != null && delta != 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _signed(delta),
                      style: AppText.body(
                        size: 11,
                        weight: FontWeight.w700,
                        height: 1,
                        color: ink,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 60),
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: AppText.display(
                      size: 26,
                      weight: FontWeight.w600,
                      height: 1,
                      spacing: -0.8,
                      color: ink,
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

/// How sure the reader said they were, against how often they were right,
/// level by level — today's line, two weeks in under it, and the diagonal
/// where the two would be the same.
class _Curve extends StatelessWidget {
  const _Curve({
    required this.now,
    required this.past,
    required this.then,
    required this.thenLabel,
  });

  final RecordAt now;
  final RecordAt? past;
  final bool then;
  final String thenLabel;

  /// Two weeks in, in the colour the design gives the past.
  static const Color pastColour = Color(0xFFFF3D7F);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    Widget legend(Color colour, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: AppText.body(
            size: 11.5,
            weight: FontWeight.w600,
            height: 1,
            color: ink.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
    return Container(
      key: const ValueKey('journey-curve'),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.journeyCurveTitle,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w600,
              height: 1.3,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 342 / 230,
            child: CustomPaint(
              painter: _CurvePainter(
                now: now.curve,
                past: past?.curve,
                then: then,
                ink: ink,
                spotOn: l.journeyCurveSpotOn,
                textStyle: AppText.body(size: 10, weight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (past?.gap != null)
                legend(
                  pastColour,
                  l.journeyCurveLegend(thenLabel, past!.gap!.round()),
                ),
              legend(ink, l.journeyCurveLegend(l.journeyNow, now.gap!.round())),
            ],
          ),
        ],
      ),
    );
  }
}

/// The curve itself, on the design's own grid (342 by 230) scaled to the
/// card: confidence from 50% to 90% across, how often right up the side.
class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.now,
    required this.past,
    required this.then,
    required this.ink,
    required this.spotOn,
    required this.textStyle,
  });

  final List<CalibrationBucket> now;
  final List<CalibrationBucket>? past;
  final bool then;
  final Color ink;
  final String spotOn;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.width / 342;
    canvas.save();
    canvas.scale(k);
    final int lo = _floor();
    double x(num said) => 36 + (said - 50) / 40 * 294;
    double y(num right) => 200 - (right - lo) / (100 - lo) * 186;

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

    // Spot on: right as often as sure.
    final Offset from = Offset(x(50), y(50));
    final Offset to = Offset(x(90), y(90));
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
    _text(
      canvas,
      spotOn,
      ink.withValues(alpha: 0.45),
      at: from + unit * (length * 0.78) + Offset(unit.dy, -unit.dx) * 7,
      angle: math.atan2(unit.dy, unit.dx),
      align: 0.5,
    );

    void line(List<CalibrationBucket> buckets, Color colour, double width) {
      if (buckets.isEmpty) return;
      final points = [for (final b in buckets) Offset(x(b.said), y(b.actual))];
      final Paint stroke = Paint()
        ..color = colour
        ..strokeWidth = width
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      if (points.length == 1) {
        canvas.drawCircle(points.single, width * 1.4, stroke);
        return;
      }
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final Offset p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, stroke);
    }

    final List<CalibrationBucket>? before = past;
    if (before != null) {
      line(
        before,
        _Curve.pastColour.withValues(alpha: then ? 1 : 0.45),
        then ? 2.5 : 1.5,
      );
    }
    line(now, ink.withValues(alpha: then ? 0.3 : 1), then ? 1.5 : 2.5);

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
    final values = [...now, ...?past].map((b) => b.actual);
    if (values.isEmpty) return 40;
    final double least = values.reduce(math.min);
    if (least >= 40) return 40;
    return (least / 10).floor() * 10;
  }

  /// A label with its baseline at [at]; [align] 0 starts it there, 0.5
  /// centres it, 1 ends it.
  void _text(
    Canvas canvas,
    String text,
    Color colour, {
    required Offset at,
    double align = 0,
    double angle = 0,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(color: colour),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final double baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    painter.paint(canvas, Offset(-painter.width * align, -baseline));
    canvas.restore();
    painter.dispose();
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.then != then || old.ink != ink || old.now != now || old.past != past;
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
