/// Challenges (the `quick-games` block, by the name the document and the
/// numbers have always known it): Explore's games as tiles, four to a page,
/// two by two — Sixty seconds, Spot the false one, True or false and Which
/// is bigger first; then the games of bets that are a game on their own;
/// then the three games of time — with the pages side by side, a swipe
/// from one to the next, and dots that say how many there are
/// (lib/widgets/explore/challenges.dart).
///
/// The games were shelves far down the page, each as tall as a screen, and
/// a reader who wanted a minute's play had to know where to scroll. A tile
/// says in a glance what each challenge is: the skill it trains, its name,
/// what it asks, its mark in its own tone, and the reader's own figure where
/// there is one — the best of Sixty seconds, the most right in one round,
/// kept for good (`AppState.sixtyBest`), and today's score of a game of
/// time once its round is over.
///
/// Every challenge is taken on a screen of its own: its tile's panel grows
/// into the page (lib/widgets/explore/challenge_screen.dart), and at the
/// end the next challenge is a tap away, opening out of its own tile in
/// turn.
/// It is the game's own reckoning that is played there — the day's round,
/// the day's bets, the record — kept and counted as it always was, under
/// the section's id and the game's (`quick-games-sixty`).
///
/// Of the games of bets (docs/explore/bets.md), these are here because each
/// is a whole game on its own: Closer, closer; Orders of magnitude; Bet a
/// range; Place your bet; Your number. Not here: the slip and Bet a friend,
/// which play nothing; Today's three, which opens Explore and whose three
/// cards and crowd belong to its own section; and the bet of the day,
/// which is Today's three again with one card.
///
/// The games of time — In order, What year?, Before or after? — are new to
/// the challenges and live only here: moments from the cards whose
/// question names the year they happened (lib/data/dated_lines.dart).
///
/// A game with nothing to play today has no tile; with none, there is no
/// section.
library;

import 'package:flutter/material.dart';

import '../../../data/dated_lines.dart';
import '../../../data/explore_mix.dart';
import '../../../data/themed_shelves.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../widgets/explore/challenge_kit.dart';
import '../../../widgets/explore/challenge_marks.dart';
import '../../../widgets/explore/challenge_screen.dart';
import '../../../widgets/explore/challenges.dart';
import '../../../widgets/explore/sixty_game.dart';
import '../../../widgets/explore/spot_game.dart';
import '../../../widgets/explore/time_games.dart';
import '../../../widgets/explore/true_false_game.dart';
import '../../explore_block.dart';
import '../bets/answers.dart';
import '../bets/bet_games.dart';
import '../bets/bets_day.dart';
import '../bets/bigger.dart';
import '../bets/block.dart';
import '../bets/closer.dart';
import '../bets/deal.dart';
import '../bets/magnitude.dart';
import '../bets/number.dart';
import '../bets/range.dart';
import '../bets/stake.dart';
import 'layout.dart';
import 'shelf_blocks.dart';
import 'shelves.dart';

/// Makes a game's screen for [inner], its section under the challenges, or
/// null when it has nothing to play.
typedef ChallengeOf =
    ChallengeGame? Function(
      ExploreHost host,
      ExploreSection inner,
      String title,
    );

/// One game a tile can open: what it is called, how it looks, what draws it
/// on a page of its own, and what plays it on a screen of its own.
@immutable
class QuickGame {
  const QuickGame({
    required this.key,
    required this.tone,
    required this.mark,
    required this.play,
    this.block,
    this.extra = const {},
  });

  /// The game's name in a section's `games`.
  final String key;

  /// The block that draws the game on a page of its own, for the games
  /// that are shelves too; none for a game played only here.
  final ExploreBlock? block;

  /// The challenge's one colour: its old colour on the subjects' wheel
  /// taken down to a deep tone, lifted a little at night.
  final ChallengeTone tone;

  /// Its mark.
  final ChallengeMark mark;

  /// What the game's section says beyond its id and block.
  final Map<String, Object?> extra;

