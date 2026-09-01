import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/motion.dart';
import '../widgets/record_share_sheet.dart';
import '../widgets/ui.dart';
import 'deck_viewer_screen.dart';
import 'paywall_screen.dart';

/// The end-of-day state: the streak recap, then either the Astuto+ upsell on
/// the free plan or the second set of the day for subscribers.
class RecapView extends StatelessWidget {
  final AppState app;
  const RecapView({super.key, required this.app});

  /// How many of today's gradeable cards were got right.
  (int, int) _tally() {
    var right = 0;
    var gradeable = 0;
    for (final pill in app.todaysDeck) {
      if (!pill.isGraded || !pill.asksSomething) continue;
      gradeable++;
      final given = app.answerFor(pill.id);
      if (given != null && pill.challenge.accepts(given.response)) right++;
    }
    return (right, gradeable);
  }

  @override
  Widget build(BuildContext context) {
    final (right, gradeable) = _tally();

    // A receipt, not a certificate. What this screen owes the reader is
    // that the day is finished, what was in it, and when the next one comes.
    // It used to open with a tick in a circle that could have belonged to
    // any app, under three tiles of which one usually read a dash — and it
    // never once named a card, which is the whole of what had just been
    // read.
    final summary = <String>[
      app.todaysDeck.length == 1 ? '1 read' : '${app.todaysDeck.length} read',
      if (gradeable > 0) '$right of $gradeable right',
      if (app.streak > 0) app.streak == 1 ? '1 day' : '${app.streak} days',
      'back at ${app.notifyTime}',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(6, 24, 6, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RiseIn(
            child: Text(
              'Done for today.',
              style: AppText.display(
                size: 34,
                weight: FontWeight.w600,
                height: 1.05,
                spacing: -1.2,
                color: context.p.ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          RiseIn(
            delay: const Duration(milliseconds: 60),
            child: Text(
              summary.join('  ·  '),
              style: AppText.body(size: 13.5, color: context.p.inkMuted),
            ),
          ),
          const SizedBox(height: 26),
          const Eyebrow('What you read'),
          const SizedBox(height: 10),
          // The five, named, each one a way back into itself. A single
          // button marked "show them again" made you re-open all five to
          // reach the one you wanted.
          for (int i = 0; i < app.todaysDeck.length; i++)
            RiseIn(
              delay: Duration(milliseconds: 100 + i * 50),
              child: _ReadRow(
                pill: app.todaysDeck[i],
                onTap: () => openDeckViewer(
                  context,
                  app,
                  app.todaysDeck,
                  "Today's five",
                  initialIndex: i,
                ),
              ),
            ),
          const SizedBox(height: 18),
          RiseIn(
            delay: const Duration(milliseconds: 340),
            child: WeekStrip(week: app.weekCompletion(), barHeight: 26),
          ),
          const SizedBox(height: 20),

          // Everything past here is optional reading.
          if (app.canOpenExtraSet)
            _ExtraSet(app: app)
          else if (!app.isPlus)
            _Upsell(app: app)
          else
            _Tomorrow(app: app),
          if (app.calibratedAnswers >= 3) ...[
            const SizedBox(height: 12),
            _RecordNudge(app: app),
          ],
        ],
      ),
    );
  }
}

/// One of the day's cards, on the screen that closes the day.
class _ReadRow extends StatelessWidget {
  const _ReadRow({required this.pill, required this.onTap});

  final Pill pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: context.p.ink.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: pill.color,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pill.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 13.5,
                        height: 1.28,
                        weight: FontWeight.w600,
                        color: context.p.ink.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pill.topic,
                      style: AppText.label(
                        size: 9.5,
                        spacing: 1.1,
                        color: context.p.inkFaint,
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

/// The Astuto+ second set, once the first five are done.
class _ExtraSet extends StatelessWidget {
  final AppState app;
  const _ExtraSet({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.p.inverse,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your second set is ready',
            style: AppText.display(
              size: 18,
              weight: FontWeight.w700,
              spacing: -0.5,
              color: context.p.onInverse,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Five more, and they count towards your record like the first.',
            style: AppText.body(
              size: 13,
              height: 1.4,
              color: context.p.onInverse.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 13),
          ChunkyButton(
            label: 'READ 5 MORE',
            height: 48,
            fill: context.p.inverse,
            ink: context.p.onInverse,
            onPressed: () => app.openExtraSet(),
          ),
        ],
      ),
    );
  }
}

/// The offer, for readers on the free plan.
class _Upsell extends StatelessWidget {
  final AppState app;
  const _Upsell({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.p.inverse,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Want 5 more?',
            style: AppText.display(
              size: 18,
              weight: FontWeight.w700,
              spacing: -0.5,
              color: context.p.onInverse,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Astuto+ unlocks a second set every day, and shows you whether '
            'the gap is closing.',
            style: AppText.body(
              size: 13,
              height: 1.4,
              color: context.p.onInverse.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 13),
          ChunkyButton(
            label: 'UNLOCK 5 EXTRA PILLS',
            height: 48,
            fill: context.p.onInverse,
            ink: context.p.inverse,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => PaywallScreen(app: app))),
          ),
        ],
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
          ChunkyButton(
            label: 'SHARE MY RECORD',
            height: 48,
            fill: context.p.inverse,
            ink: context.p.onInverse,
            onPressed: () => showRecordShareSheet(context, app),
          ),
        ],
      ),
    );
  }
}
