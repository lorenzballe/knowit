import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../analytics.dart';
import '../../../data/news_paper.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// The news, reasoned: this morning's paper (lib/data/news_paper.dart), a
/// few of the day's stories cut out like clippings, each the front of a
/// news card. A tap opens the story in the deck, three taps from what
/// happened to why; one read says so.
///
/// On Explore for every subject the whole paper; on a subject's page only
/// its stories, and nothing when it has none. A paper whose cards have all
/// expired is no paper.
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
      for (final Pill p in NewsPaper.on(app.today))
        if (subject == null || p.topic == subject) p,
    ];
    if (cards.isEmpty) return null;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _Story(
                pill: cards[i],
                lead: i == 0,
                read: app.seenIds.contains(cards[i].id),
                language: host.language,
                onOpen: () {
                  Analytics.capture('news opened', {
                    'pill_id': cards[i].id,
                    'place': i,
                    'paper': NewsPaper.date,
                  });
                  host.open(section, cards, cards[i]);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One story, as a clipping: the outlet and the day on the masthead over a
/// double rule, the headline, the number that carries it when there is one,
/// the question the card answers, and the way in.
class _Story extends StatelessWidget {
  const _Story({
    required this.pill,
    required this.lead,
    required this.read,
    required this.language,
    required this.onOpen,
  });

  final Pill pill;

  /// The first story, set larger, with its number.
  final bool lead;
  final bool read;
  final String language;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final Object? scene = pill.scene;
    final NewsScene? news = scene is NewsScene ? scene : null;
    final String headline = news?.headline ?? pill.question;
    final String figure = lead && news != null && news.panels.isNotEmpty
        ? news.panels.first.figure
        : '';
    String day() {
      if (news == null) return '';
      try {
        return DateFormat.MMMd(language).format(news.date);
      } catch (_) {
        return DateFormat.MMMd('en').format(news.date);
      }
    }

    // The subject's colour, darkened on paper when it is too light to read
    // there (a yellow, a mint).
    final Color hue =
        Theme.of(context).brightness == Brightness.light &&
            pill.color.computeLuminance() > 0.35
        ? Color.lerp(pill.color, p.ink, 0.5)!
        : pill.color;
    final TextStyle mast = AppText.body(
      size: 11,
      weight: FontWeight.w800,
      spacing: 1.4,
      color: p.inkMuted,
    );
    return Semantics(
      button: true,
      label: '${news?.outlet ?? ''}. $headline',
      child: GestureDetector(
        key: ValueKey('news-${pill.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Container(
          padding: EdgeInsets.fromLTRB(18, 14, 18, lead ? 18 : 16),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              p.ink.withValues(alpha: 0.035),
              p.surfaceRaised,
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (news?.outlet ?? '').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mast,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(day().toUpperCase(), style: mast),
                ],
              ),
              const SizedBox(height: 6),
              // The masthead's double rule.
              Container(height: 1.5, color: p.ink.withValues(alpha: 0.7)),
              const SizedBox(height: 2),
              Container(height: 0.75, color: p.ink.withValues(alpha: 0.7)),
              SizedBox(height: lead ? 12 : 10),
              Text(
                headline,
                style: AppText.display(
                  size: lead ? 23 : 18.5,
                  weight: FontWeight.w600,
                  height: 1.16,
                  spacing: -0.3,
                  color: p.ink,
                ),
              ),
              SizedBox(height: lead ? 12 : 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (figure.isNotEmpty) ...[
                    Text(
                      figure,
                      style: AppText.display(
                        size: 30,
                        weight: FontWeight.w700,
                        height: 1,
                        spacing: -0.6,
                        color: hue,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      pill.question,
                      maxLines: lead ? 4 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 14,
                        height: 1.35,
                        color: p.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: pill.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      l.subjectOf(pill.topic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: p.inkMuted,
                      ),
                    ),
                  ),
                  if (read)
                    Row(
                      key: ValueKey('news-read-${pill.id}'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 16, color: p.inkMuted),
                        const SizedBox(width: 4),
                        Text(
                          l.newsRead,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w800,
                            color: p.inkMuted,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: p.inverse,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${l.newsOpen}  →',
                        style: AppText.body(
                          size: 13,
                          weight: FontWeight.w800,
                          color: p.onInverse,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
