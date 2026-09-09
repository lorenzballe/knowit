import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/progress.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'pill_detail_screen.dart';
import 'progress_text.dart';

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
                    context.l10n.yourWeek,
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
                  ? context.l10n.nothingThisWeekYet
                  : week.kept
                  ? context.l10n.keptDaysOfSeven(week.days)
                  : context.l10n.daysOfSevenFiveKeeps(week.days),
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
              Eyebrow(context.l10n.howSureAgainstHowRight),
              const SizedBox(height: 11),
              _Verdict(week: week),
              const SizedBox(height: 22),
            ],
            if (week.misses.isNotEmpty) ...[
              Eyebrow(context.l10n.sureAndWrong),
              const SizedBox(height: 7),
              Text(
                context.l10n.worthGoingBackTo,
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
            Eyebrow(context.l10n.whereThisIsGoing),
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
                context.l10n.ofNRight(week.answered),
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
                ? context.l10n.sayHowSureOnMore
                : closing == null
                ? context.l10n.confidenceOff(gap.round())
                : closing
                ? context.l10n.confidenceClosing(
                    gap.round(),
                    week.gapBefore!.round(),
                  )
                : context.l10n.confidenceOpened(
                    gap.round(),
                    week.gapBefore!.round(),
                  ),
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
    final String? step = stepText(context, standing);

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
            next == null
                ? rungName(context, standing.rung)
                : context.l10n.nextRung(rungName(context, next)),
            style: AppText.body(
              size: 15,
              weight: FontWeight.w700,
              color: context.p.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            next == null
                ? rungClaim(context, standing.rung)
                : step == null
                ? rungClaim(context, next)
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
                    context.l10n.youSaidPercentSure(miss.confidence),
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
