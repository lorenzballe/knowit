import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../data/news_paper.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/news/news_front.dart';
import '../../../widgets/news/news_story_page.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// The latest news, reasoned (lib/data/news_paper.dart): set as a paper sets
/// its front page (lib/widgets/news/news_front.dart), the lead story on a
/// panel of its own and the rest listed under it, each a headline, two lines
/// under it and the outlets that report it; a tap opens the story's page
/// (lib/widgets/news/news_story_page.dart), which counts it as read.
///
/// On Explore for every subject, the newest paper's front page: the world's
/// most important stories of the morning ([NewsPaper.front]). On a
/// subject's page, the subject's own stories of the week
/// ([NewsPaper.ofSubject]). No story, no section: never an empty one.
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
    final String? subject = host.subject;
    final List<Pill> stories = subject == null
        ? NewsPaper.front()
        : NewsPaper.ofSubject(subject);
    if (stories.isEmpty) return null;
    final DateTime paper = (stories.first.scene as NewsScene).date;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      // The day of the paper, as a paper dates its front.
      trailing: Text(
        MaterialLocalizations.of(context)
            .formatShortMonthDay(paper)
            .toUpperCase(),
        style: AppText.label(size: 11, spacing: 1.1, color: context.p.inkFaint),
      ),
      child: NewsFront(
        stories: stories,
        isRead: host.isRead,
        onShown: (pill) => host.seen(section, pill),
        onOpen: (pill) {
          Analytics.capture('news opened', {
            'pill_id': pill.id,
            'place': stories.indexOf(pill),
            'paper': NewsPaper.date,
          });
          host.app.markReadElsewhere(pill.id);
          NewsStoryPage.open(context, pill);
        },
      ),
    );
  }
}
