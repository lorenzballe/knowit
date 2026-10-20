/// What every block of the purpose family is built from: how a section's
/// size, words, limit and pool are read, the head over a shelf and over a
/// card, the marks the canvas draws that are not subjects, the themes the
/// app rotates by the names a section gives them, and the day's play.
///
/// The pieces are the Explore screen's own, measured from it and from the
/// canvas (docs/explore/purpose.md), so a block of this family sits beside
/// the app's shelves without a seam: the same name over a shelf, the same
/// margins and radii, the same Fraunces question set to the space it has.
library;

import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/explore_mix.dart' show subjectKeyOf;
import '../../../data/themed_shelves.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../state/explore_play.dart';
import '../../../theme.dart';
import '../../../widgets/balanced_text.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/explore/parts.dart';
import '../../../widgets/subject_icon.dart';
import '../../explore_block.dart';

export '../../../widgets/explore/parts.dart'
    show
        CardQuestion,
        CardTap,
        FlatButton,
        Kicker,
        ReadMark,
        SideRow,
        fillOn,
        hairOn,
        shade,
        subOn,
        upper,
        winColor;

// ── What a section says ───────────────────────────────────────────────────

/// How many cards a block asks its host for before it chooses: as many as
/// the source holds. A block that keeps only mechanisms, or only the cards
/// a step above the reader, needs the source's whole run to choose from;
/// it shows at most the section's `limit` of what it keeps.
const int kPurposePool = 5000;

/// The most cards any block of the family lays out at once, whatever a
/// section's `limit` says: a row past this is a list nobody scrolls to the
/// end of, and a grid past it is a page of its own.
const int kPurposeMost = 24;

/// A tile's size on a shelf.
@immutable
class TileSize {
  const TileSize(this.width, this.height);

  final double width;
  final double height;
}

/// The size [section] asks for among [sizes], by the names the block gives
/// them; a size this build does not know is drawn as [fallback], which is
/// the canvas's own. Never null: an older build draws what it can.
T sizeOf<T>(
  ExploreSection section,
  Map<String, T> sizes, {
  String fallback = 'm',
}) => sizes[section.size] ?? sizes[fallback] ?? sizes.values.first;

/// A field written per language, or [fallback] when the section says
/// nothing: the block's own words, from the app's strings.
String wordsOf(
  ExploreSection section,
  String field,
  String language,
  String fallback,
) => section.text(field, language) ?? fallback;

/// The most cards [section] shows: its own `limit`, or [fallback], never
/// more than [kPurposeMost].
int limitOf(ExploreSection section, int fallback) =>
    (section.limit ?? fallback).clamp(1, kPurposeMost);

/// Whether [section] keeps only the cards its form is for (the default),
/// or takes its source's cards as they come, for a shelf curated by hand.
bool fitsOnly(ExploreSection section) => section.get<bool>('fit') ?? true;

/// The cards [section] shows: from the host's pool for it, in the pool's
/// order, the ones the form [canDraw] and, unless the section says
/// otherwise, the ones it [fits]; at most [limit] of them.
List<Pill> cardsOf(
  ExploreHost host,
  ExploreSection section, {
  required int limit,
  bool Function(Pill)? canDraw,
  bool Function(Pill)? fits,
}) {
  final bool strict = fitsOnly(section);
  return [
    for (final Pill p in host.cardsFor(section, limit: kPurposePool))
      if ((canDraw == null || canDraw(p)) &&
          (!strict || fits == null || fits(p)))
        p,
  ].take(limitOf(section, limit)).toList();
}

/// A part of [section] that is a shelf of its own — one of a read-or-do's
/// shelves, one of a reader's sets — as a section the host can find cards
/// for: the section's fields under the part's own, and an id of its own,
/// so its cards are noted under it.
ExploreSection partOf(ExploreSection section, Map<Object?, Object?> part) {
  final Object? own = part['id'];
  final Map<String, Object?> json = {
    for (final MapEntry<String, Object?> e in section.json.entries)
      if (e.key != 'shelves' && e.key != 'sets') e.key: e.value,
    for (final MapEntry<Object?, Object?> e in part.entries)
      if (e.key is String) e.key! as String: e.value,
  };
  final String id =
      '${section.id}/${own is String && own.isNotEmpty ? own : json['theme'] ?? 'part'}';
  return ExploreSection(
    id: id,
    block: section.block,
    json: {...json, 'id': id, 'block': section.block},
  );
}

