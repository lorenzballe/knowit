import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/record_share_sheet.dart';
import '../widgets/ui.dart';
import 'deck_viewer_screen.dart';
import 'paywall_screen.dart';

const _weekLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The end-of-day state: the streak recap, then either the Knowit+ upsell on
/// the free plan or the second set of the day for subscribers.
class RecapView extends StatelessWidget {
  final AppState app;
  const RecapView({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final week = app.weekCompletion();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RiseIn(
              child: Text(
                '${app.todaysDeck.length} of ${app.todaysDeck.length} · done',
                style: AppText.label(
                  size: 11,
                  spacing: 1.4,
                  color: context.p.inkMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // The number climbs rather than landing. It is the one figure the
            // reader came back for.
            RiseIn(
              delay: const Duration(milliseconds: 90),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CountUp(
                    value: app.streak,
                    style: AppText.display(
                      size: 34,
                      weight: FontWeight.w700,
                      height: 1.06,
                      spacing: -1.3,
                      color: context.p.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      app.streak == 1 ? 'day\nin a row.' : 'days\nin a row.',
                      style: AppText.display(
                        size: 34,
                        weight: FontWeight.w700,
                        height: 1.06,
                        spacing: -1.3,
                        color: AppColors.lime,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            RiseIn(
              delay: const Duration(milliseconds: 180),
              child: Row(
                children: List.generate(7, (i) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 34,
                            decoration: BoxDecoration(
                              color: week[i] ? AppColors.lime : context.p.line,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _weekLetters[i],
                            style: AppText.label(
                              size: 10,
                              color: context.p.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 22),
            RiseIn(
              delay: const Duration(milliseconds: 260),
              child: Text(
                'YOU PICKED UP TODAY',
                style: AppText.label(
                  size: 11,
                  spacing: 1.3,
                  color: context.p.inkFaint,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Each card you got through arrives in turn, so the list reads as
            // a tally being counted out rather than a screenshot.
            ...app.todaysDeck.indexed.map(
              (entry) => RiseIn.staggered(
                entry.$1,
                from: const Duration(milliseconds: 320),
                child: _RecapRow(
                  pill: entry.$2,
                  onTap: () => openDeckViewer(
                    context,
                    app,
                    app.todaysDeck,
                    "Today's five",
                    initialIndex: entry.$1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _ReadAgain(app: app),
            const SizedBox(height: 8),
            if (app.calibratedAnswers >= 3) ...[
              _RecordNudge(app: app),
              const SizedBox(height: 14),
            ],
            if (app.canOpenExtraSet)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.p.inverse,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your second set is ready',
                      style: AppText.display(
                        size: 20,
                        weight: FontWeight.w600,
                        spacing: -0.6,
                        color: context.p.onInverse,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Five more, picked the same way — and they count '
                      'towards your record like the first five.',
                      style: AppText.body(
                        size: 13.5,
                        height: 1.45,
                        color: context.p.onInverse.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => app.openExtraSet(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lime,
                          foregroundColor: AppColors.limeInk,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          'Read 5 more',
                          style: AppText.body(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: AppColors.limeInk,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (app.isPlus)
              _Tomorrow(app: app)
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.lime, AppColors.limeDark],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Want 5 more?',
                      style: AppText.display(
                        size: 20,
                        weight: FontWeight.w600,
                        spacing: -0.6,
                        color: const Color(0xFF17200A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Knowit+ unlocks an extra set every day, plus the full archive of everything you've read.",
                      style: AppText.body(
                        size: 13.5,
                        height: 1.45,
                        color: const Color(0xFF17200A).withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaywallScreen(app: app),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF17200A),
                          foregroundColor: const Color(0xFFE9FFC4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          'Unlock 5 extra pills',
                          style: AppText.body(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFFE9FFC4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!app.canOpenExtraSet && !app.isPlus) ...[
              const SizedBox(height: 14),
              _Tomorrow(app: app),
            ],
          ],
        ),
      ),
    );
  }
}

/// One line of the day's tally.
class _RecapRow extends StatelessWidget {
  final Pill pill;
  final VoidCallback onTap;
  const _RecapRow({required this.pill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Read this one again',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.p.line,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: pill.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pill.question,
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w500,
                    height: 1.3,
                    color: context.p.ink,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: context.p.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The way back into the five, once the day is done.
///
/// The recap lists what you read; this opens it. Cards come back face down,
/// so going through them again is a re-read rather than a page of answers.
class _ReadAgain extends StatelessWidget {
  final AppState app;
  const _ReadAgain({required this.app});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "Read today's five again",
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            openDeckViewer(context, app, app.todaysDeck, "Today's five"),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.p.lineStrong),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.replay_rounded, size: 16, color: context.p.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Read them again',
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: context.p.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What happens next. A daily app that ends on nothing gives no reason to
/// come back at a particular time.
class _Tomorrow extends StatelessWidget {
  final AppState app;
  const _Tomorrow({required this.app});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final left = tomorrow.difference(now);
    final hours = left.inHours;
    final minutes = left.inMinutes % 60;

    final away = hours >= 1
        ? '$hours ${hours == 1 ? 'hour' : 'hours'}'
        : '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';

    final due = app.dueReviews.length;

    return RiseIn(
      delay: const Duration(milliseconds: 460),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
        decoration: BoxDecoration(
          color: context.p.line,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Five more in $away',
              style: AppText.display(
                size: 18,
                weight: FontWeight.w600,
                spacing: -0.4,
                color: context.p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              due == 0
                  ? 'Nothing waiting to come back. Keep the streak.'
                  : due == 1
                  ? 'One card you missed is coming back with them.'
                  : '$due cards you missed are coming back with them.',
              style: AppText.body(
                size: 13,
                height: 1.45,
                color: context.p.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The day's tally answers "what did I read". This answers "how good was I",
/// which is the question worth coming back for — and the only one that makes
/// an image somebody would actually post.
class _RecordNudge extends StatelessWidget {
  final AppState app;
  const _RecordNudge({required this.app});

  @override
  Widget build(BuildContext context) {
    final s = RecordSummary.of(app);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: context.p.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Your record so far'),
          const SizedBox(height: 10),
          Text(
            'You said ${s.said.round()}% sure. '
            'You were right ${s.wasRight.round()}% of the time.',
            style: AppText.display(
              size: 19,
              weight: FontWeight.w600,
              height: 1.25,
              spacing: -0.6,
              color: context.p.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.isCalibrated
                ? 'That is closer than most people ever get.'
                : '${s.verdict} — over ${s.calls} calls.',
            style: AppText.body(
              size: 13,
              height: 1.4,
              color: context.p.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => showRecordShareSheet(context, app),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.limeInk,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'Share my record',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.limeInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
