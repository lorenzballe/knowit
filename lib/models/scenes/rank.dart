/// `rank`: put them in order.
///
/// A few things the reader thinks they can compare — sharks and snakes,
/// beef and chocolate — and one quantity to compare them by. The reader
/// drags them into the order they believe, locks it in, and then watches the
/// rows slide into their true places while each one's bar grows to its real
/// value. The row the reader got most wrong is the one that lights up: that
/// is the surprise the card is about.
///
/// The order in the data is the order the reader first sees. It is the
/// writer's choice, and it must not already be the right answer.
///
/// JSON fields:
///
/// - `type`: `"rank"`.
/// - `quantity` (string, ≤ 34 chars): what the items are compared by, read
///   as a small heading over the list ("People killed each year").
/// - `most` (string, ≤ 16 chars): the word for the top of the list, where
///   the largest value goes ("Most", "Thirstiest"). It shares one line with
///   `quantity`: the two together stay within 32 chars.
/// - `unit` (string, ≤ 10 chars, optional): printed with every value. A
///   currency sign goes in front (`$`, `€`, `£`, `¥`); anything else
///   follows the number ("L", "kg", "km/h").
/// - `log` (bool, optional, default false): bars on a logarithmic scale,
///   for values spread over several orders of magnitude (sharks against
///   mosquitoes). Every value must then be above zero.
/// - `items` (3 to 5): each `{label, value, note?}`.
///   - `label` (string, ≤ 22 chars): the thing ("Mosquitoes").
///   - `value` (number, ≥ 0, all different): its true amount.
///   - `note` (string, ≤ 90 chars, optional): one line shown under the list
///     when this item turns out to be the surprise.
///
/// Example:
///
/// ```json
/// {
///   "type": "rank",
///   "quantity": "People killed each year",
///   "most": "Most",
///   "log": true,
///   "items": [
///     {"label": "Sharks", "value": 6,
///      "note": "About six a year. Mosquitoes kill that many every five minutes."},
///     {"label": "Dogs", "value": 59000,
///      "note": "Almost all through rabies, almost all in Africa and Asia."},
///     {"label": "Mosquitoes", "value": 597000},
///     {"label": "Snakes", "value": 81000,
///      "note": "At least 81,000: most bites happen far from any antivenom."}
///   ]
/// }
/// ```
library;

import 'dart:math' as math;

import '../scene.dart';

/// One thing to put in its place.
class RankItem {
  final String label;
  final double value;
  final String note;
  const RankItem(this.label, this.value, this.note);
}

/// Put them in order.
class RankScene extends Scene {
  final String quantity;
  final String most;
  final String unit;
  final bool log;

  /// In the order the reader first sees them.
  final List<RankItem> items;

  const RankScene(
    super.raw, {
    required this.quantity,
    required this.most,
    required this.unit,
    required this.log,
    required this.items,
  });

  static RankScene parse(Map<String, Object?> raw, Object? id) {
    String text(String k, {bool required = true}) {
      final v = raw[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (!required && v == null) return '';
      throw FormatException('scene.$k must be a string', id);
    }

    final list = raw['items'];
    if (list is! List || list.length < 3 || list.length > 5) {
      throw FormatException('scene.items: between 3 and 5', id);
    }
    final log = raw['log'] == true;
    final items = <RankItem>[];
    for (final m in list) {
      if (m is! Map ||
          m['label'] is! String ||
          (m['label'] as String).trim().isEmpty ||
          m['value'] is! num) {
        throw FormatException('scene.items: each is {label, value}', id);
      }
      final v = (m['value'] as num).toDouble();
      if (!v.isFinite || v < 0 || (log && v <= 0)) {
        throw FormatException('scene.items: value out of range', id);
      }
      items.add(
        RankItem(
          (m['label'] as String).trim(),
          v,
          m['note'] is String ? (m['note'] as String).trim() : '',
        ),
      );
    }
    if (items.map((i) => i.value).toSet().length != items.length) {
      throw FormatException('scene.items: values must all differ', id);
    }
    return RankScene(
      raw,
      quantity: text('quantity'),
      most: text('most'),
      unit: raw['unit'] is String ? (raw['unit'] as String).trim() : '',
      log: log,
      items: items,
    );
  }

  /// Item indices from the largest value to the smallest.
  List<int> get truth =>
      List.generate(items.length, (i) => i)
        ..sort((a, b) => items[b].value.compareTo(items[a].value));

  /// How far along its row each item's bar reaches, 0 to 1.
  ///
  /// On a log scale the axis starts a little below the smallest value, so
  /// the smallest bar is short but never absent.
  double barOf(int i) {
    final values = items.map((e) => e.value);
    final hi = values.reduce((a, b) => a > b ? a : b);
    if (hi <= 0) return 0;
    if (!log) return items[i].value / hi;
    final lo = _log10(values.reduce((a, b) => a < b ? a : b));
    final span = _log10(hi) - lo;
    final floor = lo - (span * 0.14).clamp(0.4, double.infinity);
    return (_log10(items[i].value) - floor) / (_log10(hi) - floor);
  }

  /// The row that surprises most, given the reader's order (item indices,
  /// top first): the one placed furthest from where it belongs. Ties go to
  /// the item that truly ranks higher. A perfect order surprises nobody, and
  /// then the top item is the one held up.
  int surpriseFor(List<int> guess) {
    final t = truth;
    var best = t.first;
    var miss = 0;
    for (final i in t) {
      final d = (guess.indexOf(i) - t.indexOf(i)).abs();
      if (d > miss) {
        miss = d;
        best = i;
      }
    }
    return best;
  }
}

double _log10(double v) => math.log(v) / math.ln10;
