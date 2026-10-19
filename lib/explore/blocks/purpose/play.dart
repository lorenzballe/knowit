/// Cards you play on the shelf — the canvas's 138d.
///
/// Move it, then check, and unmask the chart are in the app already, as
/// core's work-it-out shelf. What this family adds is the trick to spot —
/// which question would catch it — and the box that says what was played
/// today.
library;

import 'package:flutter/material.dart';

import '../../../data/explore_mix.dart' show percentOf, PercentCard;
import '../../../data/themed_shelves.dart' show shelfHash;
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../state/explore_play.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../explore_block.dart';
import 'kit.dart';

// ── Spot the trick ───────────────────────────────────────────────────────

/// The three moves a card offers to pick from: its own and two others, in
/// an order of the card's own that never puts its move in the same place.
List<Principle> trickOptions(Pill p) {
  int rank(Principle m) => shelfHash('trick:${p.id}:${m.name}');
  final List<Principle> others = kTraps.where((m) => m != p.principle).toList()
    ..sort((a, b) => rank(a).compareTo(rank(b)));
  return [p.principle, ...others.take(2)]
    ..sort((a, b) => rank(a).compareTo(rank(b)));
}

/// What a reader picked on a card today, and whether it was the card's
/// move, from the day's play.
({String move, bool right})? trickPicked(String id) {
  final Object? all = PurposePlay.read('tricks');
  final Object? one = all is Map ? all[id] : null;
  if (one is! Map) return null;
  final Object? move = one['move'];
  final Object? right = one['right'];
  if (move is! String || right is! bool) return null;
  return (move: move, right: right);
}

/// 138d: which question would catch it? Three moves to pick from on each
/// card; a pick says whether it was the one.
class SpotTrickBlock extends ExploreBlock {
  const SpotTrickBlock();

  @override
  String get name => 'purpose.spot-trick';

