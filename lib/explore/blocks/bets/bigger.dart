/// Which is bigger? (139c): two cards' figures, hidden, side by side, and a
/// tap on the one that is bigger. Both show once it is tapped.
library;

import 'package:flutter/material.dart';

import '../../../data/pill_bank.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/explore/parts.dart' show upper;
import '../../explore_block.dart';
import 'answers.dart';
import 'bet_host.dart';
import 'bets_day.dart';
import 'block.dart';
import 'deal.dart';
import 'parts.dart';

/// The block: pairs of shares, one under another.
class BiggerBlock extends BetBlock {
  const BiggerBlock();

  @override
  String get name => 'bets-bigger';

  /// Pairs, not cards: three of them by default.
  @override
  int get defaultLimit => 3;

  /// Any share. A comparison is a game with two cards, not either one's
  /// answer: neither is answered, and both are counted read once shown.
  @override
  bool fits(BetAnswer a) => a.share;

  /// How far apart two figures must be, in points, for which is bigger to
  /// be a thing worked out rather than a coin tossed: `gap`, 8 by default.
  static int gapOf(BetSection shelf) => shelf.count('gap', 8, min: 1, max: 50);

  @override
  String title(AppLocalizations l, BetSection shelf) => l.betsBiggerTitle;

  @override
  String line(AppLocalizations l, BetSection shelf) => l.betsBiggerLine;

  /// The pairs the section names as `pairs`, `[[id, id], …]`, where both
  /// cards are shares and their figures differ; null when it names none.
  static List<BetAnswer>? named(BetSection shelf) {
    final List<Object?>? raw = shelf.section.get<List<Object?>>('pairs');
    if (raw == null) return null;
    final List<BetAnswer> out = [];
    for (final Object? pair in raw) {
      if (pair is! List || pair.length != 2) continue;
      final List<BetAnswer> two = [
        for (final Object? id in pair)
          if (id is String && PillBank.byId(id) != null)
            if (answerOf(PillBank.byId(id)!) case final BetAnswer a
                when a.share)
              a,
      ];
      if (two.length != 2 || two[0].value == two[1].value) continue;
      out.addAll(two);
    }
    return out.isEmpty ? null : out;
  }

  /// The day's pairs, flat: the first two, then the next two. Each pair
  /// from two subjects, far enough apart.
  @override
  List<BetAnswer> deal(ExploreHost host, BetSection shelf) {
    final int pairs = shelf.limit(defaultLimit, most: 6);
    final List<BetAnswer>? given = named(shelf);
    if (given != null) return given.take(pairs * 2).toList();
    final int gap = gapOf(shelf);
    return dealWith(
      host,
      shelf,
      salt: name,
      fits: fits,
      pick: (fit, seed) {
        final List<BetAnswer> order = dealInOrder(
          fit,
          seed: seed,
          count: fit.length,
        );
        final List<BetAnswer> out = [];
        final Set<String> used = {};
        for (int i = 0; i < order.length && out.length < pairs * 2; i++) {
          final BetAnswer a = order[i];
          if (used.contains(a.pill.id)) continue;
          for (int j = i + 1; j < order.length; j++) {
            final BetAnswer b = order[j];
            if (used.contains(b.pill.id) || b.pill.topic == a.pill.topic) {
              continue;
            }
            if ((a.value - b.value).abs() < gap) continue;
            out.addAll([a, b]);
            used.addAll([a.pill.id, b.pill.id]);
            break;
          }
        }
        return out;
      },
    );
  }

  @override
  bool canShow(ExploreHost host, BetSection shelf) =>
      named(shelf) != null || super.canShow(host, shelf);

