/// Whole Explore screens, one idea each (docs/explore, rounds 140 and 141),
/// broken into the pieces they are made of so a day's Explore can be any of
/// them: the expert's question, where subjects meet, a question asked first
/// and the questions asked before, a chain of whys, a ruler of years, a
/// stance before and after, lines to say tonight, and the front page in its
/// seven parts. docs/explore/screens.md lists every piece and what it reads.
///
/// Mood minutes (140b), Sixty seconds and the series (140d) and Did you
/// know? (141b) are shelves the app already had, and are the `core`
/// family's.
library;

import '../explore_block.dart';
import 'screens/ask_first.dart';
import 'screens/change_your_mind.dart';
import 'screens/connect_dots.dart';
import 'screens/expert.dart';
import 'screens/front_page.dart';
import 'screens/keep_asking.dart';
import 'screens/say_it_tonight.dart';
import 'screens/through_time.dart';

/// The blocks of this family, in the order the catalogue lists them.
const List<ExploreBlock> blocks = [
  ExpertBlock(),
  ConnectDotsBlock(),
  AskFirstBlock(),
  QuestionsAskedBlock(),
  KeepAskingBlock(),
  ThroughTimeBlock(),
  ChangeYourMindBlock(),
  SayItTonightBlock(),
  MastheadBlock(),
  FrontLeadBlock(),
  FrontColumnsBlock(),
  FrontNumbersBlock(),
  FrontCorrectionBlock(),
  FrontPuzzleBlock(),
  EditionEndBlock(),
];
