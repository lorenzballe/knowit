/// The engine's own blocks: every shelf the app had before Explore came from the server, and the generic ones that show any cards at any size (carousels, grids, bento, hero, banner…), plus text, countdown, subjects, promo, spacer, divider and web; the feed; and the reader's own: their day, quick games, their subjects' levels and cards like the ones they saved.
///
/// The catalogue of them, with their fields and an example each, is
/// docs/explore/core.md; their checks are
/// tool/remote/parts/explore_blocks/core.py.
library;

import '../explore_block.dart';
import 'core/card_blocks.dart';
import 'core/feed_block.dart';
import 'core/like_saved_block.dart';
import 'core/other_blocks.dart';
import 'core/quick_games_block.dart';
import 'core/shelf_blocks.dart';
import 'core/subject_levels_block.dart';
import 'core/your_day_block.dart';

/// The blocks of this family, in the order the catalogue lists them.
const List<ExploreBlock> blocks = [
  ...shelfBlocks,
  ...cardBlocks,
  ...otherBlocks,
  FeedBlock(),
  YourDayBlock(),
  QuickGamesBlock(),
  SubjectLevelsBlock(),
  LikeSavedBlock(),
];