/// The parts [field] of [section] lists: objects only, the rest passed over
/// (docs/REMOTE.md, rule 2).
List<Map<Object?, Object?>> partsOf(ExploreSection section, String field) {
  final Object? raw = section.json[field];
  if (raw is! List) return const [];
  return [
    for (final Object? part in raw)
      if (part is Map) part,
  ];
}

// ── A shelf ───────────────────────────────────────────────────────────────

/// A shelf, as Explore draws one: its name, the line under it that says
/// why it exists, and the cards — with, where it keeps count of something,
/// the count beside the name, or at the foot of the head as the canvas's
/// read-or-do and sets have it, and anything that belongs between the head
/// and the cards, like a bar of how far along.
class PurposeShelf extends StatelessWidget {
  const PurposeShelf({
    super.key,
    required this.title,
    required this.line,
    required this.child,
    this.trailing,
    this.trailingAtFoot = false,
    this.under,
    this.underGap = 8,
    this.gap = 11,
  });

  final String title;
  final String line;
  final Widget child;

  /// A count or a control, level with the name; or, with [trailingAtFoot],
  /// level with the foot of the line, which is where a count reads as the
  /// shelf's rather than the name's.
  final Widget? trailing;
  final bool trailingAtFoot;

  /// Between the head and the cards: a bar of progress, [underGap] under
  /// the head.
  final Widget? under;
  final double underGap;

  /// The room between the head and the cards.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final Widget name = Text(
      title,
      style: AppText.body(
        size: 16,
        weight: FontWeight.w600,
        height: 1,
        spacing: -0.2,
        color: context.p.ink,
      ),
    );
    final Widget why = BalancedText(
      line,
      style: AppText.body(
        size: 12,
        height: 1.3,
        color: context.p.ink.withValues(alpha: 0.42),
      ),
    );
    final Widget head;
    if (trailing == null) {
      head = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [name, const SizedBox(height: 3), why],
      );
    } else if (trailingAtFoot) {
      head = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [name, const SizedBox(height: 3), why],
            ),
          ),
          const SizedBox(width: 10),
          trailing!,
        ],
      );
    } else {
      // The control sits level with the name, and the line runs under
      // both, so a long one in any language keeps to a line.
      head = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: name),
              const SizedBox(width: 12),
              trailing!,
            ],
          ),
          const SizedBox(height: 4),
          why,
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              head,
              if (under != null) ...[SizedBox(height: underGap), under!],
            ],
          ),
        ),
        SizedBox(height: gap),
        child,
      ],
    );
  }
}

/// A count at a shelf's head: small, in the line's weight, and never cut.
class ShelfCount extends StatelessWidget {
  const ShelfCount(this.text, {super.key, this.strong = false});

  final String text;

  /// In the page's ink rather than the line's: a set's count, which is the
  /// thing the shelf is about.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      style: AppText.body(
        size: strong ? 12 : 11,
        weight: FontWeight.w600,
        height: 1.3,
        color: strong ? context.p.ink : context.p.ink.withValues(alpha: 0.42),
      ),
    );
  }
}

// ── A card's head ─────────────────────────────────────────────────────────

/// The subject's mark and its name in the reader's language, small caps:
/// the head of every card on these shelves, as the shelves above draw it,
/// with whatever the card says beside the name or, with [trailingAtEnd],
/// in its far corner.
class PurposeHead extends StatelessWidget {
  const PurposeHead({
    super.key,
    required this.pill,
    this.trailing,
    this.trailingAtEnd = false,
    this.ink,
    this.labelInk,
    this.label,
  });

  final Pill pill;
  final Widget? trailing;

  /// Whether [trailing] sits in the card's far corner rather than after the
  /// name: a badge that says something of its own, YOU SAID NO.
  final bool trailingAtEnd;

  /// The mark's colour and the label's, where the card is not its colour.
  final Color? ink;
  final Color? labelInk;

