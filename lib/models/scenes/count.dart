/// `count`: bet the number.
///
/// Some numbers are too big, or too small, to feel. A sentence that says
/// "about 1,500" slides past; a bet placed first, then a giant number
/// rolling up past it while a field of dots fills, does not. The reader
/// picks an order of magnitude from three or four, then watches the truth
/// count up, travel along those same options and stop where it really is.
/// The gap between their pick and where it stops is how far off they were.
///
/// JSON fields:
///
/// - `type`: `"count"`.
/// - `unit` (text, required, up to 40 characters): what is counted, set in
///   small spaced capitals under the giant number ("of your molecules in
///   every glass"). Written in plain case; the app capitalises it.
/// - `prefix` (text, optional, up to 3): a sign written before the number,
///   such as `"$"`.
/// - `answer` (number, required, at least 0): the true quantity.
/// - `decimals` (0, 1 or 2, optional, default 0): digits after the point.
/// - `each` (number, required, above 0): how many units one dot stands for.
///   `answer / each` dots are drawn, between 1 and 2,500.
/// - `eachLabel` (text, required, up to 34): the key to the dots, said in
///   the card's own words ("1 dot = 10,000 dollars").
/// - `arrange` (optional): `"cloud"` (the default), dots scattered like a
///   particle cloud for quantities to feel; or `"grid"`, neat rows for
///   small quantities to count one by one.
/// - `compare` (text, optional, up to 40): one line of scale shown under
///   the number once it has landed, where the scene is tall enough to keep
///   the field generous ("About $2.50 per user, every month").
/// - `options` (3 or 4, required): the bets, from smallest to largest.
///   Each is `{label, value, note}`:
///   - `label` (up to 14 characters, no word over 9): what the chip says
///     ("About 1,000"). It may wrap onto two lines.
///   - `value` (number, at least 0, rising, each positive one at least
///     three times the one before): where the option sits on the scale.
///   - `note` (up to 90): the line shown when the count lands, if this was
///     the reader's bet. It says how far off it was, and why.
///
/// A full example:
///
/// ```json
/// {
///   "type": "count",
///   "unit": "of your molecules in every glass",
///   "answer": 1500,
///   "each": 1,
///   "eachLabel": "1 dot = 1 of your molecules",
///   "options": [
///     {"label": "None", "value": 0,
///      "note": "Not even close: there are far more of them than glasses."},
///     {"label": "About 1", "value": 1,
///      "note": "Three zeros short. A glass holds more molecules than the seas hold glasses."},
///     {"label": "About 1,000", "value": 1000,
///      "note": "Right order. Every glass of sea has some of your water in it."},
///     {"label": "A million", "value": 1000000,
///      "note": "Three zeros too many: the seas still dilute it a billion billion times."}
///   ]
/// }
/// ```
library;

import 'dart:math' as math;

import '../scene.dart';

/// How the dots are laid out.
enum CountArrange { cloud, grid }

/// One bet the reader can place.
class CountOption {
  final String label;
  final double value;
  final String note;
  const CountOption(this.label, this.value, this.note);
}

/// Bet the number.
class CountScene extends Scene {
  final String unit;
  final String prefix;
  final double answer;
  final int decimals;
  final double each;
  final String eachLabel;
  final CountArrange arrange;
  final String compare;

  /// From smallest to largest.
  final List<CountOption> options;

  const CountScene(
    super.raw, {
    required this.unit,
    required this.prefix,
    required this.answer,
    required this.decimals,
    required this.each,
    required this.eachLabel,
    required this.arrange,
    required this.compare,
    required this.options,
  });

  /// More dots than this stop being dots and become a grey wash.
  static const maxDots = 2500;

