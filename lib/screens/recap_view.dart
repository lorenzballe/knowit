import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
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
    final week = app.weekCompletion();

    // Small on purpose. The end of a day is a beat, not a report: what it
    // owes the reader is that it is finished, roughly how it went, and a way
    // back into the cards. The long version pushed that way back below the
    // fold, which is the one thing on this screen anybody actually wants.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PopIn(
            child: Center(
              child: Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 34,
                  color: AppColors.limeInk,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          RiseIn(
            delay: const Duration(milliseconds: 80),
            child: Text(
              'Done for today.',
              textAlign: TextAlign.center,
              style: AppText.display(
                size: 30,
                weight: FontWeight.w700,
                height: 1.05,
                spacing: -1.2,
                color: context.p.ink,
              ),
            ),
          ),
          const SizedBox(height: 20),
          RiseIn(
            delay: const Duration(milliseconds: 160),
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: '${app.todaysDeck.length}',
                    label: 'CARDS',
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _Stat(
                    value: gradeable == 0 ? '—' : '$right/$gradeable',
                    label: 'RIGHT',
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _Stat(
                    value: '${app.streak}',
                    label: app.streak == 1 ? 'DAY' : 'DAYS',
                    accent: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          RiseIn(
            delay: const Duration(milliseconds: 240),
            child: ChunkyButton(
              label: "SHOW TODAY'S CARDS AGAIN",
              height: 54,
              fill: AppColors.lime,
              ink: AppColors.limeInk,
              onPressed: () =>
                  openDeckViewer(context, app, app.todaysDeck, "Today's five"),
            ),
          ),
          const SizedBox(height: 20),
          RiseIn(
            delay: const Duration(milliseconds: 300),
            child: Row(
              children: List.generate(7, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : 5),
                    child: Column(
                      children: [
                        Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: week[i] ? AppColors.lime : context.p.line,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _weekLetters[i],
                          style: AppText.label(
                            size: 9.5,
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
          const SizedBox(height: 16),

          // Everything past here is optional reading, and sits below the
          // thing the reader came to this screen to do.
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
          if (!app.isPlus) ...[const SizedBox(height: 12), _Tomorrow(app: app)],
        ],
      ),
    );
  }
}

/// One figure from the day, in a tile small enough that three fit a row.
class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;

  const _Stat({required this.value, required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: context.p.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.p.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppText.display(
              size: 23,
              weight: FontWeight.w700,
              spacing: -0.7,
              color: accent ? AppColors.limeDark : context.p.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppText.label(
              size: 9.5,
              spacing: 1.1,
              color: context.p.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

/// The Knowit+ second set, once the first five are done.
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
            fill: AppColors.lime,
            ink: AppColors.limeInk,
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
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.lime, AppColors.limeDark],
        ),
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
              color: AppColors.limeInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Knowit+ unlocks a second set every day, and shows you whether '
            'the gap is closing.',
            style: AppText.body(
              size: 13,
              height: 1.4,
              color: AppColors.limeInk.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 13),
          ChunkyButton(
            label: 'UNLOCK 5 EXTRA PILLS',
            height: 48,
            fill: AppColors.limeInk,
            ink: AppColors.lime,
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
            fill: AppColors.lime,
            ink: AppColors.limeInk,
            onPressed: () => showRecordShareSheet(context, app),
          ),
        ],
      ),
    );
  }
}
