/// Place your bet (139b): three amounts, a stake from the day's hundred
/// points on one of them, and the stake doubled or lost.
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

/// The canvas's stakes.
const List<int> kStakes = [10, 20, 30];

/// The block: a row of picks to stake points on, the points left beside
/// the shelf's name.
class StakeBlock extends BetBlock {
  const StakeBlock();

  @override
  String get name => 'bets-stake';

  @override
  int get defaultLimit => 4;

  /// A pick whose options are all amounts: the option staked on is the
  /// card's answer.
  @override
  bool fits(BetAnswer a) => a.isPick;

  @override
  String title(AppLocalizations l, BetSection shelf) => l.betsStakeTitle;

  @override
  String line(AppLocalizations l, BetSection shelf) =>
      l.betsStakeLine(BetsDay.dailyPoints);

  @override
  Widget? trailing(BetSection shelf) =>
      shelf.flag('wallet', true) ? const BetWallet() : null;

  /// The stakes [shelf] offers: `stakes`, one to four rising from 1 to 100,
  /// or the canvas's.
  static List<int> stakesOf(BetSection shelf) {
    final List<int> said = shelf.rising('stakes', kStakes);
    if (said.length > 4 || said.last > 100) return kStakes;
    return said;
  }

  @override
  Widget body(
    BuildContext context,
    ExploreHost host,
    BetSection shelf,
    List<BetAnswer> cards,
  ) {
    final BetTileSize size = sizeOf(shelf);
    return BetTiles(
      size: size,
      count: cards.length,
      onSeen: (i) => host.seen(shelf.section, cards[i].pill),
      builder: (context, i) => StakeTile(
        key: ValueKey('bets-stake-${cards[i].pill.id}'),
        host: host,
        shelf: shelf,
        answer: cards[i],
        cards: cards,
        size: size,
        stakes: stakesOf(shelf),
      ),
    );
  }
}

/// One pick to stake on.
class StakeTile extends StatelessWidget {
  const StakeTile({
    super.key,
    required this.host,
    required this.shelf,
    required this.answer,
    required this.cards,
    required this.size,
    required this.stakes,
  });

  final ExploreHost host;
  final BetSection shelf;
  final BetAnswer answer;
  final List<BetAnswer> cards;
  final BetTileSize size;
  final List<int> stakes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pill = answer.pill;
    final BetsDay day = BetsDay.instance;
    final BetInk ink = BetInk.of(context, pill, shelf.tone());
    final String key = BetsDay.draftKey('stake', pill.id);
    final Bet? bet = day.betOn('stake', pill.id);
    final bool elsewhere = bet == null && host.app.answerFor(pill.id) != null;
    final Map draft = day.draft(key) is Map ? day.draft(key) as Map : const {};
    final int? picked = bet != null
        ? int.tryParse(bet.said)
        : (draft['o'] as num?)?.toInt();
    final int k = bet != null
        ? stakes.indexOf((bet.facts['stake'] as num?)?.toInt() ?? stakes.first)
        : ((draft['k'] as num?)?.toInt() ?? 0).clamp(0, stakes.length - 1);
    final int stake = stakes[k.clamp(0, stakes.length - 1)];
    final bool laid = bet != null;
    final bool pending = !laid && !elsewhere && draft['p'] == true;
    final bool open = !laid && !elsewhere && !pending;
    final int wallet = day.points;
    final bool canBet = open && picked != null && stake <= wallet;
    final List<String> options = answer.options;
    final double inner = size.inner(MediaQuery.sizeOf(context).width);

    void keep({int? option, int? stakeAt, bool pend = false}) => day.keepDraft(
      key,
      {'o': option ?? picked, 'k': stakeAt ?? k, if (pend) 'p': true},
    );

    Future<void> lay(int? sure) async {
      final int o = picked!;
      final bool right = answer.accepts('$o');
      await layBet(
        host,
        shelf.section,
        Bet(
          kind: 'stake',
          section: shelf.id,
          pill: pill.id,
          said: '$o',
          right: right,
          points: right ? stake : -stake,
          confidence: sure,
          facts: {'stake': stake},
          at: DateTime.now().millisecondsSinceEpoch,
        ),
        pill: pill,
        response: '$o',
      );
    }

