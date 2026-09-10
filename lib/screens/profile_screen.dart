import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:flutter/services.dart';

import '../data/topics.dart';
import 'mix_screen.dart';
import '../cloud.dart';
import '../debug_flags.dart';
import '../state/app_state.dart';
import '../state/progress.dart';
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
import 'know_screen.dart';
import 'progress_text.dart';
import 'friends_screen.dart';
import 'journey_screen.dart';
import 'saved_screen.dart';
import 'week_screen.dart';
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
          context.l10n.signOutQuestion,
          style: AppText.display(size: 19, color: context.p.ink),
        ),
        content: Text(
          context.l10n.signOutBody,
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
              context.l10n.signOut,
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
    final l = context.l10n;
    final outcome = await run(app);
    final String? note = switch (outcome) {
      SignInOutcome.signedIn => l.signedInRecordOnAccount,
      SignInOutcome.failed => l.couldNotSignInWith(label),
      SignInOutcome.unavailable => l.signInNotAvailableBuild,
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
          context.l10n.startOverQuestion,
          style: AppText.display(size: 19, color: context.p.ink),
        ),
        content: Text(
          context.l10n.startOverBody,
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
              context.l10n.wipeIt,
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
          // The record, not an identity. This screen used to open with a
          // circle of initials nobody typed, a name nobody set, and four
          // boxes reading zero — a dashboard of nothing, with an
          // advertisement as the brightest object on it. What a reader comes
          // here for is the one number the habit has produced, so that is
          // what it opens with.
          Eyebrow(context.l10n.yourRecord),
          const SizedBox(height: 12),
          _Headline(app: app),
          if (app.weekCompletion().any((day) => day)) ...[
            const SizedBox(height: 18),
            WeekStrip(week: app.weekCompletion(), barHeight: 34),
          ],
          const SizedBox(height: 16),
          _RecordLine(app: app),
          const SizedBox(height: 18),
          _Path(app: app),
          // Under the reader's own record and above everything else: the
          // offer is about the record, so it reads as the next thing to say
          // rather than as the loudest thing on the screen. It is also the
          // only offer on the page — a second box lower down, selling the
          // same thing in different words, was the app asking twice.
          if (!app.isPlus) ...[const SizedBox(height: 20), _PlusCard(app: app)],
          // The two things a reader sets, straight after the thing they
          // came to read: how the app looks and what it deals. Both used to
          // sit under five panels of measurement, which is where a setting
          // goes to be forgotten.
          const SizedBox(height: 24),
          Eyebrow(context.l10n.appearance),
          const SizedBox(height: 11),
          _ThemePicker(app: app),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Eyebrow(context.l10n.yourTopics),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    requirePlus(context, app, () => _editTopics(context)),
                child: Row(
                  children: [
                    Text(
                      context.l10n.edit,
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
            // All of them, in the onboarding's own order — the ones in the
            // mix in their colour, the ones out of it dark. Showing only what
            // was chosen made this a list with nothing to compare against:
            // you could not see what you had turned off, or that there was
            // anything else to turn on.
            children: kMixSubjects.map((subject) {
              final bool live = app.pickedTopics.contains(subject.key);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: live
                      ? subject.color
                      : context.p.inverse.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  subject.name,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: live
                        ? inkOn(subject.color)
                        : context.p.ink.withValues(alpha: 0.34),
                  ),
                ),
              );
            }).toList(),
          ),
          // Nothing to cover until something has been read: a list of
          // nineteen subjects all reading zero is the same wall of nothing
          // the four tiles used to be. Under the topics, because it is the
          // topics, read.
          if (app.calibratedAnswers > 0) ...[
            const SizedBox(height: 22),
            Eyebrow(context.l10n.howWellYouKnowYourself),
            const SizedBox(height: 11),
            _Calibration(app: app),
            const SizedBox(height: 10),
            _ShareRecord(app: app),
          ],
          if (app.trend != null) ...[
            const SizedBox(height: 22),
            Eyebrow(context.l10n.isTheGapClosing),
            const SizedBox(height: 11),
            _TrendPanel(app: app),
          ],
          if (app.masteryByWeakness.isNotEmpty) ...[
            const SizedBox(height: 22),
            Eyebrow(context.l10n.movesYouKeepMissing),
            const SizedBox(height: 11),
            _Mastery(app: app),
          ],
          const SizedBox(height: 22),
          Eyebrow(context.l10n.dailyNudge),
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
                        context.l10n.everyDayAt(app.notifyTime),
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
                            ? context.l10n.yourFivePillsBeforeCoffee
                            : context.l10n.browserOnlySpeaksOpen,
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
                              ? context.l10n.nudgeOff
                              : app.remindersLive
                              ? context.l10n.nudgeOnEveryDayAt(app.notifyTime)
                              : remindersSupported
                              ? context.l10n.nudgeOnSystemSaidNo
                              : context.l10n.nudgeOnNeedsPhone,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // What the reader said they know, which a day is dealt by and
          // which they may well have got wrong the first morning.
          _LinkRow(
            label: context.l10n.howMuchYouKnow,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (routeContext) => KnowScreen(
                  app: app,
                  onBack: () => Navigator.of(routeContext).pop(),
                  onDone: (levels) async {
                    await app.setTopicLevels(levels);
                    if (routeContext.mounted) Navigator.of(routeContext).pop();
                  },
                ),
              ),
            ),
          ),
          // The week, which is the only distance from which a direction is
          // visible at all — the day is too close to it.
          _LinkRow(
            label: context.l10n.yourWeek,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (routeContext) => WeekScreen(
                  app: app,
                  onBack: () => Navigator.of(routeContext).pop(),
                ),
              ),
            ),
          ),
          // Your own shelf, which is a thing you own and not a place to go
          // looking — so it lives here, with the rest of what is yours,
          // rather than taking one of three tabs.
          _LinkRow(
            label: app.savedIds.isEmpty
                ? context.l10n.saved
                : context.l10n.savedN(app.savedIds.length),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (routeContext) => Scaffold(
                  backgroundColor: context.p.surface,
                  body: SafeArea(
                    child: SavedScreen(
                      app: app,
                      onBackToToday: () => Navigator.of(routeContext).pop(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // The people whose boards you look at: streaks and calibration,
          // never answers. What is compared is the habit.
          _LinkRow(
            label: app.friendCodes.isEmpty
                ? context.l10n.friends
                : context.l10n.friendsN(app.friendCodes.length),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (routeContext) => FriendsScreen(
                  app: app,
                  account: account,
                  onBack: () => Navigator.of(routeContext).pop(),
                ),
              ),
            ),
          ),
          // And the other shelf: not what you want to find again, but
          // what you liked — which is also what the app deals more of.
          _LinkRow(
            label: app.likedIds.isEmpty
                ? context.l10n.liked
                : context.l10n.likedN(app.likedIds.length),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (routeContext) => Scaffold(
                  backgroundColor: context.p.surface,
                  body: SafeArea(
                    child: SavedScreen(
                      app: app,
                      shelf: Shelf.liked,
                      onBackToToday: () => Navigator.of(routeContext).pop(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _LinkRow(
            label: context.l10n.archive,
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
            label: context.l10n.manageSubscription,
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
            label: context.l10n.howPillsAreWritten,
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
                  label: context.l10n.signingIn,
                  muted: true,
                  onTap: () {},
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LinkRow(
                    label: context.l10n.signInWithApple,
                    onTap: () =>
                        _signIn(context, 'Apple', account.signInWithApple),
                  ),
                  _LinkRow(
                    label: context.l10n.signInWithGoogle,
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
              label: app.isPlus ? 'Turn Astut+ off' : 'Turn Astut+ on',
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
            // The label and its lock together at the left, the chevron at
            // the far right. A Flexible label beside a Spacer split the row
            // in two, which left the chevron somewhere in the middle at a
            // different place on every row.
            Expanded(
              child: Row(
                children: [
                  // Flexible, so a label longer than the row does not
                  // overflow it — which any other language would manage on
                  // its own.
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
                ],
              ),
            ),
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
            _headline(context, gap),
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
            context.l10n.acrossNAnswersHowSure(app.calibratedAnswers),
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
            context.l10n.perfectlyCalibratedLine,
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

  String _headline(BuildContext context, double? gap) {
    if (gap == null) return context.l10n.notEnoughAnswersYet;
    final points = gap.abs().round();
    if (points <= 5) return context.l10n.confidenceMatchesAccuracy;
    return gap > 0
        ? context.l10n.overconfidentBy(points)
        : context.l10n.underconfidentBy(points);
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
                  context.l10n.saidPercent(bucket.said),
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
                  context.l10n.rightPercentOf(
                    bucket.actual.round(),
                    bucket.right,
                    bucket.count,
                  ),
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
                    switch (option.mode) {
                      ThemeMode.light => context.l10n.themeLight,
                      ThemeMode.dark => context.l10n.themeDark,
                      _ => context.l10n.themeSystem,
                    },
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
    // What Astut+ adds is the rest of the board.
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
                        m.isWeak ? context.p.alert : context.p.inverse,
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
              label: context.l10n.seeEveryPrincipleWithPlus,
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
      label: context.l10n.shareMyRecord,
      height: 52,
      fill: context.p.inverse,
      ink: context.p.onInverse,
      leading: Icon(
        Icons.ios_share_rounded,
        size: 17,
        color: context.p.onInverse,
      ),
      onPressed: () => showRecordShareSheet(context, app),
    );
  }
}

/// Whether the reader is actually getting better — the one question the
/// subscription is sold on, so it has to exist before it is sold.
///
/// Free readers see that the answer is being kept and how many calls it
/// rests on; the number itself is what Astut+ opens.
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
                      ? context.l10n.lastCallsAgainstFirst(t.window)
                      : t.isMoving
                      ? (t.isImproving
                            ? context.l10n.closedByPoints(
                                t.closedBy.abs().round(),
                              )
                            : context.l10n.openedByPoints(
                                t.closedBy.abs().round(),
                              ))
                      : context.l10n.holdingSteady,
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
              context.l10n.measurementRunningPlus,
              style: AppText.body(
                size: 13,
                height: 1.45,
                color: context.p.inkMuted,
              ),
            )
          else ...[
            _TrendRow(
              label: context.l10n.firstN(t.window),
              gap: t.early,
              muted: true,
            ),
            const SizedBox(height: 8),
            _TrendRow(
              label: context.l10n.lastN(t.window),
              gap: t.recent,
              muted: false,
            ),
            const SizedBox(height: 11),
            Text(
              t.isMoving
                  ? (t.isImproving
                        ? context.l10n.trackingMoreClosely
                        : context.l10n.distanceHasGrown)
                  : context.l10n.noRealMovementYet,
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
              label: context.l10n.seeWhichWay,
              height: 46,
              fill: context.p.inverse,
              ink: context.p.onInverse,
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
    final bool over = gap >= 0;
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
                muted ? context.p.lineStrong : context.p.inverse,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          points == 0
              ? context.l10n.spotOn
              : over
              ? context.l10n.pointsOver(points)
              : context.l10n.pointsUnder(points),
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

/// The Astut+ offer, on the screen where the reader is already looking at
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
                  color: context.p.inverse,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.l10n.plusNameCaps,
                  style: AppText.label(
                    size: 9.5,
                    weight: FontWeight.w700,
                    spacing: 1.1,
                    color: context.p.onInverse,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.sevenDaysFree,
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
            context.l10n.watchTheGapMove,
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
            context.l10n.measurementFreeForever,
            style: AppText.body(
              size: 13,
              height: 1.45,
              color: context.p.onInverse.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          ChunkyButton(
            label: context.l10n.seeThePlans,
            height: 48,
            fill: context.p.inverse,
            ink: context.p.onInverse,
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

/// The one number the habit has produced, set as a headline.
///
/// A streak while there is one, because that is what a reader comes back to
/// protect. Before there is a streak it says what has actually been read,
/// and on the first morning it says neither, because a screen that opens
/// with a zero has told you nothing except that you have not started.
class _Headline extends StatelessWidget {
  const _Headline({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final int streak = app.liveStreak;
    // The same count the coverage panel prints. Reading it from a second
    // field meant the headline said the record had not started while the
    // panel underneath said forty-six.
    final int read = app.seenIds.length;

    if (streak == 0 && read == 0) {
      return Text(
        context.l10n.recordStartsToday,
        style: AppText.display(
          size: 34,
          weight: FontWeight.w600,
          height: 1.08,
          spacing: -1.1,
          color: context.p.ink,
        ),
      );
    }

    final bool onStreak = streak > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${onStreak ? streak : read}',
          style: AppText.display(
            size: 64,
            weight: FontWeight.w600,
            height: 1,
            spacing: -3,
            color: context.p.ink,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          onStreak
              ? context.l10n.dayWord(streak)
              : context.l10n.pillReadWord(read),
          style: AppText.body(
            size: 16,
            weight: FontWeight.w500,
            color: context.p.inkMuted,
          ),
        ),
      ],
    );
  }
}

/// The way up, as a ladder of what the reader can do rather than a
/// syllabus of what they have covered.
///
/// The five cards a day are mixed on purpose, so a path made of chapters —
/// fifteen cards on this, then fifteen on that — would have to break the
/// deck to exist. This one does not care what the cards are about: every
/// rung is a claim about the reader, and any five at all carry them up it.
class _Path extends StatelessWidget {
  const _Path({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final standing = app.standing;
    final Rung rung = standing.rung;
    final Rung? next = standing.next;
    final String? step = stepText(context, standing);

    // The card is also the way into the journey it is a moment of.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (routeContext) => JourneyScreen(
            app: app,
            onBack: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
        decoration: BoxDecoration(
          color: context.p.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.p.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rungName(context, rung),
                        style: AppText.display(
                          size: 21,
                          weight: FontWeight.w600,
                          height: 1.1,
                          spacing: -0.5,
                          color: context.p.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rungClaim(context, rung),
                        style: AppText.body(
                          size: 13,
                          height: 1.35,
                          color: context.p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.rungOfTotal(standing.at + 1, kRungs.length),
                  style: AppText.label(
                    size: 11,
                    weight: FontWeight.w700,
                    spacing: 1,
                    color: context.p.ink.withValues(alpha: 0.32),
                  ),
                ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 14),
              // One bar, held to the least finished of the things the next
              // rung asks for, so it never runs ahead of what is actually in
              // the way.
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 5,
                  child: Stack(
                    children: [
                      Container(color: context.p.ink.withValues(alpha: 0.09)),
                      FractionallySizedBox(
                        widthFactor: standing.toNext.clamp(0.02, 1.0),
                        child: Container(color: context.p.ink),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                step == null
                    ? context.l10n.nextRung(rungName(context, next))
                    : context.l10n.stepThenRung(step, rungName(context, next)),
                style: AppText.body(
                  size: 12.5,
                  height: 1.35,
                  color: context.p.ink.withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The rest of the numbers, on one line rather than in a row of boxes.
class _RecordLine extends StatelessWidget {
  const _RecordLine({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final int weeks = app.keptWeeks;
    final parts = <String>[
      if (app.liveStreak > 0) context.l10n.nPillsRead(app.seenIds.length),
      // Five days out of seven is a week kept. The daily streak is the
      // sharper number and the crueller one — a flight or a fever and two
      // months are gone — so the record carries both, and this is the one
      // that survives a life.
      if (weeks > 0) context.l10n.nWeeksKept(weeks),
      if (app.dueReviews.isNotEmpty)
        context.l10n.nComingBack(app.dueReviews.length),
      if (app.freezes > 0) context.l10n.nFreezesInHand(app.freezes),
      app.isPlus ? context.l10n.plusName : context.l10n.freePlan,
    ];
    return Text(
      parts.join('  ·  '),
      style: AppText.body(size: 13, color: context.p.inkMuted),
    );
  }
}
