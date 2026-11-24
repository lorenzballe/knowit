/// Challenges (the `quick-games` block, by the name the document and the
/// numbers have always known it): Explore's games as tiles, four to a page,
/// two by two — Sixty seconds, Spot the false one, True or false and Which
/// is bigger first, then the games of bets that are a game on their own —
/// with the pages side by side, a swipe from one to the next, and dots that
/// say how many there are (lib/widgets/explore/challenges.dart).
///
/// The games were shelves far down the page, each as tall as a screen, and
/// a reader who wanted a minute's play had to know where to scroll. A tile
/// says what there is to play in a glance. Each tile is its game's colour
/// and picture; Sixty seconds says the reader's record on its tile, the
/// most right in one round, kept for good (`AppState.sixtyBest`), where the
/// round itself lasts only the day.
///
/// Sixty seconds is played on a screen of its own: its tile grows into the
/// whole screen (lib/widgets/explore/sixty_game.dart). Every other game
/// opens on a page of its own, drawn by its own block for the same host
/// ([ExploreHost.openSection]). Either way it is the game's own reckoning
/// that is played — the day's round, the day's bets, the record — kept and
/// counted as it always was, under the section's id and the game's
/// (`quick-games-sixty`).
///
/// Of the games of bets (docs/explore/bets.md), these are here because each
/// is a whole game on a page of its own: Closer, closer; Orders of
/// magnitude; Bet a range; Place your bet; Your number. Not here: the slip
/// and Bet a friend, which play nothing; Today's three, which opens Explore
/// and whose three cards and crowd belong to its own section; and the bet
/// of the day, which is Today's three again with one card.
///
/// A game with nothing to play today has no tile; with none, there is no
/// section.
library;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../widgets/explore/challenge_art.dart';
import '../../../widgets/explore/challenges.dart';
import '../../../widgets/explore/sixty_game.dart';
import '../../explore_block.dart';
import '../bets/bigger.dart';
import '../bets/closer.dart';
import '../bets/magnitude.dart';
import '../bets/number.dart';
import '../bets/range.dart';
import '../bets/stake.dart';
import 'layout.dart';
import 'shelf_blocks.dart';
import 'shelves.dart';

/// One game a tile can open: what it is called, how it looks, and the
/// section that draws it.
@immutable
class QuickGame {
  const QuickGame({
    required this.key,
    required this.block,
    required this.colour,
    required this.art,
    this.extra = const {},
  });

  /// The game's name in a section's `games`.
  final String key;

  /// The block that draws the game.
  final ExploreBlock block;

  /// The tile's ground, from the subjects' wheel: one the drawn cards' ink
  /// reads on.
  final Color colour;

  /// The tile's picture.
  final ChallengeArt art;

  /// What the game's section says beyond its id and block.
  final Map<String, Object?> extra;

