import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../data/news_paper.dart';
import '../../../models/pill.dart';
import '../../../state/app_state.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// The latest news, reasoned: the stories of the last two weeks' papers
/// (lib/data/news_paper.dart, [NewsPaper.latest]), the newest first, as a
/// shelf of cards like every other shelf on Explore: a row of tiles, each the
/// story's card in its subject's colour with its question, a tap from the
/// deck, three taps from what happened to why.
///
/// On Explore for every subject all of them; on a subject's page only its
/// own stories, and nothing when it has none. No story in the last two
/// weeks, no section.
class NewsBlock extends ExploreBlock with SectionLayout {
  const NewsBlock();

  @override
  String get name => 'news-today';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final AppState app = host.app;
    final String? subject = host.subject;
    final List<Pill> cards = [
      for (final Pill p in NewsPaper.latest(app.today))
        if (onSubject(p, subject)) p,
    ];
    if (cards.isEmpty) return null;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: TileRow(
        size: TileSize.m,
        pills: cards,
        isRead: host.isRead,
        onShown: (pill) => host.seen(section, pill),
        onOpen: (shelf, pill) {
          Analytics.capture('news opened', {
            'pill_id': pill.id,
            'place': shelf.indexOf(pill),
            'paper': NewsPaper.date,
          });
          host.open(section, shelf, pill);
        },
      ),
    );
  }
}