  /// What plays it on its screen.
  final ChallengeOf play;

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
    'in-order' => l.inOrderTitle,
    'what-year' => l.whatYearTitle,
    'before-after' => l.beforeAfterTitle,
    _ => l.betsBiggerTitle,
  };

  /// The skill it trains, in the reader's language.
  String skill(AppLocalizations l) => switch (key) {
    'sixty' => l.sixtySkill,
    'spot-false' => l.spotSkill,
    'true-false' => l.tfSkill,
    'bets-closer' => l.closerSkill,
    'bets-magnitude' => l.magnitudeSkill,
    'bets-range' => l.rangeSkill,
    'bets-stake' => l.stakeSkill,
    'bets-number' => l.numberSkill,
    'in-order' => l.inOrderSkill,
    'what-year' => l.whatYearSkill,
    'before-after' => l.beforeAfterSkill,
    _ => l.biggerSkill,
  };

  /// What it asks, in a quiet line.
  String asks(AppLocalizations l) => switch (key) {
    'sixty' => l.sixtyAsks,
    'spot-false' => l.spotAsks,
    'true-false' => l.tfAsks,
    'bets-closer' => l.closerAsks,
    'bets-magnitude' => l.magnitudeAsks,
    'bets-range' => l.rangeAsks,
    'bets-stake' => l.stakeAsks,
    'bets-number' => l.numberAsks,
    'in-order' => l.inOrderAsks,
    'what-year' => l.whatYearAsks,
    'before-after' => l.beforeAfterAsks,
    _ => l.biggerAsks,
  };

  /// The reader's own figure on its tile: the best of Sixty seconds, once
  /// there is one; today's score of a game of time, once its round is over.
  ChallengeFigure? figure(ExploreHost host, AppLocalizations l) {
    if (key == 'sixty') {
      final int best = host.app.sixtyBest;
      return best > 0 ? (label: l.challengeBest, value: '$best/8') : null;
    }
    final TimeGame? time = _timeOf(key);
    if (time == null) return null;
    final TimeDeal deal = ExploreShelves.of(host).time;
    void none(List<Pill> _, Pill _) {}
    final TimeChallenge played = switch (time) {
      TimeGame.order => InOrderChallenge(deal: deal, onOpen: none, title: ''),
      TimeGame.year => WhatYearChallenge(deal: deal, onOpen: none, title: ''),
      TimeGame.chain => BeforeAfterChallenge(
        deal: deal,
        onOpen: none,
        title: '',
      ),
    };
    final String? today = played.playable && played.over
        ? played.tally
        : null;
    played.dispose();
    return today == null ? null : (label: l.challengeToday, value: today);
  }

  /// The section the game is drawn from, under [parent]'s id: what its
  /// cards are noted under, so the numbers say they were played from here.
  ExploreSection sectionUnder(ExploreSection parent) => ExploreSection(
    id: '${parent.id}-$key',
    block: block?.name ?? key,
    json: {'id': '${parent.id}-$key', 'block': block?.name ?? key, ...extra},
  );

  /// Whether the game has anything to play today: asked of its block as
  /// the engine asks it of every section — only what it would draw, thrown
  /// away — or, for a game of time, of the day's moments.
  bool playable(BuildContext context, ExploreHost host, ExploreSection inner) {
    final ExploreBlock? b = block;
    if (b != null) return b.build(context, host, inner) != null;
    final TimeGame? time = _timeOf(key);
    return time != null &&
        ExploreShelves.of(host).time.round(time, 0).isNotEmpty;
  }
}

TimeGame? _timeOf(String key) => switch (key) {
  'in-order' => TimeGame.order,
  'what-year' => TimeGame.year,
  'before-after' => TimeGame.chain,
  _ => null,
};

/// The games, in the order a section that names none shows them: the four
/// the first page always had, then the games of bets, then the games of
/// time. True or false is played without the game of spotting the false
/// one under it, which has a tile of its own; a game of bets on its page
/// has its tiles one under another (`size` `l`), the width of the page.
const List<QuickGame> kQuickGames = [
  QuickGame(
    key: 'sixty',
    block: SixtyBlock(),
    tone: ChallengeTone(Color(0xFF7A5D12), Color(0xFFD2B064)),
    mark: ChallengeMark.sixty,
    play: _sixty,
  ),
  QuickGame(
    key: 'spot-false',
    block: SpotFalseBlock(),
    tone: ChallengeTone(Color(0xFF8A2846), Color(0xFFE293AB)),
    mark: ChallengeMark.spot,
    play: _spot,
  ),
  QuickGame(
    key: 'true-false',
    block: TrueFalseBlock(),
    tone: ChallengeTone(Color(0xFF1E5C46), Color(0xFF82C4A8)),
    mark: ChallengeMark.trueFalse,
    extra: {'spot': false},
    play: _trueFalse,
  ),
  QuickGame(
    key: 'bets-bigger',
    block: BiggerBlock(),
    tone: ChallengeTone(Color(0xFF2E4590), Color(0xFFA2B1EA)),
    mark: ChallengeMark.bigger,
    play: _bigger,
  ),
  QuickGame(
    key: 'bets-closer',
    block: CloserBlock(),
    tone: ChallengeTone(Color(0xFF8C4018), Color(0xFFE59E74)),
    mark: ChallengeMark.closer,
    extra: {'size': 'l'},
    play: _closer,
  ),
  QuickGame(
    key: 'bets-magnitude',
    block: MagnitudeBlock(),
    tone: ChallengeTone(Color(0xFF54378C), Color(0xFFB9A2E6)),
    mark: ChallengeMark.magnitude,
    extra: {'size': 'l'},
    play: _magnitude,
  ),
  QuickGame(
    key: 'bets-range',
    block: RangeBlock(),
    tone: ChallengeTone(Color(0xFF115A61), Color(0xFF7CC6CC)),
    mark: ChallengeMark.range,
    extra: {'size': 'l'},
    play: _range,
  ),
  QuickGame(
    key: 'bets-stake',
    block: StakeBlock(),
    tone: ChallengeTone(Color(0xFF4F5F17), Color(0xFFB7C979)),
    mark: ChallengeMark.stake,
    extra: {'size': 'l'},
    play: _stake,
  ),
  QuickGame(
    key: 'bets-number',
    block: NumberBlock(),
    tone: ChallengeTone(Color(0xFF762C70), Color(0xFFDB9AD5)),
    mark: ChallengeMark.number,
    extra: {'size': 'l'},
    play: _number,
  ),
  QuickGame(
    key: 'in-order',
    tone: ChallengeTone(Color(0xFF7E4F10), Color(0xFFE2B26E)),
    mark: ChallengeMark.order,
    play: _inOrder,
  ),
  QuickGame(
    key: 'what-year',
    tone: ChallengeTone(Color(0xFF295877), Color(0xFF94C4E3)),
    mark: ChallengeMark.year,
    play: _whatYear,
  ),
  QuickGame(
    key: 'before-after',
    tone: ChallengeTone(Color(0xFF8B3526), Color(0xFFE79F90)),
    mark: ChallengeMark.chain,
    play: _beforeAfter,
  ),
];

