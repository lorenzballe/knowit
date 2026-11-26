/// A story of Explore's latest news, on a page of its own: written to be
/// read, top to bottom, the way a good paper lays out one story.
///
/// Under the line that says where it is filed and how long ago, the
/// headline, two lines under it, and the outlets that report it, named and
/// counted. Then, a hairline down:
///
/// - the number the story turns on, large, in its subject's colour, when it
///   has one and is not the world desk's (a death toll is never set large);
/// - the key points, what to know, the most important first;
/// - behind the news: the question the story raises and its answer, the
///   reasoning that is Astute's own;
/// - both sides, when it is contested, each in its own words and alike;
/// - what it means, or the time it happened before;
/// - what to keep, and a question to ask yourself, as the cards end;
/// - the reports it was made from, each opened in the browser, and a line
///   on how it was written.
///
/// The way back is part of the page, as Instagram's is: it goes up and away
/// with the story, and comes straight back the moment the reader goes back
/// up ([QuickReturn]). On iOS 26 it is Apple's own glass button, a native
/// view, laid over the page and never inside what scrolls.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/news_paper.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../quick_return.dart';
import '../ui.dart' show BackCircle;
import 'news_parts.dart';

/// How a report is opened. Tests replace it.
typedef OpenLink = Future<void> Function(Uri link);

class NewsStoryPage extends StatelessWidget {
  const NewsStoryPage({super.key, required this.pill, this.openLink});

  final Pill pill;

  /// How a report is opened: the browser inside the app where there is one.
  final OpenLink? openLink;

  /// [pill]'s page, over whatever is showing.
  static Future<void> open(BuildContext context, Pill pill) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => NewsStoryPage(pill: pill)));

  static Future<void> _launch(Uri link) async {
    try {
      if (await launchUrl(link, mode: LaunchMode.inAppBrowserView)) return;
    } catch (_) {
      // No browser inside the app here: the phone's own.
    }
    await launchUrl(link, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final double bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        bottom: false,
        child: QuickReturn(
          ground: p.surface,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Row(
              children: [
                BackCircle(onPressed: () => Navigator.of(context).maybePop()),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  key: ValueKey('news-story-${pill.id}'),
                  // Under the way back, as tall as it stands.
                  padding: EdgeInsets.fromLTRB(0, 6 + 44 + 18, 0, bottom + 48),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: _Story(
                          pill: pill,
                          openLink: openLink ?? _launch,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // What scrolls up goes out of sight softly at the top of the
              // page, not cut at a line, once the way back has gone with it.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 18,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [p.surface, p.surface.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.pill, required this.openLink});

  final Pill pill;
  final OpenLink openLink;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final NewsScene s = pill.scene as NewsScene;
    final NewsDesk desk = NewsDesk.of(context, pill);
    final List<String> outlets = s.outlets;
    final NewsPanel lead = s.panels.first;
    // The number the story turns on, set large: not for the world desk,
    // whose numbers are too often of the dead, nor for a story whose card
    // needs no number.
    final bool figure =
        lead.hasFigure && !NewsPaper.isWorld(pill) && pill.numeracy > 0;
    final String summary = s.summary.isNotEmpty ? s.summary : lead.text;
    final NewsPanel? meaning = s.then == null && s.panels.length > 2
        ? s.panels[2]
        : null;

    final TextStyle body = AppText.body(
      size: 16.5,
      height: 1.52,
      color: p.ink.withValues(alpha: 0.9),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NewsEyebrow(pill: pill, size: 11.5),
        const SizedBox(height: 14),
        Text(
          s.headline,
          style: AppText.display(
            size: 30,
            weight: FontWeight.w600,
            height: 1.13,
            spacing: -0.7,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          summary,
          style: AppText.body(
            size: 17.5,
            height: 1.45,
            color: p.ink.withValues(alpha: 0.74),
          ),
        ),
        const SizedBox(height: 20),
        _Label(l.newsOutlets(outlets.length)),
        const SizedBox(height: 6),
        Text(
          outlets.map(unbroken).join('  ·  '),
          style: AppText.body(size: 14, height: 1.5, color: p.inkMuted),
        ),
        const SizedBox(height: 26),
        Container(height: 1, color: p.line),
        if (figure) ...[
          const SizedBox(height: 26),
          _Figure(panel: lead, color: desk.color),
        ],
        if (s.points.isNotEmpty) ...[
          const _Gap(),
          _Label(l.newsKeyPoints),
          const SizedBox(height: 12),
          for (final String point in s.points)
            _Point(text: point, color: desk.color, style: body),
        ],
        const _Gap(),
        _Label(l.newsBehind),
        const SizedBox(height: 12),
        Text(
          pill.question,
          style: AppText.display(
            size: 21,
            weight: FontWeight.w500,
            height: 1.28,
            spacing: -0.3,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(pill.answer, style: body),
        if (s.sides.length == 2) ...[
          const _Gap(),
          _Label(l.deeperSides),
          const SizedBox(height: 14),
          for (final NewsSide side in s.sides) _Side(side: side, style: body),
        ],
        if (s.then case final NewsThen then) ...[
          const _Gap(),
          _Label(then.label),
          const SizedBox(height: 12),
          _Then(then: then, color: desk.color),
        ] else if (meaning != null) ...[
          const _Gap(),
          _Label(meaning.label),
          const SizedBox(height: 10),
          Text(meaning.text, style: body),
        ],
        const _Gap(),
        _Keep(move: pill.barMove, ask: pill.ask),
        if (s.sources.isNotEmpty) ...[
          const _Gap(),
          _Label(l.newsSources),
          const SizedBox(height: 6),
          for (final NewsSource source in s.sources)
            _Source(source: source, onTap: () => openLink(source.link)),
        ],
        const SizedBox(height: 22),
        Text(
          l.newsMadeFrom,
          style: AppText.body(size: 12.5, height: 1.45, color: p.inkFaint),
        ),
      ],
    );
  }
}

/// The room between two parts of the story.
class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 34);
}

/// A part's name, in small capitals.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppText.label(size: 11.5, spacing: 1.2, color: context.p.inkFaint),
  );
}

/// The number the story turns on, and what it is: the first sentence of
/// its step, as the key points under it go on with the rest.
class _Figure extends StatelessWidget {
  const _Figure({required this.panel, required this.color});

  final NewsPanel panel;
  final Color color;

  static final RegExp _sentence = RegExp(r'^(.+?[.!?])(?=\s|$)');

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String what =
        _sentence.firstMatch(panel.text)?.group(1) ?? panel.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            panel.figure,
            maxLines: 1,
            style: AppText.display(
              size: 56,
              weight: FontWeight.w600,
              height: 1,
              spacing: -1.6,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          what,
          style: AppText.body(
            size: 15.5,
            height: 1.45,
            color: p.ink.withValues(alpha: 0.74),
          ),
        ),
      ],
    );
  }
}

