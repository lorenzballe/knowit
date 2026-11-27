/// The engine's own blocks: every shelf the app had before Explore came from the server, and the generic ones that show any cards at any size (carousels, grids, bento, hero, banner…), plus text, countdown, subjects, promo, spacer, divider and web; the feed; and the reader's own: their day, quick games, their subjects' levels, cards like the ones they saved, paths of ten, and what they started and left.
///
/// The catalogue of them, with their fields and an example each, is
/// docs/explore/core.md; their checks are
/// tool/remote/parts/explore_blocks/core.py.
library;

import '../explore_block.dart';
import 'core/books_block.dart';
import 'core/card_blocks.dart';
import 'core/continue_block.dart';
import 'core/cover_block.dart';
import 'core/feed_block.dart';
import 'core/focus_block.dart';
import 'core/founders_block.dart';
import 'core/goal_block.dart';
import 'core/like_saved_block.dart';
import 'core/line_block.dart';
import 'core/maths_daily_block.dart';
import 'core/news_block.dart';
import 'core/other_blocks.dart';
import 'core/paths_block.dart';
import 'core/quick_games_block.dart';
import 'core/shelf_blocks.dart';
import 'core/subject_levels_block.dart';
import 'core/video_block.dart';
import 'core/your_day_block.dart';
import 'core/your_five_block.dart';

/// The blocks of this family, in the order the catalogue lists them.
const List<ExploreBlock> blocks = [
  ...shelfBlocks,
  ...cardBlocks,
  ...otherBlocks,
  CoverBlock(),
  FeedBlock(),
  YourDayBlock(),
  YourFiveBlock(),
  QuickGamesBlock(),
  SubjectLevelsBlock(),
  LikeSavedBlock(),
  PathsBlock(),
  BooksBlock(),
  FoundersBlock(),
  ContinueBlock(),
  MathsDailyBlock(),
  NewsBlock(),
  LineOfDayBlock(),
  GoalBlock(),
  FocusBlock(),
  VideoCardsBlock(),
];
