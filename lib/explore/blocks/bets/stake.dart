/// Place your bet (139b): three amounts, a stake from the day's hundred
/// points on one of them, and the stake doubled or lost.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme.dart';
import '../../../widgets/explore/parts.dart' show upper;
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

  /// How wide the stakes and the bet are on one line: the label, every
  /// stake, and the bet button at its widest — or the room a line saying
  /// why there is no bet yet needs at the least.
  double _stakeRowWidth(BuildContext context, String label) {
    final l = context.l10n;
    final TextStyle chip = AppText.body(size: 12, weight: FontWeight.w700);
    double w =
        betTextWidth(
          context,
          upper(context, label),
          AppText.label(size: 9, weight: FontWeight.w700, spacing: 1.2),
        ) +
        9;
    for (final int s in stakes) {
      w += betTextWidth(context, '$s', chip) + 24 + 6;
    }
    final double bet =
        betTextWidth(
          context,
          l.betsBetN(stakes.last),
          AppText.body(size: 12.5, weight: FontWeight.w700),
        ) +
        36;
    return w + 8 + math.max(bet, MediaQuery.textScalerOf(context).scale(64));
  }

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

    Widget option(int j) {
      final bool right = j == answer.correct;
      final bool on = laid ? right : j == picked;
      final bool lost = laid && j == picked && !right;
      return BetChip(
        key: ValueKey('bets-stake-${pill.id}-o$j'),
        label: options[j],
        ink: ink,
        on: on,
        ring: lost,
        dim: laid && !on && !lost,
        height: 42,
        radius: 12,
        size: 12.5,
        weight: FontWeight.w600,
        onTap: open
            ? () {
                if (j == picked) return;
                BetFeel.tick();
                keep(option: j);
              }
            : null,
      );
    }

    final Widget stakeLabel = BetKicker(l.betsStakeLabel, color: ink.sub);
    final List<Widget> stakeChips = [
      for (int j = 0; j < stakes.length; j++)
        BetChip(
          key: ValueKey('bets-stake-${pill.id}-k$j'),
          label: '${stakes[j]}',
          ink: ink,
          on: j == k,
          dim: stakes[j] > wallet && j != k,
          height: 30,
          radius: 99,
          size: 12,
          padding: 10,
          onTap: open && stakes[j] <= wallet && j != k
              ? () {
                  BetFeel.tick();
                  keep(stakeAt: j);
                }
              : null,
        ),
    ];
    final Widget betOrWhy = canBet
        ? BetButton(
            key: ValueKey('bets-stake-bet-${pill.id}'),
            label: l.betsBetN(stake),
            ink: ink,
            height: 34,
            onTap: bet0,
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
          );
    // The stakes and the bet on one line where they fit, the bet under the
    // stakes where they do not: at a large text size, or in a narrow tile.
    final bool oneLine = _stakeRowWidth(context, l.betsStakeLabel) <= inner;
    Widget stakeRow() => oneLine
        ? Row(
            children: [
              stakeLabel,
              const SizedBox(width: 9),
              for (int j = 0; j < stakeChips.length; j++) ...[
                if (j > 0) const SizedBox(width: 6),
                stakeChips[j],
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: betOrWhy),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [stakeLabel, ...stakeChips],
              ),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: betOrWhy),
            ],
          );

    Widget settled() {
      final bool w = bet?.right ?? false;
      final int? s = bet?.confidence;
      final String verdict = w ? l.betsWin(stake) : l.betsLose(stake);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BetVerdict(
            s == null ? verdict : '$verdict ${l.betsYouWereSure(s)}',
            key: ValueKey('bets-stake-said-${pill.id}'),
            ink: ink,
          ),
          BetWhy(pill, ink: ink),
        ],
      );
    }

    Widget sureStep() => SureStep(
      key: ValueKey('bets-stake-sure-${pill.id}'),
      pill: pill,
      ink: ink,
      width: inner,
      onPick: (s) => lay(s),
    );

    Widget game(Widget foot) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BetChips(
          labels: options,
          width: inner,
          style: AppText.body(size: 12.5, weight: FontWeight.w600),
          builder: option,
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
      game: game(foot),
    );
  }
}
