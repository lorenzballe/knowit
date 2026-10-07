/// `hold`: hold for as long as you think something lasts.
///
/// Nobody carries a feel for a second, let alone for a twentieth of one,
/// and a number read in a sentence does not give it. A finger does: press,
/// wait for as long as you believe one shot of a 1940s film lasted, let go.
/// The timecode ran while you held; now your hold is laid on a ruler beside
/// the true duration and a few others, and "Show me" plays them all again
/// side by side, in real time, so the difference is felt rather than read.
///
/// Fields:
///
/// - `what` (string, up to 34 characters): what is being timed, written
///   small above the timecode. Required.
/// - `seconds` (number, 0.01 to 60): the true duration, in seconds.
///   Required.
/// - `low`, `high` (numbers, optional, both or neither): the band the truth
///   lies in, when it is a range rather than one value. `low <= seconds <=
///   high`. The truth is then written "8–11 s" and drawn as a band.
/// - `display` (string, optional): how the running clock reads. `seconds`
///   (the default: "3.42 s"), `ms` ("342 ms", for things over in a blink)
///   or `timecode` ("00:03:10", seconds and frames at 24 per second, for
///   film).
/// - `comparisons` (list, optional, up to 3): other durations on the same
///   ruler, each `{label, seconds}`; `label` up to 26 characters, `seconds`
///   0.001 to 60.
///
/// A full example:
///
/// ```json
/// {
///   "type": "hold",
///   "what": "One shot, 1940s Hollywood",
///   "seconds": 10,
///   "low": 8,
///   "high": 11,
///   "display": "timecode",
///   "comparisons": [
///     {"label": "A 2000s feature", "seconds": 4},
///     {"label": "Armageddon, 1998", "seconds": 2.3}
///   ]
/// }
/// ```
library;

import '../scene.dart';

/// How the clock reads while the reader holds.
enum HoldDisplay { seconds, ms, timecode }

/// Another duration laid on the same ruler as the truth.
class HoldComparison {
  final String label;
  final double seconds;
  const HoldComparison(this.label, this.seconds);
}

/// Hold for it.
class HoldScene extends Scene {
  /// What is being timed ("One shot, 1940s Hollywood").
  final String what;

  /// The true duration, and the band it lies in ([low] == [high] ==
  /// [seconds] when it is one value).
  final double seconds;
  final double low;
  final double high;

  final HoldDisplay display;
  final List<HoldComparison> comparisons;

  const HoldScene(
    super.raw, {
    required this.what,
    required this.seconds,
    required this.low,
    required this.high,
    required this.display,
    required this.comparisons,
  });

  /// Whether the truth is a range rather than one value.
  bool get isBand => high > low;

  static HoldScene parse(Map<String, Object?> raw, Object? id) {
    double num_(String k, Object? v, double min, double max) {
      if (v is! num || !v.isFinite) {
        throw FormatException('scene.$k must be a number', id);
      }
      if (v < min || v > max) {
        throw FormatException('scene.$k must be between $min and $max', id);
      }
      return v.toDouble();
    }

    final what = raw['what'];
    if (what is! String || what.trim().isEmpty) {
      throw FormatException('scene.what must be a string', id);
    }
    final seconds = num_('seconds', raw['seconds'], 0.01, 60);
    final hasLow = raw.containsKey('low'), hasHigh = raw.containsKey('high');
    if (hasLow != hasHigh) {
      throw FormatException('scene.low and scene.high come together', id);
    }
    final low = hasLow ? num_('low', raw['low'], 0.001, 60) : seconds;
    final high = hasHigh ? num_('high', raw['high'], 0.001, 60) : seconds;
    if (!(low <= seconds && seconds <= high)) {
      throw FormatException('scene.seconds must lie in [low, high]', id);
    }

    final shown = raw['display'] ?? 'seconds';
    final display = HoldDisplay.values
        .where((d) => d.name == shown)
        .firstOrNull;
    if (display == null) {
      throw FormatException(
        'scene.display must be seconds, ms or timecode',
        id,
      );
    }

    final list = raw['comparisons'] ?? const [];
    if (list is! List || list.length > 3) {
      throw FormatException('scene.comparisons: a list of up to 3', id);
    }
    final comparisons = <HoldComparison>[];
    for (final c in list) {
      if (c is! Map || c['label'] is! String) {
        throw FormatException(
          'scene.comparisons: each is {label, seconds}',
          id,
        );
      }
      comparisons.add(
        HoldComparison(
          c['label'] as String,
          num_('comparisons.seconds', c['seconds'], 0.001, 60),
        ),
      );
    }

    return HoldScene(
      raw,
      what: what,
      seconds: seconds,
      low: low,
      high: high,
      display: display,
      comparisons: comparisons,
    );
  }
}
