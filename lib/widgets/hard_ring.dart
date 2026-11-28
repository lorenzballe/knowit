/// A hard card, seen as hard, wherever it is read (the owner: "le carte hard,
/// facci un contorno anche quando proprio vedi la carta, uguale a quello che
/// c'è in Explore. Quelle diventano carte hard, si distinguono proprio per
/// quella caratteristica lì").
///
/// Explore's shelf of the hardest cards (SharpRow, lib/widgets/explore/
/// form_shelves.dart) draws them dark, ringed in their subject's colour,
/// the subject's name in it and HARD on them: the one shelf where the colour
/// is held back to an edge. Ringed, a hard card looks so open too, on Today,
/// in the deck viewer and on Explore's cards, front and back: on the night
/// paper the dark ground, the subject's colour as its ring, as the ink of
/// its name and as the tag's fill, and everything else in the page's light
/// ink; on the day paper the raised paper, a pale colour taken to its darker
/// tone, as the shelf takes it. A card in words is drawn in those colours
/// (Pill.withColours), so its options, its sliders, its back, its save and
/// share and Go deeper's foot follow; a drawn card's page is told them
/// (PageEnv.hard) and the kit draws itself in them
/// (docs/cards/kit/astute-card.js).
///
/// The owner chose it on 28 November 2026, and it ships
/// (DebugLooks.hardCardsShips); the developer tools can still show a hard
/// card as today, like any other (DebugLooks.hardCards). Where a drawn card
/// is shown by its picture, the shelf and Explore show the one taken
/// ringed, on the paper the reader is on (CardThumb.picturesOf,
/// tool/cards/thumbs.cjs).
library;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/debug_looks.dart';
import '../theme.dart';
import 'card_edge.dart' show colourContrast;
import 'web/page_messages.dart';

abstract final class HardRing {
  /// Whether [pill] is drawn ringed in this run: a hard card, in the look
  /// that ships, or with ringed picked in the tools.
  static bool on(Pill pill) =>
      pill.difficulty == Difficulty.hard &&
      DebugLooks.hardCardsPicked == HardCardLook.ringed;

  /// The ring's colour, and its name's and the tag's: the subject's; on the
  /// day paper a pale colour's darker tone, which carries words there.
  static Color accentOf(Pill pill, Palette p) =>
      !p.isDark && pill.color.computeLuminance() > 0.45
      ? _shade(pill.color, 0.62)
      : pill.color;

  /// [pill]'s ring in this run, or null where it is not drawn ringed.
  static Color? ringOf(Pill pill, Palette p) =>
      on(pill) ? accentOf(pill, p) : null;

  /// The ground: night black on the night paper, the raised paper on the
  /// day one, as Explore's shelf has them.
  static Color groundOf(Palette p) =>
      p.isDark ? const Color(0xFF0B0B0D) : p.surfaceRaised;

  /// [pill] in the colours it is drawn in ringed: on the ground, in the
  /// page's ink.
  static Pill dressed(Pill pill, Palette p) =>
      pill.withColours(color: groundOf(p), ink: p.ink, tint: groundOf(p));

  /// The ring's width.
  static const double width = 2;

  /// What [pill]'s page is told to draw itself ringed, or null when it is
  /// not: the ground; the ink its drawing, its name and what it asks are in,
  /// the subject's colour (a deep one lifted on the night paper until small
  /// words read in it, and on the day paper the ring's colour taken down,
  /// its hue kept, until they read there: a drawing's labels are small);
  /// the question's, the page's own ink, as on a card in words; the ring;
  /// and HARD in the reader's language. tool/cards/hard_env.cjs gives the
  /// checker and the camera the same.
  static PageHard? pageOf(BuildContext context, Pill pill) {
    if (!on(pill)) return null;
    final Palette p = context.p;
    final Color accent = accentOf(pill, p);
    return PageHard(
      ground: groundOf(p),
      ink: inkOf(accent, p),
      question: p.ink,
      ring: accent,
      label: upperIn(context, context.l10n.hardBadge),
    );
  }

  /// Small words read on the paper at this contrast, as the web's rule for
  /// small type asks.
  static const double reads = 4.5;

  /// The ink a ringed page draws in, from its ring's colour [accent].
  @visibleForTesting
  static Color inkOf(Color accent, Palette p) {
    if (p.isDark) {
      return accent.computeLuminance() < 0.16
          ? Color.lerp(accent, Colors.white, 0.4)!
          : accent;
    }
    final Color ground = groundOf(p);
    Color ink = accent;
    for (
      double k = 0.98;
      colourContrast(ink, ground) < reads && k > 0.2;
      k -= 0.02
    ) {
      ink = _shade(accent, k);
    }
    return ink;
  }

  /// [text] in capitals, with Turkish's dotted capital I.
  static String upperIn(BuildContext context, String text) =>
      Localizations.localeOf(context).languageCode == 'tr'
      ? text.replaceAll('i', 'İ').toUpperCase()
      : text.toUpperCase();

  static Color _shade(Color c, double k) => Color.fromARGB(
    255,
    (c.r * 255 * k).round().clamp(0, 255),
    (c.g * 255 * k).round().clamp(0, 255),
    (c.b * 255 * k).round().clamp(0, 255),
  );
}

/// The ring round a card, in [colour], at the card's corner [radius], drawn
/// over its edge: the card under it is untouched and takes every touch.
class HardRingEdge extends StatelessWidget {
  const HardRingEdge({
    super.key,
    required this.colour,
    required this.radius,
    required this.child,
  });

  final Color colour;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('hard-ring'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: colour, width: HardRing.width),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// HARD, as Explore's shelf prints it: small capitals in the ground's
/// colour on a tab of the ring's.
class HardTag extends StatelessWidget {
  const HardTag({
    super.key,
    required this.accent,
    required this.ground,
    this.scale = 1,
  });

  final Color accent;
  final Color ground;

  /// Its size against the deck's card: smaller on the finished day's shelf.
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('hard-tag'),
      padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(6 * scale),
      ),
      child: Text(
        HardRing.upperIn(context, context.l10n.hardBadge),
        maxLines: 1,
        softWrap: false,
        style: AppText.label(
          size: 9 * scale,
          weight: FontWeight.w700,
          spacing: 1,
          height: 1,
          color: ground,
        ),
      ),
    );
  }
}
