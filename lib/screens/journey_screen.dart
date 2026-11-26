import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart' hide Step;
import 'package:intl/intl.dart' hide TextDirection;

import '../data/goals.dart';
import '../data/pill_bank.dart';
import '../debug_flags.dart';
import '../analytics.dart';
import '../data/pills_repository.dart' show dateKey, dayShift, pillById;
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/journey_record.dart';
import '../state/progress.dart';
import '../theme.dart';
import '../sync/card_ask.dart';
import '../sync/coach.dart';
import '../widgets/deeper_sheet.dart' show cardAiOn;
import '../widgets/share_day.dart';
import '../widgets/subject_icon.dart';
import '../widgets/ui.dart';
import 'deck_viewer_screen.dart';
import 'mix_screen.dart' show kMixSubjects;
import 'subject_home_screen.dart';
import 'progress_text.dart';
import 'week_screen.dart';
import 'path_screen.dart';
import '../widgets/card_edge.dart';
import '../widgets/count_since.dart';
import '../widgets/premium.dart';
import '../widgets/quick_return.dart';
import '../widgets/area_marks.dart' show goalName;
import '../widgets/level_up.dart' show showLevelUpIfDue;
import '../widgets/move_words.dart';
import '../widgets/skill_score.dart' show scoreUp, signedNumber;
import '../widgets/top_edge.dart';
import '../widgets/training.dart';

part 'journey_story.dart';

