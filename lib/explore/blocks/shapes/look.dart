/// The pieces every shape is drawn with, beside the ones Explore's own
/// shelves share (lib/widgets/explore/parts.dart): the head of a tile that
/// lets its label wrap rather than cut it, the small words a tile says
/// beside its question, and what a card is said to be about in time.
library;

import 'package:flutter/material.dart';

import '../../../data/explore_mix.dart';
import '../../../data/themed_shelves.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/explore/form_shelves.dart' show OriginRow;
import '../../../widgets/explore/parts.dart';
import '../../../widgets/subject_icon.dart';

/// Small capitals on a tile: a subject, TRY TODAY, how long. The canvas's
/// 9-point label, the one every card head on Explore is set in.
TextStyle tileLabel(Color color, {double size = 9, double spacing = 1.2}) =>
    AppText.label(
      size: size,
      weight: FontWeight.w700,
      spacing: spacing,
      height: 1.15,
      color: color,
    );

/// The subject's name as a tile's head says it, in the reader's language.
String subjectLabel(BuildContext context, Pill p) =>
    upper(context, context.l10n.subjectOf(p.topic));

/// The head of a tile: the subject's mark, and its name where the tile has
/// room for it, and the tick of a card read.
///
/// Explore's own head (CardHead) keeps the name to one line and ends it with
/// dots; a shape's tiles are set at sizes and text sizes that one line will
/// not always hold, so here the name may take a second line and the tile's
/// question, which is fitted to whatever is left, gives way.
class ShapeHead extends StatelessWidget {
  const ShapeHead({
    super.key,
    required this.pill,
    this.named = false,
    this.read = false,
    this.trailing,
    this.ink,
    this.size = 15,
    this.tickBeside = false,
  });

  final Pill pill;

  /// Whether the subject's name goes beside its mark.
  final bool named;

  /// Whether the card has been read: a tick after the name, or at the far
  /// end where there is no name.
  final bool read;

  /// Whether the tick goes beside the mark even without a name: on a tile
  /// whose far corner is taken, by a fold or a stamp's country.
  final bool tickBeside;

  /// What the head ends with instead of nothing: a country, a figure's mark.
  final Widget? trailing;

  /// The mark's colour and the name's, where the tile is not the card's own
  /// colour.
  final Color? ink;

  /// The mark's size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color mark = ink ?? pill.ink;
    final Widget tick = ReadMark(pill: pill, color: mark);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SubjectIcon(subject: pill.topic, size: size, ink: mark),
        if (named) ...[
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              subjectLabel(context, pill),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tileLabel(
                ink == null ? subOn(pill) : mark.withValues(alpha: 0.66),
              ),
            ),
          ),
          if (read) ...[const SizedBox(width: 6), tick],
          if (trailing != null) ...[
            const Spacer(),
            const SizedBox(width: 8),
            trailing!,
          ],
        ] else if (tickBeside) ...[
          if (read) ...[const SizedBox(width: 6), tick],
          const Spacer(),
          ?trailing,
        ] else ...[
          const Spacer(),
          if (read) ...[tick, if (trailing != null) const SizedBox(width: 8)],
          ?trailing,
        ],
      ],
    );
  }
}

/// A side of a debate as its button says it: "Yes, require the record" is
/// Yes, the word before the comma when there is one and it is short, and the
/// whole side otherwise — the rule the Pick a side shelf follows.
String sideLabel(String side) {
  final String head = side.split(',').first.trim();
  return head.length <= 14 ? head : side;
}

/// The two sides of a debate card, or none for a card that is not one.
List<String> sidesOf(Pill p) => switch (p.challenge) {
  TakeASide(:final positions) when positions.length >= 2 => positions,
  _ => const [],
};

/// The side the reader took on a debate, from what the card recorded.
int? sideTaken(Pill p, Answer? given) {
  if (given == null || sidesOf(p).isEmpty) return null;
  final int? side = int.tryParse(given.response);
  return side == null || side < 0 || side > 1 ? null : side;
}

/// When a card is set, as a timeline says it: the year its question names,
/// or the age it belongs to (Explore's own "where it came from" shelf says
/// it the same way).
String yearLabel(BuildContext context, Pill p) => OriginRow.when(context, p);

/// Where a card falls on a line of time, for laying a shelf out in order:
/// the year its question names, or the middle of the age it is set in, and
/// cards set in no age last.
double timeKey(Pill p) {
  final String? year = questionYear(p);
  if (year != null) {
    final double? y = double.tryParse(year.replaceAll('s', ''));
    // "The 1820s" is the middle of the decade, not its first year.
    if (y != null) return year.endsWith('s') ? y + 5 : y;
  }
  return switch (p.era) {
    'ancient' => -500,
    'medieval' => 1000,
    'early_modern' => 1650,
    'nineteenth' => 1850,
    'twentieth' => 1950,
    'recent' => 2010,
    _ => 1e9,
  };
}

/// The figure a number card is about, set large on its tile; null on a card
/// with none worth showing (lib/data/themed_shelves.dart).
String? figureOf(Pill p) => shelfFigure(p);
