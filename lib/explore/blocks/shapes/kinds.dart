/// The kind of card a shape's shelf holds, and what the shelf is called
/// for it.
///
/// Round 131 gives every kind of card a shape of its own, so a reader can
/// tell what a shelf holds before reading a word of it: a folded corner is a
/// myth, a ruler of years is the past, a stamp is a place. That promise
/// holds only if a folded corner never holds anything else, so every shape
/// keeps to a kind — its own unless the section names another — and takes
/// from the cards it is given only those of that kind. The kinds are the
/// themed shelves' (lib/data/themed_shelves.dart), told apart by the tags
/// every card carries; besides them, `month` is one subject's cards, and
/// `any` is whatever the section's source gives.
library;

import 'package:flutter/widgets.dart';

import '../../../data/explore_mix.dart';
import '../../../data/themed_shelves.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../explore_block.dart';

/// Every kind a section can name: the themes, then `month` and `any`.
List<String> get kShapeKinds => [
  for (final ShelfTheme t in ShelfTheme.values) t.name,
  ShapeAim.month,
  ShapeAim.any,
];

/// What one shelf is aimed at: the kind, and the form of it where the kind
/// has more than one (an age of the past, a part of the world, a subject).
@immutable
class ShapeAim {
  const ShapeAim._(this.kind, this.theme, this.variant, this.subject);

  /// One subject's cards: the month's, unless the section names one.
  static const String month = 'month';

  /// Whatever the section's source gives.
  static const String any = 'any';

  /// The kind's name, as a section writes it.
  final String kind;

  /// The theme the kind is, when it is one.
  final ShelfTheme? theme;

  /// For the past, 0 the ancient world, 1 the 1600s to the 1800s, 2 the last
  /// century; for a place, 0 Asia and the Middle East, 1 the Americas, 2
  /// Europe. Otherwise 0.
  final int variant;

  /// For a month, the subject's key (`pop_culture`).
  final String subject;

  /// The aim of [section] for a block whose own kind is [fallback], on
  /// [now]: a kind it cannot read is the block's own, a form it does not
  /// name is the day's, as the themes turn on the app's own Explore, and a
  /// month's subject is the month's.
  factory ShapeAim.of(ExploreSection section, String fallback, DateTime now) {
    final String? named = section.get<String>('kind');
    final String kind = named != null && kShapeKinds.contains(named)
        ? named
        : fallback;
    final ShelfTheme? theme = ShelfTheme.values
        .where((t) => t.name == kind)
        .firstOrNull;
    final Object? asked = section.json['variant'];
    final int variant = theme == null
        ? 0
        : asked is int && asked >= 0 && asked <= 2
        ? themeVariantFor(theme, asked)
        : themeVariant(theme, themeDay(now));
    final String? subject = section.get<String>('subject');
    return ShapeAim._(
      kind,
      theme,
      variant,
      subject != null && kMonthSubjects.contains(subject)
          ? subject
          : monthSubject(now),
    );
  }

  /// A form the theme has: the past and a place have three, the rest one.
  static int themeVariantFor(ShelfTheme theme, int asked) =>
      theme == ShelfTheme.past || theme == ShelfTheme.place ? asked : 0;

  bool get isAny => kind == any;
  bool get isMonth => kind == month;

  /// Whether [p] belongs on the shelf: the theme's own test, with the two
  /// conditions the themed shelves add — a number that surprises has a
  /// figure to set large, and something to try today is not an argument to
  /// have.
  bool fits(Pill p) {
    if (isAny) return true;
    if (isMonth) return subjectKeyOf(p) == subject;
    final ShelfTheme t = theme!;
    if (!fitsTheme(t, p, variant: variant)) return false;
    if (t == ShelfTheme.numbers && shelfFigure(p) == null) return false;
    if (t == ShelfTheme.practical && p.challenge is TakeASide) return false;
    return true;
  }

  /// What the shelf is called, when the section does not say: the theme's
  /// own name, or the month's. Null for `any`, which has no name of its own.
  String? title(BuildContext context) {
    final l = context.l10n;
    if (isAny) return null;
    if (isMonth) return l.monthOf(l.subjectName(subject));
    return switch (theme!) {
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
      ShelfTheme.past => [l.themePast0, l.themePast1, l.themePast2][variant],
      ShelfTheme.place => [
        l.themePlace0,
        l.themePlace1,
        l.themePlace2,
      ][variant],
    };
  }

  /// The line under the name, likewise.
  String? line(BuildContext context) {
    final l = context.l10n;
    if (isAny) return null;
    if (isMonth) return l.monthShelfLine;
    return switch (theme!) {
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
  }
}
