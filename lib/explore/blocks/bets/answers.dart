/// A card's answer read as a number to bet on, and the numbers a bet is set
/// in.
///
/// A bet is the card's own answer, given on a shelf before the card is
/// opened. So it can only be laid on a card whose answer is a number, and
/// it is kept the way the card keeps one: a number typed into a
/// [TypeNumber] card, in its plain form, judged within the card's
/// tolerance; a size placed on an [Estimate] card's ruler, judged within
/// its factor; a pick of a [PickOne] card whose options are all amounts,
/// judged on the option it names. Nothing here judges anything: whether a
/// bet was right is always [BetAnswer.accepts], which is the card's own
/// test, so a bet and the card can never disagree about it.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../models/pill.dart';

/// How a card takes its number.
enum BetAnswerKind {
  /// Typed in ([TypeNumber]): right within the card's tolerance.
  typed,

  /// Placed on a ruler ([Estimate]): right within the card's factor.
  estimate,

  /// Picked from amounts ([PickOne]): right on the option the card names.
  amounts,
}

/// A card's answer, as a number.
@immutable
class BetAnswer {
  const BetAnswer._({
    required this.pill,
    required this.kind,
    required this.value,
    this.unit = '',
    this.share = false,
    this.amounts = const [],
    this.odds = false,
  });

  /// The card.
  final Pill pill;

  /// How the card takes it.
  final BetAnswerKind kind;

  /// The answer: the card's own number, or the amount its right option
  /// names. For odds, the n of "1 in n".
  final double value;

  /// What the number counts, as the card says it: "studies", "°C". Empty
  /// on a pick, whose options say it themselves.
  final String unit;

  /// Whether the answer is a share of a whole, from 0 to 100 per cent:
  /// what a slider from nought to a hundred is played on.
  final bool share;

  /// On a pick, the amount each option names, in the options' order.
  final List<double> amounts;

  /// Whether a pick's options are odds, "1 in 10" to "1 in 1,000": a scale
  /// of orders of magnitude rather than of amounts.
  final bool odds;

  /// The card's answer as a number, or null when it is not one.
  static BetAnswer? of(Pill pill) {
    switch (pill.challenge) {
      case TypeNumber(:final answer, :final unit):
        if (!answer.isFinite) return null;
        return BetAnswer._(
          pill: pill,
          kind: BetAnswerKind.typed,
          value: answer.toDouble(),
          unit: unit.trim(),
          share: _isShare(unit, answer),
        );
      case Estimate(:final answer, :final unit):
        if (!answer.isFinite || answer <= 0) return null;
        return BetAnswer._(
          pill: pill,
          kind: BetAnswerKind.estimate,
          value: answer.toDouble(),
          unit: unit.trim(),
          share: _isShare(unit, answer),
        );
      case PickOne(:final options, :final correct):
        if (options.length < 2 || options.length > 3) return null;
        final List<double>? odds = _all(options, oddsOf);
        if (odds != null) {
          if (odds.toSet().length != odds.length) return null;
          return BetAnswer._(
            pill: pill,
            kind: BetAnswerKind.amounts,
            value: odds[correct],
            amounts: odds,
            odds: true,
          );
        }
        final List<Amount>? parsed = _all(options, Amount.parse);
        if (parsed == null) return null;
        final List<double> values = [for (final a in parsed) a.value];
        if (values.toSet().length != values.length) return null;
        final bool shares = parsed.every(
          (a) => a.percent && a.value >= 0 && a.value <= 100,
        );
        return BetAnswer._(
          pill: pill,
          kind: BetAnswerKind.amounts,
          value: values[correct],
          share: shares,
          amounts: values,
        );
      // A free card's answer is its page's, not a number the shelf can read.
      case NoChallenge() || TakeASide() || PageJudged():
        return null;
    }
  }

  static List<T>? _all<T>(List<String> options, T? Function(String) read) {
    final List<T> out = [];
    for (final String o in options) {
      final T? v = read(o);
      if (v == null) return null;
      out.add(v);
    }
    return out;
  }

