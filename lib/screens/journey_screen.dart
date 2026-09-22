import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/genres.dart';
import '../data/pill_bank.dart';
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/progress.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/premium.dart';
import '../widgets/share_day.dart';
import '../widgets/subject_icon.dart';
import '../widgets/ui.dart';
import 'deck_viewer_screen.dart';
import 'path_screen.dart';
import 'week_screen.dart';
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

  /// The subject open to its strands, if one is.
  String? _openSubject;

  AppState get app => widget.app;

  /// What there is to say tonight: cards already read that carry a line to
  /// bring them up with. Not said yet first, then the ones the reader
  /// liked or kept, then the rest — and the order never moves under them.
  List<Pill> get _sayable {
    final read = PillBank.cards
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

    return ScreenView(
      name: 'journey',
      child: Scaffold(
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
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      children: [
                        _Score(app: app),
                        const SizedBox(height: 20),
                        _Week(app: app),
                        const SizedBox(height: 20),
                        _Level(app: app),
                        const SizedBox(height: 18),
                        _Tiles(app: app),
                        const SizedBox(height: 18),
                        if (app.seenIds.length >= _IsAbout.kWorthSaying) ...[
                          _IsAbout(app: app),
                          const SizedBox(height: 18),
                        ],
                        _BySubject(
                          app: app,
                          open: _openSubject,
                          onToggle: (key) => setState(() {
                            _openSubject = _openSubject == key ? null : key;
                          }),
                          onChanged: () => setState(() {}),
                        ),
                        // Under what has been read, what stayed: the only
                        // number on the page that measures memory rather
                        // than reading, and the second thing Astute+ is.
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Eyebrow(l.whatStays),
                            const Spacer(),
                            PlusLock(locked: !app.isPlus),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _Memory(app: app, onChanged: () => setState(() {})),
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
      ),
    );
  }
}

