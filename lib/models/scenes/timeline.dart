/// `timeline`: place it in time.
///
/// A few events, each on its own lane of one shared time axis. The reader
/// drags every event to the year they believe, locks the guesses in, and the
/// true positions slide out of their handles, leaving the gap drawn between
/// the two. The point is never the dates: it is the distance between them
/// that intuition gets wrong — Cleopatra closer to the Moon landing than to
/// the pyramids, the fax machine older than the telephone. The event most
/// readers misplace carries a `note`, and the note of the one this reader
/// missed by most is the line that comes up under the lanes.
///
/// Two axes. `years` is the calendar, drawn straight: negative years are BC,
/// there is no year 0, and distances are counted the way time passed (1 BC
/// to AD 1 is one year). `ago` is deep time, drawn in powers of ten so that
/// the age of the Earth and the age of farming fit on one phone: each event
/// gives how many years ago it was.
///
/// ```json
/// "scene": {
///   "type": "timeline",
///   "axis": "years",
///   "from": -3000,
///   "to": 2025,
///   "events": [
///     {"label": "Great Pyramid finished", "year": -2560},
///     {"label": "Last mammoths die out", "year": -2000,
///      "note": "Mammoths still lived on Wrangel Island when the Great Pyramid was new."},
///     {"label": "Cleopatra dies", "year": -30,
///      "note": "Cleopatra lived closer to the Moon landing than to the Great Pyramid."},
///     {"label": "Moon landing", "year": 1969}
///   ]
/// }
/// ```
///
/// Fields (limits are kept by tool/cards/scene_kinds/timeline.py):
/// - `axis`: `"years"` (default) or `"ago"`.
/// - `from`, `to`: the ends of the axis, left to right. For `years` two
///   calendar years with `from` < `to` (negative is BC); for `ago` two
///   numbers of years ago with `from` > `to` > 0, at most nine powers of
///   ten apart.
/// - `unit`: for `ago` only, what follows a number ("years ago"); up to 12
///   characters. The calendar needs none.
/// - `events`: 3 to 5, each `{label, year}` on `years` or `{label, ago}` on
///   `ago`, inside the axis, with an optional `note` (up to 90 characters)
///   said after the reveal. At least one event has a note. `label` is up to
///   26 characters so it shares a line with its year on a small phone.
library;

import 'dart:math' as math;

import '../../widgets/place_it.dart' show roughNumber;
import '../scene.dart';

enum TimelineSceneAxis { years, ago }

class TimelineSceneEvent {
  final String label;

  /// Where it truly sits, in axis units: an astronomical year on `years`
  /// (AD 1 is 1, 1 BC is 0, 2 BC is −1) or years ago on `ago`.
  final double at;
  final String note;
  const TimelineSceneEvent(this.label, this.at, this.note);
}

/// Place it in time.
class TimelineScene extends Scene {
  final TimelineSceneAxis axis;

  /// The axis ends, in the same units as [TimelineSceneEvent.at].
  final double from;
  final double to;
  final String unit;
  final List<TimelineSceneEvent> events;

  const TimelineScene(
    super.raw, {
    required this.axis,
    required this.from,
    required this.to,
    required this.unit,
    required this.events,
  });

  static TimelineScene parse(Map<String, Object?> raw, Object? id) {
    Never bad(String why) => throw FormatException('scene.$why', id);
    final axis = switch (raw['axis'] ?? 'years') {
      'years' => TimelineSceneAxis.years,
      'ago' => TimelineSceneAxis.ago,
      _ => bad('axis must be "years" or "ago"'),
    };
    final years = axis == TimelineSceneAxis.years;
    num n(Object? v, String what) => v is num && v.isFinite ? v : bad(what);

    final from = n(raw['from'], 'from must be a number').toDouble();
    final to = n(raw['to'], 'to must be a number').toDouble();
    if (years ? from >= to : (to <= 0 || from <= to)) {
      bad(years ? 'from must come before to' : 'from must be older than to');
    }
    if (years && (from == 0 || to == 0)) bad('there is no year 0');

    final list = raw['events'];
    if (list is! List || list.length < 3 || list.length > 5) {
      bad('events must be three to five');
    }
    final key = years ? 'year' : 'ago';
    final events = <TimelineSceneEvent>[];
    for (final e in list) {
      if (e is! Map ||
          e['label'] is! String ||
          (e['label'] as String).isEmpty) {
        bad('events must each have a label');
      }
      final v = n(e[key], 'events need a number "$key"').toDouble();
      if (years && v == 0) bad('there is no year 0');
      final at = years ? astronomical(v) : v;
      final lo = years ? astronomical(from) : to;
      final hi = years ? astronomical(to) : from;
      if (at < lo || at > hi) bad('event "${e['label']}" is off the axis');
      final note = e['note'];
      if (note != null && note is! String) bad('a note must be text');
      events.add(
        TimelineSceneEvent(e['label'] as String, at, (note ?? '') as String),
      );
    }
    if (events.every((e) => e.note.isEmpty)) bad('one event needs a note');
    final unit = raw['unit'];
    if (unit != null && unit is! String) bad('unit must be text');

    return TimelineScene(
      raw,
      axis: axis,
      from: years ? astronomical(from) : from,
      to: years ? astronomical(to) : to,
      unit: (unit ?? '') as String,
      events: events,
    );
  }