  static bool _isShare(String unit, num answer) =>
      const {'%', 'percent', 'per cent'}.contains(unit.trim().toLowerCase()) &&
      answer >= 0 &&
      answer <= 100;

  /// Whether the answer is picked from options rather than set.
  bool get isPick => kind == BetAnswerKind.amounts;

  /// A pick's options, as the card writes them.
  List<String> get options => switch (pill.challenge) {
    PickOne(:final options) => options,
    _ => const [],
  };

  /// A pick's right option.
  int get correct => switch (pill.challenge) {
    PickOne(:final correct) => correct,
    _ => -1,
  };

  /// Whether [response], in the form the card keeps an answer, is right:
  /// the card's own judgement, and nothing else.
  bool accepts(String response) => pill.challenge.accepts(response);

  /// The most a typed answer may be off and still be right.
  double get tolerance => switch (pill.challenge) {
    TypeNumber(:final tolerance) => tolerance.toDouble(),
    _ => 0,
  };

  /// How far off an estimate may be, as a factor either way.
  double get factor => switch (pill.challenge) {
    Estimate(:final withinFactor) => withinFactor.toDouble(),
    _ => 1,
  };
}

// ── Amounts, as the bank writes them ────────────────────────────────────

/// An amount an option names: "About 28", "About $1.2 million", "40 cm",
/// "Nearly 10%".
@immutable
class Amount {
  const Amount(this.value, {this.percent = false});

  final double value;

  /// Whether it is said in per cent.
  final bool percent;

  static const String _qualifier =
      r'(?:about|around|roughly|nearly|almost|approximately|close to|'
      r'just over|just under|well over|well under|over|under|less than|'
      r'more than|fewer than|up to|at least|at most|only|exactly|barely|some)';
  static const String _number =
      r'([−-]?\d{1,3}(?:,\d{3})+(?:\.\d+)?|[−-]?\d+(?:\.\d+)?)';

  static final RegExp _amount = RegExp(
    '^(?:$_qualifier\\s+)?[€\$£¥]?\\s?$_number\\s?'
    r'(%|per ?cent\b|thousand\b|million\b|billion\b|trillion\b|'
    r'quadrillion\b|bn\b|k\b)?'
    r'(?:\s*[^\d\s][^\d]{0,31})?$',
    caseSensitive: false,
  );

  /// The amount [option] names, or null when it is words, a range, a year
  /// with words around it, or anything but one amount.
  static Amount? parse(String option) {
    final RegExpMatch? m = _amount.firstMatch(option.trim());
    if (m == null) return null;
    final double? n = _read(m.group(1)!);
    if (n == null) return null;
    final String size = (m.group(2) ?? '').toLowerCase().replaceAll(' ', '');
    final bool percent = size == '%' || size == 'percent';
    return Amount(n * _scale(size), percent: percent);
  }

  static final RegExp _odds = RegExp(
    '^(?:$_qualifier\\s+)?1\\s+in\\s+$_number'
    r'(?:\s+(thousand|million|billion))?$',
    caseSensitive: false,
  );

  static double? _read(String digits) =>
      double.tryParse(digits.replaceAll(',', '').replaceAll('−', '-'));

  static double _scale(String size) => switch (size) {
    'k' || 'thousand' => 1e3,
    'million' => 1e6,
    'bn' || 'billion' => 1e9,
    'trillion' => 1e12,
    'quadrillion' => 1e15,
    _ => 1,
  };
}

/// The n of odds of "1 in n" that [option] names, or null when it names
/// none.
double? oddsOf(String option) {
  final RegExpMatch? m = Amount._odds.firstMatch(option.trim());
  if (m == null) return null;
  final double? n = Amount._read(m.group(1)!);
  if (n == null || n < 1) return null;
  return n * Amount._scale((m.group(2) ?? '').toLowerCase());
}

