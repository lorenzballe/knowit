/// `beauty`: something beautiful, and the simple rule that makes it.
///
/// A murmuration of starlings, a sunflower's head, Venus drawing a rose
/// around the Sun: things that look designed and are not. A sentence can
/// name the rule; it cannot give the moment of watching the shape pour out
/// of it. So the card is mostly picture, a living drawing in the card's own
/// two colours, with one short line under it saying what governs it, and
/// one gentle way to put a hand in: touch to disturb it, or drag to change
/// the one number the rule depends on and watch the beauty fall apart. The
/// reader thinks "that's beautiful", then "oh, so that's all it takes".
///
/// The drawing is chosen by [BeautyPiece], and each piece is drawn live
/// from seeded randomness, so every reader sees the same flock.
///
/// Fields:
///
/// - `piece` (string, required): which drawing. One of
///   - `flock`: birds that each watch only their nearest neighbours. Touch
///     and a falcon dives where the finger is. Takes no dial.
///   - `phyllotaxis`: seeds born at the centre, each turned by the dial's
///     angle from the last. Drag to change the angle.
///   - `orbits`: two planets on their real orbits, a line drawn between
///     them every few days. The dial is the inner planet's year.
///   - `waves`: ripples from two sources that cross and cancel. Drag a
///     source to move it. Takes no dial.
///   - `fractal`: a tree whose every branch splits in two, a little
///     shorter. The dial is the angle between the two.
/// - `caption` (string, up to 90 characters, required): the rule, in one or
///   two short sentences. Always on show under the drawing.
/// - `hint` (string, up to 34 characters, required): what the hand can do,
///   "Touch to send a falcon". Shown until the reader first touches.
/// - `reveal` (string, up to 90 characters, optional): what the touch
///   shows, replacing the hint once the reader has played.
/// - `dial` (object, required for `phyllotaxis`, `orbits` and `fractal`,
///   refused for the others): the one number the reader drags.
///   - `label` (up to 24 characters): what it is, "Turn between seeds".
///   - `unit` (up to 8 characters, optional): "°", "days". A degree sign
///     sits against the figure; anything else after a space.
///   - `value`: the true value, where the dial starts and clicks back to.
///   - `from`, `to`: the range it can be dragged across, around `value`.
///   - `decimals` (0, 1 or 2, optional, default 1): places on the readout.
/// - `params` (object, optional): the piece's own settings, each with a
///   default:
///   - `flock`: `birds` (40 to 400, default 220).
///   - `phyllotaxis`: `seeds` on show at once (150 to 1500, default 700).
///   - `orbits`: `outer`, the outer planet's year in days (required, the
///     dial's range must stay inside it); `radii`, `[inner, outer]` orbit
///     radii in any one unit (default `[0.723, 1]`, Venus and Earth in AU);
///     `every`, days between two lines (1 to 30, default 3); `span`, days
///     of lines kept on show (default 8 outer years), at most 1,500 lines.
///   - `waves`: `wavelength` as a share of the width (0.04 to 0.3, default
///     0.1); `gap` between the sources, a share of the width (0.05 to 0.8,
///     default 0.3).
///   - `fractal`: `ratio`, each branch to its parent (0.5 to 0.8, default
///     0.7); `depth`, how many times it splits (5 to 11, default 10).
/// - `accent` (string `#RRGGBB`, optional): the one colour beside ink and
///   ground, for the thing the eye should follow (a planet, the falcon). If
///   it would not show on the card's colour the view uses ink instead.
/// - `seed` (whole number, optional, default 1): the randomness, so the
///   same card draws the same picture for everyone.
///
/// A full example:
///
/// ```json
/// "scene": {
///   "type": "beauty",
///   "piece": "phyllotaxis",
///   "caption": "Each new seed grows 137.5° round from the last. Nothing else.",
///   "hint": "Drag sideways to change the turn",
///   "reveal": "A simple fraction of a turn lines seeds up in spokes and leaves gaps.",
///   "dial": {
///     "label": "Turn between seeds",
///     "unit": "°",
///     "value": 137.508,
///     "from": 125,
///     "to": 150,
///     "decimals": 1
///   },
///   "params": {"seeds": 700},
///   "seed": 7
/// }
/// ```
library;