  /// The block's sizes; `m` is the canvas's width.
  static const Map<String, TileSize> sizes = {
    's': TileSize(270, 288),
    'm': TileSize(300, 300),
    'l': TileSize(330, 312),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = cardsOf(
      host,
      section,
      limit: 6,
      canDraw: (p) => kTraps.contains(p.principle),
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final String lang = host.language;
    final TileSize size = sizeOf(section, sizes);
    return host.watch(
      section,
      PurposeShelf(
        title: section.title(lang) ?? l.purposeSpotTrick,
        line: section.subtitle(lang) ?? l.purposeSpotTrickLine,
        child: PlayWatch<List<String?>>(
          select: () => [for (final Pill p in cards) trickPicked(p.id)?.move],
          builder: (context, picks) => SideRow(
            height: size.height + 4,
            count: cards.length,
            itemBuilder: (context, i) {
              final Pill p = cards[i];
              host.seen(section, p);
              return TrickTile(
                pill: p,
                size: size,
                read: host.isRead(p),
                picked: picks[i],
                onOpen: () => host.open(section, cards, p),
                onPick: (move) {
                  final Object? all = PurposePlay.read('tricks');
                  final bool right = move == p.principle;
                  PurposePlay.write('tricks', {
                    if (all is Map) ...all,
                    p.id: {'move': move.name, 'right': right},
                  });
                  host.note(section, 'trick spotted', {
                    'pill_id': p.id,
                    'move': move.name,
                    'right': right,
                  });
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A card with three moves under it to pick from. Once picked, the card's
/// move is filled, a wrong pick is struck through, the rest step back, and
/// a line says which it was.
class TrickTile extends StatelessWidget {
  const TrickTile({
    super.key,
    required this.pill,
    required this.size,
    required this.read,
    required this.picked,
    required this.onOpen,
    required this.onPick,
  });

  final Pill pill;
  final TileSize size;
  final bool read;

  /// The move picked today, by name, or null.
  final String? picked;
  final VoidCallback onOpen;
  final ValueChanged<Principle> onPick;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final l = context.l10n;
    final bool done = picked != null;
    final List<Principle> options = trickOptions(p);
    return CardTap(
      pill: p,
      onTap: onOpen,
      child: Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.all(18),
        decoration: cardFace(context, p.color, radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PurposeHead(
              pill: p,
              trailing: read ? ReadMark(pill: p) : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 14),
                child: CardQuestion(
                  text: p.question,
                  color: p.ink,
                  min: 10.5,
                  max: size.width < 290 ? 16 : 17.5,
                ),
              ),
            ),
            for (final Principle m in options) ...[
              _Option(
                key: ValueKey('trick-${p.id}-${m.name}'),
                pill: p,
                label: l.purposeMoveName(m.name),
                right: done && m == p.principle,
                struck: done && m.name == picked && m != p.principle,
                faded: done && m != p.principle && m.name != picked,
                onTap: done ? null : () => onPick(m),
              ),
              if (m != options.last) const SizedBox(height: 6),
            ],
            if (done) ...[
              const SizedBox(height: 12),
              Text(
                picked == p.principle.name
                    ? l.tfRight
                    : l.tfWrong(l.purposeMoveName(p.principle.name)),
                key: ValueKey('trick-verdict-${p.id}'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  height: 1.4,
                  color: p.ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One move to pick, 38 high, as the canvas draws it; the card's own move,
/// once a pick is made, filled in the card's ink.
class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.pill,
    required this.label,
    required this.right,
    required this.struck,
    required this.faded,
    required this.onTap,
  });

  final Pill pill;
  final String label;
  final bool right;
  final bool struck;
  final bool faded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final Color fore = right ? p.color : p.ink;
    return Semantics(
      button: onTap != null,
      selected: right,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: faded ? 0.4 : 1,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: right ? p.ink : fillOn(p),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.body(
                          size: 13,
                          weight: FontWeight.w600,
                          height: 1,
                          color: fore,
                        ).copyWith(
                          decoration: struck
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: fore,
                        ),
                  ),
                ),
                if (right) PurposeGlyph(Glyphs.check, size: 15, color: fore),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── What you played ──────────────────────────────────────────────────────

/// What was played today on the shelves, from the day's play: how far the
/// sliders were from the answers, how many tricks were spotted, how many
/// cards were answered on a shelf of this family.
@immutable
class Played {
  const Played({
    required this.slides,
    required this.off,
    required this.tricks,
    required this.spotted,
    required this.answered,
  });

  /// How many sliders were checked, and how far off they were on average,
  /// in points.
  final int slides;
  final int off;

  /// How many tricks were picked, and how many were the card's move.
  final int tricks;
  final int spotted;

  /// How many cards were answered on a shelf.
  final int answered;

  /// Whether nothing was played.
  bool get none => slides == 0 && tricks == 0 && answered == 0;

  @override
  bool operator ==(Object other) =>
      other is Played &&
      other.slides == slides &&
      other.off == off &&
      other.tricks == tricks &&
      other.spotted == spotted &&
      other.answered == answered;

  @override
  int get hashCode => Object.hash(slides, off, tricks, spotted, answered);

  /// Today's play, the sliders read against the answers of the cards in
  /// [pool].
  static Played today(List<Pill> pool) {
    int slides = 0;
    double off = 0;
    for (final Pill p in pool) {
      final Object? kept = ExplorePlay.instance['slide:${p.id}'];
      if (kept is! Map || kept['ck'] != true) continue;
      final PercentCard? card = percentOf(p);
      final Object? v = kept['v'];
      if (card == null || v is! num) continue;
      slides++;
      off += (v - card.value).abs();
    }
    final Object? tricks = PurposePlay.read('tricks');
    int picked = 0, spotted = 0;
    if (tricks is Map) {
      for (final Object? t in tricks.values) {
        if (t is! Map || t['right'] is! bool) continue;
        picked++;
        if (t['right'] == true) spotted++;
      }
    }
    return Played(
      slides: slides,
      off: slides == 0 ? 0 : (off / slides).round(),
      tricks: picked,
      spotted: spotted,
      answered: PurposePlay.setOf('said').length,
    );
  }
}

/// 138d: what you played today — points off, tricks spotted, cards
/// answered on a shelf — and where it counts.
class PlayedBlock extends ExploreBlock {
  const PlayedBlock();

  @override
  String get name => 'purpose.played';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> pool = host.cardsFor(section, limit: kPurposePool);
    // With no cards to play and nothing played, there is nothing to count.
    if (pool.isEmpty && Played.today(pool).none) return null;
    final l = context.l10n;
    final String lang = host.language;
    return host.watch(
      section,
      PlayWatch<Played>(
        select: () => Played.today(pool),
        builder: (context, played) => PlayedBox(
          title: section.title(lang) ?? l.purposePlayed,
          footer: wordsOf(section, 'footer', lang, l.purposePlayedFooter),
          stats: [
            (played.slides == 0 ? '–' : '${played.off}', l.purposePlayedOff),
            (
              played.tricks == 0
                  ? '–'
                  : l.purposeOf(played.spotted, played.tricks),
              l.purposePlayedTricks,
            ),
            (
              played.answered == 0 ? '–' : '${played.answered}',
              l.purposePlayedAnswered,
            ),
          ],
        ),
      ),
    );
  }
}

/// The box of what was played: its title, three counts side by side, and
/// the line that says where they count.
class PlayedBox extends StatelessWidget {
  const PlayedBox({
    super.key,
    required this.title,
    required this.stats,
    required this.footer,
  });

  final String title;

  /// Each count's figure and what it counts.
  final List<(String, String)> stats;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final Palette pal = context.p;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pal.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.display(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
              spacing: -0.4,
              color: pal.ink,
            ),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      key: ValueKey('played-$i'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: pal.ink.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats[i].$1,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: AppText.display(
                              size: 22,
                              weight: FontWeight.w600,
                              height: 1,
                              spacing: -0.5,
                              color: pal.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stats[i].$2,
                            style: AppText.body(
                              size: 10.5,
                              weight: FontWeight.w500,
                              height: 1.3,
                              color: pal.ink.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            footer,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w500,
              height: 1.4,
              color: pal.ink.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