  bool get _years => axis == TimelineSceneAxis.years;

  /// A calendar year as a count with a zero in it, so that subtracting two
  /// years gives the time between them across BC and AD.
  static double astronomical(num year) =>
      year < 0 ? year + 1.0 : year.toDouble();

  double get _lf => math.log(from) / math.ln10;
  double get _lt => math.log(to) / math.ln10;

  /// 0..1 along the axis, left to right, for a value; and back.
  double t(double v) => _years
      ? ((v - from) / (to - from)).clamp(0.0, 1.0)
      : ((_lf - math.log(math.max(v, 1e-9)) / math.ln10) / (_lf - _lt)).clamp(
          0.0,
          1.0,
        );
  double valueAt(double t) => _years
      ? from + (to - from) * t.clamp(0.0, 1.0)
      : math.pow(10, _lf - (_lf - _lt) * t.clamp(0.0, 1.0)).toDouble();

  /// How finely a guess is read off the axis on `years`: about two hundred
  /// steps across, rounded to a step a person would say.
  double get grain {
    final want = (to - from) / 250;
    for (final g in const [1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2500]) {
      if (g >= want) return g.toDouble();
    }
    return 5000;
  }

  /// A guess where the finger left it, rounded the way it is shown: to the
  /// [grain] on a calendar (never landing on the year that does not exist),
  /// to two figures in deep time.
  double snap(double v) {
    if (!_years) return double.parse(v.toStringAsPrecision(2));
    final cal = v <= 0 ? v - 1 : v; // back to the calendar's own count
    var r = (cal / grain).round() * grain;
    if (r == 0) r = v > 0.5 ? 1 : -1;
    return astronomical(r);
  }

  /// Does the axis reach into BC? Then small AD years say so.
  bool get _hasBc => _years && from <= 0;

  /// A value as a reader says it: "2560 BC", "AD 79", "1969", "66 million".
  String say(double v) {
    if (!_years) return roughNumber(v);
    final y = v.round();
    if (y <= 0) return '${1 - y >= 10000 ? _thousands(1 - y) : 1 - y} BC';
    if (_hasBc && y < 1000) return 'AD $y';
    return y >= 10000 ? _thousands(y) : '$y';
  }

  /// The gap from the truth to a guess, signed the way the guess leans:
  /// "+460" for later on a calendar, "×3" in deep time (where the drawing
  /// shows which side). Empty when the guess is as close as it can be read.
  String gap(double guess, double truth) {
    if (_years) {
      // Exact: the guess is already rounded, the truth is not, and the
      // years between them are a fact rather than a reading.
      final d = (guess - truth).round();
      if (d.abs() < grain / 2) return '';
      return '${d > 0 ? '+' : '−'}${_thousands(d.abs())}';
    }
    final f = guess > truth ? guess / truth : truth / guess;
    if (f < 1.25) return '';
    return '×${f >= 10 ? roughNumber(f) : f.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}';
  }

  /// The marks under the axis: four to six round years on a calendar, the
  /// powers of ten in deep time.
  List<double> get ticks {
    if (!_years) {
      return [
        for (var e = (_lf + 1e-9).floor(); e >= (_lt - 1e-9).ceil(); e--)
          math.pow(10, e).toDouble(),
      ];
    }
    final span = to - from;
    var step = 1.0;
    for (final s in const [
      1, 2, 5, 10, 20, 25, 50, 100, 200, 250, 500, 1000, 2000, 2500, 5000, //
      10000, 20000, 50000,
    ]) {
      step = s.toDouble();
      if (span / s <= 6) break;
    }
    final lo = from <= 0 ? from - 1 : from; // calendar years again
    final hi = to <= 0 ? to - 1 : to;
    return [
      for (var c = (lo / step).ceil() * step; c <= hi; c += step)
        // No year 0: the mark between the eras is AD 1.
        c == 0 ? 1 : astronomical(c),
    ];
  }

  /// A tick's label, shorter than [say] in deep time: "100M", "10k".
  String tickLabel(double v) {
    if (_years) return say(v);
    String trim(double x) =>
        x.toStringAsFixed(x < 10 ? 1 : 0).replaceFirst(RegExp(r'\.0$'), '');
    if (v >= 1e9) return '${trim(v / 1e9)}bn';
    if (v >= 1e6) return '${trim(v / 1e6)}M';
    if (v >= 1e3) return '${trim(v / 1e3)}k';
    return trim(v);
  }

  static String _thousands(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}
