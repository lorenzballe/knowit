/// Shelves built on what Astute is for, and the bottom of Explore (docs/explore, rounds 133 and 138).
///
/// Every piece of the two rounds that the app did not already have as a
/// shelf, each a block the server can place anywhere in Explore; the
/// pieces, and which of them are core's, are listed in
/// docs/explore/purpose.md.
library;

import '../explore_block.dart';
import 'purpose/bottom.dart';
import 'purpose/commit.dart';
import 'purpose/feelings.dart';
import 'purpose/forms.dart';
import 'purpose/life.dart';
import 'purpose/move.dart';
import 'purpose/picked.dart';
import 'purpose/play.dart';
import 'purpose/read_or_do.dart';
import 'purpose/sets.dart';
import 'purpose/tricks.dart';

/// The blocks of this family, in the order the catalogue lists them: the
/// canvas's, from 133a to 138f.
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
  WhyBlock(),
  ThatsMeBlock(),
  AboutYouBlock(),
  HeadlineBlock(),
  OutOfWhatBlock(),
  PriceTagBlock(),
  ArgumentBlock(),
  KeepBlock(),
  LifeQuestionBlock(),
  LifeTopicsBlock(),
  SpotTrickBlock(),
  PlayedBlock(),
  SetBlock(),
  StampsBlock(),
  SetsBlock(),
  TomorrowBlock(),
  EndBlock(),
];
