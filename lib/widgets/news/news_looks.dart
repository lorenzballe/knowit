/// The looks Explore's latest news can take, by the section's `look`
/// (lib/explore/blocks/core/news_block.dart):
///
/// - `front`, the default: the front page (news_front.dart), the lead story
///   on a panel of its own and every other story under it, each with its
///   two lines and its outlets.
/// - `lead`: one story leads, large — its headline, why it matters and the
///   outlets that report it — and two more follow as compact rows, a
///   headline and a line of where they are filed.
/// - `pager`: one story to a card, each across the page, the next a swipe
///   away and dots under them that say how many there are: its headline,
///   its two lines, why it matters and its outlets.
///
/// Black and quiet, as the front page is: the only colour is each story's
/// subject, in the dot that files it and the rule beside why it matters.
/// Every word is the paper's own (functions/src/news.ts); a tap on a story
/// opens its page.
library;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../explore/challenges.dart' show ChallengeDots;
import 'news_parts.dart';

/// How the latest news is laid out (see the library's own words).
enum NewsLook {
  front,
  lead,
  pager;

  /// The look a section names, or the front page for one it does not, or
  /// does not know.
  static NewsLook of(String? name) => switch (name) {
    'lead' => lead,
    'pager' => pager,
    _ => front,
  };
}

/// Why a story matters, as the paper says it: its step of what it means
/// ("What it means", "What it means for you"), the card's third, which a
/// story that ends on the time it happened before has not. Null then.
String? newsWhy(NewsScene scene) =>
    scene.then == null && scene.panels.length > 2 ? scene.panels[2].text : null;

/// Says each story once, the frame after it is first shown.
mixin _SaysShown<T extends StatefulWidget> on State<T> {
  final Set<String> _said = {};

  void Function(Pill)? get onShown;

  void sayShown(Iterable<Pill> shown) {
    final List<Pill> now = shown.toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final Pill p in now) {
        if (_said.add(p.id)) onShown?.call(p);
      }
    });
  }
}

/// A story's place on the page: a tap on it opens its page.
class _Tap extends StatelessWidget {
  const _Tap({required this.pill, required this.onTap, required this.child});

  final Pill pill;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      key: ValueKey('explore-${pill.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    ),
  );
}

/// Why it matters: the heading in small capitals and the paper's line,
/// beside a rule in the colour the story is filed in.
class _Why extends StatelessWidget {
  const _Why({required this.pill, required this.text, this.size = 15.5});

  final Pill pill;
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 2,
            decoration: BoxDecoration(
              color: NewsDesk.of(context, pill).color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.newsWhyItMatters.toUpperCase(),
                  style: AppText.label(
                    size: 10.5,
                    spacing: 1.2,
                    height: 1.2,
                    color: p.inkFaint,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: AppText.body(
                    size: size,
                    height: 1.42,
                    color: p.ink.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `lead`: one story large, two more as compact rows.
class NewsLead extends StatefulWidget {
  const NewsLead({
    super.key,
    required this.stories,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  /// The stories, the lead first: the lead and the two after it are shown.
  final List<Pill> stories;

  /// Whether the reader has read a story: its headline is set back.
  final bool Function(Pill) isRead;

  final void Function(Pill) onOpen;

  /// Each story it shows, once.
  final void Function(Pill)? onShown;

  /// How many follow the lead.
  static const int rows = 2;

  @override
  State<NewsLead> createState() => _NewsLeadState();
}

class _NewsLeadState extends State<NewsLead> with _SaysShown<NewsLead> {
  @override
  void Function(Pill)? get onShown => widget.onShown;

  List<Pill> get _shown => widget.stories.take(1 + NewsLead.rows).toList();

  @override
  void initState() {
    super.initState();
    sayShown(_shown);
  }

  @override
  void didUpdateWidget(NewsLead old) {
    super.didUpdateWidget(old);
    sayShown(_shown);
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Pill lead = widget.stories.first;
    final List<Pill> rows = widget.stories.skip(1).take(NewsLead.rows).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _Tap(
            pill: lead,
            onTap: () => widget.onOpen(lead),
            child: _LeadStory(pill: lead, read: widget.isRead(lead)),
          ),
        ),
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: p.line,
            ),
          _Tap(
            pill: rows[i],
            onTap: () => widget.onOpen(rows[i]),
            child: _CompactRow(pill: rows[i], read: widget.isRead(rows[i])),
          ),
        ],
      ],
    );
  }
}

/// The lead story, on a panel of its own: where it is filed and when, its
/// headline set large, why it matters, and the outlets that report it.
class _LeadStory extends StatelessWidget {
  const _LeadStory({required this.pill, required this.read});

