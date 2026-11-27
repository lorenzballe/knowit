/// How a chart writes its numbers, the same on a card that plays a chart's
/// trick (trick_view.dart) and on Explore's shelf of charts that mislead
/// (explore/unmask_chart.dart), so the same chart never says 0.75°C in one
/// place and 0,8°C in the other: the reader's own decimal mark and
/// grouping, a minus sign rather than a hyphen, the unit where it goes,
/// and on an axis one precision for every mark, as many decimals as the
/// most exact of them needs.
library;

import 'dart:math' as math;

import 'package:intl/intl.dart' show NumberFormat;

/// [v] in [locale], with [decimals] decimals; with [trim], no more than it
/// needs, up to [decimals].
String chartNumber(
  double v,
  int decimals, {
  String locale = 'en',
  bool trim = false,
}) {
  String n = _numbers(locale, trim ? 0 : decimals, decimals).format(v.abs());
  if (v < 0 && RegExp('[1-9]').hasMatch(n)) n = '−$n';
  return n;
}

/// [n] with [unit] where it goes: a currency before it, a percentage or a
/// degree against it, any other unit after a space.
String chartUnit(String n, String unit) {
  if (unit.isEmpty) return n;
  if (const {'€', r'$', '£', '¥'}.contains(unit)) {
    return n.startsWith('−') ? '−$unit${n.substring(1)}' : '$unit$n';
  }
  if (unit == '%' || unit.startsWith('°')) return '$n$unit';
  return '$n $unit';
}

/// [v] in [locale] with its [unit]: [chartNumber], then [chartUnit].
String chartFigure(
  double v,
  int decimals,
  String unit, {
  String locale = 'en',
  bool trim = false,
}) => chartUnit(chartNumber(v, decimals, locale: locale, trim: trim), unit);

/// How many decimals [v] needs, up to [most].
int decimalsNeeded(double v, [int most = 2]) {
  for (int d = 0; d < most; d++) {
    final double f = v * math.pow(10, d);
    if ((f - f.roundToDouble()).abs() < 1e-6) return d;
  }
  return most;
}

/// The decimals every mark of an axis is written with: as many as the most
/// exact of [marks] needs, up to [most]. "0,30 · 0,55 · 0,80", not "0,3 ·
/// 0,55 · 0,8"; "40 · 43 · 46", not "40,00".
int axisDecimals(Iterable<double> marks, [int most = 2]) =>
    marks.fold(0, (d, v) => math.max(d, decimalsNeeded(v, most)));

/// The formats the numbers are written with, made once each: a chart is
/// drawn again on every frame of its turn.
final Map<String, NumberFormat> _formats = {};

NumberFormat _numbers(String locale, int least, int most) =>
    _formats.putIfAbsent('$locale $least $most', () {
      NumberFormat f;
      try {
        f = NumberFormat.decimalPattern(locale);
      } catch (_) {
        f = NumberFormat.decimalPattern('en');
      }
      return f
        ..minimumFractionDigits = least
        ..maximumFractionDigits = most;
    });
