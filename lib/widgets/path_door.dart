/// The path a card belongs to, under the card when it is read from Explore
/// (prototype A5, "a card answered, and the path it belongs to"): its
/// theme, where the card sits in its path, and the way on to the path's
/// next card. A card that is in no path has no door.
library;

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/genre_names.dart';
import '../data/genres.dart';
import '../data/pill_bank.dart';
import '../data/topics.dart';
import '../explore/blocks/core/paths_block.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../screens/card_path_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'subject_icon.dart';

/// The part of a path [pill] is in, and where in it: null for a card in no
/// path (a theme of fewer than ten cards, or past its last whole ten).
({CardPath path, int at})? pathOfCard(Pill pill) {
  final Genre? genre = genreById(pill.genre);
  final String? key = topicKeyForName(pill.topic);
  if (genre == null || key == null) return null;
  for (final CardPath part in partsOf(genre, key, PillBank.live)) {
    final int at = part.cards.indexWhere((c) => c.id == pill.id);
    if (at >= 0) return (path: part, at: at);
  }
  return null;
}

/// The door: a pill under the card.
class PathDoor extends StatelessWidget {
  const PathDoor({super.key, required this.app, required this.pill});

  final AppState app;
  final Pill pill;

  /// Goes on with [path] after card [at]: at the next card not read, or,
  /// where that card is past what the free plan opens, or every card is
  /// read, on the path's own page.
  void _open(BuildContext context, CardPath path, int at) {
    final Set<String> read = app.seenIds;
    int next = -1;
    for (int i = at + 1; i < path.cards.length; i++) {
      if (!read.contains(path.cards[i].id)) {
        next = i;
        break;
      }
    }
    if (next < 0) next = path.cards.indexWhere((c) => !read.contains(c.id));
    final bool page = next < 0 || (!app.isPlus && next >= kPathFree);
    Analytics.capture('path door opened', {
      'genre': path.genre.id,
      'part': path.part,
      'at': at,
      'next': next,
      'to': page ? 'page' : 'card',
      'is_plus': app.isPlus,
    });
    if (page) {
      CardPathScreen.open(context, app, path, from: 'card');
      return;
    }
    openPath(context, app, path, from: next);
  }

  @override
  Widget build(BuildContext context) {
    final ({CardPath path, int at})? where = pathOfCard(pill);
    if (where == null) return const SizedBox.shrink();
    final l = context.l10n;
    final Palette p = context.p;
    final CardPath path = where.path;
    final TopicStyle style = kTopics[path.topicKey]!;
    final Color tint = p.isDark ? style.color : style.ink;
    final String theme = l.themeOf(path.genre);
    final String place = '${where.at + 1}/${path.cards.length}';
    return Semantics(
      button: true,
      label:
          '$theme, ${l.pathCardOf(where.at + 1, path.cards.length)}. '
          '${l.pathDoorNext}',
      excludeSemantics: true,
      child: Material(
        color: p.surfaceRaised,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _open(context, path, where.at),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
            // Smaller rather than cut or spilling: at a large text size a
            // long theme and the way on are wider than the screen.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SubjectIcon(subject: style.name, size: 14, ink: tint),
                  const SizedBox(width: 8),
                  Text(
                    '$theme · $place',
                    maxLines: 1,
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l.pathDoorNext,
                    maxLines: 1,
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: p.link,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: p.link),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
