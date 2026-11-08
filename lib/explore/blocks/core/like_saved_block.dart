/// More like what you saved: a row of cards close to one the reader saved —
/// the same strand, the same genre, the things in it — not read yet, under
/// a chip that says which card they are like: "Because you saved ‘How far
/// away is the Moon…’".
///
/// A save is the clearest thing a reader says about what they want more
/// of, and the one Explore did nothing with. The row follows the most
/// recent save that has cards like it, and says so, so it never reads as
/// the app guessing: the reason is on the row. With nothing saved, or
/// nothing like it left unread, there is no section.
library;

import 'package:flutter/material.dart';

import '../../../data/pills_repository.dart' show pillById;
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// How alike [card] is to [saved], in points: the same strand 4, either
/// one also about the other's strand 3, the same genre 2, and 1 for each
/// thing in it the two share (their keywords). 0 for the card itself.
int likeness(Pill saved, Pill card) {
  if (card.id == saved.id) return 0;
  int points = 0;
  if (saved.strand.isNotEmpty && card.strand == saved.strand) points += 4;
  if ((saved.strand.isNotEmpty && card.also.contains(saved.strand)) ||
      (card.strand.isNotEmpty && saved.also.contains(card.strand))) {
    points += 3;
  }
  if (saved.genre.isNotEmpty && card.genre == saved.genre) points += 2;
  final Set<String> words = saved.keywords.toSet();
  points += card.keywords.where(words.contains).length;
  return points;
}

/// The least a card must score to be called like a saved one: a strand in
/// common, or a genre and something in it, or three things in it.
const int kLikeFloor = 3;

/// How many saved cards, most recent first, are asked for cards like them
/// before the row gives up.
const int kLikeSeeds = 6;

/// The cards like one the reader saved, and which: the most recent save
/// with any, its cards furthest alike first (in the pool's order between
/// two alike), at most [most]; null when no save has any. [pool] is where
/// they may come from; a card read or saved is not one, nor one [keep]
/// turns down — asked only of the cards that would be shown, since it may
/// be dear (a question measured against its tile).
({Pill saved, List<Pill> cards})? likeSaved({
  required List<String> savedIds,
  required List<Pill> pool,
  required bool Function(Pill) isRead,
  required int most,
  bool Function(Pill)? keep,
}) {
  final Set<String> saved = savedIds.toSet();
  final List<Pill> open = [
    for (final Pill p in pool)
      if (!saved.contains(p.id) && !isRead(p)) p,
  ];
  int asked = 0;
  for (final String id in savedIds) {
    if (asked == kLikeSeeds) break;
    final Pill? seed = pillById(id);
    if (seed == null) continue;
    asked++;
    final List<(Pill, int)> alike = [
      for (final Pill p in open)
        if (likeness(seed, p) case final int points when points >= kLikeFloor)
          (p, points),
    ];
    // A stable sort: between two alike, the pool's own order.
    final List<int> order = List.generate(alike.length, (i) => i)
      ..sort((a, b) {
        final int by = alike[b].$2.compareTo(alike[a].$2);
        return by != 0 ? by : a.compareTo(b);
      });
    final List<Pill> cards = [];
    for (final int i in order) {
      if (cards.length == most) break;
      if (keep?.call(alike[i].$1) ?? true) cards.add(alike[i].$1);
    }
    if (cards.isEmpty) continue;
    return (saved: seed, cards: cards);
  }
  return null;
}

/// [question] cut to about [most] characters at a word, with an ellipsis
/// where it was cut: enough of a card to know it by in a chip.
String shortQuestion(String question, {int most = 30}) {
  final String q = question.trim();
  if (q.length <= most) return q;
  final int space = q.lastIndexOf(' ', most);
  final String cut = q.substring(0, space > most ~/ 2 ? space : most);
  return '${cut.replaceAll(RegExp(r'[\s,;:.]+$'), '')}…';
}

/// The block: see the library's own words. `limit` is how many cards the
/// row shows, eight unless it says.
class LikeSavedBlock extends ExploreBlock with SectionLayout {
  const LikeSavedBlock();

  @override
  String get name => 'like-saved';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<String> savedIds = host.app.savedIds;
    if (savedIds.isEmpty) return null;
    const TileSize size = TileSize.m;
    final TileLook look = TileLook.of(size);
    final Size box = Size(size.width, size.height);
    // The whole bank in the day's order, narrowed to the subject in view:
    // what a section that names no source draws from.
    final like = likeSaved(
      savedIds: savedIds,
      pool: host.cardsFor(section),
      isRead: host.isRead,
      most: section.limit ?? 8,
      keep: (p) => questionFits(context, p, box, look, read: false),
    );
    if (like == null) return null;
    final l = context.l10n;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Because(
                text: l.exploreBecauseSaved(shortQuestion(like.saved.question)),
                colour: like.saved.color,
              ),
            ),
          ),
          TileRow(
            size: size,
            pills: like.cards,
            isRead: host.isRead,
            onOpen: (shelf, pill) => host.open(section, shelf, pill),
            onShown: (pill) => host.seen(section, pill),
          ),
        ],
      ),
    );
  }
}

/// The reason, in a chip: a bookmark in the saved card's colour, and the
/// words.
class _Because extends StatelessWidget {
  const _Because({required this.text, required this.colour});

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('like-saved-because'),
      padding: const EdgeInsets.fromLTRB(9, 6, 12, 6),
      decoration: BoxDecoration(
        color: context.p.ink.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_rounded, size: 14, color: colour),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w500,
                height: 1.25,
                color: context.p.ink.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
