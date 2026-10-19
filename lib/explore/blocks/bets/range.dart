/// Bet a range (139a): a share set on a track, a range either side of it,
/// and the narrower the range the more it pays, if the answer is in it.
library;

import 'dart:math' as math;

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
import 'slip.dart';

/// The block: a row of shares to bet a range on, the day's slip under it.
class RangeBlock extends BetBlock {
  const RangeBlock();

  @override
  String get name => 'bets-range';

  @override
  int get defaultLimit => 4;

  /// A share the card takes as a number: the guess at the range's middle
  /// is the card's answer.
  @override
  bool fits(BetAnswer a) => a.share && !a.isPick;

  @override
  String title(AppLocalizations l, BetSection shelf) => l.betsRangeTitle;

  @override
  String line(AppLocalizations l, BetSection shelf) => l.betsRangeLine;

  @override
  Widget? trailing(BetSection shelf) =>
      shelf.flag('wallet', false) ? const BetWallet() : null;

  @override
  Widget body(
    BuildContext context,
    ExploreHost host,
    BetSection shelf,
    List<BetAnswer> cards,
  ) {
    final BetTileSize size = sizeOf(shelf);
    final List<RangeWidth> widths = rangeWidthsOf(shelf);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BetTiles(
          size: size,
          count: cards.length,
          onSeen: (i) => host.seen(shelf.section, cards[i].pill),
          builder: (context, i) => RangeTile(
            key: ValueKey('bets-range-${cards[i].pill.id}'),
            host: host,
            shelf: shelf,
            answer: cards[i],
            cards: cards,
            size: size,
            widths: widths,
          ),
        ),
        if (shelf.flag('slip', true)) ...[
          const SizedBox(height: 28),
          BetSlip(
            onlySection: shelf.id,
            kinds: const {'range'},
            widths: widths,
          ),
        ],
      ],
    );
  }
}

/// One share to bet a range on.
class RangeTile extends StatelessWidget {
  const RangeTile({
    super.key,
    required this.host,
    required this.shelf,
    required this.answer,
    required this.cards,
    required this.size,
    required this.widths,
  });

  final ExploreHost host;
  final BetSection shelf;
  final BetAnswer answer;

  /// The row it stands in: what the viewer pages through once it is open.
  final List<BetAnswer> cards;
  final BetTileSize size;
  final List<RangeWidth> widths;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pill = answer.pill;
    final BetsDay day = BetsDay.instance;
    final BetInk ink = BetInk.of(context, pill, shelf.tone());
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final String key = BetsDay.draftKey('range', pill.id);
    final Bet? bet = day.betOn('range', pill.id);
    final bool elsewhere = bet == null && host.app.answerFor(pill.id) != null;
    final Map draft = day.draft(key) is Map ? day.draft(key) as Map : const {};
    final int middle = (widths.length - 1) ~/ 2;
    final double guess = bet != null
        ? (double.tryParse(bet.said) ?? 50)
        : (draft['g'] as num?)?.toDouble() ?? 50;
    final int wi = bet != null
        ? (bet.facts['w'] as num?)?.toInt() ?? middle
        : ((draft['w'] as num?)?.toInt() ?? middle).clamp(0, widths.length - 1);
    final RangeWidth width = widths[wi.clamp(0, widths.length - 1)];
    final double lo = math.max(0, guess - width.half).toDouble();
    final double hi = math.min(100, guess + width.half).toDouble();
    final bool laid = bet != null;
    final bool open = !laid && !elsewhere;
    final String said = n.percent(answer.value);

    void keep({double? g, int? w}) =>
        day.keepDraft(key, {'g': g ?? guess, 'w': w ?? wi});

    Future<void> lay() async {
      BetFeel.lay();
      final bool hit = answer.value >= lo && answer.value <= hi;
      final String response = plainResponse(guess);
      await layBet(
        host,
        shelf.section,
        Bet(
          kind: 'range',
          section: shelf.id,
          pill: pill.id,
          said: response,
          right: answer.accepts(response),
          points: hit ? width.pays : 0,
          facts: {
            'w': wi,
            'half': width.half,
            'pays': width.pays,
            'lo': lo,
            'hi': hi,
            'hit': hit,
          },
          at: DateTime.now().millisecondsSinceEpoch,
        ),
        pill: pill,
        response: response,
      );
    }

    final bool hit = laid && bet.facts['hit'] == true;
    final int pays = laid ? (bet.facts['pays'] as num?)?.toInt() ?? 0 : 0;

    // What the tile shows under the widths: the bet to lay, or what it came
    // to. Room is kept for the longest of what it can come to.
    Widget settled(String verdict, {bool ghost = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BetVerdict(
          verdict,
          key: ghost ? null : ValueKey('bets-range-said-${pill.id}'),
          ink: ink,
        ),
        BetWhy(pill, ink: ink),
      ],
    );
    final Widget foot = laid
        ? settled(hit ? l.betsInRange(pays, said) : l.betsMissedRange(said))
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
              key: ValueKey('bets-range-bet-${pill.id}'),
              label: l.betsBet,
              ink: ink,
              onTap: lay,
            ),
          );

    Widget game(Widget foot, {bool ghost = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
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
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                n.range(lo, hi),
                textAlign: TextAlign.right,
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w700,
                  height: 1,
                  color: ink.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BetTrack(
          key: ghost ? null : ValueKey('bets-range-track-${pill.id}'),
          ink: ink,
          value: guess,
          band: width.half.toDouble(),
          label: l.betsYourGuess,
          say: n.percent,
          answer: laid ? (answer.value, answer.value) : null,
          onChanged: open && !ghost ? (v) => keep(g: v) : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int j = 0; j < widths.length; j++) ...[
              if (j > 0) const SizedBox(width: 6),
              Expanded(
                child: BetChip(
                  key: ghost ? null : ValueKey('bets-range-${pill.id}-w$j'),
                  label: l.betsRangeWidth(widths[j].half, widths[j].pays),
                  ink: ink,
                  on: j == wi,
                  dim: !open && j != wi,
                  onTap: open && !ghost
                      ? () {
                          if (j == wi) return;
                          BetFeel.tick();
                          keep(w: j);
                        }
                      : null,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        foot,
      ],
    );

    final int most = widths.map((w) => w.pays).reduce(math.max);
    return BetFrame(
      pill: pill,
      ink: ink,
      size: size,
      read: host.isRead(pill),
      onOpen: open
          ? null
          : () =>
                host.open(shelf.section, [for (final c in cards) c.pill], pill),
      game: BetRoom(
        keep: size.inRow,
        ghosts: [
          if (!laid)
            game(settled(l.betsInRange(most, said), ghost: true), ghost: true),
        ],
        child: game(foot),
      ),
    );
  }
}
