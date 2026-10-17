import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

// How a card meets what it lies on, decided in one place, so a card is cut
// the same way on Today, on Explore, in a hand on Profile and on a shelf.
//
// On the night paper every subject's colour stands clear of black, and a
// card's edge is its own colour's. On the day paper several do not:
// Thinking's white is within a shade of the page's cream, and yellow, lime
// and peach are within two. Their edge was a guess the eye had to make, and
// the big grey shadow under them made the guess for it, as a smudge. A card
// that would melt into its ground gets a hairline instead — one pixel of
// its own colour, taken down, which is how the cut edge of a printed card
// reads — and a card that stands clear of its ground gets none, so the line
// never turns into an outline drawn round everything.

/// Contrast between two colours, from 1 to 21, as WCAG measures it.
double colourContrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Below this, a fill and the ground under it are too alike for the eye to
/// find the edge between them.
const double kEdgeContrast = 1.6;

/// The edge of a card in [colour]: its own colour, taken down.
Color cardEdgeColour(Color colour) =>
    Color.alphaBlend(const Color(0x33000000), colour);

/// The hairline that cuts [colour] out of [ground], or null where the
/// colour stands clear of it on its own. A width of nought is one device
/// pixel, whatever the phone.
Border? cardHairline(Color colour, Color ground) {
  if (colourContrast(colour, ground) >= kEdgeContrast) return null;
  return Border.all(color: cardEdgeColour(colour), width: 0);
}

/// What a card standing on the page throws under it, [depth] times as far.
///
/// On paper: a shadow close under the card, which gives its lower edge a
/// crisp line, and a soft one below it, both faint. The one this replaces —
/// a quarter of black, blurred sixty points and dropped twenty-four —
/// reached under the card behind and the page around it as a grey slab.
/// On the night paper a shadow is black on black, so none is drawn.
List<BoxShadow> cardLift(Palette p, {double depth = 1}) => p.isDark
    ? const []
    : [
        const BoxShadow(
          color: Color(0x14000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: const Color(0x17000000),
          blurRadius: 24 * depth,
          offset: Offset(0, 10 * depth),
          spreadRadius: -6 * depth,
        ),
      ];

/// A card's face in [colour], cut from [ground] (the page, unless it lies
/// on something else) and lifted by [lift] when it stands rather than
/// lies flat.
BoxDecoration cardFace(
  BuildContext context,
  Color colour, {
  required double radius,
  double lift = 0,
  Color? ground,
}) {
  final Palette p = context.p;
  return BoxDecoration(
    color: colour,
    borderRadius: BorderRadius.circular(radius),
    border: cardHairline(colour, ground ?? p.surface),
    boxShadow: lift > 0 ? cardLift(p, depth: lift) : null,
  );
}

/// A card further back, drawn toward the page's own colour by [amount],
/// from 0 to 1.
///
/// It used to be faded instead, and a faded card is a window: the shadow
/// of the card in front, and the page, showed through it, so the edge of
/// the deck read as a grey or olive band. Drawn solid and dimmed, it keeps
/// a clean edge and its own colour, quieter.
class CardDim extends StatelessWidget {
  const CardDim({
    super.key,
    required this.amount,
    required this.ground,
    required this.child,
  });

  final double amount;
  final Color ground;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = amount.clamp(0.0, 1.0);
    if (t == 0) return child;
    final double k = 1 - t;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        k, 0, 0, 0, t * ground.r * 255, //
        0, k, 0, 0, t * ground.g * 255, //
        0, 0, k, 0, t * ground.b * 255, //
        0, 0, 0, 1, 0, //
      ]),
      child: child,
    );
  }
}
