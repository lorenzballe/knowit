/// `trick`: spot the trick in a chart.
///
/// A chart as it was published, headline and all, that tells the truth in
/// its numbers and a lie in its drawing. The reader taps the part of it they
/// think is doing the lying: the headline, the axis, the time span, the
/// label, the bars themselves. A wrong part answers with why it is innocent;
/// the right one is boxed, and the chart turns into its honest self: the
/// axis drops to zero, the window opens onto the whole series, the totals
/// are divided by the people behind them. Then one line names the trick, so
/// the reader spots it the next time on their own. Like Huff's *How to Lie
/// with Statistics*, played rather than read.
///
/// Both views are drawn from the same numbers. The writer gives the data
/// once and says which trick was played on it, with the few parameters the
/// trick needs (where the cut axis starts, which years the window kept,
/// how many people each total stands for); the honest view follows from
/// them, so the two can never disagree.
///
/// The tricks:
///
/// - `truncated`: the value axis does not start at zero, so a small change
///   looks huge. `from` is where it starts. Honest: from zero.
/// - `stretched`: the value axis is far taller (or tighter) than the data
///   needs, so a real change looks flat (or a flat one steep). `from` and
///   `to` are the range drawn; `honestFrom` and `honestTo` the fair one.
/// - `window`: only a chosen stretch of a longer series is shown.
///   `window` is the first and last column kept. Honest: every column.
/// - `totals`: totals compared where a rate is the fair measure. `per` is
///   the base of each column (people, cars, hours) and `perScale` the rate's
///   unit: the honest value is `value / per × perScale`.
/// - `flipped`: the value axis runs upside down, so a rise reads as a fall.
///   Honest: the right way up.
/// - `dual`: two series on two value axes, each scaled to tell a story
///   (lines that cross, or move together). `values2` is the second series,
///   on the right axis from `from2` to `to2`. Honest: one shared axis, from
///   zero, which only fits two series in the same unit.
/// - `pie`: a pie whose slices are shares that add up to more than 100%
///   (answers where people could pick several). Honest: each answer as a
///   bar out of 100%.
///
/// The parts the reader can tap, its regions: `headline`, `label` (the
/// line saying what the numbers measure; on a pie, the list of answers),
/// `yaxis` (the value axis), `xaxis` (the columns along the bottom),
/// `marks` (the bars, line or pie), and on a dual chart `yaxis2` (the right
/// axis).
///
/// JSON fields:
///
/// - `type`: `"trick"`.
/// - `trick`: one of the tricks above.
/// - `chart`: `"bars"` or `"line"`. Default bars for `truncated` and
///   `totals`, line for `window`, `stretched`, `flipped` and `dual` (always
///   line), a pie for `pie`.
/// - `outlet`: where the chart ran, small caps over the headline ("Evening
///   news"). Up to 28 characters. Optional.
/// - `headline`: the chart's own title, as published. Up to 48 characters.
/// - `honest`: the title it should have had, shown once the chart is
///   honest. Up to 48 characters.
/// - `label`: what the numbers measure, over the chart ("Top tax rate").
///   Up to 34 characters. On a `totals` chart, `honestLabel` is the rate
///   ("Tonnes of CO₂ per person").
/// - `unit`: written with each value, up to 6 characters. `€ $ £ ¥` go in
///   front, `%` straight after, anything else after a space. Optional; on a
///   `totals` chart `honestUnit` is the rate's.
/// - `decimals`: 0, 1 or 2, for the values printed. Default 0. On `totals`,
///   `honestDecimals` for the rates; default 1.
/// - `columns`: the labels along the bottom. Bars: 2 to 8, up to 12
///   characters each. Line: 2 to 60, up to 6 characters each (only as many
///   are printed as fit). Pie: the answers, 2 to 6, up to 18 characters.
/// - `values`: one number per column. A pie's are percentages.
/// - `from`, `to`: the value range the published chart draws. Required for
///   `truncated` (`from`) and `stretched`, `dual` (both); otherwise a tidy
///   range around the data.
/// - `honestFrom`, `honestTo`: the fair range for `stretched`.
/// - `window`: `[first, last]`, the columns a `window` chart keeps.
/// - `per`, `perScale`: one base per column, and the rate's unit (1 for
///   "per person", 1000 for "per 1,000 people"), for `totals`.
/// - `values2`, `from2`, `to2`, `series`: the second series of a `dual`
///   chart, its range on the right axis, and the two series' names
///   (`[first, second]`, up to 14 characters each).
/// - `spot`: the region where the trick is, or a list of them. Default:
///   `yaxis` for `truncated`, `stretched` and `flipped`; `xaxis` for
///   `window`; `label` for `totals`; `yaxis` and `yaxis2` for `dual`;
///   `marks` for `pie`.
/// - `ask`: the instruction under the chart before the first tap. Up to 40
///   characters. Optional; the app's own "Tap your pick" otherwise.
/// - `found`: what the reader is told when they tap the trick. Up to 70
///   characters.
/// - `miss`: what a wrong part says, unless `misses` has a line for that
///   region: `{"headline": "…", "marks": "…"}`. Up to 80 characters each.
///   A miss says why the part is innocent and where to look instead.
/// - `name`: the trick's name, shown as a tag on the boxed part at the end
///   ("Truncated axis"). Up to 24 characters.
/// - `lesson`: the line that stays, so the trick is spotted next time. Up
///   to 100 characters.
///
/// A full example (Fox Business, 2012):
///
/// ```json
/// {
///   "type": "trick",
///   "trick": "truncated",
///   "outlet": "Fox Business, 2012",
///   "headline": "If Bush tax cuts expire",
///   "honest": "Top rate: up 4.6 points",
///   "label": "Top income tax rate",
///   "unit": "%",
///   "decimals": 1,
///   "columns": ["Now", "Jan 1, 2013"],
///   "values": [35, 39.6],
///   "from": 34,
///   "to": 42,
///   "found": "Yes. The axis starts at 34%, not zero.",
///   "miss": "That part is fair. Look at what the bottom of the bars stands for.",
///   "misses": {
///     "marks": "The numbers on the bars are right. It's their heights that lie."
///   },
///   "name": "Truncated axis",
///   "lesson": "Bars must start at zero. Cut the bottom off and a 13% rise looks like five times."
/// }
/// ```
library;

