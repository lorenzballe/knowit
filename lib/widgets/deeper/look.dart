/// The colours of Go deeper (deeper_sheet.dart): the card's subject as the
/// sheet's world, and around it a set of hues that belong together, one for
/// each part, so no two parts look alike and all of them look like the card.
///
/// Worked out in OKLCH rather than in RGB or HSL: there a yellow and a blue
/// at the same "lightness" are not equally light to the eye, so a title
/// drawn in one is easy to read and in the other is not. In OKLCH lightness
/// is lightness, whatever the hue, and every colour here is chosen by it
/// and then checked against the ink it carries.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/topics.dart' show inkOn;

/// A colour as lightness (0 to 1), chroma (0 to about 0.37) and hue (in
/// degrees): Björn Ottosson's OKLab, in polar form.
@immutable
class Oklch {
  const Oklch(this.l, this.c, this.h);

  final double l;
  final double c;
  final double h;

  factory Oklch.of(Color colour) {
    final double r = _linear(colour.r);
    final double g = _linear(colour.g);
    final double b = _linear(colour.b);
    final double l = _cbrt(
      0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b,
    );
    final double m = _cbrt(
      0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b,
    );
    final double s = _cbrt(
      0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b,
    );
    final double lightness =
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
    final double a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
    final double bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
    double hue = math.atan2(bb, a) * 180 / math.pi;
    if (hue < 0) hue += 360;
    return Oklch(lightness, math.sqrt(a * a + bb * bb), hue);
  }

  /// The colour, with its chroma cut to the most the screen can show at its
  /// lightness and hue.
  Color toColour() {
    final Oklch shown = _inGamut ? this : withChroma(maxChroma(l, h));
    final (double r, double g, double b) = shown._rgb();
    return Color.from(
      alpha: 1,
      red: _gamma(r.clamp(0.0, 1.0)),
      green: _gamma(g.clamp(0.0, 1.0)),
      blue: _gamma(b.clamp(0.0, 1.0)),
    );
  }

  Oklch withLightness(double value) => Oklch(value.clamp(0.0, 1.0), c, h);
  Oklch withChroma(double value) => Oklch(l, math.max(0, value), h);
  Oklch turned(double degrees) => Oklch(l, c, (h + degrees) % 360);

