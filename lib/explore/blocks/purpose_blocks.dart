/// Shelves built on what Astute is for, and the bottom of Explore (docs/explore, rounds 133 and 138).
///
/// Every piece of the two rounds that the app did not already have as a
/// shelf, each a block the server can place anywhere in Explore; the
/// pieces, and which of them are core's, are listed in
/// docs/explore/purpose.md.
library;

import '../explore_block.dart';
import 'purpose/commit.dart';
import 'purpose/forms.dart';
import 'purpose/move.dart';
import 'purpose/picked.dart';
import 'purpose/read_or_do.dart';

/// The blocks of this family, in the order the catalogue lists them.
const List<ExploreBlock> blocks = [
  ReadOrDoBlock(),
  CommitNoteBlock(),
  CommitBlock(),
  MoveBlock(),
  StepAboveBlock(),
  ThinSubjectBlock(),
  OtherSideBlock(),
  InYourHeadBlock(),
  SeenBlock(),
  MechanismBlock(),
  CuriousBlock(),
  MovingBlock(),
];
