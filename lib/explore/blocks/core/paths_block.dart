/// Paths: ten cards on one theme, from the easiest to the hardest, a row of
/// them. Astute+, with a way in: a reader on the free plan opens any path
/// and reads its first two cards, and the card after them is the rest of
/// the path, with the plans behind it. A path begun is wanted whole in a
/// way a lock is not.
///
/// A path is a genre of the bank (lib/data/genres.dart) with ten cards or
/// more: its first ten, easy before hard, a card with a drawing before one
/// without. The row turns over once a week, the same for every reader, and
/// follows the subject Explore is narrowed to. Each tile says how many of
/// its ten the reader has read; a tap opens the ten at full size, a card at
/// a time, counted as read as they go.
library;

import 'package:flutter/material.dart';

import '../../../data/genres.dart';
import '../../../data/pill_bank.dart';
import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../screens/deck_viewer_screen.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../../widgets/premium.dart';
import '../../../widgets/subject_icon.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// How many cards a path holds.
const int kPathLength = 10;

/// How many of a path's cards the free plan reads: the way in.
const int kPathFree = 2;

/// One path: a genre, its subject's key, and its ten.
class CardPath {
  const CardPath({
    required this.genre,
    required this.topicKey,
    required this.cards,
  });

  final Genre genre;
  final String topicKey;
  final List<Pill> cards;
}

/// The paths of [bank], [limit] of them, turning over weekly from [today],
/// narrowed to [subject] (a subject's name) when there is one.
List<CardPath> pathsOf(
  List<Pill> bank, {
  required DateTime today,
  String? subject,
  int limit = 8,
}) {
  final Map<String, List<Pill>> byGenre = {};
  for (final Pill p in bank) {
    if (p.genre.isEmpty) continue;
    if (subject != null && p.topic != subject) continue;
    byGenre.putIfAbsent(p.genre, () => []).add(p);
  }
  const Map<String, int> order = {'easy': 0, 'medium': 1, 'hard': 2};
  final List<CardPath> all = [];
  for (final MapEntry<String, List<Genre>> subjectGenres in kGenres.entries) {
    for (final Genre genre in subjectGenres.value) {
      final List<Pill>? cards = byGenre[genre.id];
      if (cards == null || cards.length < kPathLength) continue;
      final List<Pill> sorted = [...cards]
        ..sort((a, b) {
          final int byLevel = (order[a.difficulty.name] ?? 1).compareTo(
            order[b.difficulty.name] ?? 1,
          );
          if (byLevel != 0) return byLevel;
          final int byPage = (b.hasPage ? 1 : 0).compareTo(a.hasPage ? 1 : 0);
          return byPage != 0 ? byPage : a.id.compareTo(b.id);
        });
      all.add(
        CardPath(
          genre: genre,
          topicKey: subjectGenres.key,
          cards: sorted.take(kPathLength).toList(),
        ),
      );
    }
  }
  if (all.isEmpty) return const [];
  // One subject at a time round the wheel, so two paths side by side are
  // never of the same subject: the first of every subject, then the second.
  final Map<String, List<CardPath>> bySubject = {};
  for (final CardPath path in all) {
    bySubject.putIfAbsent(path.topicKey, () => []).add(path);
  }
  final List<CardPath> woven = [];
  for (int round = 0; woven.length < all.length; round++) {
    for (final List<CardPath> paths in bySubject.values) {
      if (round < paths.length) woven.add(paths[round]);
    }
  }
  all
    ..clear()
    ..addAll(woven);
  // The week's turn: the same start for every reader, a step on each week.
  final int week = today.difference(DateTime(2026)).inDays ~/ 7;
  final int start = (week * 5) % all.length;
  return [
    for (int i = 0; i < all.length && i < limit; i++)
      all[(start + i) % all.length],
  ];
}

/// The block: see the library's own words.
class PathsBlock extends ExploreBlock with SectionLayout {
  const PathsBlock();

  @override
  String get name => 'paths';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final AppState app = host.app;
    final List<CardPath> paths = pathsOf(
      PillBank.live,
      today: app.today,
      subject: host.subject,
      limit: section.limit ?? 8,
    );
    if (paths.isEmpty) return null;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: SizedBox(
        height: _PathTile.height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: paths.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) => _PathTile(
            path: paths[i],
            read: paths[i].cards
                .where((p) => app.seenIds.contains(p.id))
                .length,
            locked: !app.isPlus,
            onTap: () => openPath(context, app, paths[i]),
          ),
        ),
      ),
    );
  }
}