import '../scene.dart';

/// The drawings a beauty card can be.
enum BeautyPiece {
  flock,
  phyllotaxis,
  orbits,
  waves,
  fractal;

  /// Whether the reader's hand changes one number (a dial) rather than
  /// touching the drawing itself.
  bool get dialled => this == phyllotaxis || this == orbits || this == fractal;
}

/// The one number a dialled piece lets the reader drag.
class BeautyDial {
  final String label;
  final String unit;
  final double value;
  final double from;
  final double to;
  final int decimals;
  const BeautyDial({
    required this.label,
    required this.unit,
    required this.value,
    required this.from,
    required this.to,
    required this.decimals,
  });

  double clamp(double v) => v.clamp(from, to).toDouble();

  /// The value as the readout writes it: "137.5°", "224.7 days".
  String format(double v) {
    final n = v.toStringAsFixed(decimals);
    if (unit.isEmpty) return n;
    return unit == '°' || unit == '%' ? '$n$unit' : '$n $unit';
  }
}

/// Something beautiful, and the rule that makes it.
class BeautyScene extends Scene {
  final BeautyPiece piece;
  final String caption;
  final String hint;

  /// Empty when the card has none: the hint then simply goes.
  final String reveal;

  /// Null for the pieces that are touched rather than dialled.
  final BeautyDial? dial;

  /// The accent as 0xAARRGGBB, or null for ink only.
  final int? accent;
  final int seed;

  // The pieces' own settings, every one filled in (defaults applied).
  final int birds;
  final int seeds;
  final double outer;
  final double innerRadius;
  final double outerRadius;
  final double every;
  final double span;
  final double wavelength;
  final double gap;
  final double ratio;
  final int depth;

  const BeautyScene(
    super.raw, {
    required this.piece,
    required this.caption,
    required this.hint,
    required this.reveal,
    required this.dial,
    required this.accent,
    required this.seed,
    this.birds = 220,
    this.seeds = 700,
    this.outer = 365.256,
    this.innerRadius = 0.723,
    this.outerRadius = 1,
    this.every = 3,
    this.span = 2922,
    this.wavelength = 0.1,
    this.gap = 0.3,
    this.ratio = 0.7,
    this.depth = 10,
  });