    void bet0() {
      BetFeel.lay();
      if (shelf.asksSure) {
        keep(pend: true);
      } else {
        lay(null);
      }
    }

    Widget option(int j, {bool ghost = false}) {
      final bool right = j == answer.correct;
      final bool on = laid ? right : j == picked;
      final bool lost = laid && j == picked && !right;
      return BetChip(
        key: ghost ? null : ValueKey('bets-stake-${pill.id}-o$j'),
        label: options[j],
        ink: ink,
        on: on,
        ring: lost,
        dim: laid && !on && !lost,
        height: 42,
        radius: 12,
        size: 12.5,
        weight: FontWeight.w600,
        onTap: open && !ghost
            ? () {
                if (j == picked) return;
                BetFeel.tick();
                keep(option: j);
              }
            : null,
      );
    }

    Widget stakeRow({bool ghost = false}) => Row(
      children: [
        BetKicker(l.betsStakeLabel, color: ink.sub),
        const SizedBox(width: 9),
        for (int j = 0; j < stakes.length; j++) ...[
          if (j > 0) const SizedBox(width: 6),
          BetChip(
            key: ghost ? null : ValueKey('bets-stake-${pill.id}-k$j'),
            label: '${stakes[j]}',
            ink: ink,
            on: j == k,
            dim: stakes[j] > wallet && j != k,
            height: 30,
            radius: 99,
            size: 12,
            padding: 10,
            onTap: open && !ghost && stakes[j] <= wallet && j != k
                ? () {
                    BetFeel.tick();
                    keep(stakeAt: j);
                  }
                : null,
          ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: canBet
              ? Align(
                  alignment: Alignment.centerRight,
                  child: BetButton(
                    key: ghost ? null : ValueKey('bets-stake-bet-${pill.id}'),
                    label: l.betsBetN(stake),
                    ink: ink,
                    height: 34,
                    onTap: ghost ? null : bet0,
                  ),
                )
              : Text(
                  elsewhere
                      ? l.betsAnsweredAlready
                      : picked == null
                      ? l.betsPickFirst
                      : l.betsNotEnough,
                  textAlign: TextAlign.right,
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w600,
                    height: 1.2,
                    color: ink.sub,
                  ),
                ),
        ),
      ],
    );

    Widget settled({bool ghost = false, bool? won, int? sure}) {
      final bool w = won ?? (bet?.right ?? false);
      final int? s = sure ?? bet?.confidence;
      final String verdict = w ? l.betsWin(stake) : l.betsLose(stake);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BetVerdict(
            s == null ? verdict : '$verdict ${l.betsYouWereSure(s)}',
            key: ghost ? null : ValueKey('bets-stake-said-${pill.id}'),
            ink: ink,
          ),
          BetWhy(pill, ink: ink),
        ],
      );
    }

    Widget sureStep({bool ghost = false}) => SureStep(
      key: ghost ? null : ValueKey('bets-stake-sure-${pill.id}'),
      pill: pill,
      ink: ink,
      width: inner,
      onPick: ghost ? (_) {} : (s) => lay(s),
    );

    Widget game(Widget foot, {bool ghost = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int j = 0; j < options.length; j++) ...[
              if (j > 0) const SizedBox(width: 6),
              Expanded(child: option(j, ghost: ghost)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        foot,
      ],
    );

    final Widget foot = laid
        ? settled()
        : pending
        ? sureStep()
        : stakeRow();
    return BetFrame(
      pill: pill,
      ink: ink,
      size: size,
      read: host.isRead(pill),
      onOpen: laid || elsewhere
          ? () =>
                host.open(shelf.section, [for (final c in cards) c.pill], pill)
          : null,
      game: BetRoom(
        keep: size.inRow,
        ghosts: [
          if (!laid) ...[
            game(settled(ghost: true, won: false, sure: 90), ghost: true),
            game(settled(ghost: true, won: true, sure: 90), ghost: true),
            if (shelf.asksSure) game(sureStep(ghost: true), ghost: true),
          ],
        ],
        child: game(foot),
      ),
    );
  }
}
