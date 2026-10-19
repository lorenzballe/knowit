/// The cards a shape shows: asked of the host, kept to the shelf's kind,
/// and as many as the section says.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../models/pill.dart';
import '../../explore_block.dart';
import 'kinds.dart';
import 'vocabulary.dart';

/// One shelf's cards, what they are, and what the shelf is called.
@immutable
class ShapeDeal {
  const ShapeDeal._(this.section, this.aim, this.cards);

  final ExploreSection section;
  final ShapeAim aim;

  /// In the order they are laid out, which is the order a swipe from one to
  /// the next follows once a card is open — and, for a shape that chooses
  /// among more than it shows, the spares after them.
  final List<Pill> cards;

  /// The cards for [section] from [host], or null when there are fewer than
  /// make the block's shape.
  ///
  /// The host is asked for more than the shelf shows when the shelf keeps to
  /// a kind, because what a source gives is not all of one kind: a bare
  /// section takes whatever Explore deals, and the shape picks its own out
  /// of it. Cards that pass [first] go first, each lot in the order the host
  /// gave — a stamp shows the cards whose country is known before those
  /// whose is not.
  ///
  /// Cards that fail [keep] are not the shape's to draw at all, whatever
  /// the kind: a list of figures takes only cards with a figure. A shape
  /// with slots of different sizes asks for [spare] cards beyond those it
  /// shows, to choose among.
  static ShapeDeal? of(
    ExploreHost host,
    ExploreSection section,
    ShapeVocabulary words, {
    bool Function(Pill)? first,
    bool Function(Pill)? keep,
    int spare = 0,
    DateTime? now,
  }) {
    final ShapeAim aim = ShapeAim.of(
      section,
      words.kind,
      now ?? DateTime.now(),
    );
    final int limit = math.min(section.limit ?? words.limit, words.most);
    final Object? least = section.json['min'];
    final int fewest = least is int && least > 0
        ? math.min(least, limit)
        : math.min(words.fewest, limit);
    final List<Pill> given = host.cardsFor(
      section,
      limit: aim.isAny ? limit + spare : math.max((limit + spare) * 6, 48),
    );
    final List<Pill> kept = [
      for (final Pill p in given)
        if (aim.fits(p) && (keep == null || keep(p))) p,
    ];
    final List<Pill> ordered = first == null
        ? kept
        : [...kept.where(first), ...kept.where((p) => !first(p))];
    final List<Pill> cards = ordered.take(limit + spare).toList();
    if (cards.length < fewest || cards.isEmpty) return null;
    return ShapeDeal._(section, aim, cards);
  }

  /// The shelf's name: the section's, in the reader's language, or its
  /// kind's.
  String? title(BuildContext context, String language) =>
      section.title(language) ?? aim.title(context);

  /// The line under it, likewise.
  String? line(BuildContext context, String language) =>
      section.subtitle(language) ?? aim.line(context);
}