  static BeautyScene parse(Map<String, Object?> raw, Object? id) {
    Never bad(String why) => throw FormatException('scene: $why', id);

    String text(Map<String, Object?> m, String k, int most, {bool need = true}) {
      final v = m[k];
      if (v == null && !need) return '';
      if (v is! String || v.trim().isEmpty) bad('$k must be text');
      if (v.length > most) bad('$k is over $most characters');
      return v;
    }

    double number(
      Map<String, Object?> m,
      String k,
      double or, {
      required double lo,
      required double hi,
    }) {
      final v = m[k];
      if (v == null) return or;
      if (v is! num || !v.isFinite || v < lo || v > hi) {
        bad('$k must be a number from $lo to $hi');
      }
      return v.toDouble();
    }

    final piece = BeautyPiece.values.asNameMap()[raw['piece']];
    if (piece == null) {
      bad('piece must be one of ${BeautyPiece.values.map((p) => p.name)}');
    }

    BeautyDial? dial;
    final d = raw['dial'];
    if (piece.dialled) {
      if (d is! Map) bad('a ${piece.name} needs a dial');
      final m = d.cast<String, Object?>();
      double need(String k) {
        final v = m[k];
        if (v is! num || !v.isFinite) bad('dial.$k must be a number');
        return v.toDouble();
      }

      final value = need('value');
      final from = need('from');
      final to = need('to');
      if (!(from < value && value < to)) {
        bad('dial.value must lie between dial.from and dial.to');
      }
      final decimals = m['decimals'] ?? 1;
      if (decimals is! int || decimals < 0 || decimals > 2) {
        bad('dial.decimals must be 0, 1 or 2');
      }
      dial = BeautyDial(
        label: text(m, 'label', 24),
        unit: text(m, 'unit', 8, need: false),
        value: value,
        from: from,
        to: to,
        decimals: decimals,
      );
      // What each drawing can bear: an angle that stays an angle, a year
      // that stays shorter than the outer planet's.
      switch (piece) {
        case BeautyPiece.phyllotaxis when from <= 0 || to >= 360:
          bad('a turn between seeds lies inside 0° to 360°');
        case BeautyPiece.fractal when from < 0 || to > 180:
          bad('a branching angle lies inside 0° to 180°');
        case BeautyPiece.orbits when from <= 0:
          bad('an orbital period must be positive');
        default:
      }
    } else if (d != null) {
      bad('a ${piece.name} is touched, not dialled: it takes no dial');
    }

    final params = switch (raw['params']) {
      null => const <String, Object?>{},
      final Map m => m.cast<String, Object?>(),
      _ => bad('params must be an object'),
    };

    final accent = switch (raw['accent']) {
      null => null,
      final String s when RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(s) =>
        0xFF000000 | int.parse(s.substring(1), radix: 16),
      _ => bad('accent must be a colour written #RRGGBB'),
    };

    final seed = raw['seed'] ?? 1;
    if (seed is! int || seed < 1 || seed > 0x7FFFFFFF) {
      bad('seed must be a whole number from 1');
    }

    final common = (
      caption: text(raw, 'caption', 90),
      hint: text(raw, 'hint', 34),
      reveal: text(raw, 'reveal', 90, need: false),
    );

    switch (piece) {
      case BeautyPiece.flock:
        return BeautyScene(
          raw,
          piece: piece,
          caption: common.caption,
          hint: common.hint,
          reveal: common.reveal,
          dial: null,
          accent: accent,
          seed: seed,
          birds: number(params, 'birds', 220, lo: 40, hi: 400).round(),
        );
      case BeautyPiece.phyllotaxis:
        return BeautyScene(
          raw,
          piece: piece,
          caption: common.caption,
          hint: common.hint,
          reveal: common.reveal,
          dial: dial,
          accent: accent,
          seed: seed,
          seeds: number(params, 'seeds', 700, lo: 150, hi: 1500).round(),
        );
      case BeautyPiece.orbits:
        final outer = params['outer'];
        if (outer is! num || outer <= dial!.to) {
          bad('params.outer must be a year longer than the dial reaches');
        }
        final radii = params['radii'] ?? const [0.723, 1.0];
        if (radii is! List ||
            radii.length != 2 ||
            radii[0] is! num ||
            radii[1] is! num ||
            !((radii[0] as num) > 0 && (radii[0] as num) < (radii[1] as num))) {
          bad('params.radii must be [inner, outer], inner smaller');
        }
        final every = number(params, 'every', 3, lo: 1, hi: 30);
        final span = number(
          params,
          'span',
          outer * 8,
          lo: every * 10,
          hi: every * 1500,
        );
        return BeautyScene(
          raw,
          piece: piece,
          caption: common.caption,
          hint: common.hint,
          reveal: common.reveal,
          dial: dial,
          accent: accent,
          seed: seed,
          outer: outer.toDouble(),
          innerRadius: (radii[0] as num).toDouble(),
          outerRadius: (radii[1] as num).toDouble(),
          every: every,
          span: span,
        );
      case BeautyPiece.waves:
        return BeautyScene(
          raw,
          piece: piece,
          caption: common.caption,
          hint: common.hint,
          reveal: common.reveal,
          dial: null,
          accent: accent,
          seed: seed,
          wavelength: number(params, 'wavelength', 0.1, lo: 0.04, hi: 0.3),
          gap: number(params, 'gap', 0.3, lo: 0.05, hi: 0.8),
        );
      case BeautyPiece.fractal:
        return BeautyScene(
          raw,
          piece: piece,
          caption: common.caption,
          hint: common.hint,
          reveal: common.reveal,
          dial: dial,
          accent: accent,
          seed: seed,
          ratio: number(params, 'ratio', 0.7, lo: 0.5, hi: 0.8),
          depth: number(params, 'depth', 10, lo: 5, hi: 11).round(),
        );
    }
  }
}
