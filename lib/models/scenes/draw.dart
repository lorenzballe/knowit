/// `draw`: draw it yourself, then see the real line.
///
/// A chart with its axes labelled and, usually, the first stretch of a real
/// series already drawn. The reader carries the line on with a finger,
/// locks it in, and the real line draws itself over theirs. The gap between
/// the two is the lesson: growth that multiplies looks flat until it leaves
/// every guess behind; a memory falls off a cliff and then barely moves.
/// Like the New York Times' "You Draw It", and the best-wards card of round
/// five.
///
/// The x axis is a row of columns, evenly spaced, one label each. The line is
/// stored one value per column, so a finger snaps to them; it is drawn as a
/// smooth curve through them.
///
/// JSON fields:
///
/// - `type`: `"draw"`.
/// - `label`: what the y axis measures, small caps over the chart ("CO₂ in
///   the air"). Up to 34 characters.
/// - `unit`: the unit of a value, up to 8 characters. `€ $ £ ¥ ×` are written
///   in front ("×1,845"), `%` straight after, anything else after a space
///   ("414 ppm"). Optional.
/// - `columns`: the x labels, 3 to 10 of them, each up to 8 characters.
/// - `values`: the real series, one number per column.
/// - `given`: how many columns are shown before the reader draws, 0 to
///   columns − 2. With 1 or more the reader starts from the last one shown;
///   with 0 they draw the whole line. Default 1.
/// - `min`, `max`: the y range. Choose it with care: a ceiling that sits on
///   the truth gives the answer away. Default 0 (or the lowest value) to a
///   round number a quarter above the highest. With `log`, both above 0.
/// - `log`: a log scale, for series that span powers of ten. Default false.
/// - `decimals`: 0, 1 or 2, for the numbers the reader reads. Default 0.
/// - `judge`: the column where the two lines are compared, the one the
///   verdict and the YOU / TRUTH numbers speak about. Default the last.
/// - `near`: how close counts as right, as a share of the chart's height.
///   Default 0.1.
/// - `verdict`: `{under, near, over}`, the line shown when the real one has
///   drawn itself, chosen by where the reader's line ended at `judge`: below
///   the truth, near it, or above it. Each up to 90 characters.
/// - `notes`: up to 3 `{at, text}` labels pinned to the real line at column
///   `at` once it has drawn past it. Up to 28 characters; never at `judge`,
///   which carries the YOU and TRUTH tags.
///
/// A full example:
///
/// ```json
/// {
///   "type": "draw",
///   "label": "Training compute, × today",
///   "unit": "×",
///   "columns": ["Today", "Yr 1", "Yr 2", "Yr 3", "Yr 4", "Yr 5"],
///   "values": [1, 4.5, 20.25, 91.1, 410, 1845],
///   "given": 1,
///   "min": 0,
///   "max": 2000,
///   "verdict": {
///     "under": "Too low, like most guesses. ×4.5 a year looks flat for years, then takes off.",
///     "near": "Close. You felt it: almost all of the climb comes in the last two years.",
///     "over": "Higher than the truth. Five years at ×4.5 is ×1,845: steep, but not endless."
///   },
///   "notes": [
///     {"at": 2, "text": "Only ×20 after 2 years"},
///     {"at": 4, "text": "×410 after 4 years"}
///   ]
/// }
/// ```
library;

import 'dart:math' as math;

import '../scene.dart';

/// A label pinned to the real line at one column.
class DrawNote {
  final int at;
  final String text;
  const DrawNote(this.at, this.text);
}

/// Draw the line you expect.
class DrawScene extends Scene {
  final String label;
  final String unit;
  final List<String> columns;
  final List<double> values;
  final int given;
  final double min;
  final double max;
  final bool log;
  final int decimals;
  final int judge;
  final double near;
  final String under;
  final String close;
  final String over;
  final List<DrawNote> notes;

  const DrawScene(
    super.raw, {
    required this.label,
    required this.unit,
    required this.columns,
    required this.values,
    required this.given,
    required this.min,
    required this.max,
    required this.log,
    required this.decimals,
    required this.judge,
    required this.near,
    required this.under,
    required this.close,
    required this.over,
    required this.notes,
  });

  int get count => columns.length;

  /// The column the reader's line starts from: the last one shown, or the
  /// first column when nothing is.
  int get anchor => given > 0 ? given - 1 : 0;

  /// The first column the reader sets.
  int get firstDrawn => given > 0 ? given : 0;

