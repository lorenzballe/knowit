/// The bet of the day (139e): one share, the same card for everyone given
/// the same shelf, set on a track and locked in; then how far off it was.
///
/// The canvas shows what everyone else guessed once the reader locks in.
/// Those figures were made up for the prototype, and the phone has no real
/// ones: the counts it reads (lib/sync/tally.dart) are of cards held on to,
/// not of what anybody answered, and how each card is answered is counted
/// on the server for the tools that check cards, where none of it reaches
/// a shelf. So the crowd is left out, and nothing here says what other
/// readers did (docs/explore/bets.md).
library;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import 'answers.dart';
import 'bet_host.dart';
import 'bets_day.dart';
import 'block.dart';
import 'deal.dart';
import 'parts.dart';

/// The block: the bet of the day, and a few more shares to lock in under
/// it. `s` lays them in a row, `m` one under another as the canvas does,
/// `l` the bet of the day alone, large.
class DayBlock extends BetBlock {
  const DayBlock();

  @override
  String get name => 'bets-day';

  @override
  int get defaultLimit => 3;

  /// A share the card takes as a number: the guess locked in is the card's
  /// answer.
  @override
  bool fits(BetAnswer a) => a.share && !a.isPick;

  @override
  String title(AppLocalizations l, BetSection shelf) => l.betsDayTitle;

  @override
  String line(AppLocalizations l, BetSection shelf) => l.betsDayLine;

  @override
  BetTileSize sizeOf(BetSection shelf) =>
      switch (shelf.size(sizes, defaultSize)) {
        's' => BetTileSize.m,
        _ => BetTileSize.l,
      };

  /// The bet of the day first, the same for everyone: dealt by the day
  /// alone, whatever the reader has read. Then the others, from what the
  /// reader has not.
  @override
  List<BetAnswer> deal(ExploreHost host, BetSection shelf) {
    final List<BetAnswer> first = dealBets(
      host,
      shelf,
      fits: fits,
      count: 1,
      salt: 'bets-day',
      fresh: false,
    );
    final bool alone = shelf.size(sizes, defaultSize) == 'l';
    final int more = alone ? 0 : shelf.limit(defaultLimit) - 1;
    if (first.isEmpty || more <= 0) return first;
    final String day = first.first.pill.id;
    return [
      ...first,
      ...dealBets(
        host,
        shelf,
        fits: (a) => fits(a) && a.pill.id != day,
        count: more,
        salt: 'bets-day-more',
      ),
    ];
  }

  @override
  bool canShow(ExploreHost host, BetSection shelf) {
    for (final p in host.cardsFor(shelf.section, limit: kBetPool)) {
      final BetAnswer? a = answerOf(p);
      if (a != null && fits(a)) return true;
    }
    return false;
  }

  @override
  Widget body(
    BuildContext context,
    ExploreHost host,
    BetSection shelf,
    List<BetAnswer> cards,
  ) {
    final BetTileSize size = sizeOf(shelf);
    final bool alone = shelf.size(sizes, defaultSize) == 'l';
    return BetTiles(
      size: size,
      count: cards.length,
      onSeen: (i) => host.seen(shelf.section, cards[i].pill),
      builder: (context, i) => DayTile(
        key: ValueKey('bets-day-${cards[i].pill.id}'),
        host: host,
        shelf: shelf,
        answer: cards[i],
        cards: cards,
        size: size,
        first: i == 0,
        questionMax: alone ? 24 : (i == 0 ? 19.5 : 18),
      ),
    );
  }
}

/// One share to lock in.
class DayTile extends StatelessWidget {
  const DayTile({
    super.key,
    required this.host,
    required this.shelf,
    required this.answer,
    required this.cards,
    required this.size,
    required this.first,
    required this.questionMax,
  });

  final ExploreHost host;
  final BetSection shelf;
  final BetAnswer answer;
  final List<BetAnswer> cards;
  final BetTileSize size;

  /// Whether it is the bet of the day itself, under its tag.
  final bool first;
  final double questionMax;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pill = answer.pill;
    final BetsDay day = BetsDay.instance;
    final BetInk ink = BetInk.of(context, pill, shelf.tone());
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final String key = BetsDay.draftKey('day', pill.id);
    final Bet? bet = day.betOn('day', pill.id);
    final bool elsewhere = bet == null && host.app.answerFor(pill.id) != null;
    final Map draft = day.draft(key) is Map ? day.draft(key) as Map : const {};
    final double guess = bet != null
        ? double.tryParse(bet.said) ?? 50
        : (draft['g'] as num?)?.toDouble() ?? 50;
    final bool laid = bet != null;
    final bool pending = !laid && !elsewhere && draft['p'] == true;
    final bool open = !laid && !elsewhere && !pending;
    final double inner = size.inner(MediaQuery.sizeOf(context).width);
    final String said = n.percent(answer.value);