  /// The game's own name, in the reader's language.
  String title(AppLocalizations l) => switch (key) {
    'sixty' => l.sixtyTitle,
    'spot-false' => l.spotTitle,
    'true-false' => l.themeTrueOrFalse,
    'bets-closer' => l.betsCloserTitle,
    'bets-magnitude' => l.betsMagnitudeTitle,
    'bets-range' => l.betsRangeTitle,
    'bets-stake' => l.betsStakeTitle,
    'bets-number' => l.betsNumberTitle,
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

/// The games, in the order a section that names none shows them: the four
/// the first page always had, then the games of bets. True or false is
/// played without the game of spotting the false one under it, which has a
/// tile of its own; a game of bets on its page has its tiles one under
/// another (`size` `l`), the width of the page.
const List<QuickGame> kQuickGames = [
  QuickGame(
    key: 'sixty',
    block: SixtyBlock(),
    colour: Color(0xFFFFE600),
    art: ChallengeArt.sixty,
  ),
  QuickGame(
    key: 'spot-false',
    block: SpotFalseBlock(),
    colour: Color(0xFFFF3D7F),
    art: ChallengeArt.spot,
  ),
  QuickGame(
    key: 'true-false',
    block: TrueFalseBlock(),
    colour: Color(0xFF00E5A0),
    art: ChallengeArt.trueFalse,
    extra: {'spot': false},
  ),
  QuickGame(
    key: 'bets-bigger',
    block: BiggerBlock(),
    colour: Color(0xFF4C6FFF),
    art: ChallengeArt.bigger,
  ),
  QuickGame(
    key: 'bets-closer',
    block: CloserBlock(),
    colour: Color(0xFFFF7A1A),
    art: ChallengeArt.closer,
    extra: {'size': 'l'},
  ),
  QuickGame(
    key: 'bets-magnitude',
    block: MagnitudeBlock(),
    colour: Color(0xFF9B5CFF),
    art: ChallengeArt.magnitude,
    extra: {'size': 'l'},
  ),
  QuickGame(
    key: 'bets-range',
    block: RangeBlock(),
    colour: Color(0xFF00D9D9),
    art: ChallengeArt.range,
    extra: {'size': 'l'},
  ),
  QuickGame(
    key: 'bets-stake',
    block: StakeBlock(),
    colour: Color(0xFFA6FF00),
    art: ChallengeArt.stake,
    extra: {'size': 'l'},
  ),
  QuickGame(
    key: 'bets-number',
    block: NumberBlock(),
    colour: Color(0xFFE040FB),
    art: ChallengeArt.number,
    extra: {'size': 'l'},
  ),
];

/// The games [section] names in `games`, in its order, or all of them.
List<QuickGame> gamesOf(ExploreSection section) {
  final Object? named = section.json['games'];
  if (named is! List) return kQuickGames;
  return [
    for (final Object? key in named.toSet())
      ...kQuickGames.where((g) => g.key == key),
  ];
}

/// What a game's tile flies from, and its screen back to.
Object challengeHeroOf(ExploreSection inner) => 'challenge-${inner.id}';

/// The block: see the library's own words.
class QuickGamesBlock extends ExploreBlock with SectionLayout {
  const QuickGamesBlock();

  @override
  String get name => 'quick-games';

  /// Games for every subject: not on a subject's page.
  @override
  bool get onSubjectPages => false;

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
    ChallengeLook lookOf(QuickGame game) => ChallengeLook(
      title: game.title(l),
      colour: game.colour,
      art: game.art,
      note: game.key == 'sixty'
          ? (best > 0 ? l.exploreSixtyRecord(best, 8) : l.exploreSixtyFirst)
          : null,
    );
    final List<ChallengeTileSpec> tiles = [];
    for (int i = 0; i < games.length; i++) {
      final (QuickGame game, ExploreSection inner) = games[i];
      final ChallengeLook look = lookOf(game);
      if (game.key != 'sixty') {
        tiles.add(
          ChallengeTileSpec(
            id: game.key,
            look: look,
            onTap: () => host.openSection(inner),
          ),
        );
        continue;
      }
      // Sixty seconds, on the whole screen; the challenge after it offered
      // when the round is over.
      final (QuickGame, ExploreSection)? next = games.length > 1
          ? games[(i + 1) % games.length]
          : null;
      tiles.add(
        ChallengeTileSpec(
          id: game.key,
          look: look,
          heroTag: challengeHeroOf(inner),
          onTap: () => _playSixty(
            context,
            host,
            inner,
            look,
            next: next == null ? null : (lookOf(next.$1), next.$2),
          ),
        ),
      );
    }

    return SectionFrame(
      title: section.title(host.language) ?? l.challengesTitle,
      line: section.subtitle(host.language) ?? l.challengesLine,
      child: ChallengePager(id: section.id, tiles: tiles),
    );
  }

  /// Opens Sixty seconds on its own screen, out of its tile, playing the
  /// day's round exactly as its shelf does: the same eight claims, the
  /// record kept by the app, a card opened as from any shelf.
  static void _playSixty(
    BuildContext context,
    ExploreHost host,
    ExploreSection inner,
    ChallengeLook look, {
    (ChallengeLook, ExploreSection)? next,
  }) {
    final List<Pill> pills = ExploreShelves.of(host).mix.sixty;
    if (pills.length != 8) {
      host.openSection(inner);
      return;
    }
    host.openScreen(
      inner,
      sixtyGameRoute(
        SixtyGame(
          look: look,
          heroTag: challengeHeroOf(inner),
          pills: pills,
          best: () => host.app.sixtyBest,
          onFinished: host.app.noteSixtyRound,
          onOpen: (shelf, pill) => host.open(inner, shelf, pill),
          onShown: (pill) => host.seen(inner, pill),
          next: next?.$1,
          onNext: next == null ? null : () => host.openSection(next.$2),
        ),
        calm: MediaQuery.disableAnimationsOf(context),
      ),
    );
  }
}