  /// A value on the chart's own scale: its logarithm on a log chart.
  double plot(double v) => log ? math.log(v) / math.ln10 : v;
  double unplot(double t) => log ? math.pow(10, t).toDouble() : t;

  /// Where a value sits between the bottom of the chart (0) and the top (1).
  double share(double v) => (plot(v) - plot(min)) / (plot(max) - plot(min));
  double fromShare(double s) =>
      unplot(plot(min) + s.clamp(0.0, 1.0) * (plot(max) - plot(min)));

  /// Below the truth, near it or above it, measured as a share of the
  /// chart's height so a log chart judges by eye, as the reader drew.
  int verdictFor(double guess) {
    final d = share(guess) - share(values[judge]);
    if (d.abs() <= near) return 0;
    return d < 0 ? -1 : 1;
  }

  String verdictText(double guess) => switch (verdictFor(guess)) {
    0 => close,
    < 0 => under,
    _ => over,
  };

  static DrawScene parse(Map<String, Object?> raw, Object? id) {
    Never bad(String why) => throw FormatException('scene.$why', id);
    String text(String k) => raw[k] is String ? raw[k] as String : '';
    int whole(String k, int or) {
      final v = raw[k];
      if (v == null) return or;
      if (v is num && v == v.roundToDouble()) return v.toInt();
      bad('$k must be a whole number');
    }

    final cols = raw['columns'];
    if (cols is! List || cols.any((c) => c is! String || c.trim().isEmpty)) {
      bad('columns must be a list of labels');
    }
    final columns = cols.cast<String>().toList(growable: false);
    if (columns.length < 3 || columns.length > 12) {
      bad('columns: between 3 and 12');
    }

    final vals = raw['values'];
    if (vals is! List || vals.any((v) => v is! num || !v.isFinite)) {
      bad('values must be a list of numbers');
    }
    final values = [for (final v in vals) (v as num).toDouble()]
        .toList(growable: false);
    if (values.length != columns.length) {
      bad('values: one per column');
    }

    final given = whole('given', 1);
    if (given < 0 || given > columns.length - 2) {
      bad('given: between 0 and columns − 2');
    }

    final log = raw['log'] == true;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    double number(String k, double or) {
      final v = raw[k];
      if (v == null) return or;
      if (v is num && v.isFinite) return v.toDouble();
      bad('$k must be a number');
    }

    final min = number('min', log ? _decadeBelow(lo) : math.min(0, lo));
    final max = number(
      'max',
      log ? _decadeBelow(hi * 1.5) * 10 : _roundUp(hi * 1.25),
    );
    if (max <= min) bad('max must be above min');
    if (log && (min <= 0 || lo <= 0)) bad('log needs min and values above 0');
    if (lo < min || hi > max) bad('values must lie between min and max');

    final decimals = whole('decimals', 0);
    if (decimals < 0 || decimals > 2) bad('decimals: 0, 1 or 2');

    final firstDrawn = given > 0 ? given : 0;
    final judge = whole('judge', columns.length - 1);
    if (judge < firstDrawn || judge >= columns.length) {
      bad('judge must be a column the reader draws');
    }
    final near = number('near', 0.1);
    if (near <= 0 || near >= 1) bad('near: between 0 and 1');

    final v = raw['verdict'];
    String say(String k) => v is Map && v[k] is String ? (v[k] as String) : '';

    final notes = <DrawNote>[];
    for (final m in (raw['notes'] as List? ?? const [])) {
      if (m is! Map || m['at'] is! num || m['text'] is! String) {
        bad('notes: each is {at, text}');
      }
      final at = (m['at'] as num).toInt();
      if (at < 0 || at >= columns.length) bad('notes: at is not a column');
      notes.add(DrawNote(at, m['text'] as String));
    }
    notes.sort((a, b) => a.at.compareTo(b.at));

    return DrawScene(
      raw,
      label: text('label'),
      unit: text('unit'),
      columns: columns,
      values: values,
      given: given,
      min: min,
      max: max,
      log: log,
      decimals: decimals,
      judge: judge,
      near: near,
      under: say('under'),
      close: say('near'),
      over: say('over'),
      notes: notes,
    );
  }

  static double _decadeBelow(double v) =>
      math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();

  /// 1, 2, 2.5 or 5 times a power of ten, at or above [v].
  static double _roundUp(double v) {
    if (v <= 0) return 1;
    final mag = _decadeBelow(v);
    for (final k in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (k * mag >= v - 1e-9) return k * mag;
    }
    return 10 * mag;
  }
}