/// Your journey, as artboard 137a: tiles, two to a row.
///
/// The reader's training first, the Astute score large; what to practise;
/// the week; and everything else as tiles — the subjects, strongest and
/// most missed, what has stayed, how far the reading reaches in time, in
/// place, in topics and in words, how sure against how right, the moves,
/// the days in a row, the time, the days, what the reading is worth and how
/// hard; and the story so far.
///
/// Everything on it is counted from what the app writes down, with a date
/// where it has one ([JourneyRecord]). What it never wrote down is not
/// worked out now: a tile with nothing to go on shows a dash and says why.
///
/// It remembers every figure on it as the reader last saw it: opened again,
/// a figure that has moved since counts up from there, calmly, and keeps a
/// quiet mark of how far it went (lib/widgets/count_since.dart). That is
/// where the day's scores are seen to go up; the finished day no longer
/// raises a sheet of them.
///
/// The whole page scrolls, its title and the way back with it, as
/// Instagram's pages do: going down, the way back goes up and away with the
/// page; going back up even a little, it comes straight back over it
/// ([QuickReturn]). The page goes soft under the status bar as Explore's
/// does.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key, required this.app, required this.onBack});

  final AppState app;
  final VoidCallback onBack;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  /// The figures as the reader last saw them, frozen as the page opens, and
  /// what this visit sees of them, written down as it is seen.
  late final LastSeen _seen = LastSeen(
    was: widget.app.journeySeen,
    onSeen: widget.app.rememberJourney,
  );

  /// The day the reader last looked, as it was when the page opened.
  late final String? _lastOn = widget.app.journeySeenOn;

  @override
  void initState() {
    super.initState();
    // A level reached since one was last told rises over the journey once
    // it has come in (lib/widgets/level_up.dart). The figures under it
    // count once it has gone (count_since.dart): a count run behind it
    // would land unseen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showLevelUpIfDue(context, widget.app);
    });
  }

  @override
  void dispose() {
    _seen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final AppState app = widget.app;
    final JourneyRecord record = app.record;
    const chapterGap = SizedBox(height: 28);
    // Numbered as they come: the coach's chapter is there only where the
    // answers by Claude are on.
    var n = 0;
    final String language = Localizations.localeOf(context).languageCode;
    // The status bar's room, at least 12 where there is none (a browser):
    // the page starts under it and runs on under it once scrolled.
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final double top = math.max(safe.top, 12);

    final List<Widget> page = [
      // The title, beside where the way back stands, and gone with the
      // page as it scrolls.
      _Title(
        title: l.yourJourney,
        since: _lastOn,
        today: record.today,
        moved: _seen.moved,
      ),
      const SizedBox(height: 18),
      // The journey in chapters: what the reader trains and what to
      // practise first, then the week, then the numbers behind them,
      // grouped by what they are about, and the story so far at the end.
      // What the reader is training first: their Astute score, the one
      // number the journey keeps, and the skills they picked with theirs.
      _Chapter(
        n: ++n,
        title: l.trainingTitle,
        trailing: TrainingChapter.change(context, app),
        child: TrainingChapter(app: app),
      ),
      chapterGap,
      // What to do now, under the number it moves.
      _Chapter(
        n: ++n,
        title: l.storyChapterPractice,
        child: _Practice(app: app),
      ),
      chapterGap,
      // The week in one sentence, and the questions it left the reader
      // with, each a tap from its card.
      _Chapter(
        n: ++n,
        title: l.storyChapterWeek,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Headline(app: app),
            if (_WeekAsksTile.asksOf(app, record.today)
                case final List<Pill> asks when asks.isNotEmpty) ...[
              const SizedBox(height: 18),
              _WeekAsksTile(app: app, asks: asks),
            ],
          ],
        ),
      ),
      if (cardAiOn(app, language)) ...[
        chapterGap,
        _Chapter(
          n: ++n,
          title: l.journeyChapterCoach,
          child: _Coach(app: app),
        ),
      ],
      chapterGap,
      _Chapter(
        n: ++n,
        title: l.journeyChapterKnow,
        child: _Stack([
          _SubjectsTile(app: app, record: record),
          _Pair(
            _SpotTile(app: app, strongest: true),
            _SpotTile(app: app, strongest: false),
          ),
          // What has stayed: the cards still with the reader, and how they
          // held when they came back. Part of what they know, once
          // something has stayed; it was a chapter of its own near the end,
          // its bars of then and now hard to read.
          if (app.heldCards > 0) _MemoryTile(app: app, record: record),
          _Pair(_InTimeTile(app: app), _InPlaceTile(app: app)),
          _Pair(_TopicsTile(app: app), _WordsTile(app: app, record: record)),
        ]),
      ),
      chapterGap,
      _Chapter(
        n: ++n,
        title: l.storyChapterReason,
        child: _Stack([
          _HowYouReason(app: app),
          // How far off the reader's sureness is, once there are enough
          // answers to say: before, the line above says how many more,
          // and an empty chart said it again.
          if (app.calibratedAnswers >= kCalibrationFloor)
            _PointsOffTile(app: app, record: record),
          _Pair(
            _SureTile(record: record),
            _MovesTile(app: app, record: record),
          ),
          if (_MissingTile.missed(app).isNotEmpty) _MissingTile(app: app),
          // What the cards that ask did for the reader, in their own
          // word; nothing until one has asked.
          if (app.reactions.isNotEmpty)
            _Pair(
              _ReactionTile(app: app, changed: true),
              _ReactionTile(app: app, changed: false),
            ),
        ]),
      ),
      chapterGap,
      _Chapter(
        n: ++n,
        title: l.journeyChapterHabits,
        child: _Stack([
          _Pair(
            _InARowTile(app: app, record: record),
            _ReadingTimeTile(record: record),
          ),
          _DaysTile(record: record),
          _Pair(_WorthTile(app: app), _HowHardTile(record: record)),
        ]),
      ),
      chapterGap,
      _Chapter(
        n: ++n,
        title: l.storyChapterStory,
        child: _YourStory(app: app),
      ),
      // The day, sent as five squares, once it is done: the way the app
      // travels, kept at the foot of the journey. The finished day sends
      // it too, on either plan.
      if (app.dayClosed) ...[
        const SizedBox(height: 22),
        Center(
          child: ShareDay(app: app, from: 'journey'),
        ),
      ],
    ];

    return ScreenView(
      name: 'journey',
      child: Scaffold(
        backgroundColor: context.p.surface,
        body: LastSeenScope(
          seen: _seen,
          child: Stack(
            children: [
              // The way back is part of the page, as Instagram's is: it goes
              // up and away with the chapters, and the moment the reader
              // goes back up it comes back, on its glass, over whatever is
              // there; at the top it stands beside the title.
              Positioned.fill(
                child: QuickReturn(
                  clip: false,
                  header: Padding(
                    padding: EdgeInsets.only(left: 20, top: top + 8),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: BackCircle(
                        onPressed: widget.onBack,
                        floating: true,
                      ),
                    ),
                  ),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: ListView(
                      key: const ValueKey('journey-page'),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        top + 8,
                        16,
                        30 + safe.bottom,
                      ),
                      children: page,
                    ),
                  ),
                ),
              ),
              // Under the status bar, where the chapters run under the time
              // and the battery: they go soft and dissolve into the page,
              // as Explore's shelves do, and so does the way back on its
              // way up.
              Positioned(
                key: const ValueKey('journey-top-edge'),
                left: 0,
                right: 0,
                top: 0,
                height: top,
                child: IgnorePointer(child: TopEdge(ground: context.p.surface)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [child] growing into its room as it changes, or at once for whoever
/// asked for less motion: an animated size of no time at all re-dirties its
/// own layout.
class _Unfold extends StatelessWidget {
  const _Unfold({required this.still, required this.child});

  final bool still;
  final Widget child;

  @override
  Widget build(BuildContext context) => still
      ? child
      : AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: child,
        );
}

/// The page's title, with the way back standing beside it as the page
/// opens; and under it, once a figure on the page has moved since the
/// reader last looked, when that was, after a dot of the marks' green.
class _Title extends StatelessWidget {
  const _Title({
    required this.title,
    required this.since,
    required this.today,
    required this.moved,
  });

  final String title;

  /// The day the reader last looked, if they have.
  final String? since;
  final DateTime today;

  /// Whether anything on the page moved since then.
  final ValueListenable<bool> moved;

  /// The way back's room at the start of the row.
  static const double _back = 4 + 44 + 12;

  @override
  Widget build(BuildContext context) {
    final String? on = since;
    final int days = on == null
        ? 0
        : math.max(
            0,
            DateTime(
              today.year,
              today.month,
              today.day,
            ).difference(dayOfKey(on)).inDays,
          );
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(left: _back, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // As tall as the way back beside it, the title on its middle.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                header: true,
                child: Text(
                  title,
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
            ),
          ),
          if (on != null)
            ValueListenableBuilder<bool>(
              valueListenable: moved,
              builder: (context, moved, _) => _Unfold(
                still: still,
                child: !moved
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        key: const ValueKey('journey-since'),
                        padding: const EdgeInsets.only(top: 1),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: scoreUp(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                context.l10n.journeySince(days),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  size: 12.5,
                                  weight: FontWeight.w500,
                                  height: 1.25,
                                  color: context.p.ink.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
        ],
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

/// Capitals, with Turkish's dotted capital I.
String _upper(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// The month the reader started in, and its last day — once it is over.
({DateTime first, String last})? _firstMonth(JourneyRecord record) {
  final DateTime start = dayOfKey(record.start);
  final DateTime end = DateTime(start.year, start.month + 1, 0);
  if (!record.today.isAfter(end)) return null;
  return (first: start, last: dateKey(end));
}

/// A tile: the faint panel every number sits on.
class _Box extends StatelessWidget {
  const _Box({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

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
/// The tiles of a chapter, one under another, the usual gap between.
class _Stack extends StatelessWidget {
  const _Stack(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        children[i],
      ],
    ],
  );
}

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
  const _Unit(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    style: AppText.body(
      size: 12,
      weight: FontWeight.w600,
      height: 1.2,
      color: context.p.ink.withValues(alpha: 0.5),
    ),
  );
}

/// A figure of the journey that counts from where the reader last saw it
/// (lib/widgets/count_since.dart): its name, where it stands, and how it
/// reads at any value on the way.
class _Fig {
  const _Fig(
    this.id,
    this.value,
    this.text, {
    this.mark,
    this.better = Better.higher,
  });

  /// Its name, as it is remembered: 'streak', 'held'.
  final String id;
  final double value;

  /// How it reads at a value: '12 days'.
  final String Function(double value) text;

  /// How its mark says how far it went; by default the whole numbers'
  /// difference, with its sign.
  final String Function(BuildContext context, double was, double now)? mark;
  final Better better;
}

/// [fig], counting: [builder] sets it at each step, with its mark.
Widget _count(
  _Fig fig,
  Widget Function(BuildContext context, double value, String text, Widget? mark)
  builder,
) => CountSince(
  id: fig.id,
  value: fig.value,
  shows: fig.text,
  mark: fig.mark,
  better: fig.better,
  builder: (context, v, mark) => builder(context, v, fig.text(v), mark),
);

/// How far a share went, in the points the reader sees: +6%.
String _pointsMark(BuildContext context, double was, double now) {
  final int d = (now * 100).round() - (was * 100).round();
  final String sign = d > 0 ? '+' : (d < 0 ? '\u2212' : '');
  return '$sign${_percent(context, d.abs() / 100)}';
}

/// A large figure and, on its baseline, the word after it and the mark of
/// how far it went since the reader last looked.
class _BigLine extends StatelessWidget {
  const _BigLine(
    this.text, {
    this.unit,
    this.mark,
    this.size = 30,
    this.valueKey,
  });

  final String text;
  final String? unit;
  final Widget? mark;
  final double size;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    if (unit == null && mark == null) {
      return _Big(text, size: size, valueKey: valueKey);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: _Big(text, size: size, valueKey: valueKey),
        ),
        if (unit != null) ...[const SizedBox(width: 6), _Unit(unit!)],
        if (mark != null) ...[const SizedBox(width: 6), mark!],
      ],
    );
  }
}

/// A half tile: what it is, the number, a line under it, and a picture at
/// the foot. The number is [value] as it stands, or [fig], counting from
/// where the reader last saw it.
class _Half extends StatelessWidget {
  const _Half({
    super.key,
    required this.label,
    this.value,
    this.fig,
    this.unit,
    this.sub,
    this.foot,
    this.size = 30,
  }) : assert(value != null || fig != null);

  final String label;
  final String? value;
  final _Fig? fig;
  final String? unit;
  final String? sub;
  final Widget? foot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final _Fig? fig = this.fig;
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two lines where a language runs long (Russian, German),
          // rather than cut.
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 11.5,
              weight: FontWeight.w600,
              height: 1,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          if (fig == null)
            _BigLine(value!, unit: unit, size: size)
          else
            _count(
              fig,
              (context, _, text, mark) =>
                  _BigLine(text, unit: unit, mark: mark, size: size),
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

// ── The score ─────────────────────────────────────────────────────────────

// ── The level ─────────────────────────────────────────────────────────────

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

    // The cards as books once there is one; until then, as cards.
    String worth(double v) {
      final int cards = v.round();
      return cards < perBook
          ? l.journeyCards(cards)
          : l.journeyBooks(cards ~/ perBook);
    }

    return _Half(
      label: l.journeyWorth,
      fig: _Fig(
        'worth',
        n.toDouble(),
        worth,
        // In books once there were books; across the first, in cards.
        mark: (context, was, now) => was >= perBook
            ? signedNumber(context, now ~/ perBook - was ~/ perBook)
            : '+${l.journeyCards(now.round() - was.round())}',
      ),
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
          fig: _Fig(
            'streak',
            app.liveStreak.toDouble(),
            (v) => l.journeyDays(v.round()),
          ),
          sub: l.journeyBestActive(app.bestStreak, active, record.daysIn),
          foot: Column(children: [row(0), const SizedBox(height: 3), row(7)]),
        ),
      ),
    );
  }
}

// ── The subjects ──────────────────────────────────────────────────────────

/// The subjects round the wheel in the order of their colours, as the mix
/// lays them out (Maths between Science and Language, Life at the pale
/// end), Thinking, which has none, last.
List<String> get _wheel {
  int rank(String key) {
    final int i = kMixSubjects.indexWhere((s) => s.key == key);
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

  /// A subject's own home, from its mark on the wheel: how far into it,
  /// its level, the next card, its themes (subject_home_screen.dart).
  void _open(BuildContext context, String key) =>
      SubjectHomeScreen.open(context, app, key, from: 'journey');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final List<String> keys = _wheel;
    final Map<String, Pill> byId = {for (final p in PillBank.live) p.id: p};
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
                _count(
                  _Fig(
                    'subjects',
                    opened.toDouble(),
                    (v) => l.journeySubjectsOf(v.round(), keys.length),
                  ),
                  (context, _, text, mark) => _BigLine(text, mark: mark),
                ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l.journeySubjectsTap,
              key: const ValueKey('journey-subjects-tap'),
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 12.5,
                color: context.p.ink.withValues(alpha: 0.5),
              ),
            ),
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
                  button: true,
                  label: kTopics[keys[i]]!.name,
                  child: GestureDetector(
                    key: ValueKey('subject-${keys[i]}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onOpen(keys[i]),
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
    final Map<String, Pill> byId = {for (final p in PillBank.live) p.id: p};
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
      value: now == null ? '—' : null,
      fig: now == null
          ? null
          : _Fig(
              'hard',
              now,
              (v) => one.format(v),
              mark: (context, was, now) {
                final double d =
                    double.parse(one.format(now).replaceAll(',', '.')) -
                    double.parse(one.format(was).replaceAll(',', '.'));
                return '${d >= 0 ? '+' : '\u2212'}${one.format(d.abs())}';
              },
            ),
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

    String time(int m) => m < 60
        ? l.journeyMinutes(m)
        : l.journeyHoursMinutes(m ~/ 60, (m % 60).toString().padLeft(2, '0'));
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
      value: timed == null ? '—' : null,
      fig: timed == null
          ? null
          : _Fig(
              'minutes',
              minutes.toDouble(),
              (v) => time(v.round()),
              mark: (context, was, now) =>
                  '+${time(math.max(0, now.round() - was.round()))}',
            ),
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
    final int toGo = kCalibrationFloor - app.calibratedAnswers;

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (gap == null)
                const _Big('—', valueKey: ValueKey('journey-gap'))
              else
                _count(
                  _Fig('gap', gap, (v) => '${v.round()}', better: Better.lower),
                  (context, _, text, mark) => _BigLine(
                    text,
                    mark: mark,
                    valueKey: const ValueKey('journey-gap'),
                  ),
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
      value: now.share == null ? '—' : null,
      fig: now.share == null
          ? null
          : _Fig(
              'sure',
              now.share!,
              (v) => _percent(context, v),
              mark: _pointsMark,
            ),
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
      fig: _Fig('moves', have.length.toDouble(), (v) => '${v.round()}'),
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

// ── The moves you keep missing ────────────────────────────────────────────

/// The moves the reader gets wrong most, weakest first: each one named, the
/// reader's own record on it, and a bar.
///
/// Naming the move you missed, with your record on it, is the part of
/// debiasing training that carried to a real decision months later
/// (Sellier, Scopelliti & Morewedge, 2019); knowing you got card seven wrong
/// is worth nothing by comparison. Only moves missed at least once — a move
/// got right every time is not one you keep missing — and five at most:
/// past those the list stops being the ones to work on.
class _MissingTile extends StatelessWidget {
  const _MissingTile({required this.app});

  final AppState app;

  static List<Mastery> missed(AppState app) =>
      app.masteryByWeakness.where((m) => m.right < m.met).take(5).toList();

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final rows = missed(app);
    return _Box(
      key: const ValueKey('journey-missing'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.movesYouKeepMissing,
            style: AppText.body(
              size: 11.5,
              weight: FontWeight.w600,
              height: 1,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
          for (final m in rows) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    moveName(context.l10n, m.principle),
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${m.right}/${m.met}',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: m.isWeak
                        ? context.p.alert
                        : ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              moveLine(context.l10n, m.principle),
              style: AppText.body(
                size: 12,
                height: 1.35,
                color: ink.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: m.share,
                minHeight: 5,
                backgroundColor: ink.withValues(alpha: 0.09),
                valueColor: AlwaysStoppedAnimation(
                  m.isWeak ? context.p.alert : ink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── The week in questions ─────────────────────────────────────────────────

/// The week, told back as the questions it left the reader with.
///
/// Every card ends on one question to carry into the day. Seven days of
/// them, side by side, are a record of what the reader has been thinking
/// about rather than of how much they read: the part of a habit a person
/// would recognise as their own. Each opens the card it came from.
class _WeekAsksTile extends StatelessWidget {
  const _WeekAsksTile({required this.app, required this.asks});

  final AppState app;
  final List<Pill> asks;

  /// The asks of the cards read in the seven days up to [now], newest
  /// first, one per card, at most seven.
  static List<Pill> asksOf(AppState app, DateTime now) {
    final out = <Pill>[];
    for (int back = 0; back < 7 && out.length < 7; back++) {
      final DateTime day = DateTime(now.year, now.month, now.day - back);
      for (final id in app.deckHistory[dateKey(day)] ?? const <String>[]) {
        final Pill? p = pillById(id);
        if (p != null &&
            p.ask.isNotEmpty &&
            app.seenIds.contains(id) &&
            !out.contains(p)) {
          out.add(p);
        }
        if (out.length == 7) break;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    return _Box(
      key: const ValueKey('journey-week-asks'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _upper(context, l.weekRecapCaps),
            style: AppText.body(
              size: 11.5,
              weight: FontWeight.w600,
              height: 1,
              spacing: 0.6,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.weekRecapLine,
            style: AppText.body(
              size: 12,
              height: 1.3,
              color: ink.withValues(alpha: 0.45),
            ),
          ),
          for (final (int i, Pill pill) in asks.indexed) ...[
            const SizedBox(height: 12),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DeckViewerScreen(
                      app: app,
                      deck: asks,
                      title: l.yourJourney,
                      initialIndex: i,
                      source: 'journey',
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration: cardFace(context, pill.color, radius: 2),
                    ),
                    Expanded(
                      child: Text(
                        pill.ask,
                        style: AppText.display(
                          size: 15.5,
                          height: 1.25,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── What has stayed ───────────────────────────────────────────────────────

/// What has stayed, as part of what the reader knows: the cards still with
/// them, and how the cards went when they came back after each wait on the
/// review ladder — two days after a miss, a week after the first right
/// answer, three weeks after the second.
///
/// It was a chapter of its own, What stays with you, with a pair of bars
/// for each wait, four weeks ago against now, and no word for which bar was
/// which. Its figures count from where the reader last saw them instead,
/// which says plainly whether what comes back is holding, and the chapter's
/// one real thing — the cards that stayed — sits with the rest of what they
/// know.
class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.app, required this.record});

  final AppState app;
  final JourneyRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final int held = app.heldCards;

    Widget column(int wait) {
      final Tally now = record.recall(wait);
      final int days = kReviewLadder[wait];
      final String after = days % 7 == 0
          ? l.journeyRecallWeeks(now.right, now.of, days ~/ 7)
          : l.journeyRecallDays(now.right, now.of, days);
      final double? share = now.share;
      final TextStyle figure = AppText.display(
        size: 20,
        weight: FontWeight.w600,
        height: 1,
        color: ink,
      );
      Widget bar(double v) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          height: 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: ink.withValues(alpha: 0.1)),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: v.clamp(0.0, 1.0),
                child: ColoredBox(color: ink),
              ),
            ],
          ),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (share == null) ...[
            Text('—', style: figure),
            const SizedBox(height: 8),
            bar(0),
          ] else
            _count(
              _Fig(
                'recall.$wait',
                share,
                (v) => _percent(context, v),
                mark: _pointsMark,
              ),
              (context, v, text, mark) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(text, maxLines: 1, style: figure),
                        ),
                      ),
                      if (mark != null) ...[const SizedBox(width: 5), mark],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // The bar fills with the count.
                  bar(v),
                ],
              ),
            ),
          const SizedBox(height: 8),
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
      key: const ValueKey('journey-memory'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _count(
                _Fig('held', held.toDouble(), (v) => '${v.round()}'),
                (context, _, text, mark) => _BigLine(
                  text,
                  mark: mark,
                  valueKey: const ValueKey('journey-held'),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: _Unit(l.journeyStillWithYou(held))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var w = 0; w < kReviewLadder.length; w++) ...[
                if (w > 0) const SizedBox(width: 14),
                Expanded(child: column(w)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Strongest and most missed ─────────────────────────────────────────────

/// Answers in a subject before it is measured, and how many of its latest
/// are counted: a level is what the reader knows now, not what they knew
/// the first week.
const int _spotFloor = 6;
const int _spotSample = 20;

/// How the reader does in each subject they are measured in: of their
/// latest answers in it, how often right, and of how many.
@visibleForTesting
List<({String key, double share, int of})> subjectShares(AppState app) {
  final Map<String, String> keyOf = {
    for (final e in kTopics.entries) e.value.name: e.key,
  };
  final Map<String, List<bool>> byKey = {};
  for (final Judgement j in app.judgements) {
    final String? id = j.pillId;
    final String? key = id == null ? null : keyOf[PillBank.byId(id)?.topic];
    if (key == null) continue;
    byKey.putIfAbsent(key, () => []).add(j.correct);
  }
  return [
    for (final MapEntry<String, List<bool>> e in byKey.entries)
      if (e.value.length >= _spotFloor)
        (
          key: e.key,
          share:
              e.value.reversed.take(_spotSample).where((c) => c).length /
              math.min(e.value.length, _spotSample),
          of: math.min(e.value.length, _spotSample),
        ),
  ];
}

/// The subject the reader is strongest in, or the one they miss most — a
/// different one, once two are measured: its name, how often right, and
/// that share as a bar in its colour.
class _SpotTile extends StatelessWidget {
  const _SpotTile({required this.app, required this.strongest});

  final AppState app;
  final bool strongest;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final shares = subjectShares(app);
    // The more answers break a tie: the surer of the two.
    bool better(
      ({String key, double share, int of}) a,
      ({String key, double share, int of}) b,
    ) => a.share != b.share ? a.share > b.share : a.of > b.of;
    bool worse(
      ({String key, double share, int of}) a,
      ({String key, double share, int of}) b,
    ) => a.share != b.share ? a.share < b.share : a.of > b.of;
    final spot = shares.isEmpty
        ? null
        : strongest
        ? shares.reduce((a, b) => better(b, a) ? b : a)
        : shares.length < 2
        ? null
        : shares.reduce((a, b) => worse(b, a) ? b : a);
    final TopicStyle? style = spot == null ? null : kTopics[spot.key];
    return _Half(
      label: strongest ? l.journeyStrongest : l.journeyMostMissed,
      value: style == null ? '—' : l.subjectOf(style.name),
      size: 24,
      sub: spot == null
          ? l.journeySubjectsNotYet
          : l.journeyRightShare(_percent(context, spot.share)),
      foot: spot == null || style == null
          ? null
          : ClipRRect(
              key: ValueKey('journey-spot-${spot.key}'),
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: context.p.line),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: spot.share.clamp(0.0, 1.0),
                      child: ColoredBox(color: style.color),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// What the cards that ask ([Pill.reacts]) did for the reader, in their own
/// word: the times one changed their mind, of the cards that asked, and the
/// things new to them, beside the ones they knew. The part of the record no
/// right answer can make: what reading did to what they thought.
class _ReactionTile extends StatelessWidget {
  const _ReactionTile({required this.app, required this.changed});

  final AppState app;
  final bool changed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Map<Reaction, int> n = app.reactionCounts;
    final int told = n.values.fold(0, (a, b) => a + b);
    return _Half(
      key: ValueKey(changed ? 'journey-changed-mind' : 'journey-new-to-you'),
      label: changed ? l.journeyChangedMind : l.journeyNewToYou,
      fig: _Fig(
        changed ? 'changed' : 'fresh',
        ((changed ? n[Reaction.changed] : n[Reaction.fresh]) ?? 0).toDouble(),
        (v) => '${v.round()}',
      ),
      sub: changed
          ? l.journeyReactedOf(told)
          : l.journeyKnewAlready(n[Reaction.knew] ?? 0),
    );
  }
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
                child: _count(
                  _Fig(
                    'activeDays',
                    active.toDouble(),
                    (v) => l.journeyActiveDays(v.round(), record.daysIn),
                  ),
                  (context, _, text, mark) => Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          text,
                          key: const ValueKey('journey-days'),
                          style: AppText.body(
                            size: 15,
                            weight: FontWeight.w600,
                            height: 1.2,
                            color: ink,
                          ),
                        ),
                      ),
                      if (mark != null) ...[const SizedBox(width: 6), mark],
                    ],
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
    PillBank.live.where((p) => app.seenIds.contains(p.id));

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
    // To the hundred, past a hundred, at every step of a count too.
    int round(double y) => y >= 100 ? (y / 100).round() * 100 : y.round();
    final int shown = round(years.toDouble());
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
      fig: _Fig(
        'inTime',
        shown.toDouble(),
        (v) => l.journeyYears(round(v)),
        mark: (context, was, now) =>
            signedNumber(context, round(now) - round(was)),
      ),
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
      fig: _Fig(
        'inPlace',
        named.length.toDouble(),
        (v) => l.journeyRegions(v.round()),
      ),
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
      fig: _Fig(
        'topics',
        strands.length.toDouble(),
        (v) => l.journeyMet(v.round()),
      ),
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
    final Map<String, Pill> byId = {for (final p in PillBank.live) p.id: p};
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
      fig: _Fig('words', met.length.toDouble(), (v) => l.journeyNew(v.round())),
      sub: '$words…',
      size: 24,
    );
  }
}