  final Pill pill;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final NewsScene s = pill.scene! as NewsScene;
    final String? why = newsWhy(s);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NewsEyebrow(pill: pill),
          const SizedBox(height: 12),
          Text(
            s.headline,
            style: AppText.display(
              size: 28,
              weight: FontWeight.w600,
              height: 1.12,
              spacing: -0.6,
              color: read ? p.inkMuted : p.ink,
            ),
          ),
          if (why != null) ...[
            const SizedBox(height: 16),
            _Why(pill: pill, text: why),
          ],
          const SizedBox(height: 18),
          Container(height: 1, color: p.line),
          const SizedBox(height: 12),
          NewsOutlets(scene: s, size: 12.5),
        ],
      ),
    );
  }
}

/// A story after the lead: where it is filed, how many report it and when,
/// over its headline.
class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.pill, required this.read});

  final Pill pill;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final NewsScene s = pill.scene! as NewsScene;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NewsEyebrow(pill: pill, size: 10.5, outlets: true),
          const SizedBox(height: 8),
          Text(
            s.headline,
            style: AppText.display(
              size: 18,
              weight: FontWeight.w600,
              height: 1.22,
              spacing: -0.3,
              color: read ? p.inkMuted : p.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// `pager`: a story to a card, across the page, the next a swipe away.
class NewsPager extends StatefulWidget {
  const NewsPager({
    super.key,
    required this.stories,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  /// The stories, in the paper's order.
  final List<Pill> stories;

  /// Whether the reader has read a story: its headline is set back.
  final bool Function(Pill) isRead;

  final void Function(Pill) onOpen;

  /// Each story it shows, once, as its card comes into view.
  final void Function(Pill)? onShown;

  @override
  State<NewsPager> createState() => _NewsPagerState();
}

class _NewsPagerState extends State<NewsPager> with _SaysShown<NewsPager> {
  final PageController _pages = PageController();

  @override
  void Function(Pill)? get onShown => widget.onShown;

  @override
  void initState() {
    super.initState();
    sayShown(widget.stories.take(1));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) => _pages.animateToPage(
    page,
    duration: MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 1)
        : const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );

  Widget _card(int i, {required bool fill}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: _StoryCard(
      pill: widget.stories[i],
      read: widget.isRead(widget.stories[i]),
      fill: fill,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final int count = widget.stories.length;
    if (count == 1) {
      return _Tap(
        pill: widget.stories.single,
        onTap: () => widget.onOpen(widget.stories.single),
        child: _card(0, fill: false),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Every card as tall as the tallest, so a swipe never changes the
        // height of the page under it: the cards laid out unseen give the
        // height, the pages are drawn over them.
        Stack(
          children: [
            for (int i = 0; i < count; i++)
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _card(i, fill: false),
              ),
            Positioned.fill(
              child: PageView.builder(
                key: const PageStorageKey<String>('news-pager'),
                controller: _pages,
                itemCount: count,
                onPageChanged: (i) => sayShown([widget.stories[i]]),
                itemBuilder: (context, i) => _Tap(
                  pill: widget.stories[i],
                  onTap: () => widget.onOpen(widget.stories[i]),
                  child: _card(i, fill: true),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ChallengeDots(
          controller: _pages,
          count: count,
          onPick: _go,
          name: 'news',
        ),
      ],
    );
  }
}

/// One story's card: where it is filed and when, its headline, its two
/// lines, why it matters and the outlets that report it, at its foot.
class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.pill,
    required this.read,
    required this.fill,
  });

  final Pill pill;
  final bool read;

  /// Whether it fills the height it is given, its outlets at the foot.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final NewsScene s = pill.scene! as NewsScene;
    final String? why = newsWhy(s);
    final String summary = s.summary.isNotEmpty
        ? s.summary
        : s.panels.first.text;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NewsEyebrow(pill: pill),
          const SizedBox(height: 12),
          Text(
            s.headline,
            style: AppText.display(
              size: 24,
              weight: FontWeight.w600,
              height: 1.14,
              spacing: -0.5,
              color: read ? p.inkMuted : p.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: AppText.body(
              size: 15,
              height: 1.42,
              color: p.ink.withValues(alpha: 0.7),
            ),
          ),
          if (why != null) ...[
            const SizedBox(height: 16),
            _Why(pill: pill, text: why, size: 14.5),
          ],
          const SizedBox(height: 18),
          if (fill) const Spacer(),
          Container(height: 1, color: p.line),
          const SizedBox(height: 12),
          NewsOutlets(scene: s, size: 12.5),
        ],
      ),
    );
  }
}