import 'dart:math' as math;

import '../scene.dart';

/// The trick a chart plays.
enum TrickSceneKind { truncated, stretched, window, totals, flipped, dual, pie }

/// How the numbers are drawn.
enum TrickSceneForm { bars, line, pie }

/// The parts of a chart the reader can tap.
enum TrickSceneRegion { headline, label, yaxis, xaxis, marks, yaxis2 }

/// A value range, bottom to top.
typedef TrickSceneRange = ({double lo, double hi});

/// Find the trick in a chart.
class TrickScene extends Scene {
  final TrickSceneKind trick;
  final TrickSceneForm form;
  final String outlet;
  final String headline;
  final String honest;
  final String label;
  final String honestLabel;
  final String unit;
  final String honestUnit;
  final int decimals;
  final int honestDecimals;
  final List<String> columns;
  final List<double> values;

  /// The second series of a `dual` chart, and the two series' names.
  final List<double> values2;
  final List<String> series;

  /// The value axis as published, and as it should be.
  final TrickSceneRange shown;
  final TrickSceneRange fair;

  /// The right axis of a `dual` chart, as published.
  final TrickSceneRange shown2;

  /// The columns the published chart keeps, first and last.
  final int first;
  final int last;

  /// The rates of a `totals` chart, one per column.
  final List<double> rates;

  final Set<TrickSceneRegion> spot;
  final String ask;
  final String found;
  final String miss;
  final Map<TrickSceneRegion, String> misses;
  final String name;
  final String lesson;

  const TrickScene(
    super.raw, {
    required this.trick,
    required this.form,
    required this.outlet,
    required this.headline,
    required this.honest,
    required this.label,
    required this.honestLabel,
    required this.unit,
    required this.honestUnit,
    required this.decimals,
    required this.honestDecimals,
    required this.columns,
    required this.values,
    required this.values2,
    required this.series,
    required this.shown,
    required this.fair,
    required this.shown2,
    required this.first,
    required this.last,
    required this.rates,
    required this.spot,
    required this.ask,
    required this.found,
    required this.miss,
    required this.misses,
    required this.name,
    required this.lesson,
  });

