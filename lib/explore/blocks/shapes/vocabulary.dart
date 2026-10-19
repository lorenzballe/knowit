/// What a shape block reads from its section, said once, so the block and
/// the checker that passes its sections cannot come to disagree.
///
/// The checker (tool/remote/parts/explore_blocks/shapes.py) reads the same
/// words from shapes.json beside it, and test/explore/shapes_words_test.dart
/// holds the two to each other: a size, a signature or a style key the app
/// can draw is one the checker lets through, and nothing else is.
library;

import 'package:flutter/foundation.dart';

/// The sizes every shape comes in, smallest first. `m` is the canvas's own.
const List<String> kShapeSizes = ['s', 'm', 'l'];

/// The size a section gets when it names none, or one its block does not
/// have: the one the canvas drew.
const String kShapeSize = 'm';

/// The graphics a tile can carry behind its words, each drawn in a darker
/// tone of the card's own colour (design 132): the subject's mark, a quote
/// struck out, two circles that overlap, a sun about to set, a postmark,
/// the card in two halves, the card cut corner to corner, the figure set
/// large. `none` is a tile with only its words.
const List<String> kShapeSignatures = [
  'none',
  'mark',
  'quote',
  'circles',
  'sunset',
  'postmark',
  'halves',
  'diagonal',
  'figure',
];

/// One style key a block reads: a switch, a word from a list, or a whole
/// number in a range.
@immutable
class ShapeStyleKey {
  const ShapeStyleKey.flag() : words = null, least = null, most = null;
  const ShapeStyleKey.oneOf(List<String> this.words)
    : least = null,
      most = null;
  const ShapeStyleKey.count(int this.least, int this.most) : words = null;

  /// The words it may be, for a word.
  final List<String>? words;

  /// The range it may be in, for a number.
  final int? least;
  final int? most;

  /// As the checker's shapes.json writes it.
  Map<String, Object?> toJson() => words != null
      ? {'oneOf': words}
      : least != null
      ? {
          'count': [least, most],
        }
      : {'flag': true};
}

/// What one block reads, beyond what every section says (its id, block,
/// source, audience, title and line).
@immutable
class ShapeVocabulary {
  const ShapeVocabulary({
    required this.canvas,
    required this.kind,
    this.signatures = const ['none'],
    this.limit = 8,
    this.most = 12,
    this.fewest = 3,
    this.fields = const [],
    this.style = const {},
  });

  /// The designs of the canvas it was drawn from (docs/explore/shapes.md).
  final List<String> canvas;

  /// The kind of card its shelf holds when the section does not say
  /// (lib/explore/blocks/shapes/kinds.dart).
  final String kind;

  /// The signatures it can carry, the one it carries unless told first.
  final List<String> signatures;

  /// How many cards it shows unless told, and the most it ever shows.
  final int limit;
  final int most;

  /// The fewest cards that still make its shape: with fewer, the shelf is
  /// left out.
  final int fewest;

  /// Fields of its own on the section, beside size, limit, min, kind,
  /// variant, subject and signature, which every shape reads.
  final List<String> fields;

  /// The keys it reads under `style`.
  final Map<String, ShapeStyleKey> style;

  /// As the checker's shapes.json writes it.
  Map<String, Object?> toJson() => {
    'canvas': canvas,
    'kind': kind,
    'sizes': kShapeSizes,
    'signatures': signatures,
    'limit': [limit, most],
    'min': fewest,
    'fields': fields,
    'style': {for (final e in style.entries) e.key: e.value.toJson()},
  };
}