  @override
  Widget body(
    BuildContext context,
    ExploreHost host,
    BetSection shelf,
    List<BetAnswer> cards,
  ) {
    final l = context.l10n;
    final String size = shelf.size(sizes, defaultSize);
    final int pairs = cards.length ~/ 2;
    final List<Bet> picked = [
      for (int i = 0; i < pairs; i++)
        ?BetsDay.instance.betOn('bigger', cards[i * 2].pill.id),
    ];
    final int right = picked.where((b) => b.right).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BetTiles(
          size: BetTileSize.l,
          count: pairs,
          onSeen: (i) {
            host.seen(shelf.section, cards[i * 2].pill);
            host.seen(shelf.section, cards[i * 2 + 1].pill);
          },
          builder: (context, i) => BiggerPair(
            key: ValueKey('bets-bigger-pair-${cards[i * 2].pill.id}'),
            host: host,
            shelf: shelf,
            a: cards[i * 2],
            b: cards[i * 2 + 1],
            size: size,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            picked.isEmpty
                ? l.betsBiggerFoot
                : l.betsBiggerScore(right, picked.length),
            key: const ValueKey('bets-bigger-foot'),
            style: AppText.body(
              size: 12,
              weight: FontWeight.w500,
              height: 1.4,
              color: context.p.ink.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

/// Two figures, and an "or" between them.
class BiggerPair extends StatelessWidget {
  const BiggerPair({
    super.key,
    required this.host,
    required this.shelf,
    required this.a,
    required this.b,
    required this.size,
  });

  final ExploreHost host;
  final BetSection shelf;
  final BetAnswer a;
  final BetAnswer b;

  /// `s`, `m` or `l`: how tall the two are and how large their figures.
  final String size;

  @override
  Widget build(BuildContext context) {
    final Bet? bet = BetsDay.instance.betOn('bigger', a.pill.id);
    final int? picked = bet == null ? null : int.tryParse(bet.said);
    final int bigger = a.value > b.value ? 0 : 1;

    Future<void> pick(int j) async {
      BetFeel.lay();
      await layBet(
        host,
        shelf.section,
        Bet(
          kind: 'bigger',
          section: shelf.id,
          pill: a.pill.id,
          other: b.pill.id,
          said: '$j',
          right: j == bigger,
          facts: {'a': a.value, 'b': b.value, 'gap': (a.value - b.value).abs()},
          at: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      revealCard(host, shelf.section, a.pill);
      revealCard(host, shelf.section, b.pill);
    }

    Widget half(int j, BetAnswer c) => _Figure(
      key: ValueKey('bets-bigger-${c.pill.id}'),
      answer: c,
      shelf: shelf,
      size: size,
      picked: picked,
      side: j,
      bigger: bigger,
      onTap: picked == null
          ? () => pick(j)
          : () => host.open(shelf.section, [a.pill, b.pill], c.pill),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: half(0, a)),
              const SizedBox(width: 8),
              Expanded(child: half(1, b)),
            ],
          ),
        ),
        IgnorePointer(
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.p.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.p.ink.withValues(alpha: 0.18)),
            ),
            child: Text(
              context.l10n.betsOr,
              style: AppText.display(
                size: 12,
                weight: FontWeight.w600,
                height: 1,
                color: context.p.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One of the two: its figure, hidden until the pick, what it is the
/// answer to, and what the pick made of it.
class _Figure extends StatelessWidget {
  const _Figure({
    super.key,
    required this.answer,
    required this.shelf,
    required this.size,
    required this.picked,
    required this.side,
    required this.bigger,
    required this.onTap,
  });

  final BetAnswer answer;
  final BetSection shelf;
  final String size;
  final int? picked;
  final int side;
  final int bigger;
  final VoidCallback onTap;

  /// What the figure is the answer to: the section's own words for it, in
  /// the reader's language, or the card's question.
  static String labelOf(BuildContext context, BetSection shelf, Pill pill) {
    final Object? labels = shelf.section.json['labels'];
    if (labels is Map && labels[pill.id] != null) {
      final ExploreSection one = ExploreSection(
        id: shelf.id,
        block: shelf.section.block,
        json: {'label': labels[pill.id]},
      );
      final String? said = one.text(
        'label',
        Localizations.localeOf(context).languageCode,
      );
      if (said != null) return said;
    }
    return pill.question;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Pill pill = answer.pill;
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final bool done = picked != null;
    final bool big = done && side == bigger;
    final bool page = shelf.tone(BetTone.page) == BetTone.page;
    final BetInk base = BetInk.of(context, pill, shelf.tone(BetTone.page));
    // On the page the bigger turns over to the page's reverse, as the
    // canvas has it; in the subject's colours the smaller steps back.
    final Color ground = big && page ? context.p.inverse : base.ground;
    final Color ink = big && page ? context.p.onInverse : base.ink;
    final Color sub = ink.withValues(alpha: big ? 0.6 : 0.45);
    final String tag = !done
        ? l.betsTapIfBigger
        : big
        ? (picked == side ? l.betsBiggerGotIt : l.betsBigger)
        : (picked == side ? l.betsYourPick : '');
    final (double minHeight, double figure, double words) = switch (size) {
      's' => (112.0, 24.0, 11.5),
      'l' => (168.0, 38.0, 13.5),
      _ => (136.0, 30.0, 12.0),
    };
    final Duration motion = betMotion(context, 300);
    return Semantics(
      button: true,
      label: done ? '${n.percent(answer.value)}. $tag' : l.betsTapIfBigger,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: motion,
          opacity: done && !big && !page ? 0.55 : 1,
          child: AnimatedContainer(
            duration: motion,
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ground,
              borderRadius: BorderRadius.circular(18),
              border: page ? null : base.edge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? n.percent(answer.value) : '?',
                  style: AppText.display(
                    size: figure,
                    weight: FontWeight.w600,
                    height: 1,
                    spacing: -1,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labelOf(context, shelf, pill),
                  style: AppText.body(
                    size: words,
                    weight: FontWeight.w500,
                    height: 1.35,
                    color: ink,
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (big && !page) ...[
                      Icon(Icons.check_rounded, size: 14, color: ink),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        upper(context, tag),
                        style: AppText.label(
                          size: 9,
                          weight: FontWeight.w700,
                          spacing: 1.2,
                          height: 1.2,
                          color: big ? ink.withValues(alpha: 0.75) : sub,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
