/// A path's own page (prototype A6): what it is, its ten in order, which
/// are read, which the free plan opens, and the way on.
///
/// A path is ten cards of one theme, easy before hard
/// (lib/explore/blocks/core/paths_block.dart). A theme with twenty cards or
/// more goes on in a second part, and with thirty in a third: the same
/// theme, deeper. The page says which part it is and opens the next one.
///
/// On the free plan the first two cards of every part are open, the rest
/// locked behind the plans; on Astute+ all of them. Reading is done in the
/// viewer, a card at a time, from the card tapped.
library;

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/topics.dart';
import '../explore/blocks/core/paths_block.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/move_words.dart';
import '../widgets/premium.dart';
import '../widgets/subject_icon.dart';
import '../widgets/ui.dart';

/// About how long a card takes, for the page's "about N min".
const double kMinutesPerCard = 1.5;

class CardPathScreen extends StatelessWidget {
  const CardPathScreen({super.key, required this.app, required this.path});

  final AppState app;
  final CardPath path;

  /// Opens [path]'s page, from wherever a path is shown.
  static Future<void> open(
    BuildContext context,
    AppState app,
    CardPath path, {
    required String from,
  }) {
    Analytics.capture('path page opened', {
      'genre': path.genre.id,
      'part': path.part,
      'parts': path.parts,
      'read': path.cards.where((p) => app.seenIds.contains(p.id)).length,
      'from': from,
      'is_plus': app.isPlus,
    });
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CardPathScreen(app: app, path: path),
      ),
    );
  }

  /// Opens the viewer on card [at]: on the free plan only a card it opens;
  /// any other goes through the plans first.
  void _read(BuildContext context, int at) {
    if (!app.isPlus && at >= kPathFree) {
      requirePlus(
        context,
        app,
        () => openPath(context, app, path, from: at),
        source: 'path page',
      );
      return;
    }
    openPath(context, app, path, from: at);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenView(
      name: 'path page',
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
    final TopicStyle style = kTopics[path.topicKey]!;
    final List<bool> read = [
      for (final Pill c in path.cards) app.seenIds.contains(c.id),
    ];
    final bool plus = app.isPlus;
    bool open(int i) => plus || i < kPathFree;
    // The card to go on with: the first not read that the plan opens.
    int? next;
    for (int i = 0; i < path.cards.length; i++) {
      if (!read[i] && open(i)) {
        next = i;
        break;
      }
    }
    final int done = read.where((r) => r).length;
    final CardPath? deeper = path.part < path.parts
        ? partOf(path, path.part + 1)
        : null;

    final Widget action;
    if (next != null) {
      final int at = next;
      action = ChunkyButton(
        key: const ValueKey('path-go'),
        label: done == 0 ? l.pathStart : l.pathContinueAt(at + 1),
        fill: style.color,
        ink: style.ink,
        height: 54,
        onPressed: () => _read(context, at),
      );
    } else if (!plus) {
      action = ChunkyButton(
        key: const ValueKey('path-unlock'),
        label: l.pathUnlock,
        fill: p.inverse,
        ink: p.onInverse,
        height: 54,
        onPressed: () => _read(context, kPathFree),
      );
    } else if (deeper != null) {
      action = ChunkyButton(
        key: const ValueKey('path-deeper'),
        label: l.pathNextPart(deeper.part),
        fill: style.color,
        ink: style.ink,
        height: 54,
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => CardPathScreen(app: app, path: deeper),
          ),
        ),
      );
    } else {
      action = ChunkyButton(
        key: const ValueKey('path-again'),
        label: l.pathAgain,
        fill: p.inverse,
        ink: p.onInverse,
        height: 54,
        onPressed: () => _read(context, 0),
      );
    }

    // The way on stays in sight at the foot, the ten scrolling above it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Row(
                children: [
                  BackCircle(onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.pathKicker.toUpperCase(),
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
              const SizedBox(height: 16),
              _Head(path: path, style: style, read: read),
              const SizedBox(height: 14),
              for (int i = 0; i < path.cards.length; i++)
                _Row(
                  key: ValueKey('path-card-$i'),
                  index: i,
                  pill: path.cards[i],
                  style: style,
                  read: read[i],
                  open: open(i),
                  next: i == next,
                  free: !plus && i < kPathFree,
                  onTap: () => _read(context, i),
                ),
              // The theme goes on: the next part, from here on either plan.
              if (deeper != null && (next != null || !plus)) ...[
                const SizedBox(height: 12),
                _Deeper(app: app, path: deeper, style: style),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              action,
              if (!plus) ...[
                const SizedBox(height: 8),
                Text(
                  l.pathFreeLine,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 12.5,
                    height: 1.35,
                    color: p.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The head, in the subject's colour: subject, how many cards, how long,
/// the theme's name, which part, the moves it trains, and how far along.
class _Head extends StatelessWidget {
  const _Head({required this.path, required this.style, required this.read});

  final CardPath path;
  final TopicStyle style;
  final List<bool> read;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = style.ink;
    final int minutes = (path.cards.length * kMinutesPerCard).round();
    final List<String> moves = [
      for (final Principle m in {
        for (final Pill c in path.cards)
          if (c.principle.isReal) c.principle,
      })
        moveName(l, m),
    ];
    final int done = read.where((r) => r).length;
    return Container(
      key: const ValueKey('path-head'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SubjectIcon(subject: style.name, size: 15, ink: ink),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  l
                      .pathMeta(
                        l.subjectOf(style.name),
                        path.cards.length,
                        minutes,
                      )
                      .toUpperCase(),
                  style: AppText.label(
                    size: 11,
                    weight: FontWeight.w700,
                    spacing: 1.1,
                    color: ink.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              path.genre.label,
              style: AppText.display(
                size: 30,
                weight: FontWeight.w600,
                height: 1.05,
                spacing: -0.8,
                color: ink,
              ),
            ),
          ),
          if (path.parts > 1) ...[
            const SizedBox(height: 4),
            Text(
              l.pathPartOf(path.part, path.parts),
              key: const ValueKey('path-part'),
              style: AppText.body(
                size: 14,
                weight: FontWeight.w700,
                color: ink.withValues(alpha: 0.78),
              ),
            ),
          ],
          if (moves.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l.pathTrains(moves.join(', ')),
              style: AppText.body(
                size: 14.5,
                height: 1.35,
                color: ink.withValues(alpha: 0.88),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ExcludeSemantics(
            child: Row(
              children: [
                for (int i = 0; i < read.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: read[i] ? 0.92 : 0.22),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.pathReadOf(done, read.length),
            key: const ValueKey('path-read'),
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w600,
              color: ink.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the ten: its number, its question, and whether it is read, open
/// on the free plan, or locked.
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.index,
    required this.pill,
    required this.style,
    required this.read,
    required this.open,
    required this.next,
    required this.free,
    required this.onTap,
  });

  final int index;
  final Pill pill;
  final TopicStyle style;
  final bool read;
  final bool open;

  /// The card to go on with, set apart.
  final bool next;

  /// Open on the free plan.
  final bool free;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Color text = read || !open ? p.inkMuted : p.ink;
    final Widget mark = read
        ? Icon(
            Icons.check_rounded,
            size: 18,
            color: p.ink.withValues(alpha: 0.7),
          )
        : !open
        ? Icon(Icons.lock_outline_rounded, size: 17, color: p.inkFaint)
        : free
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              l.pathFreeTag.toUpperCase(),
              style: AppText.label(
                size: 10,
                weight: FontWeight.w800,
                spacing: 0.6,
                color: style.ink,
              ),
            ),
          )
        : Icon(Icons.chevron_right_rounded, size: 20, color: p.inkFaint);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: next ? p.surfaceRaised : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: next
              ? BorderSide(
                  color: p.isDark
                      ? style.color.withValues(alpha: 0.9)
                      : p.ink.withValues(alpha: 0.8),
                  width: 1.4,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    style: AppText.display(
                      size: 19,
                      weight: FontWeight.w600,
                      color: next
                          ? (p.isDark ? style.color : p.ink)
                          : p.inkMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    pill.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 14.5,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: text,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                mark,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The next part of the theme, as a row to open.
class _Deeper extends StatelessWidget {
  const _Deeper({required this.app, required this.path, required this.style});

  final AppState app;
  final CardPath path;
  final TopicStyle style;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Material(
      color: p.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const ValueKey('path-next-part'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => CardPathScreen(app: app, path: path),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.south_rounded, size: 18, color: style.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.pathNextPart(path.part),
                      style: AppText.body(
                        size: 14.5,
                        weight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.pathDeeperLine(path.cards.length),
                      style: AppText.body(size: 12.5, color: p.inkMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