/// One of the key points.
class _Point extends StatelessWidget {
  const _Point({required this.text, required this.color, required this.style});

  final String text;
  final Color color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final double line = (style.fontSize ?? 16) * (style.height ?? 1.5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            height: line,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

/// One side of a contested story: who holds it, and their view, each side
/// drawn alike.
class _Side extends StatelessWidget {
  const _Side({required this.side, required this.style});

  final NewsSide side;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: p.lineStrong, width: 2)),
        ),
        padding: const EdgeInsets.only(left: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              side.who,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w700,
                height: 1.3,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(side.view, style: style),
          ],
        ),
      ),
    );
  }
}

/// The time it happened before: its year, large, beside that time's news.
class _Then extends StatelessWidget {
  const _Then({required this.then, required this.color});

  final NewsThen then;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${then.year}',
          style: AppText.display(
            size: 34,
            weight: FontWeight.w600,
            height: 1,
            spacing: -0.8,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                then.headline,
                style: AppText.display(
                  size: 18,
                  weight: FontWeight.w600,
                  height: 1.25,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                then.line,
                style: AppText.body(
                  size: 15.5,
                  height: 1.45,
                  color: p.ink.withValues(alpha: 0.74),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What to keep, and a question to ask yourself: how the cards end.
class _Keep extends StatelessWidget {
  const _Keep({required this.move, required this.ask});

  final String move;
  final String ask;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Label(l.barMoveCaps),
          const SizedBox(height: 10),
          Text(
            move,
            style: AppText.display(
              size: 20,
              weight: FontWeight.w500,
              height: 1.3,
              spacing: -0.2,
              color: p.ink,
            ),
          ),
          if (ask.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(height: 1, color: p.line),
            const SizedBox(height: 16),
            _Label(l.askYourselfCaps),
            const SizedBox(height: 8),
            Text(
              ask,
              style: AppText.body(
                size: 15.5,
                height: 1.45,
                color: p.ink.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One report the story was made from: its outlet over its own headline,
/// opened in the browser.
class _Source extends StatelessWidget {
  const _Source({required this.source, required this.onTap});

  final NewsSource source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Semantics(
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.outlet,
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w700,
                        height: 1.3,
                        color: p.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      source.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 15,
                        height: 1.38,
                        color: p.ink.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: p.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
