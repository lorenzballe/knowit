/// Explore's latest news as a front page: the lead story on a panel of its
/// own, the rest under it as a list, each a headline, two lines under it and
/// the outlets that report it, named and counted. A tap opens the story's
/// page (news_story_page.dart). Black and quiet: the only colour is each
/// story's subject, in the dot that files it.
library;

import 'package:flutter/material.dart';

import '../../models/pill.dart';
import '../../theme.dart';
import 'news_parts.dart';

class NewsFront extends StatefulWidget {
  const NewsFront({
    super.key,
    required this.stories,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  /// The stories, the lead first.
  final List<Pill> stories;

  /// Whether the reader has read a story: its headline is set back.
  final bool Function(Pill) isRead;

  final void Function(Pill) onOpen;

  /// Each story the front shows, once.
  final void Function(Pill)? onShown;

  @override
  State<NewsFront> createState() => _NewsFrontState();
}

class _NewsFrontState extends State<NewsFront> {
  final Set<String> _said = {};

  void _sayShown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final Pill p in widget.stories) {
        if (_said.add(p.id)) widget.onShown?.call(p);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _sayShown();
  }

  @override
  void didUpdateWidget(NewsFront old) {
    super.didUpdateWidget(old);
    _sayShown();
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final List<Pill> rest = widget.stories.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _Lead(
            pill: widget.stories.first,
            read: widget.isRead(widget.stories.first),
            onTap: () => widget.onOpen(widget.stories.first),
          ),
        ),
        for (int i = 0; i < rest.length; i++) ...[
          if (i > 0)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: p.line,
            ),
          _Row(
            pill: rest[i],
            read: widget.isRead(rest[i]),
            onTap: () => widget.onOpen(rest[i]),
          ),
        ],
      ],
    );
  }
}

/// The two lines under a headline: the story's own, or, from a paper made
/// before there were story pages, its first step.
String _summaryOf(NewsScene s) =>
    s.summary.isNotEmpty ? s.summary : s.panels.first.text;

/// The lead story, on a panel of its own.
class _Lead extends StatelessWidget {
  const _Lead({required this.pill, required this.read, required this.onTap});

  final Pill pill;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final NewsScene s = pill.scene as NewsScene;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: ValueKey('explore-${pill.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(
                  size: 25,
                  weight: FontWeight.w600,
                  height: 1.15,
                  spacing: -0.5,
                  color: read ? p.inkMuted : p.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _summaryOf(s),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 15,
                  height: 1.42,
                  color: p.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: p.line),
              const SizedBox(height: 12),
              NewsOutlets(scene: s, size: 12.5),
            ],
          ),
        ),
      ),
    );
  }
}

/// A story under the lead.
class _Row extends StatelessWidget {
  const _Row({required this.pill, required this.read, required this.onTap});

  final Pill pill;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final NewsScene s = pill.scene as NewsScene;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: ValueKey('explore-${pill.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NewsEyebrow(pill: pill, size: 10.5),
              const SizedBox(height: 9),
              Text(
                s.headline,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(
                  size: 19,
                  weight: FontWeight.w600,
                  height: 1.2,
                  spacing: -0.3,
                  color: read ? p.inkMuted : p.ink,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _summaryOf(s),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 14,
                  height: 1.4,
                  color: p.ink.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 10),
              NewsOutlets(scene: s),
            ],
          ),
        ),
      ),
    );
  }
}
