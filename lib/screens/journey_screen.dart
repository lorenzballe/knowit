import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/pills_data.dart';
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/progress.dart';
import '../theme.dart';
import '../widgets/share_day.dart';
import '../widgets/subject_icon.dart';
import '../widgets/ui.dart';
import 'deck_viewer_screen.dart';
import 'path_screen.dart';
import 'progress_text.dart';

/// Your journey — artboard 83a: the numbers first, the card to say last.
///
/// Everything on it is counted from what the app already writes down. The
/// order is the argument: what the reading has come to (the level, the
/// four numbers, what it is about), then where it has gone (by subject),
/// and at the foot the one thing to do with it tonight — a card to say out
/// loud to somebody. A page of statistics that ends in an action.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key, required this.app, required this.onBack});

  final AppState app;
  final VoidCallback onBack;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  /// How far down the queue of things to say the reader has pressed.
  int _sayAt = 0;

  AppState get app => widget.app;

  /// What there is to say tonight: cards already read that carry a line to
  /// bring them up with. Not said yet first, then the ones the reader
  /// liked or kept, then the rest — and the order never moves under them.
  List<Pill> get _sayable {
    final read = kPillPool
        .where((p) => app.seenIds.contains(p.id) && p.barMove.trim().isNotEmpty)
        .toList();
    int rank(Pill p) {
      if (app.hasSaid(p.id)) return 3;
      if (app.isLiked(p.id) || app.isSaved(p.id)) return 0;
      if (app.answerFor(p.id) != null) return 1;
      return 2;
    }

    read.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.id.compareTo(b.id);
    });
    return read;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final List<Pill> sayable = _sayable;

    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  BackCircle(onPressed: widget.onBack),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.yourJourney,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(
                        size: 27,
                        weight: FontWeight.w600,
                        height: 1,
                        spacing: -0.8,
                        color: ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // The headline number, in the one place a reader looks
                  // first. Cards read: the number every other number on
                  // this page is a way of looking at.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: context.p.inverse,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l.nRead(app.seenIds.length),
                      style: AppText.body(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: context.p.onInverse,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [
                      _Level(app: app),
                      const SizedBox(height: 18),
                      _Tiles(app: app),
                      const SizedBox(height: 18),
                      if (app.seenIds.length >= _IsAbout.kWorthSaying) ...[
                        _IsAbout(app: app),
                        const SizedBox(height: 18),
                      ],
                      _BySubject(app: app),
                      if (sayable.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Eyebrow(l.toSayTonight),
                        const SizedBox(height: 8),
                        _SayCard(
                          pill: sayable[_sayAt % sayable.length],
                          held: app.hasSaid(
                            sayable[_sayAt % sayable.length].id,
                          ),
                          onAnother: () => setState(() => _sayAt++),
                          onSaid: () async {
                            HapticFeedback.mediumImpact();
                            await app.markSaid(
                              sayable[_sayAt % sayable.length].id,
                            );
                            if (mounted) setState(() => _sayAt++);
                          },
                        ),
                      ],
                      if (app.dayClosed) ...[
                        const SizedBox(height: 18),
                        Center(child: ShareDay(app: app)),
                      ],
                    ],
                  ),
                  // The list runs under the foot of the screen rather than
                  // stopping at it, so there is always a reason to scroll.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 36,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              context.p.surface.withValues(alpha: 0),
                              context.p.surface,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rung as a level: where the reader stands, what stands between them
/// and the next one, and a bar. Tapping it opens the whole path.
class _Level extends StatelessWidget {
  const _Level({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final Standing standing = app.standing;
    final Rung? next = standing.next;
    final String? step = stepText(context, standing);
    final int readToday = app.todayIndex;

    return Semantics(
      button: true,
      key: const ValueKey('journey-level'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (routeContext) => PathScreen(
              app: app,
              onBack: () => Navigator.of(routeContext).pop(),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l.levelNamed(
                      standing.at + 1,
                      rungName(context, standing.rung),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
                if (readToday > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    l.plusNToday(readToday),
                    style: AppText.body(
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: ink.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(color: ink.withValues(alpha: 0.1)),
                    FractionallySizedBox(
                      widthFactor: standing.toNext.clamp(0.02, 1.0),
                      child: Container(color: ink),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    next == null
                        ? l.topLevel
                        : (step == null
                              ? l.nextRung(rungName(context, next))
                              : l.stepThenRung(step, rungName(context, next))),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 11.5,
                      weight: FontWeight.w500,
                      height: 1.35,
                      color: ink.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: ink.withValues(alpha: 0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The four numbers, two by two.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final int answered = app.answers.length;
    final int held = app.heldCards;
    final double? gap = app.confidenceGap;
    final int moves = app.movesDown;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  value: answered == 0
                      ? '—'
                      : '${(held / answered * 100).round()}%',
                  label: answered == 0
                      ? l.stillWithYouNothing
                      : l.stillWithYouOf(held, answered),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Tile(
                  value: gap == null ? '—' : '${gap.round()}',
                  label: gap == null
                      ? l.calibrationNotMeasured
                      : l.calibrationPointsOff,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  value: '${app.liveStreak}',
                  label: l.inARowBest(app.bestStreak),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Tile(value: '$moves', label: l.movesYouCanSpot(moves)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            style: AppText.body(
              size: 26,
              weight: FontWeight.w700,
              height: 1,
              spacing: -1,
              color: ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppText.body(
              size: 10.5,
              weight: FontWeight.w500,
              height: 1.2,
              color: ink.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the pile of cards amounts to in things a person can picture. The
/// conversions are stated rather than hidden — it is "about", and the
/// eyebrow says so.
class _IsAbout extends StatelessWidget {
  const _IsAbout({required this.app});

  final AppState app;

  /// Seconds a card takes to read, for the hours line.
  static const int kSecondsACard = 40;

  /// Below this the comparison says nothing — "five cards is about zero
  /// books" is worse than not asking the question yet.
  static const int kWorthSaying = 25;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final int n = app.seenIds.length;
    final int minutes = (n * kSecondsACard / 60).round();
    final int books = (n / 50).round();
    final int hours = (n * 3 / 60).round();
    final int lectures = (n / 25).round();
    final parts = <(String, String)>[
      ('$books', l.nonFictionBooks(books)),
      ('$hours', l.hoursOfDocumentaries(hours)),
      ('$lectures', l.lectures(lectures)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(l.nCardsIsAbout(n)),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < parts.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parts[i].$1,
                          style: AppText.body(
                            size: 22,
                            weight: FontWeight.w700,
                            height: 1,
                            spacing: -0.8,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          parts[i].$2,
                          style: AppText.body(
                            size: 10.5,
                            weight: FontWeight.w500,
                            height: 1.25,
                            color: ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.inTotalACard(
            minutes < 60
                ? l.justMinutes(minutes)
                : l.hoursMinutes(minutes ~/ 60, minutes % 60),
          ),
          style: AppText.body(
            size: 11,
            height: 1.35,
            color: ink.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

/// Where the reading has actually gone, subject by subject: how much of
/// each shelf has been read, most-read first.
class _BySubject extends StatelessWidget {
  const _BySubject({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;

    final total = <String, int>{};
    final read = <String, int>{};
    for (final pill in kPillPool) {
      total[pill.topic] = (total[pill.topic] ?? 0) + 1;
      if (app.seenIds.contains(pill.id)) {
        read[pill.topic] = (read[pill.topic] ?? 0) + 1;
      }
    }
    final rows = kTopicOrder
        .map((key) => kTopics[key]!)
        .where((style) => (total[style.name] ?? 0) > 0)
        .toList();
    double share(TopicStyle s) =>
        (read[s.name] ?? 0) / (total[s.name] ?? 1).clamp(1, 1 << 30);
    rows.sort((a, b) {
      final byShare = share(b).compareTo(share(a));
      if (byShare != 0) return byShare;
      return (read[b.name] ?? 0).compareTo(read[a.name] ?? 0);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Eyebrow(l.bySubject)),
            Text(
              l.readOfTheShelf,
              style: AppText.body(
                size: 10.5,
                weight: FontWeight.w500,
                color: ink.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        for (final style in rows)
          _SubjectRow(
            app: app,
            style: style,
            read: read[style.name] ?? 0,
            of: total[style.name] ?? 0,
          ),
      ],
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.app,
    required this.style,
    required this.read,
    required this.of,
  });

  final AppState app;
  final TopicStyle style;
  final int read;
  final int of;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final double share = of == 0 ? 0 : read / of;
    final bool any = read > 0;

    // A subject that has been read opens what was read of it; one that has
    // not is a row, not a button.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: !any
          ? null
          : () {
              final deck = kPillPool
                  .where(
                    (p) => p.topic == style.name && app.seenIds.contains(p.id),
                  )
                  .toList();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DeckViewerScreen(app: app, deck: deck, title: style.name),
                ),
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            SubjectIcon(subject: style.name, size: 13, ink: style.color),
            const SizedBox(width: 10),
            SizedBox(
              width: 84,
              child: Text(
                style.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: ink.withValues(alpha: any ? 0.82 : 0.3),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  height: 7,
                  child: Stack(
                    children: [
                      Container(color: ink.withValues(alpha: 0.06)),
                      FractionallySizedBox(
                        widthFactor: share.clamp(0.0, 1.0),
                        child: Container(color: style.color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 36,
              child: Text(
                any ? '${(share * 100).round()}%' : '—',
                textAlign: TextAlign.right,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: ink.withValues(alpha: any ? 0.82 : 0.3),
                ),
              ),
            ),
            SizedBox(
              width: 26,
              child: Text(
                any ? '$read' : '',
                textAlign: TextAlign.right,
                style: AppText.body(
                  size: 10.5,
                  weight: FontWeight.w500,
                  color: ink.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card to say out loud tonight: the question, the answer, and the
/// line to bring it up with — the one thing on this page that is not a
/// number, and the only one that leaves the phone.
class _SayCard extends StatelessWidget {
  const _SayCard({
    required this.pill,
    required this.held,
    required this.onAnother,
    required this.onSaid,
  });

  final Pill pill;

  /// True once this one has been said. The card stays sayable — a good
  /// line is worth telling twice — but it says so.
  final bool held;
  final VoidCallback onAnother;
  final VoidCallback onSaid;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = pill.ink;
    final bool darkInk = ink.computeLuminance() < 0.5;
    final Color sub = ink.withValues(alpha: darkInk ? 0.6 : 0.66);
    final Color strong = ink.withValues(alpha: darkInk ? 0.8 : 0.86);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: pill.color,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SubjectIcon(subject: pill.topic, size: 14, ink: sub),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pill.topic.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 9.5,
                    weight: FontWeight.w700,
                    spacing: 1.4,
                    color: sub,
                  ),
                ),
              ),
              if (held)
                Text(
                  l.saidAlready,
                  style: AppText.body(
                    size: 10,
                    weight: FontWeight.w600,
                    color: sub,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pill.question,
            style: AppText.display(
              size: 24,
              weight: FontWeight.w600,
              height: 1.1,
              spacing: -0.9,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pill.answer,
            style: AppText.body(size: 14.5, height: 1.4, color: strong),
          ),
          const SizedBox(height: 12),
          Text(
            pill.barMove,
            style: AppText.body(
              size: 11,
              weight: FontWeight.w600,
              height: 1.3,
              color: sub,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SayButton(
                  label: l.anotherOne,
                  onTap: onAnother,
                  fill: null,
                  ink: ink,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SayButton(
                  label: l.saidIt,
                  onTap: onSaid,
                  fill: ink,
                  ink: pill.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SayButton extends StatelessWidget {
  const _SayButton({
    required this.label,
    required this.onTap,
    required this.fill,
    required this.ink,
  });

  final String label;
  final VoidCallback onTap;

  /// Null draws the outlined one, in the card's own ink.
  final Color? fill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: fill == null ? Border.all(color: ink, width: 1.5) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}
