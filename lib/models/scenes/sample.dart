/// `sample`: grow the sample.
///
/// Twenty deaths can draw a dip before a birthday; twenty thousand cannot. A
/// sentence about sample sizes says this and is forgotten. Watching the same
/// rate leap about at twenty, wobble at two hundred and lie down flat on the
/// truth at twenty thousand is what makes a reader distrust the next small
/// study they hear about.
///
/// The reader grows a simulated sample in steps, each a few times the last,
/// and watches one rate (or two, side by side) settle. Every draw comes from
/// a seeded generator, so the card shows the same sample to everyone, the
/// writer can pick a seed whose first steps show the fake pattern the card
/// is about, and `tool/cards/scene_kinds/sample.py` can run the very same
/// draws to check what the notes say. The card must say it is a simulation:
/// [dots] names the sample and the bank's checker wants "simulated" in it.
///
/// JSON fields:
///
/// - `dots` (≤26 chars): what the sample is, plural and saying it is made up:
///   "Simulated deaths". Under the big count.
/// - `hit` (≤26): what a solid dot is: "Died in the week after". Under the
///   big rate; with two groups it is what both rates count.
/// - `rate`: the true share of hits, between 0 and 1, built into the
///   simulation. Or, to compare two groups:
/// - `groups`: exactly two `{label (≤14), rate}`. Draws alternate between
///   them, the first draw to the first group.
/// - `steps`: 2–5 sample sizes, rising, each at least twice the last, the
///   first at least 4 per group, the last at most 1,000,000.
/// - `seed`: 1–2147483646. Park–Miller's generator, three draws dropped.
/// - `notes`: one line per step (≤96 chars), shown once that step is reached.
/// - `button` (≤20): what growing is called on this card: "Grow the sample".
/// - `decimals` (optional, 0 or 1): places on a rate. Without it, one place
///   when a true rate has one (48.6%), none otherwise.
/// - `max` (optional): the top of the gauge, above every rate, at most 1.
///   Without it the gauge runs to a round share about twice the highest rate.
///
/// ```json
/// "scene": {
///   "type": "sample",
///   "dots": "Simulated deaths",
///   "hit": "In the week after the date",
///   "rate": 0.5,
///   "steps": [20, 200, 2000, 20000, 309221],
///   "seed": 12123,
///   "button": "Grow the sample",
///   "notes": [
///     "Fourteen of twenty died after the date: 70%. A strong story, made by chance alone.",
///     "Ten times the deaths. Still 57% after: a dip you could publish.",
///     "Two thousand. The gap is shrinking toward the truth, 50%.",
///     "Twenty thousand. Before and after are level.",
///     "As many as Ohio's real study. The real records showed no dip either."
///   ]
/// }
/// ```
library;

import 'dart:typed_data';

import '../scene.dart';

/// One of the populations drawn from, and its true share of hits.
class SampleGroup {
  final String label;
  final double rate;
  const SampleGroup(this.label, this.rate);
}

/// Grow it and watch the pattern go.
class SampleScene extends Scene {
  final String dots;
  final String hit;

  /// One group to watch a rate settle; two to watch a difference settle.
  /// A single group's label is empty.
  final List<SampleGroup> groups;
  final List<int> steps;
  final List<String> notes;
  final int seed;
  final String button;
  final int decimals;

  /// The top of the gauge, a share.
  final double top;

  const SampleScene(
    super.raw, {
    required this.dots,
    required this.hit,
    required this.groups,
    required this.steps,
    required this.notes,
    required this.seed,
    required this.button,
    required this.decimals,
    required this.top,
  });

  bool get compares => groups.length == 2;

