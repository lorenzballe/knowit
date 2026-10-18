/// Every block Explore can draw, by the name the remote document gives it.
///
/// One file per family in `lib/explore/blocks/`; a block a document names
/// that is not here is one this build does not know, and its section is
/// passed over (docs/REMOTE.md, rule 3).
library;

import 'blocks/bets_blocks.dart' as bets;
import 'blocks/core_blocks.dart' as core;
import 'blocks/purpose_blocks.dart' as purpose;
import 'blocks/screens_blocks.dart' as screens;
import 'blocks/shapes_blocks.dart' as shapes;
import 'explore_block.dart';

/// The blocks, by name.
final Map<String, ExploreBlock> kExploreBlocks = {
  for (final ExploreBlock block in [
    ...core.blocks,
    ...shapes.blocks,
    ...purpose.blocks,
    ...bets.blocks,
    ...screens.blocks,
  ])
    block.name: block,
};
