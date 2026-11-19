/// A subject's own home, from Your journey (prototype D3): how far into it
/// the reader is, their level in it and what the next level asks, the card
/// to read next a step above where they are, and every theme inside it with
/// how much of it is read.
///
/// The level is the one Explore shows (SubjectLevel, 1 to 10, from the
/// cards read and the answers right), so the two never disagree.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/genre_names.dart';
import '../data/genres.dart';
import '../data/pill_bank.dart';
import '../data/pills_repository.dart' show dateKey;
import '../data/topics.dart';
import '../explore/blocks/core/paths_block.dart';
import '../explore/blocks/core/subject_levels_block.dart' show SubjectLevel;
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../models/place.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/subject_icon.dart';
import '../widgets/ui.dart';
import 'card_path_screen.dart';
import 'deck_viewer_screen.dart';

/// What the subject's home shows, counted.
class SubjectHome {
  const SubjectHome({
    required this.key,
    required this.total,
    required this.level,
    required this.answered,
    required this.next,
    required this.themes,
  });

  final String key;

  /// The cards of the subject a reader can be dealt.
  final int total;

  /// Read, right, and the level they come to.
  final SubjectLevel level;

  /// The cards of it the reader has answered, right or wrong.
  final int answered;

  /// The card to read next: unread, one step above where the reader is.
  final Pill? next;

  /// Every theme of the subject with cards: the theme, its cards, how many
  /// of them are read.
  final List<({Genre genre, List<Pill> cards, int read})> themes;

  /// Points a new card answered right brings: one for reading it, two for
  /// the answer (SubjectLevel.points).
  static const int pointsPerRight = 3;

  /// Right answers, on new cards, from the next level; 0 at the top.
  int get rightToNext {
    final int n = level.level;
    if (n >= 10) return 0;
    final int need = SubjectLevel.pointsFor(n + 1) - level.points;
    return (need / pointsPerRight).ceil().clamp(1, 9999);
  }
}

/// Counts [key]'s home for the reader of [app].
SubjectHome subjectHomeOf(AppState app, String key) {
  final TopicStyle style = kTopics[key]!;
  final Place? home = app.place;
  final List<Pill> cards = [
    for (final Pill p in PillBank.live)
      if (p.topic == style.name &&
          p.book == null &&
          (p.place == null || placeFit(p.place!, home) != PlaceFit.none))
        p,
  ];
  int read = 0;
  int right = 0;
  int answered = 0;
  for (final Pill p in cards) {
    if (app.seenIds.contains(p.id)) read++;
    final String? said = app.answers[p.id]?.response;
    if (said == null) continue;
    answered++;
    if (p.isGraded && p.challenge.accepts(said)) right++;
  }
  // A step above where the reader is: medium for one starting out, hard
  // for one getting there or strong; a card that asks, the day's pick.
  final int dealt = app.dealtLevels[key] ?? 1;
  final Difficulty step = dealt <= 0 ? Difficulty.medium : Difficulty.hard;
  final List<Pill> fresh = [
    for (final Pill p in cards)
      if (!app.seenIds.contains(p.id) && p.asksSomething) p,
  ]..sort((a, b) => a.id.compareTo(b.id));
  fresh.shuffle(math.Random(dateKey(app.today).hashCode ^ key.hashCode));
  final Pill? next =
      fresh.where((p) => p.difficulty == step).firstOrNull ?? fresh.firstOrNull;
  final Map<String, List<Pill>> byGenre = {};
  for (final Pill p in cards) {
    if (p.genre.isEmpty) continue;
    byGenre.putIfAbsent(p.genre, () => []).add(p);
  }
  final List<({Genre genre, List<Pill> cards, int read})> themes = [
    for (final Genre g in kGenres[key] ?? const <Genre>[])
      if (byGenre[g.id] case final List<Pill> of when of.isNotEmpty)
        (
          genre: g,
          cards: of,
          read: of.where((p) => app.seenIds.contains(p.id)).length,
        ),
  ];
  return SubjectHome(
    key: key,
    total: cards.length,
    level: SubjectLevel(key: key, read: read, right: right),
    answered: answered,
    next: next,
    themes: themes,
  );
}

class SubjectHomeScreen extends StatelessWidget {
  const SubjectHomeScreen({
    super.key,
    required this.app,
    required this.topicKey,
  });

  final AppState app;
  final String topicKey;

