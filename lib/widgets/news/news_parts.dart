/// The pieces Explore's latest news is made of, on the shelf
/// (lib/explore/blocks/core/news_block.dart) and on a story's page
/// (news_story_page.dart): where a story is filed and in what colour, how
/// long ago it came out, and the line over a headline that says both.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/news_paper.dart';
import '../../data/topics.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';

/// Where a story is filed: its subject, by name and in its colour, or the
/// world desk, in the page's own ink.
class NewsDesk {
  const NewsDesk(this.name, this.color);

  final String name;
  final Color color;

  static NewsDesk of(BuildContext context, Pill pill) {
    if (NewsPaper.isWorld(pill)) {
      return NewsDesk(context.l10n.newsWorld, context.p.ink);
    }
    final String? key = topicKeyForName(pill.topic);
    final TopicStyle? style = key == null ? null : kTopics[key];
    return NewsDesk(
      key == null ? pill.topic : context.l10n.subjectName(key),
      style?.color ?? context.p.ink,
    );
  }
}

/// How long ago [scene]'s newest report came out, as the news says it: in
/// hours on the day, in days after; null when the paper did not say.
String? newsAgo(BuildContext context, NewsScene scene) {
  final DateTime? at = scene.at;
  if (at == null) return null;
  final DateTime now = NewsPaper.clock();
  final Duration since = now.difference(at);
  if (since.inHours < 24) {
    return context.l10n.newsHoursAgo(math.max(0, since.inHours));
  }
  final DateTime local = at.toLocal();
  final int days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(local.year, local.month, local.day)).inDays;
  return context.l10n.newsDaysAgo(math.max(1, days));
}

/// The line over a headline: the story's desk, in its colour, and how long
/// ago it came out, in small capitals.
class NewsEyebrow extends StatelessWidget {
  const NewsEyebrow({
    super.key,
    required this.pill,
    this.size = 11,
    this.outlets = false,
  });

  final Pill pill;
  final double size;

  /// Whether the count of outlets that report it goes on the line too.
  final bool outlets;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final NewsScene scene = pill.scene! as NewsScene;
    final NewsDesk desk = NewsDesk.of(context, pill);
    final String? ago = newsAgo(context, scene);
    final List<String> after = [
      if (outlets) context.l10n.newsOutlets(scene.outlets.length),
      ?ago,
    ];
    final TextStyle style = AppText.label(
      size: size,
      spacing: 1.1,
      height: 1.2,
      color: p.inkMuted,
    );
    return Row(
      children: [
        Container(
          width: size * 0.62,
          height: size * 0.62,
          decoration: BoxDecoration(color: desk.color, shape: BoxShape.circle),
        ),
        SizedBox(width: size * 0.62),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: desk.name.toUpperCase(),
                  style: style.copyWith(color: p.ink.withValues(alpha: 0.86)),
                ),
                for (final String part in after)
                  TextSpan(text: '  ·  ${part.toUpperCase()}'),
              ],
            ),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The outlets that report a story, counted, then named on one line: as
/// many whole names as the line holds and the rest counted, "7 outlets ·
/// BBC News, The Guardian +5". A name is never cut.
class NewsOutlets extends StatelessWidget {
  const NewsOutlets({super.key, required this.scene, this.size = 12});

  final NewsScene scene;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final List<String> names = scene.outlets;
    final TextStyle base = AppText.body(
      size: size,
      height: 1.3,
      color: p.inkFaint,
    );
    final TextStyle counted = AppText.body(
      size: size,
      weight: FontWeight.w600,
      height: 1.3,
      color: p.inkMuted,
    );
    TextSpan line(int named) => TextSpan(
      style: base,
      children: [
        TextSpan(text: context.l10n.newsOutlets(names.length), style: counted),
        TextSpan(
          text:
              '  ·  ${names.take(named).join(', ')}'
              '${named < names.length ? ' +${names.length - named}' : ''}',
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        int named = names.length;
        for (; named > 1; named--) {
          // Measured as it is drawn: inside the page's own text style,
          // whose letter spacing the line inherits. Without it the line
          // measured a few points short, and on a 430-point phone "+4"
          // gave way to "…".
          final TextPainter painter = TextPainter(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [line(named)],
            ),
            maxLines: 1,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: box.maxWidth);
          final bool fits = !painter.didExceedMaxLines;
          painter.dispose();
          if (fits) break;
        }
        return Text.rich(
          line(named),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// [name] kept whole on a line: its spaces made ones a line never breaks at.
String unbroken(String name) => name.replaceAll(' ', ' ');