// ── What plays each game ─────────────────────────────────────────────────

/// A card opened from a game's screen, as from its shelf.
void Function(List<Pill>, Pill) _opener(
  ExploreHost host,
  ExploreSection inner,
) =>
    (shelf, pill) => host.open(inner, shelf, pill);

ChallengeGame? _sixty(ExploreHost host, ExploreSection inner, String title) {
  final List<Pill> pills = ExploreShelves.of(host).mix.sixty;
  if (pills.length != 8) return null;
  return SixtyChallenge(
    pills: pills,
    best: () => host.app.sixtyBest,
    onFinished: host.app.noteSixtyRound,
    onOpen: _opener(host, inner),
    onShown: (pill) => host.seen(inner, pill),
  );
}

ChallengeGame? _spot(ExploreHost host, ExploreSection inner, String title) {
  final SpotTheFalse? spot = ExploreShelves.of(host).mix.spot;
  if (spot == null) return null;
  return SpotChallenge(
    spot: spot,
    title: title,
    onCommit: spotCommitter(host, spot),
    onOpen: _opener(host, inner),
    onShown: spotShower(host, inner),
  );
}

ChallengeGame? _trueFalse(
  ExploreHost host,
  ExploreSection inner,
  String title,
) {
  final ThemedShelf? t = ExploreShelves.of(host).mix.trueFalse;
  if (t == null || t.pills.isEmpty) return null;
  return TrueFalseChallenge(
    pills: t.pills,
    title: title,
    answerOf: (p) => host.app.answerFor(p.id)?.response,
    onCommit: host.commit,
    onOpen: _opener(host, inner),
    onShown: (pill) => host.seen(inner, pill),
  );
}

/// A game of bets: the cards its block deals today for its section, once
/// the day's bets are read.
ChallengeGame? _bets(
  ExploreHost host,
  ExploreSection inner,
  BetBlock block,
  BetChallenge Function(BetSection shelf, List<BetAnswer> cards) make, {
  int least = 1,
}) {
  if (!BetsDay.instance.loaded) return null;
  final BetSection shelf = BetSection(inner);
  final List<BetAnswer> cards = block.deal(host, shelf);
  if (cards.length < least) return null;
  return make(shelf, cards);
}

ChallengeGame? _bigger(ExploreHost host, ExploreSection inner, String title) =>
    _bets(
      host,
      inner,
      const BiggerBlock(),
      (shelf, cards) => BiggerChallenge(
        host: host,
        shelf: shelf,
        cards: cards,
        title: title,
      ),
      least: 2,
    );

ChallengeGame? _closer(ExploreHost host, ExploreSection inner, String title) =>
    _bets(
      host,
      inner,
      const CloserBlock(),
      (shelf, cards) => CloserChallenge(
        host: host,
        shelf: shelf,
        cards: cards,
        title: title,
      ),
    );

ChallengeGame? _magnitude(
  ExploreHost host,
  ExploreSection inner,
  String title,
) => _bets(
  host,
  inner,
  const MagnitudeBlock(),
  (shelf, cards) => MagnitudeChallenge(
    host: host,
    shelf: shelf,
    cards: cards,
    title: title,
  ),
);

