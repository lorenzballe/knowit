/// Quick games: four of Explore's games as four colourful tiles, two by
/// two — Sixty seconds, Spot the false one, True or false, and Which is
/// bigger — each opening its game on a page of its own.
///
/// The games were shelves far down the page, each as tall as a screen, and
/// a reader who wanted a minute's play had to know where to scroll. A tile
/// says what there is to play in a glance, and the game it opens is the
/// same block it always was, drawn by the engine for the same host
/// ([ExploreHost.openSection]), so a round played there is the round of the
/// day, kept and counted as it always was. Sixty seconds says the reader's
/// record on its tile: the most right in one round, kept for good
/// (`AppState.sixtyBest`), where the round itself lasts only the day.
///
/// A game with nothing to play today — not eight claims for the round, no
/// pair of figures to compare — has no tile; with none, there is no
/// section.
library;

import 'package:flutter/material.dart';

import '../../../data/topics.dart' show inkOn;
import '../../../l10n/l10n.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import '../bets/bigger.dart';
import 'layout.dart';
import 'shelf_blocks.dart';

/// One game a tile can open: what it is called, how it looks, and the
/// section that draws it.
@immutable
class QuickGame {
  const QuickGame({
    required this.key,
    required this.block,
    required this.colour,
    required this.icon,
    this.extra = const {},
  });

  /// The game's name in a section's `games`.
  final String key;

  /// The block that draws the game.
  final ExploreBlock block;

  /// The tile's ground, from the subjects' wheel.
  final Color colour;
  final IconData icon;

  /// What the game's section says beyond its id and block.
  final Map<String, Object?> extra;

  /// The game's own name, in the reader's language.
  String title(AppLocalizations l) => switch (key) {
    'sixty' => l.sixtyTitle,
    'spot-false' => l.spotTitle,
    'true-false' => l.themeTrueOrFalse,
    _ => l.betsBiggerTitle,
  };

  /// The section the game is drawn from, under [parent]'s id: what its
  /// cards are noted under, so the numbers say they were played from here.
  ExploreSection sectionUnder(ExploreSection parent) => ExploreSection(
    id: '${parent.id}-$key',
    block: block.name,
    json: {'id': '${parent.id}-$key', 'block': block.name, ...extra},
  );
}

/// The games, in the order a section that names none shows them. True or
/// false is played without the game of spotting the false one under it,
/// which has a tile of its own.
const List<QuickGame> kQuickGames = [
  QuickGame(
    key: 'sixty',
    block: SixtyBlock(),
    colour: Color(0xFFFFE600),
    icon: Icons.timer_outlined,
  ),
  QuickGame(
    key: 'spot-false',
    block: SpotFalseBlock(),
    colour: Color(0xFFFF3D7F),
    icon: Icons.manage_search_rounded,
  ),
  QuickGame(
    key: 'true-false',
    block: TrueFalseBlock(),
    colour: Color(0xFF00E5A0),
    icon: Icons.rule_rounded,
    extra: {'spot': false},
  ),
  QuickGame(
    key: 'bets-bigger',
    block: BiggerBlock(),
    colour: Color(0xFF4C6FFF),
    icon: Icons.swap_vert_rounded,
  ),
];

/// The games [section] names in `games`, in its order, or all four.
List<QuickGame> gamesOf(ExploreSection section) {
  final Object? named = section.json['games'];
  if (named is! List) return kQuickGames;
  return [
    for (final Object? key in named.toSet())
      ...kQuickGames.where((g) => g.key == key),
  ];
}

/// The block: see the library's own words.
class QuickGamesBlock extends ExploreBlock with SectionLayout {
  const QuickGamesBlock();

  @override
  String get name => 'quick-games';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    // Whether a game has anything to play is asked of its own block, as the
    // engine asks it of every section: only what it would draw, thrown away.
    final List<(QuickGame, ExploreSection)> games = [
      for (final QuickGame game in gamesOf(section))
        if (game.sectionUnder(section) case final ExploreSection inner
            when game.block.build(context, host, inner) != null)
          (game, inner),
    ];
    if (games.isEmpty) return null;
    final l = context.l10n;
    final int best = host.app.sixtyBest;
    Widget tile((QuickGame, ExploreSection) entry) {
      final (QuickGame game, ExploreSection inner) = entry;
      return GameTile(
        key: ValueKey('quick-game-${game.key}'),
        title: game.title(l),
        colour: game.colour,
        icon: game.icon,
        note: game.key == 'sixty'
            ? (best > 0 ? l.exploreSixtyRecord(best, 8) : l.exploreSixtyFirst)
            : null,
        onTap: () => host.openSection(inner),
      );
    }

    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            for (int i = 0; i < games.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tile(games[i])),
                    const SizedBox(width: 10),
                    Expanded(
                      child: i + 1 < games.length
                          ? tile(games[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One game's tile: its colour, its mark, its name, and a note on top
/// where the game has one to say.
class GameTile extends StatelessWidget {
  const GameTile({
    super.key,
    required this.title,
    required this.colour,
    required this.icon,
    required this.onTap,
    this.note,
  });

  final String title;
  final Color colour;
  final IconData icon;
  final VoidCallback onTap;

  /// A line in a pill at the top right: the record, on Sixty seconds.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final Color ink = inkOn(colour);
    return Semantics(
      button: true,
      label: note == null ? title : '$title, $note',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 116),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colour,
                    Color.alphaBlend(
                      Colors.black.withValues(alpha: 0.16),
                      colour,
                    ),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // The mark again, large and faint, off the corner: the
                  // tile is the game's colour first and its words second.
                  Positioned(
                    right: -18,
                    bottom: -22,
                    child: Icon(
                      icon,
                      size: 96,
                      color: ink.withValues(alpha: 0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 12, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: ink.withValues(alpha: 0.13),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(icon, size: 18, color: ink),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: note == null
                                  ? const SizedBox.shrink()
                                  : Align(
                                      alignment: Alignment.topRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ink.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          note!,
                                          key: const ValueKey('game-note'),
                                          textAlign: TextAlign.end,
                                          style: AppText.body(
                                            size: 10.5,
                                            weight: FontWeight.w700,
                                            height: 1.15,
                                            color: ink,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          style: AppText.display(
                            size: 18,
                            weight: FontWeight.w600,
                            height: 1.08,
                            spacing: -0.3,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