  int get count => columns.length;

  /// The regions this chart has: a pie has no axes, only a dual chart has
  /// a right one.
  List<TrickSceneRegion> get regions => [
    TrickSceneRegion.headline,
    TrickSceneRegion.label,
    if (form != TrickSceneForm.pie) ...[
      TrickSceneRegion.yaxis,
      TrickSceneRegion.xaxis,
    ],
    TrickSceneRegion.marks,
    if (trick == TrickSceneKind.dual) TrickSceneRegion.yaxis2,
  ];

  bool isTrick(TrickSceneRegion r) => spot.contains(r);

  /// What a wrong part says.
  String missFor(TrickSceneRegion r) => misses[r] ?? miss;

  /// Whether the honest view is reached by emptying the chart and filling
  /// it again with other numbers, rather than by moving what is there.
  bool get refills =>
      trick == TrickSceneKind.totals || trick == TrickSceneKind.pie;

  /// The values the honest view shows: rates for `totals`, the same
  /// numbers for every other trick.
  List<double> get honestValues =>
      trick == TrickSceneKind.totals ? rates : values;

  static TrickScene parse(Map<String, Object?> raw, Object? id) {
    Never bad(String why) => throw FormatException('scene.$why', id);
    String text(String k, {bool need = false}) {
      final v = raw[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v != null && v is! String) bad('$k must be text');
      if (need) bad('$k is missing');
      return '';
    }

    double? number(String k) {
      final v = raw[k];
      if (v == null) return null;
      if (v is num && v.isFinite) return v.toDouble();
      bad('$k must be a number');
    }

    List<double> numbers(String k) {
      final v = raw[k];
      if (v is! List || v.any((e) => e is! num || !e.isFinite)) {
        bad('$k must be a list of numbers');
      }
      return [for (final e in v) (e as num).toDouble()].toList(growable: false);
    }

    int whole(String k, int or) {
      final v = raw[k];
      if (v == null) return or;
      if (v is num && v == v.roundToDouble()) return v.toInt();
      bad('$k must be a whole number');
    }

    final trick = switch (raw['trick']) {
      'truncated' => TrickSceneKind.truncated,
      'stretched' => TrickSceneKind.stretched,
      'window' => TrickSceneKind.window,
      'totals' => TrickSceneKind.totals,
      'flipped' => TrickSceneKind.flipped,
      'dual' => TrickSceneKind.dual,
      'pie' => TrickSceneKind.pie,
      _ => bad('trick is not one this app knows'),
    };

    final form = switch ((trick, raw['chart'])) {
      (TrickSceneKind.pie, null || 'pie') => TrickSceneForm.pie,
      (TrickSceneKind.pie, _) => bad('chart: a pie trick is a pie'),
      (TrickSceneKind.dual, null || 'line') => TrickSceneForm.line,
      (TrickSceneKind.dual, _) => bad('chart: a dual chart is two lines'),
      (_, 'bars') => TrickSceneForm.bars,
      (_, 'line') => TrickSceneForm.line,
      (TrickSceneKind.truncated || TrickSceneKind.totals, null) =>
        TrickSceneForm.bars,
      (_, null) => TrickSceneForm.line,
      _ => bad('chart: bars or line'),
    };

    final cols = raw['columns'];
    if (cols is! List || cols.any((c) => c is! String || c.trim().isEmpty)) {
      bad('columns must be a list of labels');
    }
    final columns = [
      for (final c in cols) (c as String).trim(),
    ].toList(growable: false);
    final (lo, hi) = switch (form) {
      TrickSceneForm.bars => (2, 8),
      TrickSceneForm.line => (2, 60),
      TrickSceneForm.pie => (2, 6),
    };
    if (columns.length < lo || columns.length > hi) {
      bad('columns: between $lo and $hi for this chart');
    }
    final values = numbers('values');
    if (values.length != columns.length) bad('values: one per column');

    final decimals = whole('decimals', 0);
    final honestDecimals = whole('honestDecimals', 1);
    if (decimals < 0 || decimals > 2 || honestDecimals < 0 || honestDecimals > 2) {
      bad('decimals: 0, 1 or 2');
    }

    final from = number('from');
    final to = number('to');
    final vLo = values.reduce(math.min);
    final vHi = values.reduce(math.max);
    final bars = form == TrickSceneForm.bars;

    // The honest range of a set of values: from zero for bars, which are
    // read by their length; a tidy span around the data for a line, which is
    // read by its slope, unless that span would still include zero anyway.
    TrickSceneRange fairOf(List<double> vs) {
      final a = vs.reduce(math.min), b = vs.reduce(math.max);
      if (bars || a >= 0 && a < (b - a) * 0.6) {
        return (lo: math.min(0, tidyFloor(a, b)), hi: tidyCeil(math.min(0, a), b));
      }
      return (lo: tidyFloor(a, b), hi: tidyCeil(a, b));
    }

    var first = 0;
    var last = columns.length - 1;
    var rates = const <double>[];
    var values2 = const <double>[];
    var series = const <String>[];
    var shown2 = (lo: 0.0, hi: 1.0);
    TrickSceneRange shown;
    TrickSceneRange fair;

    switch (trick) {
      case TrickSceneKind.truncated:
        if (from == null) bad('from: where the cut axis starts');
        if (from <= 0 || from > vLo) {
          bad('from: above zero and at or below the smallest value');
        }
        shown = (lo: from, hi: to ?? tidyCeil(from, vHi));
        fair = fairOf([0, ...values]);
      case TrickSceneKind.stretched:
        final a = number('honestFrom'), b = number('honestTo');
        if (from == null || to == null || a == null || b == null) {
          bad('stretched needs from, to, honestFrom and honestTo');
        }
        shown = (lo: from, hi: to);
        fair = (lo: a, hi: b);
      case TrickSceneKind.window:
        final w = raw['window'];
        if (w is! List || w.length != 2 || w.any((e) => e is! int)) {
          bad('window: [first, last] column');
        }
        first = w[0] as int;
        last = w[1] as int;
        if (first < 0 || last >= columns.length || last - first < 1) {
          bad('window: two columns or more, inside the series');
        }
        if (first == 0 && last == columns.length - 1) {
          bad('window: keeps every column, so hides nothing');
        }
        final kept = values.sublist(first, last + 1);
        shown = from != null && to != null
            ? (lo: from, hi: to)
            : (
                lo: tidyFloor(kept.reduce(math.min), kept.reduce(math.max)),
                hi: tidyCeil(kept.reduce(math.min), kept.reduce(math.max)),
              );
        fair = fairOf(values);
      case TrickSceneKind.totals:
        final per = numbers('per');
        if (per.length != columns.length || per.any((p) => p <= 0)) {
          bad('per: one base above zero per column');
        }
        final scale = number('perScale') ?? 1;
        if (scale <= 0) bad('perScale must be above zero');
        rates = [
          for (var i = 0; i < per.length; i++) values[i] / per[i] * scale,
        ].toList(growable: false);
        shown = fairOf([0, ...values]);
        fair = fairOf([0, ...rates]);
      case TrickSceneKind.flipped:
        shown = from != null && to != null ? (lo: from, hi: to) : fairOf(values);
        fair = shown;
      case TrickSceneKind.dual:
        values2 = numbers('values2');
        if (values2.length != columns.length) bad('values2: one per column');
        final from2 = number('from2'), to2 = number('to2');
        if (from == null || to == null || from2 == null || to2 == null) {
          bad('dual needs from, to, from2 and to2');
        }
        if (to2 <= from2) bad('to2 must be above from2');
        shown2 = (lo: from2, hi: to2);
        final s = raw['series'];
        if (s is! List || s.length != 2 || s.any((e) => e is! String || e.trim().isEmpty)) {
          bad('series: the two series\' names');
        }
        series = [for (final e in s) (e as String).trim()].toList(growable: false);
        shown = (lo: from, hi: to);
        fair = fairOf([0, ...values, ...values2]);
        if (values2.any((v) => v < from2 || v > to2)) {
          bad('values2 must lie between from2 and to2');
        }
      case TrickSceneKind.pie:
        if (values.any((v) => v <= 0 || v > 100)) {
          bad('values: a pie\'s are percentages, above 0 and up to 100');
        }
        if (values.fold(0.0, (a, b) => a + b) <= 100) {
          bad('values: a pie that adds up to 100% or less plays no trick');
        }
        shown = (lo: 0, hi: 100);
        fair = shown;
    }
    if (shown.hi <= shown.lo || fair.hi <= fair.lo) bad('to must be above from');
    if (form != TrickSceneForm.pie) {
      final kept = values.sublist(first, last + 1);
      if (kept.any((v) => v < shown.lo - 1e-9 || v > shown.hi + 1e-9)) {
        bad('values must lie between from and to');
      }
    }

    // Where the trick is.
    TrickSceneRegion region(Object? v) => switch (v) {
      'headline' => TrickSceneRegion.headline,
      'label' => TrickSceneRegion.label,
      'yaxis' => TrickSceneRegion.yaxis,
      'xaxis' => TrickSceneRegion.xaxis,
      'marks' => TrickSceneRegion.marks,
      'yaxis2' => TrickSceneRegion.yaxis2,
      _ => bad('spot: $v is not a region'),
    };
    final s = raw['spot'];
    final spot = switch (s) {
      null => switch (trick) {
        TrickSceneKind.truncated ||
        TrickSceneKind.stretched ||
        TrickSceneKind.flipped => {TrickSceneRegion.yaxis},
        TrickSceneKind.window => {TrickSceneRegion.xaxis},
        TrickSceneKind.totals => {TrickSceneRegion.label},
        TrickSceneKind.dual => {TrickSceneRegion.yaxis, TrickSceneRegion.yaxis2},
        TrickSceneKind.pie => {TrickSceneRegion.marks},
      },
      final List l when l.isNotEmpty => {for (final e in l) region(e)},
      _ => {region(s)},
    };

    final m = raw['misses'];
    if (m != null && m is! Map) bad('misses: {region: line}');
    final misses = <TrickSceneRegion, String>{
      if (m is Map)
        for (final e in m.entries)
          if (e.value is String) region(e.key): e.value as String,
    };

    final scene = TrickScene(
      raw,
      trick: trick,
      form: form,
      outlet: text('outlet'),
      headline: text('headline', need: true),
      honest: text('honest', need: true),
      label: text('label', need: true),
      honestLabel: trick == TrickSceneKind.totals
          ? text('honestLabel', need: true)
          : text('label'),
      unit: text('unit'),
      honestUnit: trick == TrickSceneKind.totals ? text('honestUnit') : text('unit'),
      decimals: decimals,
      honestDecimals: trick == TrickSceneKind.totals ? honestDecimals : decimals,
      columns: columns,
      values: values,
      values2: values2,
      series: series,
      shown: shown,
      fair: fair,
      shown2: shown2,
      first: first,
      last: last,
      rates: rates,
      spot: spot,
      ask: text('ask'),
      found: text('found', need: true),
      miss: text('miss', need: true),
      misses: misses,
      name: text('name', need: true),
      lesson: text('lesson', need: true),
    );
    if (!scene.regions.toSet().containsAll(spot)) {
      bad('spot: a region this chart does not have');
    }
    return scene;
  }

  /// A round step that cuts [span] into about [parts].
  static double tidyStep(double span, [int parts = 5]) {
    if (span <= 0) return 1;
    final raw = span / parts;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final k in const [1.0, 2.0, 2.5, 5.0]) {
      if (k * mag >= raw - 1e-12) return k * mag;
    }
    return 10 * mag;
  }

  /// The round number at or below [a], on the step of the span [a]–[b].
  static double tidyFloor(double a, double b) {
    final step = tidyStep(b - a == 0 ? b.abs() : b - a);
    return (a / step + 1e-9).floor() * step;
  }

  /// The round number at or above [b], on the step of the span [a]–[b].
  static double tidyCeil(double a, double b) {
    final step = tidyStep(b - a == 0 ? b.abs() : b - a);
    return (b / step - 1e-9).ceil() * step;
  }

  /// The round values to mark on an axis from [r.lo] to [r.hi].
  static List<double> ticks(TrickSceneRange r) {
    final step = tidyStep(r.hi - r.lo, 4);
    final out = <double>[];
    var v = (r.lo / step - 1e-9).ceil() * step;
    while (v <= r.hi + step * 1e-6) {
      out.add(v.abs() < step * 1e-9 ? 0 : v);
      v += step;
    }
    return out;
  }
}
