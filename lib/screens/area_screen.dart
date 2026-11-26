/// An area's own page (prototype D2): where cards pay off in a life
/// (lib/data/goals.dart), as paths to follow, the moves the area trains,
/// and more of its cards.
///
/// Opened from the search before anything is typed (By need), and from the
/// area's shelf on Explore. Its paths are the paths of its themes
/// (lib/explore/blocks/core/paths_block.dart), each at the part the reader
/// has got to; its moves are the reasoning the area trains, each with a
/// card of it to try.
library;

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/genre_names.dart';
import '../data/genres.dart';
import '../data/goals.dart';
import '../data/pill_bank.dart';
import '../data/topics.dart';
import '../explore/blocks/core/paths_block.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/area_marks.dart';
import '../widgets/move_words.dart';
import '../widgets/quick_return.dart';
import '../widgets/subject_icon.dart';
import '../widgets/ui.dart';
import 'card_path_screen.dart';
import 'deck_viewer_screen.dart';

class AreaScreen extends StatelessWidget {
  const AreaScreen({super.key, required this.app, required this.area});

  final AppState app;
  final Goal area;

  /// Opens [area]'s page.
  static Future<void> open(
    BuildContext context,
    AppState app,
    Goal area, {
    required String from,
  }) {
    Analytics.capture('area page opened', {
      'area': area.key,
      'from': from,
      'is_plus': app.isPlus,
    });
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AreaScreen(app: app, area: area),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenView(
      name: 'area',
      child: Scaffold(
        backgroundColor: context.p.surface,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: app,
            builder: (context, _) => _page(context),
          ),
        ),
      ),
    );
  }

  Widget _page(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final List<CardPath> paths = pathsForArea(area, read: app.seenIds);
    final List<(Principle, Pill)> moves = movesOf(area, app.seenIds);
    final List<Pill> cards = area.cardsFor(app.today, app.seenIds, count: 12);
    // The way back and the line beside it are part of the page, as
    // Instagram's are: they go up and away with it, and come straight back
    // the moment the reader goes back up ([QuickReturn]). Apple's glass is a
    // layer over the page, never laid inside the list, where a native button
    // is drawn away from its place.
    return QuickReturn(
      ground: p.surface,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              BackCircle(onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Icon(goalIcon(area), size: 16, color: goalHue(area)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.areaUsefulFor.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 12,
                    weight: FontWeight.w700,
                    spacing: 1.4,
                    color: p.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      child: ListView(
        // Under the way back and its line, as tall as they stand.
        padding: const EdgeInsets.fromLTRB(0, 8 + 44 + 4 + 12, 0, 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    goalName(l, area),
                    style: AppText.display(
                      size: 34,
                      weight: FontWeight.w600,
                      height: 1.05,
                      spacing: -1,
                      color: p.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  goalLine(l, area),
                  style: AppText.body(size: 15, height: 1.4, color: p.inkMuted),
                ),
                if (paths.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    l.areaPaths(paths.length).toUpperCase(),
                    style: AppText.label(
                      size: 11.5,
                      weight: FontWeight.w700,
                      spacing: 1.3,
                      color: p.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final CardPath path in paths)
                    _PathRow(
                      key: ValueKey('area-path-${path.genre.id}'),
                      app: app,
                      path: path,
                    ),
                ],
              ],
            ),
          ),
          if (moves.isNotEmpty) ...[
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l.areaMoves,
                style: AppText.display(
                  size: 22,
                  weight: FontWeight.w600,
                  spacing: -0.5,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: moves.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _MoveTile(
                  key: ValueKey('area-move-${moves[i].$1.name}'),
                  move: moves[i].$1,
                  pill: moves[i].$2,
                  onTap: () => _openCards(
                    context,
                    [for (final m in moves) m.$2],
                    i,
                    moveName(l, moves[i].$1),
                    'area move',
                  ),
                ),
              ),
            ),
          ],
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l.areaMoreCards,
                style: AppText.display(
                  size: 22,
                  weight: FontWeight.w600,
                  spacing: -0.5,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final (int i, Pill c) in cards.indexed)
                    _CardLine(
                      key: ValueKey('area-card-${c.id}'),
                      pill: c,
                      onTap: () => _openCards(
                        context,
                        cards,
                        i,
                        goalName(l, area),
                        'area card',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openCards(
    BuildContext context,
    List<Pill> deck,
    int at,
    String title,
    String source,
  ) {
    Analytics.capture('area card opened', {
      'area': area.key,
      'source': source,
      'rank': at + 1,
    });
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeckViewerScreen(
          app: app,
          deck: deck,
          title: title,
          initialIndex: at,
          countsAsRead: true,
          source: source,
        ),
      ),
    );
  }
}

/// The paths of [area]'s themes, each at the part [read] has got to: the
/// first part not read through, or the last of a theme read through.
List<CardPath> pathsForArea(Goal area, {Set<String> read = const {}}) {
  final List<CardPath> out = [];
  for (final MapEntry<String, List<Genre>> subject in kGenres.entries) {
    for (final Genre genre in subject.value) {
      if (!area.genres.contains(genre.id)) continue;
      final List<CardPath> parts = partsOf(genre, subject.key, PillBank.live);
      if (parts.isEmpty) continue;
      out.add(currentPart(parts, read));
    }
  }
  return out;
}

/// The moves [area] trains, each with a card of it the reader has not read
/// (or, all read, the first): from the area's own subjects first.
List<(Principle, Pill)> movesOf(Goal area, Set<String> read) {
  final List<(Principle, Pill)> out = [];
  for (final Principle move in area.moves) {
    final List<Pill> of =
        [
          for (final Pill p in PillBank.live)
            if (p.principle == move && p.book == null && p.place == null) p,
        ]..sort((a, b) {
          int rank(Pill p) =>
              (read.contains(p.id) ? 2 : 0) +
              (area.topicNames.contains(p.topic) ? 0 : 1);
          final int byRank = rank(a).compareTo(rank(b));
          return byRank != 0 ? byRank : a.id.compareTo(b.id);
        });
    if (of.isNotEmpty) out.add((move, of.first));
  }
  return out;
}

/// One path of the area: its subject's colour, how far along, its name and
/// subject, and what a tap does.
class _PathRow extends StatelessWidget {
  const _PathRow({super.key, required this.app, required this.path});

  final AppState app;
  final CardPath path;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final TopicStyle style = kTopics[path.topicKey]!;
    final int done = path.cards.where((c) => app.seenIds.contains(c.id)).length;
    final String? aside = done > 0 && done < path.cards.length
        ? l.pathContinue
        : !app.isPlus && done == 0
        ? l.pathFree(kPathFree)
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => CardPathScreen.open(context, app, path, from: 'area'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: LayoutBuilder(
              builder: (context, box) {
                final double width = box.maxWidth;
                return Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: style.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: done > 0
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$done/${path.cards.length}',
                                style: AppText.display(
                                  size: 17,
                                  weight: FontWeight.w600,
                                  color: style.ink,
                                ),
                              ),
                            )
                          : SubjectIcon(
                              subject: style.name,
                              size: 22,
                              ink: style.ink,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.themeOf(path.genre),
                            style: AppText.body(
                              size: 15,
                              weight: FontWeight.w700,
                              height: 1.25,
                              color: p.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            path.parts > 1
                                ? '${l.subjectOf(style.name)} · ${l.pathPartOf(path.part, path.parts)}'
                                : l.subjectOf(style.name),
                            style: AppText.body(size: 12.5, color: p.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    if (aside != null) ...[
                      const SizedBox(width: 8),
                      // Never more than a third of the row: the name has the rest.
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: width / 3),
                        child: Text(
                          aside,
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          style: AppText.body(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: done > 0
                                ? (p.isDark ? style.color : p.ink)
                                : p.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A move the area trains: its name, and the question of a card of it.
class _MoveTile extends StatelessWidget {
  const _MoveTile({
    super.key,
    required this.move,
    required this.pill,
    required this.onTap,
  });

  final Principle move;
  final Pill pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return SizedBox(
      width: 210,
      child: Material(
        color: p.inverse,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moveName(l, move).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 10.5,
                    weight: FontWeight.w700,
                    spacing: 1.1,
                    color: p.onInverse.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    pill.question,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(
                      size: 17,
                      weight: FontWeight.w600,
                      height: 1.15,
                      color: p.onInverse,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A card of the area, as a line: its subject's mark and its question.
class _CardLine extends StatelessWidget {
  const _CardLine({super.key, required this.pill, required this.onTap});

  final Pill pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pill.color,
                borderRadius: BorderRadius.circular(9),
              ),
              child: SubjectIcon(subject: pill.topic, size: 15, ink: pill.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pill.question,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 14.5,
                  weight: FontWeight.w600,
                  height: 1.3,
                  color: p.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
