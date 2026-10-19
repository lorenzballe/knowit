/// The engine's own blocks: every shelf the app had before Explore came from the server, and the generic ones that show any cards at any size (carousels, grids, bento, hero, banner…), plus text, countdown, subjects, promo, spacer, divider and web.
///
/// The catalogue of them, with their fields and an example each, is
/// docs/explore/core.md; their checks are
/// tool/remote/parts/explore_blocks/core.py.
library;

import '../explore_block.dart';
import 'core/card_blocks.dart';
import 'core/other_blocks.dart';
import 'core/shelf_blocks.dart';

/// The blocks of this family, in the order the catalogue lists them.
const List<ExploreBlock> blocks = [
  ...shelfBlocks,
  ...cardBlocks,
  ...otherBlocks,
];