  /// The most chroma sRGB can show at lightness [l] and hue [h].
  static double maxChroma(double l, double h) {
    double lo = 0;
    double hi = 0.4;
    for (int i = 0; i < 18; i++) {
      final double mid = (lo + hi) / 2;
      if (Oklch(l, mid, h)._inGamut) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Where hue [h] is most vivid: its lightness and chroma there. A yellow
  /// is most itself near white, a blue far below it.
  static (double, double) cusp(double h) {
    double bestL = 0.6;
    double bestC = 0;
    for (double l = 0.3; l <= 0.985; l += 0.01) {
      final double c = maxChroma(l, h);
      if (c > bestC) {
        bestC = c;
        bestL = l;
      }
    }
    return (bestL, bestC);
  }

  bool get _inGamut {
    final (double r, double g, double b) = _rgb();
    const double e = 1e-4;
    return r >= -e &&
        r <= 1 + e &&
        g >= -e &&
        g <= 1 + e &&
        b >= -e &&
        b <= 1 + e;
  }

  (double, double, double) _rgb() {
    final double rad = h * math.pi / 180;
    final double a = c * math.cos(rad);
    final double b = c * math.sin(rad);
    final double l1 = l + 0.3963377774 * a + 0.2158037573 * b;
    final double m1 = l - 0.1055613458 * a - 0.0638541728 * b;
    final double s1 = l - 0.0894841775 * a - 1.2914855480 * b;
    final double l3 = l1 * l1 * l1;
    final double m3 = m1 * m1 * m1;
    final double s3 = s1 * s1 * s1;
    return (
      4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3,
      -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3,
      -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3,
    );
  }

  static double _linear(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  static double _gamma(double v) => v <= 0.0031308
      ? 12.92 * v
      : 1.055 * math.pow(v, 1 / 2.4).toDouble() - 0.055;

  static double _cbrt(double v) =>
      v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();
}

/// How far apart two colours are to the eye, as WCAG counts it: 1 for the
/// same, 21 for black on white. Running text wants 4.5, large text 3.
double contrastOf(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The near-black every drawing in the sheet is outlined in, as the drawn
/// cards are (docs/cards/STILE.md).
const Color kDeeperLine = Color(0xFF17140F);

/// The cream a drawing is filled with where a drawn card would leave paper.
const Color kDeeperCream = Color(0xFFFFF7E8);

/// One vivid colour with the ink that reads on it: a half of the two views,
/// the reader's own bubble, a button.
@immutable
class DeeperVivid {
  const DeeperVivid({
    required this.hue,
    required this.fill,
    required this.deep,
    required this.ink,
  });

  /// Where it sits on the wheel, in degrees.
  final double hue;

  /// The colour itself, where a gradient starts.
  final Color fill;

  /// The same, deeper and turned a little, where the gradient ends.
  final Color deep;

  /// Black or white, whichever reads on both, at 4.5 to 1 or better.
  final Color ink;

  /// The two as a gradient from the top left.
  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [fill, deep],
  );

  /// [hue] at its most vivid, kept within [low] and [high] lightness so a
  /// yellow does not wash out and a blue does not go to night.
  factory DeeperVivid.of(double hue, {double low = 0.6, double high = 0.86}) {
    final (double cl, double cc) = Oklch.cusp(hue);
    final double l = cl.clamp(low, high);
    Oklch fill = Oklch(l, cc * 0.96, hue);
    Oklch deep = Oklch(math.max(low - 0.1, l - 0.1), cc, (hue - 14) % 360);
    // Whichever ink reads better on the pair, then the pair moved, a step
    // at a time, until it reads well on both.
    final Color first = fill.toColour();
    final bool white =
        contrastOf(first, Colors.white) >= contrastOf(first, kInkDark);
    final Color ink = white ? Colors.white : kInkDark;
    for (int i = 0; i < 30; i++) {
      final bool ok =
          contrastOf(fill.toColour(), ink) >= 4.5 &&
          contrastOf(deep.toColour(), ink) >= 4.5;
      if (ok) break;
      final double step = white ? -0.012 : 0.012;
      if (contrastOf(fill.toColour(), ink) < 4.5) {
        fill = fill.withLightness(fill.l + step);
      }
      if (contrastOf(deep.toColour(), ink) < 4.5) {
        deep = deep.withLightness(deep.l + step);
      }
    }
    return DeeperVivid(
      hue: hue % 360,
      fill: fill.toColour(),
      deep: deep.toColour(),
      ink: ink,
    );
  }
}

/// The ink the cards print in where it is dark (topics.dart, [inkOn]).
const Color kInkDark = Color(0xFF10100C);

/// One part's colours: its own hue, as each theme wants it.
@immutable
class DeeperTone {
  const DeeperTone({
    required this.hue,
    required this.vivid,
    required this.title,
    required this.accent,
    required this.wash,
    required this.tile,
    required this.edge,
    required this.shadow,
    required this.field,
  });

  final double hue;

  /// The drawing's ground and the part's buttons, the same in both themes:
  /// the colour of the part, as a card is the colour of its subject.
  final DeeperVivid vivid;

  /// The part's name, read on the part's own ground.
  final Color title;

  /// Small marks in the part's colour: a letter, an outline, a focus ring.
  final Color accent;

  /// The colour the part's ground is washed with from its top left corner.
  final Color wash;

  /// The part's ground under the wash.
  final Color tile;

  /// The hairline round the part.
  final Color edge;

  /// The soft light under the part, on paper; clear at night, where a
  /// shadow on black is not seen.
  final Color shadow;

  /// A box to write in, inside the part.
  final Color field;

  /// One tone for every part, in the editorial ways of setting them: the
  /// subject's hue only as a quiet echo, the grounds left to the sheet.
  factory DeeperTone.quiet(
    double hue, {
    required bool dark,
    required bool pearl,
  }) {
    final double h = hue % 360;
    final double c = pearl ? 0.025 : 0.085;
    return DeeperTone(
      hue: h,
      vivid: DeeperVivid.of(h),
      title: dark
          ? Oklch(0.86, c * 0.8, h).toColour()
          : Oklch(0.42, c, h).toColour(),
      accent: dark
          ? Oklch(0.80, c, h).toColour()
          : Oklch(0.50, c * 1.15, h).toColour(),
      wash: dark
          ? Oklch(0.25, c * 0.25, h).toColour()
          : Oklch(0.955, c * 0.15, h).toColour(),
      tile: const Color(0x00000000),
      edge: dark ? const Color(0x24FFFFFF) : const Color(0x1F000000),
      shadow: const Color(0x00000000),
      field: dark ? const Color(0x0DFFFFFF) : const Color(0xB3FFFFFF),
    );
  }

  factory DeeperTone.of(double hue, {required bool dark}) {
    final double h = hue % 360;
    return DeeperTone(
      hue: h,
      vivid: DeeperVivid.of(h),
      title: dark
          ? Oklch(0.87, 0.11, h).toColour()
          : Oklch(0.45, 0.15, h).toColour(),
      accent: dark
          ? Oklch(0.80, 0.14, h).toColour()
          : Oklch(0.52, 0.17, h).toColour(),
      wash: dark
          ? Oklch(0.31, 0.075, h).toColour()
          : Oklch(0.955, 0.04, h).toColour(),
      tile: dark ? const Color(0xFF131316) : Colors.white,
      edge: dark
          ? Color.alphaBlend(
              Oklch(0.6, 0.1, h).toColour().withValues(alpha: 0.16),
              const Color(0x14FFFFFF),
            )
          : Oklch(0.9, 0.035, h).toColour(),
      shadow: dark
          ? const Color(0x00000000)
          : Oklch(0.55, 0.12, h).toColour().withValues(alpha: 0.16),
      field: dark
          ? Color.alphaBlend(
              Oklch(0.35, 0.06, h).toColour().withValues(alpha: 0.45),
              const Color(0xFF0B0B0D),
            )
          : Oklch(0.975, 0.018, h).toColour(),
    );
  }
}

/// The parts of Go deeper that wear a colour of their own.
enum DeeperPart { simply, why, sides, example, quiz, take, ask, source }

/// The whole sheet's colours, for one card in one theme.
@immutable
class DeeperLook {
  const DeeperLook._({
    required this.dark,
    required this.pearl,
    required this.world,
    required this.worldInk,
    required this.glow,
    required this.ground,
    required this.tones,
    required this.sideA,
    required this.sideB,
  });

  final bool dark;

  /// Whether the world has no hue of its own: Thinking's paper, which is
  /// lit like mother of pearl rather than coloured.
  final bool pearl;

  /// The card's colour, the header's ground.
  final Color world;

  /// The ink the card prints in, and the header with it.
  final Color worldInk;

  /// The lights that drift across the header, all of them close enough to
  /// [world] for [worldInk] to keep reading on every one.
  final List<Color> glow;

  /// The sheet under the parts.
  final Color ground;

  final Map<DeeperPart, DeeperTone> tones;

  /// The two views, facing each other: one near the subject's own hue, the
  /// other across the wheel from it.
  final DeeperVivid sideA;
  final DeeperVivid sideB;

  DeeperTone tone(DeeperPart part) => tones[part]!;

  /// The subject's own hue, the one the parts turn from.
  double get hue => tones[DeeperPart.simply]!.hue;

  /// The same sheet for the editorial ways of setting the parts
  /// (editorial.dart): the head as it is, every part in one quiet tone of
  /// the subject's hue instead of a colour of its own.
  DeeperLook get quiet => _quiet[(world.toARGB32(), dark)] ??= DeeperLook._(
    dark: dark,
    pearl: pearl,
    world: world,
    worldInk: worldInk,
    glow: glow,
    ground: ground,
    tones: {
      for (final DeeperPart part in DeeperPart.values)
        part: DeeperTone.quiet(hue, dark: dark, pearl: pearl),
    },
    sideA: sideA,
    sideB: sideB,
  );

  static final Map<(int, bool), DeeperLook> _quiet = {};

  /// Where each part sits on the wheel, from the subject's hue: a fan of
  /// neighbours, so the parts differ and still belong to the card.
  ///
  /// Both sides alone turns right across, to the second view's colour: one
  /// part in each sheet that stands apart from the others, as the other
  /// side of a question does.
  static const Map<DeeperPart, double> turns = {
    DeeperPart.simply: 0,
    DeeperPart.why: 45,
    DeeperPart.sides: 162,
    DeeperPart.example: -45,
    DeeperPart.quiz: 90,
    DeeperPart.take: -90,
    DeeperPart.ask: 135,
    DeeperPart.source: 0,
  };

  /// Where each part sits for a world with no hue: the whole wheel, the
  /// colours of all the subjects together, as the app's own voice is.
  static const Map<DeeperPart, double> pearlTurns = {
    DeeperPart.simply: 0,
    DeeperPart.why: 67,
    DeeperPart.sides: 127,
    DeeperPart.example: -73,
    DeeperPart.quiz: 172,
    DeeperPart.take: -118,
    DeeperPart.ask: 32,
    DeeperPart.source: 0,
  };

  /// The hue a world with none of its own turns from: indigo, the colour of
  /// the app's own links.
  static const double pearlHue = 268;

  static final Map<(int, bool), DeeperLook> _made = {};

  /// The look for a card of colour [world] in the dark or on paper. Made
  /// once for each colour and theme: the sums are small, but there is no
  /// reason to do them twice.
  factory DeeperLook.of(Color world, {required bool dark}) =>
      _made[(world.toARGB32(), dark)] ??= DeeperLook._make(world, dark: dark);

  factory DeeperLook._make(Color world, {required bool dark}) {
    final Oklch o = Oklch.of(world);
    final bool pearl = o.c < 0.035;
    final double base = pearl ? pearlHue : o.h;
    final Color ink = inkOn(world);
    final bool inkIsDark = ink.computeLuminance() < 0.5;

    // The header's lights: the subject's hue turned a little either way,
    // one lighter and one deeper, each moved back towards the world's own
    // lightness until the ink reads on it as well as on the card.
    final List<Color> glow;
    if (pearl) {
      glow = [
        const Oklch(0.89, 0.075, 305).toColour(),
        const Oklch(0.92, 0.075, 170).toColour(),
        const Oklch(0.925, 0.07, 65).toColour(),
        const Oklch(0.9, 0.065, 240).toColour(),
      ];
    } else {
      final double need = inkIsDark
          ? 4.5
          : math.min(3.0, contrastOf(world, ink)) - 0.05;
      Color kept(Oklch c) {
        Oklch at = c;
        for (int i = 0; i < 40; i++) {
          final Color shown = at.toColour();
          if (contrastOf(shown, ink) >= need) return shown;
          at = at.withLightness(at.l + (inkIsDark ? 0.012 : -0.012));
        }
        return world;
      }

      glow = [
        kept(Oklch(o.l, o.c, (o.h + 42) % 360)),
        kept(Oklch(o.l + 0.09, o.c * 0.8, (o.h + 10) % 360)),
        kept(Oklch(o.l, o.c, (o.h - 40) % 360)),
        kept(Oklch(o.l - 0.09, o.c, (o.h - 14) % 360)),
      ];
    }

    final Color ground = dark
        ? Color.alphaBlend(
            (pearl
                    ? const Color(0xFF1A1A1F)
                    : Oklch(0.3, 0.07, base).toColour())
                .withValues(alpha: 0.42),
            const Color(0xFF050506),
          )
        : pearl
        ? const Color(0xFFEAE8E2)
        : Color.alphaBlend(
            Oklch(0.93, 0.035, base).toColour().withValues(alpha: 0.55),
            const Color(0xFFF5F3EE),
          );

    return DeeperLook._(
      dark: dark,
      pearl: pearl,
      world: world,
      worldInk: ink,
      glow: glow,
      ground: ground,
      tones: {
        for (final MapEntry<DeeperPart, double> e
            in (pearl ? pearlTurns : turns).entries)
          e.key: DeeperTone.of(base + e.value, dark: dark),
      },
      sideA: DeeperVivid.of(pearl ? 255 : base - 18),
      sideB: DeeperVivid.of(pearl ? 35 : base + 162),
    );
  }
}
