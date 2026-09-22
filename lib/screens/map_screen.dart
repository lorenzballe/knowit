import 'package:flutter/material.dart';

import '../data/genres.dart';
import '../data/pill_bank.dart';
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/fit_text.dart';
import '../widgets/premium.dart';
import '../widgets/ui.dart';

/// Your map: what the reader knows, subject by subject, and what stays.
///
/// The bars by subject are everybody's — a reader has to see the shape of
/// what they have read before they will pay to see inside it. What Astute+
/// opens is the inside: each subject's genres and the strands under them,
/// with how much of each has been read, and under that what actually
/// stayed — the cards that came back and were still right. The calibration
/// record, the third thing the map perk promises, is on the profile where
/// it always was.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.app, required this.onBack});

  final AppState app;
  final VoidCallback onBack;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// The subject open to its strands, if one is.
  String? _open;

  AppState get app => widget.app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ScreenView(
      name: 'map',
      child: Scaffold(
        backgroundColor: context.p.surface,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
            children: [
              Row(
                children: [
                  BackCircle(onPressed: widget.onBack),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FitText(
                      l.yourMap,
                      maxLines: 1,
                      minSize: 20,
                      style: AppText.display(
                        size: 27,
                        weight: FontWeight.w600,
                        height: 1,
                        spacing: -0.8,
                        color: context.p.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l.mapLine,
                style: AppText.body(
                  size: 13,
                  height: 1.4,
                  color: context.p.inkMuted,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Eyebrow(l.bySubject),
                  const Spacer(),
                  PlusLock(locked: !app.isPlus),
                ],
              ),
              const SizedBox(height: 11),
              _Subjects(
                app: app,
                open: _open,
                onToggle: (key) => setState(() {
                  _open = _open == key ? null : key;
                }),
                onLocked: () => requirePlus(
                  context,
                  app,
                  () => setState(() {}),
                  source: 'map',
                ),
              ),
              if (!app.isPlus) ...[
                const SizedBox(height: 8),
                Text(
                  l.strandsWithPlus,
                  style: AppText.body(
                    size: 12,
                    height: 1.35,
                    color: context.p.inkFaint,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Eyebrow(l.whatStays),
                  const Spacer(),
                  PlusLock(locked: !app.isPlus),
                ],
              ),
              const SizedBox(height: 11),
              _Memory(app: app),
            ],
          ),
        ),
      ),
    );
  }
}

/// How much of each subject has been read, and — open — how much of each
/// strand inside it.
class _Subjects extends StatelessWidget {
  const _Subjects({
    required this.app,
    required this.open,
    required this.onToggle,
    required this.onLocked,
  });

  final AppState app;
  final String? open;
  final ValueChanged<String> onToggle;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    final byTopic = <String, int>{};
    final seenByTopic = <String, int>{};
    for (final pill in PillBank.cards) {
      byTopic[pill.topic] = (byTopic[pill.topic] ?? 0) + 1;
      if (app.seenIds.contains(pill.id)) {
        seenByTopic[pill.topic] = (seenByTopic[pill.topic] ?? 0) + 1;
      }
    }

    final rows = kTopicOrder
        .where(app.pickedTopics.contains)
        .where((key) => (byTopic[kTopics[key]!.name] ?? 0) > 0)
        .toList();

    // The most any one subject has been read. The bars are drawn against
    // this, not against how many cards exist: the pool is written to keep
    // growing, so a total would be a number that quietly stops being true
    // — and one that says "you have read 3% of Astute", which is nobody's
    // idea of progress.
    final int busiest = rows
        .map((key) => seenByTopic[kTopics[key]!.name] ?? 0)
        .fold(0, (a, b) => a > b ? a : b);

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final key in rows)
            _SubjectRow(
              key: ValueKey('map-$key'),
              style: kTopics[key]!,
              seen: seenByTopic[kTopics[key]!.name] ?? 0,
              share: busiest == 0
                  ? 0
                  : (seenByTopic[kTopics[key]!.name] ?? 0) / busiest,
              genres: kGenres[key] ?? const [],
              open: open == key,
              plus: app.isPlus,
              seenIds: app.seenIds,
              onTap: app.isPlus ? () => onToggle(key) : onLocked,
            ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    super.key,
    required this.style,
    required this.seen,
    required this.share,
    required this.genres,
    required this.open,
    required this.plus,
    required this.seenIds,
    required this.onTap,
  });

  final TopicStyle style;
  final int seen;
  final double share;
  final List<Genre> genres;
  final bool open;
  final bool plus;
  final Set<String> seenIds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A subject with nothing written under it yet — Thinking, which is not
    // a subject — has no inside to open.
    final bool opens = genres.isNotEmpty;
    return Semantics(
      button: opens,
      expanded: opens ? open : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: opens ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // The subject's own colour, present before any of it has
                  // been read. An empty bar is the same grey for every
                  // topic, which loses the one thing that tells them apart
                  // at a glance.
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(right: 9),
                    decoration: BoxDecoration(
                      color: style.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      style.name,
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w500,
                        color: context.p.ink,
                      ),
                    ),
                  ),
                  Text(
                    '$seen',
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w500,
                      color: context.p.inkFaint,
                    ),
                  ),
                  if (opens)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        plus
                            ? (open
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded)
                            : Icons.lock_rounded,
                        size: plus ? 18 : 12,
                        color: context.p.inkFaint,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 5,
                  backgroundColor: context.p.line,
                  valueColor: AlwaysStoppedAnimation(style.color),
                ),
              ),
              if (open && plus) ...[
                const SizedBox(height: 10),
                for (final genre in genres) ...[
                  _GenreLines(genre: genre, seenIds: seenIds),
                ],
              ],
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.only(left: 18, bottom: 8),
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
  const _Memory({required this.app});

  final AppState app;

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
                  requirePlus(context, app, () {}, source: 'memory'),
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
