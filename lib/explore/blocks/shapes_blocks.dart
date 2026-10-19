/// Shelf shapes and signatures: one shape for every kind of card, and one confident graphic per kind of shelf (docs/explore, rounds 131 and 132).
///
/// Every piece of the two rounds that the app did not already have is a
/// block here, named `shape-…` so no other family's names can be taken for
/// one of these: docs/explore/shapes.md lists them all, where each was
/// drawn, what it needs and what it is called.
library;

import '../explore_block.dart';
import 'shapes/layouts.dart';
import 'shapes/rows.dart';
import 'shapes/specials.dart';
import 'shapes/years.dart';

/// The blocks of this family, in the order the catalogue lists them.
const List<ExploreBlock> blocks = [
  foldRow,
  tornRow,
  tabRow,
  archRow,
  capsuleRow,
  diagonalRow,
  leafRow,
  heroRow,
  spinesRow,
  squaresRow,
  wideRow,
  mediumRow,
  markRow,
  quoteRow,
  circlesRow,
  StampBlock(),
  PostcardBlock(),
  TicketBlock(),
  TryBlock(),
  TwinsBlock(),
  SidesBlock(),
  yearsRow,
  rulerRow,
  GridBlock(),
  BentoBlock(),
  TwoRowsBlock(),
  MasonryBlock(),
];
