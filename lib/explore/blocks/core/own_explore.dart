/// The build's own Explore: the sections Explore shows when the remote
/// document says nothing of it — exactly the shelves it had before it came
/// from the server, in their order, drawn by the same engine as any
/// document's, so `explore: null` is that Explore to the pixel.
///
/// remote/examples/explore-today.json is the same list as a document; a
/// test keeps the two the same.
library;

import '../../explore_block.dart';

/// The sections as the remote document would give them, as JSON.
const List<Map<String, Object?>> kOwnExploreJson = [
  // Two lines that are not shelves, then the shelves, each the room of
  // 24 points under the one above but today's, which is the first.
  {'id': 'nothing', 'block': 'nothing-here'},
  {'id': 'offline', 'block': 'offline'},
  {'id': 'today', 'block': 'today', 'gap': 0},
  {'id': 'top', 'block': 'top'},
  {'id': 'loved', 'block': 'loved'},
  {'id': 'asking', 'block': 'asking'},
  {'id': 'mine', 'block': 'mine'},
  {'id': 'where-you-live', 'block': 'where-you-live'},
  // The mix, in three movements: cards to read (the month, numbers, a side
  // to pick, the hardest, origins, stories played a beat at a time), cards
  // to play (true or false, what came back, the tricks in a number, working
  // it out, a chart unmasked, how sure, what if), and ways in by time (a
  // few cards, sixty seconds, your minutes, a fact), then one card from
  // anywhere and something to use before tonight at the very end. Every one
  // is free: Explore is what brings a reader back.
  {'id': 'month', 'block': 'month'},
  {'id': 'signature-numbers', 'block': 'numbers'},
  {'id': 'signature-debates', 'block': 'debates'},
  {'id': 'theme-sharpest-0', 'block': 'sharpest'},
  {'id': 'theme-origins-0', 'block': 'origins'},
  {'id': 'theme-stories-0', 'block': 'stories'},
  {'id': 'theme-trueOrFalse-0', 'block': 'true-false'},
  {'id': 'came-back', 'block': 'came-back'},
  {'id': 'move-sampling', 'block': 'move-sampling'},
  {'id': 'move-counterfactual', 'block': 'move-compared'},
  {'id': 'work', 'block': 'work'},
  {'id': 'unmask', 'block': 'unmask'},
  {'id': 'how-sure', 'block': 'how-sure', 'gap': 28},
  {'id': 'what-if', 'block': 'what-if'},
  {'id': 'series', 'block': 'series'},
  {'id': 'sixty', 'block': 'sixty'},
  {'id': 'mood', 'block': 'mood', 'gap': 28},
  {'id': 'did-you-know', 'block': 'did-you-know'},
  {'id': 'surprise', 'block': 'surprise'},
  {'id': 'theme-practical-0', 'block': 'practical'},
];

/// The build's own sections.
final List<ExploreSection> kOwnExplore = List.unmodifiable([
  for (final Map<String, Object?> json in kOwnExploreJson)
    ExploreSection.fromJson(json),
]);