    Future<void> lay(int? sure) async {
      final String response = plainResponse(guess);
      await layBet(
        host,
        shelf.section,
        Bet(
          kind: 'day',
          section: shelf.id,
          pill: pill.id,
          said: response,
          right: answer.accepts(response),
          confidence: sure,
          facts: {
            'off': (guess - answer.value).abs(),
            if (first) 'of_the_day': true,
          },
          at: DateTime.now().millisecondsSinceEpoch,
        ),
        pill: pill,
        response: response,
      );
    }

    void lockIn() {
      BetFeel.lay();
      if (shelf.asksSure) {
        day.keepDraft(key, {'g': guess, 'p': true});
      } else {
        lay(null);
      }
    }

    Widget settled({bool ghost = false, double? at, int? sure}) {
      final double you = at ?? guess;
      final int off = (you - answer.value).abs().round();
      final int? s = sure ?? bet?.confidence;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: !ghost,
            child: Text(
              '${l.betsItIs(said)} ${l.betsPointsOff(off)}',
              key: ghost ? null : ValueKey('bets-day-said-${pill.id}'),
              style: AppText.display(
                size: 17,
                weight: FontWeight.w600,
                height: 1.25,
                spacing: -0.3,
                color: ink.ink,
              ),
            ),
          ),
          if (s != null) ...[
            const SizedBox(height: 6),
            Text(
              l.betsYouWereSure(s),
              style: AppText.body(
                size: 13,
                weight: FontWeight.w600,
                height: 1.3,
                color: ink.ink,
              ),
            ),
          ],
          BetWhy(pill, ink: ink),
        ],
      );
    }

    final Widget foot = laid
        ? settled()
        : pending
        ? SureStep(
            key: ValueKey('bets-day-sure-${pill.id}'),
            pill: pill,
            ink: ink,
            width: inner,
            onPick: lay,
          )
        : elsewhere
        ? Text(
            l.betsAnsweredAlready,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w600,
              color: ink.sub,
            ),
          )
        : Align(
            alignment: Alignment.centerLeft,
            child: BetButton(
              key: ValueKey('bets-day-lock-${pill.id}'),
              label: l.betsLockIn,
              ink: ink,
              onTap: lockIn,
            ),
          );

    Widget game(Widget foot, {bool ghost = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          n.percent(guess),
          style: AppText.display(
            size: 34,
            weight: FontWeight.w600,
            height: 1,
            spacing: -1,
            color: ink.ink,
          ),
        ),
        const SizedBox(height: 14),
        BetTrack(
          key: ghost ? null : ValueKey('bets-day-track-${pill.id}'),
          ink: ink,
          value: guess,
          filled: true,
          label: l.betsYourGuess,
          say: n.percent,
          answer: laid ? (answer.value, answer.value) : null,
          onChanged: open && !ghost
              ? (v) => day.keepDraft(key, {'g': v})
              : null,
        ),
        const SizedBox(height: 14),
        foot,
      ],
    );

    final Widget? tag = first
        ? Container(
            constraints: const BoxConstraints(minHeight: 24),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ink.ink,
              borderRadius: BorderRadius.circular(99),
            ),
            child: BetKicker(
              shelf.flag('same', false) ? l.betsDayTagSame : l.betsDayTag,
              color: ink.onInk,
            ),
          )
        : null;
    return BetFrame(
      pill: pill,
      ink: ink,
      size: size,
      questionMax: questionMax,
      read: host.isRead(pill),
      top: shelf.flag('tag', true) ? tag : null,
      onOpen: laid || elsewhere
          ? () =>
                host.open(shelf.section, [for (final c in cards) c.pill], pill)
          : null,
      game: BetRoom(
        keep: size.inRow,
        ghosts: [
          if (!laid)
            game(
              settled(ghost: true, at: answer.value < 50 ? 100 : 0, sure: 90),
              ghost: true,
            ),
        ],
        child: game(foot),
      ),
    );
  }
}