  static SampleScene parse(Map<String, Object?> raw, Object? id) {
    String text(String k) {
      final v = raw[k];
      if (v is String && v.trim().isNotEmpty) return v;
      throw FormatException('scene.$k must be text', id);
    }

    double share(Object? v, String what) {
      if (v is num && v > 0 && v < 1) return v.toDouble();
      throw FormatException('$what must be a share between 0 and 1', id);
    }

    final List<SampleGroup> groups;
    if (raw['groups'] case final List gs) {
      if (gs.length != 2) {
        throw FormatException('scene.groups must be two', id);
      }
      groups = [
        for (final g in gs)
          if (g is Map && g['label'] is String)
            SampleGroup(g['label'] as String, share(g['rate'], 'a group rate'))
          else
            throw FormatException('scene.groups are {label, rate}', id),
      ];
    } else {
      groups = [SampleGroup('', share(raw['rate'], 'scene.rate'))];
    }

    final steps = <int>[
      for (final s in (raw['steps'] as List? ?? const []))
        if (s is int && s >= groups.length)
          s
        else
          throw FormatException('scene.steps must be whole numbers', id),
    ];
    if (steps.length < 2 || steps.length > 5) {
      throw FormatException('scene.steps must be two to five', id);
    }
    for (var i = 1; i < steps.length; i++) {
      if (steps[i] <= steps[i - 1]) {
        throw FormatException('scene.steps must rise', id);
      }
    }
    if (steps.last > 1000000) {
      throw FormatException('scene.steps go to a million at most', id);
    }

    final notes = <String>[
      for (final n in (raw['notes'] as List? ?? const []))
        if (n is String) n else throw FormatException('a note is text', id),
    ];
    if (notes.length != steps.length) {
      throw FormatException('scene.notes must be one per step', id);
    }

    final seed = raw['seed'];
    if (seed is! int || seed < 1 || seed >= _modulus) {
      throw FormatException('scene.seed must be 1 to ${_modulus - 1}', id);
    }

    final highest = groups.map((g) => g.rate).reduce((a, b) => a > b ? a : b);
    final int decimals;
    if (raw['decimals'] case final num d) {
      decimals = d.toInt().clamp(0, 1);
    } else {
      // A truth written with a decimal (48.6%) needs one to be seen landing.
      final whole = groups.every(
        (g) => ((g.rate * 100) - (g.rate * 100).roundToDouble()).abs() < 1e-9,
      );
      decimals = whole ? 0 : 1;
    }

    final double top;
    if (raw['max'] case final num m) {
      if (m <= highest || m > 1) {
        throw FormatException('scene.max must be above every rate', id);
      }
      top = m.toDouble();
    } else {
      top = _roundTop(highest * 2);
    }

    return SampleScene(
      raw,
      dots: text('dots'),
      hit: text('hit'),
      groups: groups,
      steps: steps,
      notes: notes,
      seed: seed,
      button: text('button'),
      decimals: decimals,
      top: top,
    );
  }

  /// A gauge ends on a figure a reader would write down: 10%, 20%, 25%,
  /// 30%, 40%, 50%, 60%, 80% or all of it.
  static double _roundTop(double v) {
    for (final t in const [.1, .2, .25, .3, .4, .5, .6, .8]) {
      if (v <= t + 1e-9) return t;
    }
    return 1;
  }

  /// The step in force at sample size [n]: the last one reached, or -1
  /// before the first.
  int stepAt(num n) {
    var out = -1;
    for (var i = 0; i < steps.length; i++) {
      if (n + 1e-9 >= steps[i]) out = i;
    }
    return out;
  }

  /// How a share is written on this card: "57%", "48.6%", "80%". Rounded half up,
  /// the same way the checker rounds it, so a note can quote it exactly.
  String percent(double share) {
    final scale = decimals == 0 ? 1 : 10;
    final v = (share * 100 * scale + 0.5).floorToDouble() / scale;
    // A whole number keeps no ".0": 80% reads as a figure, 80.0% as a form.
    final text = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(decimals);
    return '$text%';
  }

  /// Draws the whole sample once, up to the last step.
  SampleDraws draw() => SampleDraws._(this);
}

const _modulus = 2147483647;

/// Every draw of a [SampleScene], kept as running counts so any sample size
/// can be read back at once: the reader may drag the size down as well as
/// up, and the 20,000th draw is the same whichever way they came to it.
class SampleDraws {
  final SampleScene scene;

  /// For each group, how many of its first `k` draws were hits, at `[k]`.
  final List<Int32List> _hits;

  SampleDraws._(this.scene)
    : _hits = [
        for (var g = 0; g < scene.groups.length; g++)
          Int32List(_sizeOf(scene.steps.last, g, scene.groups.length) + 1),
      ] {
    final k = scene.groups.length;
    // Park and Miller's minimal standard generator, the same integers the
    // Python checker computes: x·16807 stays under 2^46, exact in a double
    // as well as in a 64-bit int, so the web build draws the same sample.
    var x = scene.seed;
    for (var i = 0; i < 3; i++) {
      x = x * 16807 % _modulus;
    }
    final at = List<int>.filled(k, 0);
    for (var n = 0; n < scene.steps.last; n++) {
      x = x * 16807 % _modulus;
      final g = n % k;
      final hit = x / _modulus < scene.groups[g].rate;
      _hits[g][at[g] + 1] = _hits[g][at[g]] + (hit ? 1 : 0);
      at[g]++;
    }
  }

  /// How many of the first [n] draws went to group [g].
  static int _sizeOf(int n, int g, int k) => (n + k - 1 - g) ~/ k;

  int sizeOf(int n, int g) =>
      _sizeOf(n.clamp(0, scene.steps.last), g, scene.groups.length);

  int hitsOf(int n, int g) => _hits[g][sizeOf(n, g)];

  /// The share of hits in group [g] after [n] draws, or null before any.
  double? shareOf(int n, int g) {
    final size = sizeOf(n, g);
    return size == 0 ? null : _hits[g][size] / size;
  }
}
