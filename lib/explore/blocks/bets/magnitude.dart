/// Orders of magnitude (139d): is it ten, a thousand or a million? A size
/// picked from a staircase of powers of ten.
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

/// The block: a row of sizes to pick by their order of magnitude.
class MagnitudeBlock extends BetBlock {
  const MagnitudeBlock();

  @override
  String get name => 'bets-magnitude';

  @override
  int get defaultLimit => 3;

  /// A card judged on its order of magnitude: an estimate a power of ten
  /// is close enough to for the card to count right, or a pick of odds.
  @override
  bool fits(BetAnswer a) => Notches.of(a) != null;

  @override
  String title(AppLocalizations l, BetSection shelf) => l.betsMagnitudeTitle;

  @override
  String line(AppLocalizations l, BetSection shelf) => l.betsMagnitudeLine;

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
      builder: (context, i) => MagnitudeTile(
        key: ValueKey('bets-magnitude-${cards[i].pill.id}'),
        host: host,
        shelf: shelf,
        answer: cards[i],
        cards: cards,
        size: size,
      ),
    );
  }
}

/// One size to pick.
class MagnitudeTile extends StatelessWidget {
  const MagnitudeTile({
    super.key,
    required this.host,
    required this.shelf,
    required this.answer,
    required this.cards,
    required this.size,
  });

  final ExploreHost host;
  final BetSection shelf;
  final BetAnswer answer;
  final List<BetAnswer> cards;
  final BetTileSize size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pill = answer.pill;
    final BetsDay day = BetsDay.instance;
    final BetInk ink = BetInk.of(context, pill, shelf.tone());
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final Notches notches = Notches.of(answer)!;
    final String key = BetsDay.draftKey('magnitude', pill.id);
    final Bet? bet = day.betOn('magnitude', pill.id);
    final bool elsewhere = bet == null && host.app.answerFor(pill.id) != null;
    final Map draft = day.draft(key) is Map ? day.draft(key) as Map : const {};
    final int? picked = bet != null
        ? (bet.facts['at'] as num?)?.toInt()
        : (draft['p'] as num?)?.toInt();
    final bool laid = bet != null;
    final bool pending = !laid && !elsewhere && picked != null;
    final bool open = !laid && !elsewhere;
    final double inner = size.inner(MediaQuery.sizeOf(context).width);
    final int count = notches.values.length;

    // The language's short form where every label fits its notch on one
    // stair, a little smaller where it must be; powers of ten where only
    // they do; and where neither does, at a large text size, the short
    // form on a staircase that turns.
    TextStyle styleAt(double size) =>
        AppText.body(size: size, weight: FontWeight.w700, height: 1.1);
    final double room = (inner - 4 * (count - 1)) / count - 8;
    double sizeFor(List<String> all) =>
        chipSizeFor(context, all, room, max: 12, min: 10.5);
    bool fit(List<String> all, double size) =>
        all.every((s) => betTextWidth(context, s, styleAt(size)) <= room);
    final List<String> short = [
      for (final double v in notches.values) n.compact(v),
    ];
    final List<String> powers = [
      for (final double v in notches.values) BetNumbers.power(v),
    ];
    final double shortSize = sizeFor(short);
    final double powerSize = sizeFor(powers);
    final bool shortFits = fit(short, shortSize);
    final bool asPowers = !shortFits && fit(powers, powerSize);
    final List<String> labels = asPowers ? powers : short;
    final double labelSize = asPowers
        ? powerSize
        : (shortFits ? shortSize : 12);
    final TextStyle labelStyle = styleAt(labelSize);

    Future<void> lay(int at, int? sure) async {
      final String response = notches.responseAt(at);
      await layBet(
        host,
        shelf.section,
        Bet(
          kind: 'magnitude',
          section: shelf.id,
          pill: pill.id,
          said: response,
          right: answer.accepts(response),
          confidence: sure,
          facts: {
            'at': at,
            'value': notches.values[at],
            'off': notches.offBy(at),
          },
          at: DateTime.now().millisecondsSinceEpoch,
        ),
        pill: pill,
        response: response,
      );
    }

    void pick(int at) {
      BetFeel.tick();
      if (shelf.asksSure) {
        day.keepDraft(key, {'p': at});
      } else {
        BetFeel.lay();
        lay(at, null);
      }
    }

    Widget stairs() => BetChips(
      labels: labels,
      width: inner,
      style: labelStyle,
      chrome: 8,
      gap: 4,
      crossAxisAlignment: CrossAxisAlignment.end,
      builder: (j) => BetChip(
        key: ValueKey('bets-magnitude-${pill.id}-$j'),
        label: labels[j],
        ink: ink,
        on: laid ? j == notches.right : j == picked,
        ring: laid && j == picked && j != notches.right,
        dim: laid && j != notches.right && j != picked,
        height: count > 3 ? 28.0 + 4 * j : 30.0 + 9 * j,
        radius: 10,
        size: labelSize,
        padding: 2,
        semantics: answer.odds
            ? l.betsOneIn(n.plain(notches.values[j], decimals: 0))
            : '${n.plain(notches.values[j], decimals: 3)} '
                  '${answer.unit}',
        onTap: open && j != picked ? () => pick(j) : null,
      ),
    );

    Widget settled() {
      final int o = (bet?.facts['off'] as num?)?.toInt() ?? 0;
      final bool right = bet?.right ?? false;
      final String verdict = right || o == 0
          ? l.betsMagnitudeRight
          : l.betsMagnitudeOff(o);
      final int? s = bet?.confidence;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BetVerdict(
            s == null ? verdict : '$verdict ${l.betsYouWereSure(s)}',
            key: ValueKey('bets-magnitude-said-${pill.id}'),
            ink: ink,
          ),
          BetWhy(pill, ink: ink),
        ],
      );
    }

    Widget sureStep() => SureStep(
      key: ValueKey('bets-magnitude-sure-${pill.id}'),
      pill: pill,
      ink: ink,
      width: inner,
      onPick: picked == null ? (_) {} : (s) => lay(picked, s),
    );

    Widget game(Widget foot) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BetKicker(answer.odds ? l.betsOneInLabel : answer.unit, color: ink.sub),
        const SizedBox(height: 7),
        stairs(),
        const SizedBox(height: 12),
        foot,
      ],
    );

    final Widget foot = laid
        ? settled()
        : pending
        ? sureStep()
        : elsewhere
        ? Text(
            l.betsAnsweredAlready,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w600,
              color: ink.sub,
            ),
          )
        : const SizedBox.shrink();
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