// ── The form an answer is kept in ───────────────────────────────────────

/// [v] in the plain form an answer is kept in: no grouping, a point for a
/// decimal, no trailing noughts — the form [TypeNumber.read] puts a typed
/// answer into, so a bet is graded exactly as the same number typed.
String plainResponse(double v) {
  if (v == v.roundToDouble() && v.abs() < 1e15) return '${v.round()}';
  String s = v.toStringAsFixed(6);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  return s.endsWith('.') ? s.substring(0, s.length - 1) : s;
}

/// A number from 0 to 1 for [text], the same on every phone and every run:
/// what places a card's start and its scale, so neither gives the answer
/// away by always sitting at the same place.
double betUnit(String text) {
  // FNV-1a, then the murmur finaliser to spread ids that differ by a digit.
  int h = 0x811c9dc5;
  for (final int c in text.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  h ^= h >> 16;
  h = (h * 0x85ebca6b) & 0xFFFFFFFF;
  h ^= h >> 13;
  h = (h * 0xc2b2ae35) & 0xFFFFFFFF;
  h ^= h >> 16;
  return h / 0x100000000;
}

// ── Numbers, as the reader's language writes them ───────────────────────

/// Numbers in the reader's language: its decimal mark, its grouping, where
/// its per cent sign goes ("21,5 %", "%21,5").
class BetNumbers {
  BetNumbers(this.locale)
    : _percent = NumberFormat.percentPattern(locale)..maximumFractionDigits = 1;

  final String locale;
  final NumberFormat _percent;

  /// [v] with up to [decimals] places, grouped.
  String plain(double v, {int decimals = 2}) {
    final NumberFormat f = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = decimals;
    return f.format(v);
  }

  /// [v], a share from 0 to 100, with its sign.
  String percent(double v) => _percent.format(v / 100);

  /// A stretch of shares, "40–60%", with the sign once, on the side the
  /// language puts it.
  String range(double lo, double hi) {
    final String sample = _percent.format(0.5);
    final bool before = !sample.startsWith('5');
    return before
        ? '${percent(lo)}–${plain(hi, decimals: 1)}'
        : '${plain(lo, decimals: 1)}–${percent(hi)}';
  }

  /// [v] said short, "1K", "10 Mio.", for a label with little room.
  String compact(double v) => NumberFormat.compact(locale: locale).format(v);

  /// [v] said as a power of ten, "10⁶": what a label falls back on where
  /// the language's short form will not fit.
  static String power(double v) {
    final int e = (math.log(v) / math.ln10).round();
    if (e >= 0 && e <= 3) return '${math.pow(10, e).round()}';
    const String digits = '⁰¹²³⁴⁵⁶⁷⁸⁹';
    final String sign = e < 0 ? '⁻' : '';
    final String up = [
      for (final String d in '${e.abs()}'.split('')) digits[int.parse(d)],
    ].join();
    return '10$sign$up';
  }
}

// ── The steppers' scale ─────────────────────────────────────────────────

/// The steps a number is set in on the steppers, and where it starts.
///
/// The small step is a tenth of the answer's order of magnitude, or a
/// twentieth where the answer can only be reached in that, within the
/// card's tolerance; a card that cannot be reached in either (457, exactly,
/// or a third of a million to the nearest two hundred) is not one to set
/// on steppers, and is left to the shelves that type or place it. The big
/// step is five or ten small ones, chosen by the card. Both say the
/// answer's order of magnitude, which the question already sets, and
/// nothing finer. The start is a round number of that order, never the
/// answer itself, and nothing stops the number at a ceiling the reader
/// could bump into: a ceiling would say where the answer is not.
@immutable
class StepScale {
  const StepScale({
    required this.small,
    required this.big,
    required this.start,
    required this.decimals,
  });

  final double small;
  final double big;
  final double start;

  /// The places the number is shown to.
  final int decimals;

  /// The steps for [answer]'s card, or null when it cannot be set in them.
  static StepScale? around(BetAnswer answer) {
    final double a = answer.value;
    if (a < 0 || a > 1e9) return null;
    final double magnitude = a < 1e-9
        ? 1
        : math.pow(10, (math.log(a) / math.ln10).floor()).toDouble();
    double? small;
    for (final double step in [magnitude / 10, magnitude / 20]) {
      if (step < 0.01 - 1e-12) break;
      // Reached when the card itself counts the nearest step right: 27 is
      // 0.3 from 27.3 in arithmetic and a hair more in a double, and the
      // card judges the double.
      final double nearest = (a / step).round() * step;
      if (answer.accepts(plainResponse(nearest))) {
        small = step;
        break;
      }
    }
    if (small == null) return null;
    final bool tens = betUnit('big:${answer.pill.id}') < 0.5;
    final double big = small * (tens ? 10 : 5);
    final int decimals = small >= 1
        ? 0
        : (-(math.log(small * 1.0000001) / math.ln10).floor()).clamp(0, 3);
    // A round number of the answer's order, chosen by the card.
    final List<double> rounds = [
      for (final double k in const [1, 2, 5]) k * magnitude,
    ];
    final int pick = (betUnit('start:${answer.pill.id}') * 3).floor();
    double start = rounds[pick.clamp(0, 2)];
    if (answer.accepts(plainResponse(start))) {
      start = rounds[(pick + 1) % 3];
    }
    return StepScale(
      small: small,
      big: big,
      start: _snap(start, small, decimals),
      decimals: decimals,
    );
  }

  /// [v] moved by [by], kept at nought or above and on the small step.
  double move(double v, double by) =>
      _snap(math.max(0, v + by), small, decimals);

  static double _snap(double v, double step, int decimals) =>
      double.parse(((v / step).round() * step).toStringAsFixed(decimals + 2));
}

// ── Orders of magnitude ─────────────────────────────────────────────────

/// The sizes an answer is picked from by its order of magnitude: six powers
/// of ten for an estimate, with the answer's own placed by the card so it
/// is not always the same notch; or a pick's own odds, smallest first.
@immutable
class Notches {
  const Notches({
    required this.values,
    required this.right,
    this.options = const [],
  });

  /// The sizes, smallest first.
  final List<double> values;

  /// The notch the card itself counts right.
  final int right;

  /// On a pick, the option each notch is, by its index; empty on an
  /// estimate, whose notches are kept as the number they name.
  final List<int> options;

  /// The notches for [answer]'s card, or null when it has none: a card not
  /// judged on its order of magnitude, or an estimate that no power of ten
  /// is close enough to for the card to count right.
  static Notches? of(BetAnswer answer) {
    if (answer.isPick) {
      if (!answer.odds) return null;
      final List<int> order = [
        for (int i = 0; i < answer.amounts.length; i++) i,
      ]..sort((a, b) => answer.amounts[a].compareTo(answer.amounts[b]));
      return Notches(
        values: [for (final int i in order) answer.amounts[i]],
        right: order.indexOf(answer.correct),
        options: order,
      );
    }
    if (answer.kind != BetAnswerKind.estimate) return null;
    final int decade = (math.log(answer.value) / math.ln10).round();
    final double exact = math.pow(10, decade).toDouble();
    if (!answer.accepts(plainResponse(exact))) return null;
    final int at = 1 + (betUnit('notch:${answer.pill.id}') * 4).floor();
    final List<double> values = [
      for (int i = 0; i < 6; i++) math.pow(10, decade - at + i).toDouble(),
    ];
    if (values.first < 1e-6 || values.last > 1e15) return null;
    return Notches(values: values, right: at);
  }

  /// What picking notch [i] keeps as the card's answer.
  String responseAt(int i) =>
      options.isEmpty ? plainResponse(values[i]) : '${options[i]}';

  /// Orders of magnitude between notch [i] and the right one.
  int offBy(int i) => (i - right).abs();
}
