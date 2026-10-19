/// One move, many places — the canvas's 133c.
///
/// Meeting base-rate neglect once, in a medical test, teaches medical
/// tests; meeting it in hiring, in crime figures and in a sales pitch
/// teaches base rates (lib/models/pill.dart, [Principle]). So the move is
/// set large in a box of its own — A MOVE, its name, the line that says it,
/// and how often the reader has met it — and under it the cards where it
/// hides, each saying where.
library;

import 'package:flutter/material.dart';

import '../../../data/explore_mix.dart';
import '../../../data/themed_shelves.dart' show shelfHash;
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../state/progress.dart' show Score;
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/explore/form_shelves.dart' show MoveBadge;
import '../../explore_block.dart';
import 'kit.dart';

/// The moves a box can name: every real one.
final List<Principle> kMoves = [
  for (final Principle p in Principle.values)
    if (p.isReal) p,
];

/// A move by the name a section gives it, `baseRate`, or null.
Principle? moveNamed(Object? name) =>
    kMoves.where((m) => m.name == name).firstOrNull;

/// The fewest cards a move needs here to be shown as met in many places.
const int kMoveCards = 3;

/// 133c: a move in a box, and the cards where it hides.
class MoveBlock extends ExploreBlock {
  const MoveBlock();

  @override
  String get name => 'purpose.move';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(172, 196),
    'm': TileSize(196, 216),
    'l': TileSize(224, 244),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> pool = host.cardsFor(section, limit: kPurposePool);
    final Principle? move =
        moveNamed(section.json['move']) ?? _moveFor(host, pool);
    if (move == null) return null;
    final List<Pill> cards = [
      for (final Pill p in pool)
        if (p.principle == move) p,
    ].take(limitOf(section, 8)).toList();
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final String lang = host.language;
    final int met = host.app.masteryOf(move).met;
    final TileSize size = sizeOf(section, sizes);
    return host.watch(
      section,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoveBox(
            name: wordsOf(section, 'name', lang, l.purposeMoveName(move.name)),
            line: wordsOf(section, 'line', lang, l.purposeMoveLine(move.name)),
            badge: MoveBadge(
              key: ValueKey('move-badge-${section.id}'),
              label: met > 0
                  ? l.inYourMoves(met)
                  : l.purposeMoveNew(Score.perMove),
              lit: met > 0,
            ),
          ),
          const SizedBox(height: 12),
          SideRow(
            height: size.height + 4,
            count: cards.length,
            itemBuilder: (context, i) {
              final Pill p = cards[i];
              host.seen(section, p);
              return MoveTile(
                pill: p,
                size: size,
                read: host.isRead(p),
                onOpen: () => host.open(section, cards, p),
              );
            },
          ),
        ],
      ),
    );
  }

  /// The move to show when the section names none: the one the reader is
  /// weakest at, among the moves with cards enough here, so the box is the
  /// one most worth meeting again; for a reader who has met none, one of
  /// them by the day, the same for everybody.
  static Principle? _moveFor(ExploreHost host, List<Pill> pool) {
    final Map<Principle, int> counts = {};
    for (final Pill p in pool) {
      if (p.principle.isReal)
        counts[p.principle] = (counts[p.principle] ?? 0) + 1;
    }
    final List<Principle> shown = [
      for (final MapEntry<Principle, int> e in counts.entries)
        if (e.value >= kMoveCards) e.key,
    ];
    if (shown.isEmpty) return null;
    for (final m in host.app.masteryByWeakness) {
      if (m.isWeak && shown.contains(m.principle)) return m.principle;
    }
    final int day = today();
    shown.sort(
      (a, b) =>
          shelfHash('$day:move:${a.name}')
              .compareTo(shelfHash('$day:move:${b.name}')),
    );
    return shown.first;
  }
}

/// The move, set large in a box of its own: what the box holds, its name,
/// the line that says it, and what the reader has done with it.
class MoveBox extends StatelessWidget {
  const MoveBox({
    super.key,
    required this.name,
    required this.line,
    required this.badge,
  });

  final String name;
  final String line;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ink.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    upper(context, context.l10n.purposeMoveKicker),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      size: 9.5,
                      weight: FontWeight.w700,
                      spacing: 1.4,
                      color: ink.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(flex: 3, child: badge),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              name,
              style: AppText.display(
                size: 31,
                weight: FontWeight.w600,
                height: 1.02,
                spacing: -1,
                color: ink,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              line,
              style: AppText.body(
                size: 13.5,
                height: 1.4,
                color: ink.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card where the move hides, saying where: in a hiring change, in a
/// famous study.
class MoveTile extends StatelessWidget {
  const MoveTile({
    super.key,
    required this.pill,
    required this.size,
    required this.read,
    required this.onOpen,
  });

  final Pill pill;
  final TileSize size;
  final bool read;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    return CardTap(
      pill: p,
      onTap: onOpen,
      child: Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.all(16),
        decoration: cardFace(context, p.color, radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PurposeHead(
              pill: p,
              trailing: read ? ReadMark(pill: p) : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 9),
                child: CardQuestion(
                  text: p.question,
                  color: p.ink,
                  min: 10.5,
                  max: size.width < 190 ? 15 : 16.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 9),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: hairOn(p))),
              ),
              child: Row(
                children: [
                  PurposeGlyph(Glyphs.search, size: 14, color: p.ink),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.hidesIn(inSentence(genreLabel(p))),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 11,
                        weight: FontWeight.w600,
                        height: 1,
                        color: p.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
