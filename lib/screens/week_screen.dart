import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/progress.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'pill_detail_screen.dart';

/// The week, read back to the reader.
///
/// The day is the loop; the week is the only distance from which anybody
/// can see a direction. It is deliberately short and deliberately blunt:
/// how many days were kept, how sure the reader was against how right they
/// were, whether that gap is closing, and the cards they were sure about
/// and wrong about — which is the one page in the app worth going back to.
class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key, required this.app, required this.onBack});

  final AppState app;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final WeekReport week = app.thisWeek;
    final ink = context.p.ink;

    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Row(
              children: [
                BackCircle(onPressed: onBack),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your week',
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
            const SizedBox(height: 5),
            Text(
              week.empty
                  ? 'Nothing this week yet. Five cards start it.'
                  : week.kept
                  ? 'Kept — ${week.days} days of seven.'
                  : '${week.days} day${week.days == 1 ? '' : 's'} of seven. '
                        'Five keeps the week.',
              style: AppText.body(
                size: 12.5,
                height: 1.35,
                color: ink.withValues(alpha: 0.42),
              ),
            ),
            const SizedBox(height: 18),
            WeekStrip(week: app.weekCompletion(), barHeight: 40),
            const SizedBox(height: 22),
            if (week.answered > 0) ...[
              const Eyebrow('How sure, against how right'),
              const SizedBox(height: 11),
              _Verdict(week: week),
              const SizedBox(height: 22),
            ],
            if (week.misses.isNotEmpty) ...[
              const Eyebrow('Sure, and wrong'),
              const SizedBox(height: 7),
              Text(
                'The ones worth going back to. Being wrong about something '
                'you were sure of is the only cheap way to find out what you '
                'actually believe.',
                style: AppText.body(
                  size: 13,
                  height: 1.45,
                  color: context.p.inkMuted,
                ),
              ),
              const SizedBox(height: 12),
              for (final miss in week.misses.take(3)) ...[
                _MissRow(
                  miss: miss,
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PillDetailScreen(pill: miss.pill, app: app),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
            ],
            const Eyebrow('Where this is going'),
            const SizedBox(height: 11),
            _Next(app: app),
          ],
        ),
      ),
    );
  }
}

/// The week's two numbers, and whether the gap between them is closing.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.week});

  final WeekReport week;

  @override
  Widget build(BuildContext context) {
    final double? gap = week.gap;
    final bool? closing = week.closing;
    final int right = week.right;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: context.p.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$right',
                style: AppText.display(
                  size: 40,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -1.6,
                  color: context.p.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'of ${week.answered} right',
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w500,
                  color: context.p.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            gap == null
                ? 'Say how sure you are on a few more and the app will tell '
                      'you what that confidence is worth.'
                : closing == null
                ? 'Your confidence was ${gap.round()} points off what you '
                      'actually knew.'
                : closing
                ? 'Your confidence was ${gap.round()} points off, against '
                      '${week.gapBefore!.round()} last week. It is closing.'
                : 'Your confidence was ${gap.round()} points off, against '
                      '${week.gapBefore!.round()} last week. It opened up.',
            style: AppText.body(
              size: 13.5,
              height: 1.45,
              color: context.p.ink.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rung, and the one thing that moves the reader off it.
class _Next extends StatelessWidget {
  const _Next({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final standing = app.standing;
    final Rung? next = standing.next;
    final String? step = standing.step;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: context.p.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            next == null ? standing.rung.name : 'Next: ${next.name}',
            style: AppText.body(
              size: 15,
              weight: FontWeight.w700,
              color: context.p.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            next == null
                ? standing.rung.claim
                : step == null
                ? next.claim
                : '$step.',
            style: AppText.body(
              size: 13,
              height: 1.45,
              color: context.p.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// One card the reader was sure about and wrong about.
class _MissRow extends StatelessWidget {
  const _MissRow({required this.miss, required this.onOpen});

  final Miss miss;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill pill = miss.pill;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: context.p.surfaceRaised,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: context.p.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: TopicDot(pill.color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pill.question,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      height: 1.32,
                      color: context.p.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'You said ${miss.confidence}% sure',
                    style: AppText.label(
                      size: 10.5,
                      weight: FontWeight.w700,
                      spacing: 1,
                      color: context.p.ink.withValues(alpha: 0.38),
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