  static CountScene parse(Map<String, Object?> raw, Object? id) {
    String text(String k, {bool required = false}) {
      final v = raw[k];
      if (v is String && v.trim().isNotEmpty) return v;
      if (v != null && v is! String) {
        throw FormatException('scene.$k must be text', id);
      }
      if (required) throw FormatException('scene.$k is missing', id);
      return '';
    }

    double number(String k, {double? or}) {
      final v = raw[k];
      if (v is num && v.isFinite) return v.toDouble();
      if (v == null && or != null) return or;
      throw FormatException('scene.$k must be a number', id);
    }

    final answer = number('answer');
    if (answer < 0) throw FormatException('scene.answer is negative', id);
    final each = number('each');
    if (each <= 0) throw FormatException('scene.each must be above 0', id);
    final decimals = number('decimals', or: 0).toInt();
    if (decimals < 0 || decimals > 2) {
      throw FormatException('scene.decimals must be 0, 1 or 2', id);
    }
    final arrange = switch (raw['arrange']) {
      null || 'cloud' => CountArrange.cloud,
      'grid' => CountArrange.grid,
      _ => throw FormatException('scene.arrange is cloud or grid', id),
    };

    final rawOptions = raw['options'];
    if (rawOptions is! List || rawOptions.length < 3 || rawOptions.length > 4) {
      throw FormatException('scene.options must be 3 or 4 bets', id);
    }
    final options = <CountOption>[];
    for (final o in rawOptions) {
      if (o is! Map ||
          o['label'] is! String ||
          o['value'] is! num ||
          o['note'] is! String) {
        throw FormatException(
          'scene.options: each is {label, value, note}',
          id,
        );
      }
      final v = (o['value'] as num).toDouble();
      if (!v.isFinite || v < 0) {
        throw FormatException('scene.options: value below 0', id);
      }
      if (options.isNotEmpty && v <= options.last.value) {
        throw FormatException('scene.options: values must rise', id);
      }
      options.add(CountOption(o['label'] as String, v, o['note'] as String));
    }

    return CountScene(
      raw,
      unit: text('unit', required: true),
      prefix: text('prefix'),
      answer: answer,
      decimals: decimals,
      each: each,
      eachLabel: text('eachLabel', required: true),
      arrange: arrange,
      compare: text('compare'),
      options: options,
    );
  }

  /// How many dots the whole answer makes.
  int get dots => (answer / each).round().clamp(0, maxDots);

  /// The option nearest the truth, counting in zeros rather than units: a
  /// bet of 1,000 is nearer 1,500 than a bet of 1 is, and nearer than a
  /// bet of a million.
  int get nearest {
    var best = 0;
    var gap = double.infinity;
    for (var i = 0; i < options.length; i++) {
      final g = (_log(options[i].value) - _log(answer)).abs();
      if (g < gap) {
        gap = g;
        best = i;
      }
    }
    return best;
  }

  /// Where [v] sits along the options, in option steps: 0 at the first,
  /// 1 at the second, and so on, measured in zeros between neighbours.
  /// A value below the first sits at 0; above the last it runs on by up to
  /// half a step, so a truth past every bet is seen to be past them.
  double stopOf(double v) {
    final o = options;
    if (v <= o.first.value) return 0;
    for (var i = 1; i < o.length; i++) {
      if (v <= o[i].value) {
        final a = _log(o[i - 1].value, below: o[i].value);
        final b = _log(o[i].value);
        return i - 1 + ((_log(v) - a) / (b - a)).clamp(0.0, 1.0);
      }
    }
    final n = o.length;
    final a = _log(o[n - 2].value, below: o[n - 1].value);
    final b = _log(o[n - 1].value);
    final over = (_log(v) - b) / (b - a);
    return n - 1 + over.clamp(0.0, 0.5);
  }

  /// Zeros counted: log10. Nothing at all sits one zero below [below], or
  /// below one when nothing follows it, so "none" has a place on the scale.
  static double _log(double v, {double below = 1}) {
    if (v > 0) return math.log(v) / math.ln10;
    return (below > 0 ? math.log(below) / math.ln10 : 0) - 1;
  }
}