  static Future<void> open(
    BuildContext context,
    AppState app,
    String key, {
    required String from,
  }) {
    Analytics.capture('subject home opened', {
      'subject': key,
      'from': from,
      'is_plus': app.isPlus,
    });
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectHomeScreen(app: app, topicKey: key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenView(
      name: 'subject home',
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

  void _openCards(
    BuildContext context,
    List<Pill> deck,
    int at,
    String title,
    String source,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeckViewerScreen(
          app: app,
          deck: deck,
          title: title,
          initialIndex: at,
          countsAsRead: true,
          source: source,
        ),
      ),
    );
  }

  Widget _page(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final TopicStyle style = kTopics[topicKey]!;
    final SubjectHome home = subjectHomeOf(app, topicKey);
    final String name = l.subjectOf(style.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The way back stays put above what scrolls: Apple's glass is a layer
        // over the page, and a native button inside a scrolling list is drawn
        // away from its place.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              BackCircle(onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.subjectKicker.toUpperCase(),
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
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _Head(home: home, style: style, name: name),
              if (home.next case final Pill next) ...[
                const SizedBox(height: 26),
                Text(
                  l.subjectNext,
                  style: AppText.display(
                    size: 22,
                    weight: FontWeight.w600,
                    spacing: -0.5,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.subjectNextLine,
                  style: AppText.body(size: 13.5, color: p.inkMuted),
                ),
                const SizedBox(height: 12),
                _NextCard(
                  pill: next,
                  style: style,
                  onTap: () {
                    Analytics.capture('subject next opened', {
                      'subject': topicKey,
                    });
                    _openCards(context, [next], 0, name, 'subject next');
                  },
                ),
              ],
              if (home.themes.isNotEmpty) ...[
                const SizedBox(height: 26),
                Text(
                  l.subjectInside(name),
                  style: AppText.display(
                    size: 22,
                    weight: FontWeight.w600,
                    spacing: -0.5,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 12),
                for (final t in home.themes)
                  _Theme(
                    key: ValueKey('subject-theme-${t.genre.id}'),
                    label: context.l10n.themeOf(t.genre),
                    read: t.read,
                    total: t.cards.length,
                    style: style,
                    onTap: () {
                      final List<CardPath> parts = partsOf(
                        t.genre,
                        topicKey,
                        PillBank.live,
                      );
                      if (parts.isNotEmpty) {
                        CardPathScreen.open(
                          context,
                          app,
                          currentPart(parts, app.seenIds),
                          from: 'subject',
                        );
                        return;
                      }
                      final List<Pill> unread = [
                        ...t.cards.where((c) => !app.seenIds.contains(c.id)),
                        ...t.cards.where((c) => app.seenIds.contains(c.id)),
                      ];
                      _openCards(
                        context,
                        unread,
                        0,
                        context.l10n.themeOf(t.genre),
                        'subject theme',
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The head, in the subject's colour: its name, how much is read, the level
/// in a ring, and what the next level asks.
class _Head extends StatelessWidget {
  const _Head({required this.home, required this.style, required this.name});

  final SubjectHome home;
  final TopicStyle style;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = style.ink;
    final SubjectLevel level = home.level;
    final int toNext = home.rightToNext;
    return Container(
      key: const ValueKey('subject-head'),
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SubjectIcon(subject: style.name, size: 18, ink: ink),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Semantics(
                            header: true,
                            child: Text(
                              name,
                              style: AppText.display(
                                size: 30,
                                weight: FontWeight.w600,
                                height: 1.05,
                                spacing: -0.8,
                                color: ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.subjectReadOf(level.read, home.total),
                      key: const ValueKey('subject-read'),
                      style: AppText.body(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: ink.withValues(alpha: 0.82),
                      ),
                    ),
                    if (home.answered > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        l.subjectRight(level.right, home.answered),
                        style: AppText.body(
                          size: 13.5,
                          color: ink.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Ring(level: level, ink: ink),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: home.total == 0 ? 0 : level.read / home.total,
              minHeight: 8,
              backgroundColor: ink.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation(ink),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            level.level >= 10
                ? l.topLevel
                : l.subjectToNext(toNext, level.level + 1),
            key: const ValueKey('subject-next-level'),
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w700,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// The level, in a ring that fills toward the next.
class _Ring extends StatelessWidget {
  const _Ring({required this.level, required this.ink});

  final SubjectLevel level;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      label: l.journeyLevelOf(level.level, 10),
      excludeSemantics: true,
      child: SizedBox(
        key: const ValueKey('subject-ring'),
        width: 72,
        height: 72,
        child: CustomPaint(
          painter: _RingPainter(progress: level.toNext, ink: ink),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${level.level}',
                  style: AppText.display(
                    size: 26,
                    weight: FontWeight.w600,
                    height: 1,
                    color: ink,
                  ),
                ),
                Text(
                  l.subjectLevel.toUpperCase(),
                  style: AppText.label(
                    size: 8.5,
                    weight: FontWeight.w800,
                    spacing: 0.8,
                    color: ink.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.ink});

  final double progress;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2 - 4;
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = ink.withValues(alpha: 0.18);
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = ink;
    canvas.drawCircle(c, r, track);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.02, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.ink != ink;
}

/// The card to read next, framed in the subject's colour.
class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.pill,
    required this.style,
    required this.onTap,
  });

  final Pill pill;
  final TopicStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Material(
      key: const ValueKey('subject-next'),
      color: p.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: style.color, width: 1.6),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.themeById(pill.genre).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        size: 10.5,
                        weight: FontWeight.w700,
                        spacing: 1.1,
                        color: p.isDark
                            ? style.color
                            : p.ink.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: style.color,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      l.difficultyLabel(pill.difficulty.name).toUpperCase(),
                      style: AppText.label(
                        size: 9.5,
                        weight: FontWeight.w800,
                        spacing: 0.6,
                        color: style.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                pill.question,
                style: AppText.display(
                  size: 21,
                  weight: FontWeight.w600,
                  height: 1.15,
                  spacing: -0.4,
                  color: p.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A theme of the subject: its name, how much of it is read, as a bar.
class _Theme extends StatelessWidget {
  const _Theme({
    super.key,
    required this.label,
    required this.read,
    required this.total,
    required this.style,
    required this.onTap,
  });

  final String label;
  final int read;
  final int total;
  final TopicStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: AppText.body(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.nOfM(read, total),
                      style: AppText.body(size: 12.5, color: p.inkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : read / total,
                    minHeight: 5,
                    backgroundColor: p.ink.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(style.color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