  /// What the head says instead of the subject's name.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final Widget name = Text(
      upper(context, label ?? context.l10n.subjectOf(pill.topic)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.label(
        size: 9,
        weight: FontWeight.w700,
        spacing: 1.2,
        color: labelInk ?? subOn(pill),
      ),
    );
    return Row(
      children: [
        SubjectIcon(subject: pill.topic, size: 15, ink: ink ?? pill.ink),
        const SizedBox(width: 7),
        if (trailingAtEnd) Expanded(child: name) else Flexible(child: name),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );
  }
}

/// The subject's key for a card, `human_body`, for the app's strings that
/// name a subject by it.
String subjectKey(Pill p) => subjectKeyOf(p);

// ── A plain card ──────────────────────────────────────────────────────────

/// A card as the shelves draw one when its form is the shelf's and not the
/// card's: the head, the question set to the space it has, a tap from the
/// card.
class PlainTile extends StatelessWidget {
  const PlainTile({
    super.key,
    required this.pill,
    required this.size,
    required this.onOpen,
    this.read = false,
    this.radius = 22,
    this.max,
  });

  final Pill pill;
  final TileSize size;
  final VoidCallback onOpen;
  final bool read;
  final double radius;

  /// The question's largest size; by default, the size the tile's width
  /// takes on the shelves above.
  final double? max;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    return CardTap(
      pill: p,
      onTap: onOpen,
      child: Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.all(16),
        decoration: cardFace(context, p.color, radius: radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PurposeHead(
              pill: p,
              trailing: read ? ReadMark(pill: p) : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CardQuestion(
                  text: p.question,
                  color: p.ink,
                  min: 11,
                  max: max ?? (size.width < 190 ? 15.5 : 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── A card in a shape of its own ──────────────────────────────────────────

/// A card's face in a shape that is not a rounded box — a price tag, a
/// speech bubble, a stamp — cut from the page the way [cardFace] cuts a box:
/// its colour, and the hairline only where the colour would melt into the
/// page. With [outline], only the shape's edge, a point wide, and with
/// [dashed], dashed: the frame inside a stamp, and a stamp not yet had.
class ShapedFace extends CustomPainter {
  ShapedFace({
    required this.shape,
    required this.colour,
    required this.ground,
    this.outline = false,
    this.dashed = false,
  });

  /// The outline, for the size the face is painted at.
  final Path Function(Size size) shape;
  final Color colour;

  /// What the card lies on: the page.
  final Color ground;
  final bool outline;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = shape(size);
    if (outline || dashed) {
      final Paint pen = Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      if (!dashed) {
        canvas.drawPath(path, pen);
        return;
      }
      for (final PathMetric line in path.computeMetrics()) {
        for (double at = 0; at < line.length; at += 6) {
          canvas.drawPath(line.extractPath(at, at + 3), pen);
        }
      }
      return;
    }
    canvas.drawPath(path, Paint()..color = colour);
    if (cardHairline(colour, ground) != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = cardEdgeColour(colour)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0,
      );
    }
  }

  @override
  bool shouldRepaint(ShapedFace old) =>
      old.colour != colour ||
      old.ground != ground ||
      old.outline != outline ||
      old.dashed != dashed ||
      old.shape != shape;
}

// ── Marks ─────────────────────────────────────────────────────────────────

/// The marks the canvas draws that are not subjects, as path data on the
/// subjects' own 24-unit grid, so a chip's mark and a card's subject mark
/// are drawn the same way.
abstract final class Glyphs {
  static const String bet = 'M9 4L7 20 M17 4l-2 16 M4 9h16 M3 15h16';
  static const String trueFalse = 'M4 12.5l3 3 5.5-6.5 M15 9l5 5 M20 9l-5 5';
  static const String read = 'M5 6h14 M5 11h14 M5 16h10';
  static const String person =
      'M12 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7z M5 20c0-3.6 3.1-6 7-6s7 2.4 7 6';
  static const String type = 'M7 4h10 M12 4v16 M7 20h10';
  static const String target =
      'M12 5a7 7 0 1 0 0 14 7 7 0 1 0 0-14z M12 10a2 2 0 1 0 0 4 2 2 0 1 0 0-4z';
  static const String slider = 'M4 12h16 M9 7v10';
  static const String play = 'M7 5l10 7-10 7z';
  static const String lock = 'M7 11V8a5 5 0 0 1 10 0v3 M6 11h12v9H6z';
  static const String arrow = 'M5 12h14 M13 6l6 6-6 6';
  static const String check = 'M5 12.5l4.5 4.5L19 7.5';
  static const String again = 'M4 12a8 8 0 1 0 2.34-5.66 M4 4v5h5';
  static const String plus = 'M12 5v14 M5 12h14';
  static const String sun =
      'M12 8.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 1 0 0-7z M12 2.5v3 M12 18.5v3 '
      'M2.5 12h3 M18.5 12h3 M5.3 5.3l2.1 2.1 M16.6 16.6l2.1 2.1 '
      'M5.3 18.7l2.1-2.1 M16.6 7.4l2.1-2.1';
  static const String scales =
      'M12 4v16 M8 20h8 M5 7h14 M5 7l-2.5 6h5z M19 7l-2.5 6h5z';
  static const String search =
      'M10.5 4a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13z M20 20l-4.8-4.8';
  static const String curve = 'M3 19c4-1 5-11 9-11s5 6 9 4 M3 5v14h18';
  static const String sort = 'M4 7h9 M4 12h6 M4 17h3 M17 5v14 M14 16l3 3 3-3';
  static const String steps = 'M4 18h4v-4h4v-4h4V6h4';
  static const String hold =
      'M12 7v5l3 2 M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z';
  static const String dots =
      'M6 7h.01 M12 7h.01 M18 7h.01 M6 12h.01 M12 12h.01 M18 12h.01 M6 17h.01 M12 17h.01';
  static const String why =
      'M9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.6V14 M12 17.5h.01 '
      'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z';
  static const String speech =
      'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H9l-5 4V6z M8 9h8 M8 12h5';
  static const String pair =
      'M9 15l6-6 M7.5 11.5l-2 2a3 3 0 0 0 4.2 4.2l2-2 M16.5 12.5l2-2a3 3 0 0 0-4.2-4.2l-2 2';
  static const String clue = 'M4 20l7-7 M14 4l6 6-5 5-6-6z M9 9l6 6';
  static const String eye =
      'M2.5 12s3.5-6.5 9.5-6.5S21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z '
      'M12 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z';
  static const String note =
      'M9.5 17.75V5.75l10-2v12 M9.5 17.75a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z '
      'M19.5 15.75a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z';

  /// The canvas's bulb over WHAT TO KEEP.
  static const String bulb =
      'M9.5 18h5 M10.5 21h3 M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2.1h5'
      'c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3z';
}

/// One of [Glyphs], recoloured to whatever ink it sits on.
class PurposeGlyph extends StatelessWidget {
  const PurposeGlyph(
    this.path, {
    super.key,
    required this.size,
    required this.color,
    this.stroke = 2.2,
    this.filled = false,
  });

  final String path;
  final double size;
  final Color color;

  /// The line's weight on the 24-unit grid.
  final double stroke;

  /// Filled rather than stroked: the play triangle on a story's tile.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final String svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        '<path d="$path" fill="${filled ? '#ffffff' : 'none'}" '
        'stroke="#ffffff" stroke-width="$stroke" '
        'stroke-linecap="round" stroke-linejoin="round"/></svg>';
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.string(
          svg,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}

// ── The moves ─────────────────────────────────────────────────────────────

/// The moves that catch a trick: every move but the ones that are ways of
/// working (reflection, estimation, computation), which nothing hides in.
const Set<Principle> kTraps = {
  Principle.baseRate,
  Principle.survivorship,
  Principle.regression,
  Principle.confirmation,
  Principle.anchoring,
  Principle.sampling,
  Principle.confounding,
  Principle.counterfactual,
  Principle.multipleComparisons,
  Principle.availability,
  Principle.sunkCost,
  Principle.conjunction,
  Principle.conditional,
  Principle.independence,
  Principle.coincidence,
  Principle.exponential,
  Principle.simpson,
};

// ── The themes ────────────────────────────────────────────────────────────

/// A theme the app rotates, by the name a section gives it: its own name
/// (`myths`, `howItWorks`), or with the form it takes (`past-1`, `place-2`).
/// A theme with forms named without one takes the form of [day]. Null for
/// a name this build does not know.
(ShelfTheme, int)? themeNamed(Object? name, {required int day}) {
  if (name is! String || name.isEmpty) return null;
  final List<String> parts = name.split('-');
  final ShelfTheme? theme = ShelfTheme.values
      .where((t) => t.name == parts.first)
      .firstOrNull;
  if (theme == null || parts.length > 2) return null;
  if (parts.length == 1) return (theme, themeVariant(theme, day));
  final int? variant = int.tryParse(parts[1]);
  final bool forms = theme == ShelfTheme.past || theme == ShelfTheme.place;
  if (variant == null || variant < 0 || variant > (forms ? 2 : 0)) return null;
  return (theme, variant);
}

/// A theme's name, in the reader's language: the app's own title for it.
String themeTitle(AppLocalizations l, ShelfTheme theme, int variant) =>
    switch (theme) {
      ShelfTheme.myths => l.themeMyths,
      ShelfTheme.paradoxes => l.themeParadoxes,
      ShelfTheme.numbers => l.themeNumbers,
      ShelfTheme.practical => l.themePractical,
      ShelfTheme.origins => l.themeOrigins,
      ShelfTheme.stories => l.themeStories,
      ShelfTheme.debates => l.themeDebates,
      ShelfTheme.workItOut => l.themeWorkItOut,
      ShelfTheme.seen => l.themeSeen,
      ShelfTheme.sharpest => l.themeSharpest,
      ShelfTheme.puzzles => l.themePuzzles,
      ShelfTheme.howItWorks => l.themeHowItWorks,
      ShelfTheme.moving => l.themeMoving,
      ShelfTheme.curious => l.themeCurious,
      ShelfTheme.ideas => l.themeIdeas,
      ShelfTheme.reasoning => l.themeReasoning,
      ShelfTheme.trueOrFalse => l.themeTrueOrFalse,
      ShelfTheme.past => [
        l.themePast0,
        l.themePast1,
        l.themePast2,
      ][variant.clamp(0, 2)],
      ShelfTheme.place => [
        l.themePlace0,
        l.themePlace1,
        l.themePlace2,
      ][variant.clamp(0, 2)],
    };

/// The line under a theme's name, in the reader's language.
String themeLine(AppLocalizations l, ShelfTheme theme) => switch (theme) {
  ShelfTheme.myths => l.themeMythsLine,
  ShelfTheme.paradoxes => l.themeParadoxesLine,
  ShelfTheme.numbers => l.themeNumbersLine,
  ShelfTheme.practical => l.themePracticalLine,
  ShelfTheme.origins => l.themeOriginsLine,
  ShelfTheme.stories => l.themeStoriesLine,
  ShelfTheme.debates => l.themeDebatesLine,
  ShelfTheme.workItOut => l.themeWorkItOutLine,
  ShelfTheme.seen => l.themeSeenLine,
  ShelfTheme.sharpest => l.themeSharpestLine,
  ShelfTheme.puzzles => l.themePuzzlesLine,
  ShelfTheme.howItWorks => l.themeHowItWorksLine,
  ShelfTheme.moving => l.themeMovingLine,
  ShelfTheme.curious => l.themeCuriousLine,
  ShelfTheme.ideas => l.themeIdeasLine,
  ShelfTheme.reasoning => l.themeReasoningLine,
  ShelfTheme.trueOrFalse => l.themeTrueOrFalseLine,
  ShelfTheme.past => l.themePastLine,
  ShelfTheme.place => l.themePlaceLine,
};

/// The cards of a theme in an order that does not turn with the day: what a
/// set is made of, so the set a reader is filling is the same set tomorrow.
List<Pill> themeSet(
  Iterable<Pill> pool,
  ShelfTheme theme,
  int variant, {
  required int size,
}) {
  final List<Pill> fits =
      pool.where((p) => fitsTheme(theme, p, variant: variant)).toList()..sort(
        (a, b) =>
            shelfHash('set:${theme.name}-$variant:${a.id}')
                .compareTo(shelfHash('set:${theme.name}-$variant:${b.id}')),
      );
  return fits.take(size).toList();
}

/// Today, as the themes count days.
int today() => themeDay(purposeClock());

/// The clock the purpose blocks read the day from: the phone's, unless a
/// test pins it, so a shelf that turns with the day is tested on a day
/// whose turn is known rather than on whatever day the test runs.
@visibleForTesting
DateTime Function() purposeClock = DateTime.now;

/// The theme a set stands for this week, when a section names none: the
/// themes in the order the app turns them, one a week, among [among] and
/// those [pool] holds at least [least] cards of, so a set is the same set
/// all week and a different one the next. Null when the pool fills none.
(ShelfTheme, int)? weekTheme(
  List<Pill> pool, {
  required int day,
  Iterable<ShelfTheme> among = kThemeCycle,
  int least = kThemeMinimum,
}) {
  final List<ShelfTheme> order = [
    for (final ShelfTheme t in kThemeCycle)
      if (among.contains(t)) t,
  ];
  final int week = day ~/ 7;
  for (int i = 0; i < order.length; i++) {
    final ShelfTheme theme = order[(week + i) % order.length];
    final int variant = themeVariant(theme, week * 7);
    final int count = pool
        .where((p) => fitsTheme(theme, p, variant: variant))
        .length;
    if (count >= least) return (theme, variant);
  }
  return null;
}

// ── The day's play ────────────────────────────────────────────────────────

/// What this family keeps in the day's play (lib/state/explore_play.dart),
/// under its own prefix: the marks, the picks, the tricks spotted. A day's
/// play and nothing more, like every game on a shelf; what is worth keeping
/// for good is an answer, and goes through the host.
abstract final class PurposePlay {
  static const String _prefix = 'purpose:';

  /// What a block listens to, to be drawn again when the day's play
  /// changes: a pick here, a slider checked on a shelf above.
  static Listenable get listenable => ExplorePlay.instance;

  /// What was kept under [key] for today, or null.
  static Object? read(String key) => ExplorePlay.instance['$_prefix$key'];

  /// Keeps [value] under [key] for the rest of the day; null forgets it.
  static void write(String key, Object? value) =>
      ExplorePlay.instance.put('$_prefix$key', value);

  /// A set of strings kept under [key]: card ids, topics.
  static Set<String> setOf(String key) {
    final Object? raw = read(key);
    if (raw is! List) return {};
    return {
      for (final Object? v in raw)
        if (v is String) v,
    };
  }

  /// Keeps [values] under [key], in a stable order.
  static void writeSet(String key, Set<String> values) =>
      write(key, values.isEmpty ? null : (values.toList()..sort()));

  /// Notes that the card [id] was answered on a shelf of this family
  /// today, for the count of what was played.
  static void said(String id) => writeSet('said', setOf('said')..add(id));
}

/// Draws [builder] again when what [select] reads from the day's play
/// changes, and only then. A slider dragged on a shelf above changes the
/// day's play many times a second; a shelf that does not show it is not
/// laid out again each time.
class PlayWatch<T> extends StatefulWidget {
  const PlayWatch({super.key, required this.select, required this.builder});

  /// What the shelf shows of the day's play: a value that compares equal
  /// when nothing it shows has changed (a set, a list, a record).
  final T Function() select;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<PlayWatch<T>> createState() => _PlayWatchState<T>();
}

class _PlayWatchState<T> extends State<PlayWatch<T>> {
  late final Listenable _play = PurposePlay.listenable;
  late T _value = widget.select();

  @override
  void initState() {
    super.initState();
    _play.addListener(_changed);
  }

  @override
  void didUpdateWidget(PlayWatch<T> old) {
    super.didUpdateWidget(old);
    _value = widget.select();
  }

  @override
  void dispose() {
    _play.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final T now = widget.select();
    if (!_same(now, _value)) setState(() => _value = now);
  }

  static bool _same(Object? a, Object? b) => switch ((a, b)) {
    (final Set<Object?> x, final Set<Object?> y) => setEquals(x, y),
    (final List<Object?> x, final List<Object?> y) => listEquals(x, y),
    _ => a == b,
  };

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