ChallengeGame? _range(ExploreHost host, ExploreSection inner, String title) =>
    _bets(
      host,
      inner,
      const RangeBlock(),
      (shelf, cards) => RangeChallenge(
        host: host,
        shelf: shelf,
        cards: cards,
        title: title,
      ),
    );

ChallengeGame? _stake(ExploreHost host, ExploreSection inner, String title) =>
    _bets(
      host,
      inner,
      const StakeBlock(),
      (shelf, cards) => StakeChallenge(
        host: host,
        shelf: shelf,
        cards: cards,
        title: title,
      ),
    );

ChallengeGame? _number(ExploreHost host, ExploreSection inner, String title) =>
    _bets(
      host,
      inner,
      const NumberBlock(),
      (shelf, cards) => NumberChallenge(
        host: host,
        shelf: shelf,
        cards: cards,
        title: title,
      ),
    );

/// A game of time, on the day's moments.
ChallengeGame? _time(
  ExploreHost host,
  ExploreSection inner,
  TimeGame game,
  TimeChallenge Function(TimeDeal deal) make,
) {
  final TimeDeal deal = ExploreShelves.of(host).time;
  if (deal.round(game, 0).isEmpty) return null;
  final TimeChallenge played = make(deal);
  return played.playable ? played : null;
}

ChallengeGame? _inOrder(ExploreHost host, ExploreSection inner, String title) =>
    _time(
      host,
      inner,
      TimeGame.order,
      (deal) => InOrderChallenge(
        deal: deal,
        title: title,
        onOpen: _opener(host, inner),
        onShown: (pill) => host.seen(inner, pill),
      ),
    );

ChallengeGame? _whatYear(
  ExploreHost host,
  ExploreSection inner,
  String title,
) => _time(
  host,
  inner,
  TimeGame.year,
  (deal) => WhatYearChallenge(
    deal: deal,
    title: title,
    onOpen: _opener(host, inner),
    onShown: (pill) => host.seen(inner, pill),
  ),
);

ChallengeGame? _beforeAfter(
  ExploreHost host,
  ExploreSection inner,
  String title,
) => _time(
  host,
  inner,
  TimeGame.chain,
  (deal) => BeforeAfterChallenge(
    deal: deal,
    title: title,
    onOpen: _opener(host, inner),
    onShown: (pill) => host.seen(inner, pill),
  ),
);

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
    final List<(QuickGame, ExploreSection)> games = [
      for (final QuickGame game in gamesOf(section))
        if (game.sectionUnder(section) case final ExploreSection inner
            when game.playable(context, host, inner))
          (game, inner),
    ];
    if (games.isEmpty) return null;
    final l = context.l10n;
    ChallengeLook lookOf(QuickGame game) => ChallengeLook(
      title: game.title(l),
      skill: game.skill(l),
      line: game.asks(l),
      tone: game.tone,
      mark: game.mark,
      figure: game.figure(host, l),
    );

    // Opens the game at [i] on its screen, out of its tile, the challenge
    // after it offered at the end; a game that cannot be played there
    // after all opens on its page, as before.
    void openAt(int i) {
      if (!context.mounted) return;
      final (QuickGame game, ExploreSection inner) = games[i];
      final ChallengeLook look = lookOf(game);
      final ChallengeGame? played = game.play(host, inner, look.title);
      if (played == null) {
        host.openSection(inner);
        return;
      }
      final int j = (i + 1) % games.length;
      final bool more = games.length > 1;
      final bool calm = MediaQuery.disableAnimationsOf(context);
      host.openScreen(
        inner,
        challengeRoute(
          ChallengeScreen(
            game: played,
            look: look,
            heroTag: challengeHeroOf(inner),
            next: more ? lookOf(games[j].$1) : null,
            onNext: more
                ? () {
                    // Back into this tile, the pager turned to the next
                    // one's page under the screen, and out of the next.
                    Navigator.of(context).pop();
                    ChallengePager.reveal(section.id, games[j].$1.key);
                    Future<void>.delayed(
                      calm ? Duration.zero : const Duration(milliseconds: 320),
                      () => openAt(j),
                    );
                  }
                : null,
          ),
          calm: calm,
        ),
      );
    }

    return SectionFrame(
      title: section.title(host.language) ?? l.challengesTitle,
      line: section.subtitle(host.language) ?? l.challengesLine,
      child: ChallengePager(
        id: section.id,
        tiles: [
          for (int i = 0; i < games.length; i++)
            ChallengeTileSpec(
              id: games[i].$1.key,
              look: lookOf(games[i].$1),
              heroTag: challengeHeroOf(games[i].$2),
              onTap: () => openAt(i),
            ),
        ],
      ),
    );
  }
}