/// Opens [path] at full size, a card at a time, counted as read as they go:
/// all ten on Astute+, from [from]; on the free plan its first [kPathFree],
/// then the card that offers the rest.
Future<void> openPath(
  BuildContext context,
  AppState app,
  CardPath path, {
  int from = 0,
}) {
  final bool whole = app.isPlus;
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DeckViewerScreen(
        app: app,
        deck: whole ? path.cards : path.cards.take(kPathFree).toList(),
        title: path.genre.label,
        initialIndex: whole ? from : 0,
        countsAsRead: true,
        source: 'path',
        of: path.cards.length,
        end: whole ? null : PathMore(app: app, path: path),
      ),
    ),
  );
}

/// The card after a path's free cards: how many are left, and the way to
/// them. Through the plans, and on with the path where it was left.
class PathMore extends StatelessWidget {
  const PathMore({super.key, required this.app, required this.path});

  final AppState app;
  final CardPath path;

  @override
  Widget build(BuildContext context) {
    final TopicStyle style = kTopics[path.topicKey]!;
    final Color ink = style.ink;
    final int left = path.cards.length - kPathFree;
    return Container(
      key: const ValueKey('path-more'),
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(34),
      ),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SubjectIcon(subject: style.name, size: 22, ink: ink),
              const Spacer(),
              Icon(
                Icons.lock_rounded,
                size: 18,
                color: ink.withValues(alpha: 0.7),
              ),
            ],
          ),
          const Spacer(),
          // The path: the two read, the rest still to come.
          ExcludeSemantics(
            child: Row(
              children: [
                for (int i = 0; i < path.cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: i < kPathFree ? 0.9 : 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            path.genre.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              size: 11,
              weight: FontWeight.w700,
              spacing: 1.2,
              color: ink.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              context.l10n.pathMoreTitle(left),
              style: AppText.display(
                size: 30,
                weight: FontWeight.w600,
                height: 1.08,
                spacing: -0.9,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.pathMoreLine,
            style: AppText.body(
              size: 15,
              height: 1.4,
              color: ink.withValues(alpha: 0.82),
            ),
          ),
          const Spacer(),
          _InkButton(
            key: const ValueKey('path-more-go'),
            label: context.l10n.pathMoreGo,
            ink: ink,
            ground: style.color,
            onTap: () => requirePlus(context, app, () {
              // Back through the plans with Astute+: the rest of the path,
              // where the free cards left it.
              final NavigatorState nav = Navigator.of(context);
              nav.pop();
              openPath(nav.context, app, path, from: kPathFree);
            }, source: 'paths'),
          ),
        ],
      ),
    );
  }
}

/// A full-width button in the subject's ink on its colour.
class _InkButton extends StatelessWidget {
  const _InkButton({
    super.key,
    required this.label,
    required this.ink,
    required this.ground,
    required this.onTap,
  });

  final String label;
  final Color ink;
  final Color ground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 16,
              weight: FontWeight.w700,
              color: ground,
            ),
          ),
        ),
      ),
    );
  }
}

/// One path: its subject's colour and mark, its name, its ten, and how far
/// the reader has gone in it.
class _PathTile extends StatelessWidget {
  const _PathTile({
    required this.path,
    required this.read,
    required this.locked,
    required this.onTap,
  });

  final CardPath path;
  final int read;
  final bool locked;
  final VoidCallback onTap;

  static const double height = 196;
  static const double width = 150;

  @override
  Widget build(BuildContext context) {
    final TopicStyle style = kTopics[path.topicKey]!;
    final Color ink = style.ink;
    return Semantics(
      button: true,
      label: [
        path.genre.label,
        context.l10n.nCards(path.cards.length),
        if (locked) context.l10n.pathFree(kPathFree),
      ].join(', '),
      child: GestureDetector(
        key: ValueKey('path-${path.genre.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: style.color,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SubjectIcon(subject: style.name, size: 18, ink: ink),
                  const Spacer(),
                  if (locked) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        context.l10n.pathFree(kPathFree),
                        style: AppText.label(
                          size: 9.5,
                          weight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.lock_rounded,
                      size: 15,
                      color: ink.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                path.genre.label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(
                  size: 19,
                  weight: FontWeight.w700,
                  height: 1.08,
                  spacing: -0.4,
                  color: ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.subjectOf(style.name).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  size: 9.5,
                  weight: FontWeight.w700,
                  spacing: 1.1,
                  color: ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              // Ten steps, the read ones filled: the path at a glance.
              Row(
                children: [
                  for (int i = 0; i < path.cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: ink.withValues(
                            alpha: i < read
                                ? 0.9
                                : locked && i >= kPathFree
                                ? 0.12
                                : 0.22,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
