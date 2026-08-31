import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/pills_data.dart';
import '../data/topics.dart';
import '../cloud.dart';
import '../debug_flags.dart';
import '../state/app_state.dart';
import '../sync/identity.dart';
import '../sync/account.dart';
import '../sync/subscription.dart';
import '../utils/reminders.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/premium.dart';
import '../widgets/record_share_sheet.dart';
import '../widgets/ui.dart';
import 'archive_screen.dart';
import 'how_screen.dart';
import 'paywall_screen.dart';
import 'topics_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AppState app;
  final Account account;
  final VoidCallback onSignedOut;

  const ProfileScreen({
    super.key,
    required this.app,
    required this.account,
    required this.onSignedOut,
  });

  Future<void> _editTopics(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => TopicsScreen(
          initial: app.pickedTopics,
          isOnboarding: false,
          onBack: () => Navigator.of(routeContext).pop(),
          onDone: (picked) async {
            await app.setTopics(picked);
            if (routeContext.mounted) Navigator.of(routeContext).pop();
          },
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.p.surface,
        title: Text(
          'Sign out?',
          style: AppText.display(size: 19, color: context.p.ink),
        ),
        content: Text(
          'Your streak, saved pills and record stay on your account. This '
          'clears them from this device.',
          style: AppText.body(
            size: 14,
            height: 1.45,
            color: context.p.inkMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppText.body(size: 14, color: context.p.ink),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Sign out',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: context.p.alert,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await account.signOut();
      await app.signOut();
      // The phone keeps an account of its own, so what happens next still
      // has somewhere to be written.
      await account.ensureAnonymous(app);
      onSignedOut();
    }
  }

  Future<void> _signIn(
    BuildContext context,
    String label,
    Future<SignInOutcome> Function(AppState) run,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final outcome = await run(app);
    final String? note = switch (outcome) {
      SignInOutcome.signedIn =>
        'Signed in. Your streak and record are on your account now.',
      SignInOutcome.failed => 'Could not sign in with $label.',
      SignInOutcome.unavailable => 'Signing in is not available on this build.',
      SignInOutcome.cancelled => null,
    };
    if (note != null) {
      messenger?.showSnackBar(SnackBar(content: Text(note)));
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.p.surface,
        title: Text(
          'Start over?',
          style: AppText.display(size: 19, color: context.p.ink),
        ),
        content: Text(
          'Wipes everything on this device — streak, saved pills, answers, '
          'your judgement record, topics and plan — and reopens the '
          'onboarding.',
          style: AppText.body(
            size: 14,
            height: 1.45,
            color: context.p.inkMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppText.body(size: 14, color: context.p.ink),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Wipe it',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: context.p.alert,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // signOut() is already the full wipe: it clears every stored key and
      // puts onboarded back to false, which is what sends the root back to
      // the welcome screen.
      await app.signOut();
      onSignedOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: context.p.inverse,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  app.initials,
                  style: AppText.display(
                    size: 18,
                    weight: FontWeight.w600,
                    color: context.p.onInverse,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: AppText.display(
                        size: 22,
                        weight: FontWeight.w700,
                        height: 1.1,
                        spacing: -0.7,
                        color: context.p.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.isPlus
                          ? 'Astuto+ · ${app.pickedTopics.length} topics'
                          : 'Free plan · ${app.pickedTopics.length} topics',
                      style: AppText.body(
                        size: 12.5,
                        color: context.p.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(value: '${app.liveStreak}', label: 'day streak'),
              const SizedBox(width: 10),
              _Stat(value: '${app.pillsRead}', label: 'pills read'),
              const SizedBox(width: 10),
              _Stat(value: '${app.dueReviews.length}', label: 'coming back'),
            ],
          ),
          // The offer belongs where the reader is already looking at their own
          // numbers, not as a link under the settings. A profile is the one
          // screen somebody opens because they care how they are doing.
          if (!app.isPlus) ...[const SizedBox(height: 14), _PlusCard(app: app)],
          if (app.calibratedAnswers > 0) ...[
            const SizedBox(height: 22),
            const Eyebrow('How well you know yourself'),
            const SizedBox(height: 11),
            _Calibration(app: app),
            const SizedBox(height: 10),
            _ShareRecord(app: app),
          ],
          if (app.trend != null) ...[
            const SizedBox(height: 22),
            const Eyebrow('Is the gap closing?'),
            const SizedBox(height: 11),
            _TrendPanel(app: app),
          ],
          if (app.masteryByWeakness.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Eyebrow('The moves you keep missing'),
            const SizedBox(height: 11),
            _Mastery(app: app),
          ],
          const SizedBox(height: 22),
          const Eyebrow('What you have covered'),
          const SizedBox(height: 11),
          _Coverage(app: app),
          const SizedBox(height: 22),
          const Eyebrow('Appearance'),
          const SizedBox(height: 11),
          _ThemePicker(app: app),
          const SizedBox(height: 22),
          const Eyebrow('Daily nudge'),
          const SizedBox(height: 11),
          PaperCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            radius: 18,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Every day at ${app.notifyTime}',
                        style: AppText.body(
                          size: 14.5,
                          weight: FontWeight.w500,
                          height: 1.2,
                          color: context.p.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remindersSupported
                            ? 'Your 5 pills, before the first coffee.'
                            : 'A browser can only speak while it is open, '
                                  'so this one needs the phone build.',
                        style: AppText.body(
                          size: 12,
                          height: 1.3,
                          color: context.p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                NudgeSwitch(
                  value: app.notificationsOn,
                  onChanged: (v) async {
                    await app.setNotifications(v);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !v
                              ? 'Nudge off.'
                              : app.remindersLive
                              ? 'Nudge on, every day at ${app.notifyTime}.'
                              : remindersSupported
                              ? 'Nudge on, but the system said no. Turn '
                                    'notifications on for Astuto in settings.'
                              : 'Nudge on. Delivery needs the phone build.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Eyebrow('Your topics'),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    requirePlus(context, app, () => _editTopics(context)),
                child: Row(
                  children: [
                    Text(
                      'Edit',
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: context.p.link,
                      ),
                    ),
                    PlusLock(locked: !app.isPlus),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kTopicOrder.where(app.pickedTopics.contains).map((key) {
              final style = kTopics[key]!;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: style.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  style.name,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: style.ink,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (!app.isPlus)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.lime, AppColors.limeDark],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Astuto+',
                          style: AppText.display(
                            size: 17,
                            weight: FontWeight.w600,
                            color: AppColors.limeInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '5 extra pills a day, full archive.',
                          style: AppText.body(
                            size: 12.5,
                            color: AppColors.limeInk.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaywallScreen(app: app),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.limeInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Upgrade',
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFFE9FFC4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          _LinkRow(
            label: 'Archive',
            locked: !app.isPlus,
            onTap: () => requirePlus(
              context,
              app,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (routeContext) => ArchiveScreen(
                    app: app,
                    onBack: () => Navigator.of(routeContext).pop(),
                  ),
                ),
              ),
            ),
          ),
          _LinkRow(
            label: 'Manage subscription',
            // A subscriber wants to cancel, change plan or ask for a refund,
            // and none of that belongs on a screen built to sell. RevenueCat's
            // customer centre does all of it; the paywall is for everyone
            // else.
            onTap: () => app.isPlus
                ? Subscription.instance.presentCustomerCenter()
                : Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PaywallScreen(app: app)),
                  ),
          ),
          _LinkRow(
            label: 'How pills are written',
            onTap: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const HowScreen())),
          ),
          // The account changes under this screen — a sign-in that lands, a
          // sheet still up — and none of it is worth leaving the profile to
          // see.
          ListenableBuilder(
            listenable: account,
            builder: (context, _) {
              if (account.signedInForReal) {
                return _LinkRow(
                  label: 'Sign out',
                  muted: true,
                  onTap: () => _confirmSignOut(context),
                );
              }
              // While a sheet is up, say so and take no second tap. Two flows
              // at once cancel each other, so a reader tapping again because
              // nothing seemed to happen would end up with nothing.
              if (account.busy) {
                return _LinkRow(
                  label: 'Signing in…',
                  muted: true,
                  onTap: () {},
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LinkRow(
                    label: 'Sign in with Apple',
                    onTap: () =>
                        _signIn(context, 'Apple', account.signInWithApple),
                  ),
                  _LinkRow(
                    label: 'Sign in with Google',
                    onTap: () =>
                        _signIn(context, 'Google', account.signInWithGoogle),
                  ),
                ],
              );
            },
          ),
          if (kDebugTools) ...[
            const SizedBox(height: 40),
            const Eyebrow('Debug'),
            const SizedBox(height: 6),
            Text(
              'Temporary, and visible in release builds on purpose — these '
              'are needed on a real phone. Remove before anyone else has it.',
              style: AppText.body(
                size: 12.5,
                height: 1.45,
                color: context.p.inkFaint,
              ),
            ),
            const SizedBox(height: 10),
            // What the app actually knows about itself. "Nothing happens"
            // is the least useful bug report there is, so it is replaced
            // here by something that can be read off a screen.
            _DebugLine('Firebase', Cloud.ready ? 'running' : 'NOT running'),
            if (Cloud.failure != null) _DebugLine('Why', Cloud.failure!),
            _DebugLine(
              'Account',
              account.signedInForReal
                  ? 'signed in${account.email == null ? '' : ' · ${account.email}'}'
                  : account.signedIn
                  ? 'anonymous'
                  : 'none',
            ),
            _DebugLine('Account id', account.uid ?? '—'),
            // Which sign-in code this build carries, and which road the last
            // attempt actually took. Between them a screenshot answers "is
            // this the new build, and did it use the phone's own sheet" —
            // which otherwise costs a round trip and a TestFlight install.
            _DebugLine('Sign-in build', Identity.implementation),
            _DebugLine('Last sign-in route', account.lastRoute ?? '—'),
            if (account.lastError != null)
              _DebugLine('Last auth error', account.lastError!),
            _DebugLine(
              'Store',
              Subscription.instance.ready ? 'answered' : 'no answer',
            ),
            _DebugLine(
              'Offering',
              Subscription.instance.offering?.identifier ?? 'none',
            ),
            _DebugLine('Entitlement asked for', kPlusEntitlement),
            const SizedBox(height: 10),
            _LinkRow(
              label: 'Wipe everything and restart',
              onTap: () => _confirmReset(context),
            ),
            _LinkRow(
              label: app.isPlus ? 'Turn Astuto+ off' : 'Turn Astuto+ on',
              onTap: () async {
                if (app.isPlus) {
                  await app.endPlus();
                } else {
                  await app.startPlusTrial();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: context.p.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.p.line),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppText.display(
                size: 24,
                weight: FontWeight.w700,
                height: 1,
                spacing: -0.6,
                color: context.p.ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppText.label(
                size: 9.5,
                spacing: 1,
                color: context.p.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool muted;
  final bool locked;

  const _LinkRow({
    required this.label,
    required this.onTap,
    this.muted = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.p.line)),
        ),
        child: Row(
          children: [
            // Flexible, so a label longer than the row does not overflow it —
            // which any other language would manage on its own.
            Flexible(
              child: Text(
                label,
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w500,
                  color: muted ? context.p.inkMuted : context.p.ink,
                ),
              ),
            ),
            PlusLock(locked: locked),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.p.inkFaint,
            ),
          ],
        ),
      ),
    );
  }
}

/// The collection, topic by topic. A daily app needs somewhere to be going,
/// and a bar that fills is the cheapest honest version of that.
class _Coverage extends StatelessWidget {
  final AppState app;
  const _Coverage({required this.app});

  @override
  Widget build(BuildContext context) {
    final byTopic = <String, int>{};
    final seenByTopic = <String, int>{};
    for (final pill in kPillPool) {
      byTopic[pill.topic] = (byTopic[pill.topic] ?? 0) + 1;
      if (app.seenIds.contains(pill.id)) {
        seenByTopic[pill.topic] = (seenByTopic[pill.topic] ?? 0) + 1;
      }
    }

    final rows = kTopicOrder
        .where(app.pickedTopics.contains)
        .map((key) => kTopics[key]!)
        .where((style) => (byTopic[style.name] ?? 0) > 0)
        .toList();

    final seenTotal = app.seenIds.length;
    final poolTotal = kPillPool.length;

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$seenTotal of $poolTotal pills',
            style: AppText.display(
              size: 20,
              weight: FontWeight.w600,
              spacing: -0.5,
              color: context.p.ink,
            ),
          ),
          const SizedBox(height: 14),
          ...rows.map((style) {
            final total = byTopic[style.name] ?? 0;
            final seen = seenByTopic[style.name] ?? 0;
            final complete = seen >= total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                        complete ? 'complete' : '$seen/$total',
                        style: AppText.body(
                          size: 12,
                          weight: complete ? FontWeight.w600 : FontWeight.w400,
                          color: complete ? style.color : context.p.inkFaint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : seen / total,
                      minHeight: 5,
                      backgroundColor: context.p.line,
                      valueColor: AlwaysStoppedAnimation(style.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Stated confidence against what actually happened.
///
/// This is the one number in the app that says something about the reader
/// rather than about the cards: not how much they know, but how well they
/// know what they know.
class _Calibration extends StatelessWidget {
  final AppState app;
  const _Calibration({required this.app});

  @override
  Widget build(BuildContext context) {
    final buckets = app.calibration.toList();
    final gap = app.overconfidence;

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headline(gap),
            style: AppText.display(
              size: 19,
              weight: FontWeight.w600,
              height: 1.25,
              spacing: -0.4,
              color: context.p.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Across ${app.calibratedAnswers} answers you said how sure you '
            'were. Here is what happened.',
            style: AppText.body(
              size: 12.5,
              height: 1.4,
              color: context.p.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          ...buckets.map((b) => _Row(bucket: b)),
          const SizedBox(height: 4),
          Text(
            'A perfectly calibrated person is right 70% of the time when '
            'they say 70%.',
            style: AppText.body(
              size: 11.5,
              height: 1.4,
              color: context.p.inkFaint,
            ),
          ),
        ],
      ),
    );
  }

  String _headline(double? gap) {
    if (gap == null) return 'Not enough answers yet';
    final points = gap.abs().round();
    if (points <= 5) return 'Your confidence matches your accuracy';
    return gap > 0
        ? 'You are overconfident by $points points'
        : 'You are underconfident by $points points';
  }
}

class _Row extends StatelessWidget {
  final CalibrationBucket bucket;
  const _Row({required this.bucket});

  @override
  Widget build(BuildContext context) {
    // Only overconfidence is worth marking in alarm, and only once there is
    // enough of it to mean anything: being right more often than you claimed
    // is the good direction, and one answer in a bucket is noise.
    final off = bucket.count >= 3 && bucket.gap > 15;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  'Said ${bucket.said}%',
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: context.p.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'right ${bucket.actual.round()}% '
                  '(${bucket.right} of ${bucket.count})',
                  style: AppText.body(
                    size: 12.5,
                    color: off ? context.p.alert : context.p.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Two bars: what you claimed, and what you managed.
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: context.p.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (bucket.said / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: context.p.lineStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (bucket.actual / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: off ? context.p.alert : context.p.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One choice for the whole app. It used to change between tabs, which is
/// the sort of thing that reads as unfinished.
class _ThemePicker extends StatelessWidget {
  final AppState app;
  const _ThemePicker({required this.app});

  static const _options = [
    (mode: ThemeMode.light, label: 'Light'),
    (mode: ThemeMode.dark, label: 'Dark'),
    (mode: ThemeMode.system, label: 'System'),
  ];

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.all(6),
      radius: 18,
      child: Row(
        children: _options.map((option) {
          final selected = app.themeMode == option.mode;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (selected) return;
                  HapticFeedback.selectionClick();
                  app.setThemeMode(option.mode);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selected ? context.p.inverse : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.label,
                    style: AppText.body(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: selected
                          ? context.p.onInverse
                          : context.p.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// How the reader is doing on each principle, weakest first.
///
/// This is the readout the evidence points at. Naming the move you missed,
/// and showing your own record on it, is the part of debiasing training that
/// carried to a real decision months later (Sellier, Scopelliti & Morewedge,
/// 2019). Knowing you got card seven wrong is worth nothing by comparison.
class _Mastery extends StatelessWidget {
  final AppState app;
  const _Mastery({required this.app});

  @override
  Widget build(BuildContext context) {
    // The three you are worst at are the ones worth acting on, and they are
    // free: a reader has to see the measurement before paying to keep it.
    // What Astuto+ adds is the rest of the board.
    final all = app.masteryByWeakness;
    final rows = app.isPlus ? all : all.take(3).toList();
    final hidden = all.length - rows.length;

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rows.indexed.map((entry) {
            final m = entry.$2;
            final last = entry.$1 == rows.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: last ? 6 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.principle.label,
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w600,
                            color: context.p.ink,
                          ),
                        ),
                      ),
                      Text(
                        '${m.right}/${m.met}',
                        style: AppText.body(
                          size: 13,
                          weight: FontWeight.w600,
                          color: m.isWeak
                              ? context.p.alert
                              : context.p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    m.principle.oneLine,
                    style: AppText.body(
                      size: 12.5,
                      height: 1.4,
                      color: context.p.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: m.share,
                      minHeight: 5,
                      backgroundColor: context.p.line,
                      valueColor: AlwaysStoppedAnimation(
                        m.isWeak ? context.p.alert : AppColors.lime,
                      ),
                    ),
                  ),
                  if (m.met < m.contexts) ...[
                    const SizedBox(height: 5),
                    Text(
                      '${m.contexts - m.met} more '
                      '${m.contexts - m.met == 1 ? 'context' : 'contexts'} '
                      'of this to come',
                      style: AppText.body(
                        size: 11.5,
                        color: context.p.inkFaint,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (hidden > 0)
            Semantics(
              button: true,
              label: 'See every principle with Astuto plus',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => requirePlus(context, app, () {}),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$hidden more '
                          '${hidden == 1 ? 'principle' : 'principles'} '
                          'being tracked',
                          style: AppText.body(
                            size: 13.5,
                            weight: FontWeight.w600,
                            color: context.p.inkMuted,
                          ),
                        ),
                      ),
                      const PlusLock(locked: true),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The one thing this app makes that no other daily-learning app holds: a
/// number about the reader. It sits directly under the calibration rows, so
/// it is offered at the moment the number has just been read.
class _ShareRecord extends StatelessWidget {
  final AppState app;
  const _ShareRecord({required this.app});

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      label: 'SHARE MY RECORD',
      height: 52,
      fill: AppColors.lime,
      ink: AppColors.limeInk,
      leading: const Icon(
        Icons.ios_share_rounded,
        size: 17,
        color: AppColors.limeInk,
      ),
      onPressed: () => showRecordShareSheet(context, app),
    );
  }
}

/// Whether the reader is actually getting better — the one question the
/// subscription is sold on, so it has to exist before it is sold.
///
/// Free readers see that the answer is being kept and how many calls it
/// rests on; the number itself is what Astuto+ opens.
class _TrendPanel extends StatelessWidget {
  final AppState app;
  const _TrendPanel({required this.app});

  @override
  Widget build(BuildContext context) {
    final t = app.trend!;
    final locked = !app.isPlus;

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  locked
                      ? 'Your last ${t.window} calls, against your first '
                            '${t.window}'
                      : t.isMoving
                      ? (t.isImproving
                            ? 'Closed by ${t.closedBy.abs().round()} points'
                            : 'Opened by ${t.closedBy.abs().round()} points')
                      : 'Holding steady',
                  style: AppText.display(
                    size: 18,
                    weight: FontWeight.w600,
                    height: 1.2,
                    spacing: -0.5,
                    color: context.p.ink,
                  ),
                ),
              ),
              PlusLock(locked: locked),
            ],
          ),
          const SizedBox(height: 10),
          if (locked)
            Text(
              'The measurement is running. Astuto+ shows you which way it '
              'is going.',
              style: AppText.body(
                size: 13,
                height: 1.45,
                color: context.p.inkMuted,
              ),
            )
          else ...[
            _TrendRow(label: 'First ${t.window}', gap: t.early, muted: true),
            const SizedBox(height: 8),
            _TrendRow(label: 'Last ${t.window}', gap: t.recent, muted: false),
            const SizedBox(height: 11),
            Text(
              t.isMoving
                  ? (t.isImproving
                        ? 'Your confidence is tracking your accuracy more '
                              'closely than it did.'
                        : 'The distance has grown. Worth slowing down before '
                              'you commit.')
                  : 'No real movement yet. This takes weeks, not days.',
              style: AppText.body(
                size: 12.5,
                height: 1.45,
                color: context.p.inkMuted,
              ),
            ),
          ],
          if (locked) ...[
            const SizedBox(height: 12),
            ChunkyButton(
              label: 'SEE WHICH WAY',
              height: 46,
              fill: AppColors.lime,
              ink: AppColors.limeInk,
              onPressed: () => requirePlus(context, app, () {}),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  final String label;
  final double gap;
  final bool muted;
  const _TrendRow({
    required this.label,
    required this.gap,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final points = gap.abs().round();
    final word = gap >= 0 ? 'over' : 'under';
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w500,
              color: context.p.inkMuted,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              // Fills as the reader gets closer, not as they get further
              // out: a long bar has to mean the good thing. 30 points out is
              // a wide miss, and past that the bar is simply empty rather
              // than pretending to more resolution.
              value: (1 - points / 30).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: context.p.line,
              valueColor: AlwaysStoppedAnimation(
                muted ? context.p.lineStrong : AppColors.lime,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          points == 0 ? 'spot on' : '$points $word',
          style: AppText.body(
            size: 12.5,
            weight: FontWeight.w600,
            color: context.p.ink,
          ),
        ),
      ],
    );
  }
}

/// The Astuto+ offer, on the screen where the reader is already looking at
/// what the app knows about them.
class _PlusCard extends StatelessWidget {
  final AppState app;
  const _PlusCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: context.p.inverse,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ASTUTO+',
                  style: AppText.label(
                    size: 9.5,
                    weight: FontWeight.w700,
                    spacing: 1.1,
                    color: AppColors.limeInk,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '7 days free',
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: context.p.onInverse.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Watch the gap move.',
            style: AppText.display(
              size: 22,
              weight: FontWeight.w700,
              height: 1.1,
              spacing: -0.8,
              color: context.p.onInverse,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The measurement is free and always will be. Astuto+ is what '
            'tells you which way it is going.',
            style: AppText.body(
              size: 13,
              height: 1.45,
              color: context.p.onInverse.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          ChunkyButton(
            label: 'SEE THE PLANS',
            height: 48,
            fill: AppColors.lime,
            ink: AppColors.limeInk,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => PaywallScreen(app: app))),
          ),
        ],
      ),
    );
  }
}

/// One fact about the running app, for the debug section.
class _DebugLine extends StatelessWidget {
  const _DebugLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: AppText.body(size: 12, color: context.p.inkFaint),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w600,
                color: context.p.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