/// The record as one number, set large, with the bar that says where it
/// came from. A score nobody can see the parts of is a number to distrust.
class _Score extends StatelessWidget {
  const _Score({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final Score score = app.score;
    final int today = app.pointsToday;
    final String locale = Localizations.localeOf(context).toString();
    final NumberFormat number = NumberFormat.decimalPattern(locale);

    // Held first: it is worth the most and it is the part that fails.
    final parts = <(int, Color, String)>[
      (score.fromHeld, ink, l.nStillWithYou(score.held)),
      (score.fromRead, ink.withValues(alpha: 0.22), l.nRead(score.read)),
      (score.fromMoves, context.p.link, l.nMoves(score.moves)),
      (score.fromWeeks, ink.withValues(alpha: 0.5), l.nWeeksKept(score.weeks)),
    ];
    final int total = score.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              number.format(total),
              key: const ValueKey('journey-score'),
              style: AppText.display(
                size: 64,
                weight: FontWeight.w600,
                height: 1,
                spacing: -3,
                color: ink,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                l.pts,
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w600,
                  color: ink.withValues(alpha: 0.45),
                ),
              ),
            ),
            if (today > 0)
              Text(
                l.plusNToday(today),
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: ink.withValues(alpha: 0.45),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (total > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (final part in parts)
                    if (part.$1 > 0)
                      Expanded(
                        flex: part.$1,
                        child: Container(color: part.$2),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final part in parts)
                if (part.$1 > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: part.$2,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        part.$3,
                        style: AppText.body(
                          size: 11.5,
                          weight: FontWeight.w500,
                          color: ink.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ] else
          Text(
            l.scoreStartsToday,
            style: AppText.body(
              size: 12.5,
              height: 1.35,
              color: ink.withValues(alpha: 0.45),
            ),
          ),
      ],
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

/// The week: seven bars and how many were kept, under the score and above
/// the level — the day is too close to see a direction from, and the level
/// too far. Tapping opens the week read back in full.
class _Week extends StatelessWidget {
  const _Week({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final WeekReport week = app.thisWeek;

    return Semantics(
      button: true,
      key: const ValueKey('journey-week'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (routeContext) => WeekScreen(
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
                    l.yourWeek,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l.nOfSeven(week.days),
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: ink.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            WeekStrip(week: app.weekCompletion(), barHeight: 26),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    week.empty
                        ? l.nothingThisWeekYet
                        : week.kept
                        ? l.keptDaysOfSeven(week.days)
                        : l.daysOfSevenFiveKeeps(week.days),
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
  const _BySubject({
    required this.app,
    required this.open,
    required this.onToggle,
    required this.onChanged,
  });

  final AppState app;

  /// The subject open to its strands, by topic key, if one is.
  final String? open;
  final ValueChanged<String> onToggle;

  /// Something changed under the page — the trial started from a lock
  /// inside it — and the page should look again.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;

    final total = <String, int>{};
    final read = <String, int>{};
    for (final pill in PillBank.cards) {
      total[pill.topic] = (total[pill.topic] ?? 0) + 1;
      if (app.seenIds.contains(pill.id)) {
        read[pill.topic] = (read[pill.topic] ?? 0) + 1;
      }
    }
    final rows = kTopicOrder
        .where((key) => (total[kTopics[key]!.name] ?? 0) > 0)
        .toList();
    double share(String key) {
      final String name = kTopics[key]!.name;
      return (read[name] ?? 0) / (total[name] ?? 1).clamp(1, 1 << 30);
    }

    rows.sort((a, b) {
      final byShare = share(b).compareTo(share(a));
      if (byShare != 0) return byShare;
      return (read[kTopics[b]!.name] ?? 0).compareTo(
        read[kTopics[a]!.name] ?? 0,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Both ends give way: a long translation of either wraps or
        // trails off rather than pushing the row past its edge.
        Row(
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Eyebrow(l.bySubject)),
                  PlusLock(locked: !app.isPlus),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l.readOfTheShelf,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppText.body(
                  size: 10.5,
                  weight: FontWeight.w500,
                  color: ink.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        for (final key in rows)
          _SubjectRow(
            key: ValueKey('subject-$key'),
            app: app,
            topicKey: key,
            style: kTopics[key]!,
            read: read[kTopics[key]!.name] ?? 0,
            of: total[kTopics[key]!.name] ?? 0,
            open: open == key,
            onToggle: () => onToggle(key),
            onChanged: onChanged,
          ),
      ],
    );
  }
}

/// One subject: its bar, and — open — the genres and strands inside it
/// with how much of each has been read, which is what Astute+ shows, and
/// the way back into the cards of it that were read, which is everybody's.
class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    super.key,
    required this.app,
    required this.topicKey,
    required this.style,
    required this.read,
    required this.of,
    required this.open,
    required this.onToggle,
    required this.onChanged,
  });

  final AppState app;
  final String topicKey;
  final TopicStyle style;
  final int read;
  final int of;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final double share = of == 0 ? 0 : read / of;
    final bool any = read > 0;
    // Thinking is not a subject and has no strands; unread, it is a row
    // and not a button.
    final List<Genre> genres = kGenres[topicKey] ?? const [];
    final bool opens = genres.isNotEmpty || any;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: opens,
          expanded: opens ? open : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: opens ? onToggle : null,
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
                    width: 18,
                    child: opens
                        ? Icon(
                            open
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 16,
                            color: ink.withValues(alpha: 0.35),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(31, 0, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (genres.isNotEmpty)
                  if (app.isPlus)
                    for (final genre in genres)
                      _GenreLines(genre: genre, seenIds: app.seenIds)
                  else
                    // The strands are behind the lock, and the lock says
                    // what it is keeping.
                    Semantics(
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => requirePlus(
                          context,
                          app,
                          onChanged,
                          source: 'strands',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 12,
                                color: ink.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  l.strandsWithPlus,
                                  style: AppText.body(
                                    size: 12,
                                    height: 1.35,
                                    color: ink.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                if (any)
                  // What was read of it, to read again.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final deck = PillBank.cards
                          .where(
                            (p) =>
                                p.topic == style.name &&
                                app.seenIds.contains(p.id),
                          )
                          .toList();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DeckViewerScreen(
                            app: app,
                            deck: deck,
                            title: style.name,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${l.nCards(read)} \u2192',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: context.p.link,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One genre's strands, each with how much of it has been read — only the
/// strands the bank has written something under, so a reader sees what is
/// there to know rather than a list of empty rooms.
class _GenreLines extends StatelessWidget {
  const _GenreLines({required this.genre, required this.seenIds});

  final Genre genre;
  final Set<String> seenIds;

  @override
  Widget build(BuildContext context) {
    final lines = <(Strand, int, int)>[];
    for (final strand in genre.strands) {
      var total = 0;
      var read = 0;
      for (final Pill pill in PillBank.cards) {
        if (!pill.strands.contains(strand.id)) continue;
        total++;
        if (seenIds.contains(pill.id)) read++;
      }
      if (total > 0) lines.add((strand, read, total));
    }
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            genre.label,
            style: AppText.body(
              size: 11.5,
              weight: FontWeight.w600,
              color: context.p.inkMuted,
            ),
          ),
          const SizedBox(height: 3),
          for (final (strand, read, total) in lines)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strand.label,
                      style: AppText.body(
                        size: 12.5,
                        color: read > 0 ? context.p.ink : context.p.inkFaint,
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.nReadOfN(read, total),
                    style: AppText.body(size: 11.5, color: context.p.inkFaint),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// What stayed: of the cards answered, how many came back, and how many
/// were still right when they did. That last number is the only one in the
/// app that measures memory rather than reading.
class _Memory extends StatelessWidget {
  const _Memory({required this.app, required this.onChanged});

  final AppState app;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!app.isPlus) {
      return PaperCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.memoryWithPlus,
              style: AppText.body(
                size: 13.5,
                height: 1.45,
                color: context.p.inkMuted,
              ),
            ),
            const SizedBox(height: 12),
            ChunkyButton(
              label: l.seeThePlans,
              height: 46,
              fill: context.p.inverse,
              ink: context.p.onInverse,
              onPressed: () =>
                  requirePlus(context, app, onChanged, source: 'memory'),
            ),
          ],
        ),
      );
    }

    // Judgements are appended, never rewritten, so a card judged twice is a
    // card that came back — and the last judgement on it is whether it
    // stayed.
    final runs = <String, List<Judgement>>{};
    for (final j in app.judgements) {
      final String? id = j.pillId;
      if (id == null) continue;
      runs.putIfAbsent(id, () => []).add(j);
    }
    final int answered = runs.length;
    final returned = runs.values.where((run) => run.length > 1).toList();
    final int kept = returned.where((run) => run.last.correct).length;

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: returned.isEmpty
          ? Text(
              l.nothingBackYet,
              style: AppText.body(
                size: 13.5,
                height: 1.45,
                color: context.p.inkMuted,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MemoryLine(
                  icon: Icons.check_circle_outline_rounded,
                  text: l.nAnswered(answered),
                ),
                const SizedBox(height: 8),
                _MemoryLine(
                  icon: Icons.replay_rounded,
                  text: l.nCameBackAgain(returned.length),
                ),
                const SizedBox(height: 8),
                _MemoryLine(
                  icon: Icons.psychology_alt_rounded,
                  text: l.nKeptOnReturn(kept),
                  strong: true,
                ),
              ],
            ),
    );
  }
}

class _MemoryLine extends StatelessWidget {
  const _MemoryLine({
    required this.icon,
    required this.text,
    this.strong = false,
  });

  final IconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: strong ? context.p.ink : context.p.inkFaint,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppText.body(
              size: 13.5,
              weight: strong ? FontWeight.w600 : FontWeight.w500,
              height: 1.35,
              color: strong ? context.p.ink : context.p.inkMuted,
            ),
          ),
        ),
      ],
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
