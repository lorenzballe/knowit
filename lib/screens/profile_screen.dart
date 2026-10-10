import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../l10n/l10n.dart';

import 'package:flutter/services.dart';

import '../data/topics.dart';
import 'mix_screen.dart';
import '../analytics.dart';
import '../cloud.dart';
import '../debug_flags.dart';
import '../state/app_state.dart';
import '../state/progress.dart' show kCalibrationFloor;
import '../sync/identity.dart';
import '../sync/served.dart';
import '../sync/trace.dart';
import '../sync/account.dart';
import '../sync/subscription.dart';
import '../utils/reminders.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/premium.dart';
import '../widgets/record_share_sheet.dart';
import '../widgets/ui.dart';
import 'archive_screen.dart';
import 'friends_screen.dart';
import 'journey_screen.dart';
import 'saved_screen.dart';
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

  Future<void> _confirmDelete(BuildContext context) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    Analytics.capture('account deletion asked', {
      'signed_in': account.signedInForReal,
      'is_plus': app.isPlus,
    });
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.p.surface,
        title: Text(
          l.deleteAccountQuestion,
          style: AppText.display(size: 19, color: context.p.ink),
        ),
        content: Text(
          l.deleteAccountBody,
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
              l.cancel,
              style: AppText.body(size: 14, color: context.p.ink),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l.deleteAccountConfirm,
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
    if (confirmed != true) {
      Analytics.capture('account deletion cancelled');
      return;
    }
    final DeleteOutcome outcome = await account.deleteAccount(app);
    switch (outcome) {
      case DeleteOutcome.deleted:
        // As after signing out, the phone keeps an account of its own, a
        // new and empty one, so what happens next has somewhere to go.
        await account.ensureAnonymous(app);
        messenger?.showSnackBar(SnackBar(content: Text(l.accountDeleted)));
        onSignedOut();
      case DeleteOutcome.failed:
        messenger?.showSnackBar(
          SnackBar(content: Text(l.couldNotDeleteAccount)),
        );
      case DeleteOutcome.cancelled:
        break;
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
              // The mix is everybody's: it is what the free day's cards
              // are dealt from, the reader's own and the ones at random, so
              // gating it would gate the one thing the free day has to show.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _editTopics(context),
                child: Text(
                  context.l10n.edit,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: context.p.link,
                  ),
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
          // How well you know yourself is the one measurement kept here.
          // Everything else the app counts — the level, the moves you keep
          // missing, the week in questions, whether the gap is closing —
          // is the journey, one button away.
          const SizedBox(height: 22),
          _JourneyButton(app: app),
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
                  label: context.l10n.dailyNudge,
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
          // The archive is Astute+ only: on the free plan it opens the
          // paywall.
          _LinkRow(
            label: context.l10n.archive,
            onTap: () => requirePlus(
              context,
              app,
              source: 'archive',
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
            onTap: () {
              Analytics.capture('manage subscription opened', {
                'is_plus': app.isPlus,
              });
              app.isPlus
                  ? Subscription.instance.presentCustomerCenter()
                  : Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PaywallScreen(app: app, source: 'manage plan'),
                      ),
                    );
            },
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
                  label: context.l10n.signOut,
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
          // Deleting the account, for anyone who has one — the phone makes
          // one of its own before anybody signs in, and that one holds a
          // backup too. Muted, under the sign-in: where a reader looking for
          // it finds it, and where nobody trips on it.
          ListenableBuilder(
            listenable: account,
            builder: (context, _) {
              if (!account.signedIn) return const SizedBox.shrink();
              return _LinkRow(
                label: account.deleting
                    ? context.l10n.deletingAccount
                    : context.l10n.deleteAccount,
                muted: true,
                onTap: account.deleting ? () {} : () => _confirmDelete(context),
              );
            },
          ),
          const SizedBox(height: 24),
          Eyebrow(context.l10n.anonymousUsage),
          const SizedBox(height: 11),
          const _UsageSwitch(),
          if (debugToolsOn) ...[
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
            // Whether the day came from the server, and whether what the
            // reader does is reaching it: the two numbers that say the
            // server is doing its job.
            _DebugLine('Today dealt by', app.dealtBy),
            _DebugLine(
              'Trace',
              '${Trace.instance.written} written · ${Trace.instance.waiting} waiting',
            ),
            _DebugLine(
              'Explore',
              Served.instance.lastExplore == null
                  ? 'assembled here'
                  : 'served${Served.instance.lastExplore!.fromCache ? ' (cached)' : ''} for ${Served.instance.lastExplore!.day}',
            ),
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
            // What the offering holds, as the store priced it: enough to
            // check the whole RevenueCat and App Store setup from the phone —
            // the product each plan sells, its price, and the free week.
            _DebugLine('Yearly', _packageLine(Subscription.instance.yearly)),
            _DebugLine('Monthly', _packageLine(Subscription.instance.monthly)),
            _DebugLine(
              'Astute+ from the store',
              Subscription.instance.isPlus ? 'active' : 'not active',
            ),
            _DebugLine(
              'Analytics',
              Analytics.ready
                  ? (Analytics.collecting ? 'sending' : 'opted out')
                  : 'NOT running',
            ),
            _DebugLine('Analytics host', kPostHogHost),
            if (Analytics.failure != null)
              _DebugLine('Why', Analytics.failure!),
            const SizedBox(height: 10),
            _LinkRow(
              label: 'Wipe everything and restart',
              onTap: () => _confirmReset(context),
            ),
            // Everything a confirmed purchase does, without the store:
            // Astute+ turns on and the screen a purchase ends on opens.
            _LinkRow(
              label: 'Simulate a successful purchase',
              onTap: () async {
                if (!app.isPlus) await app.startPlusTrial();
                if (!context.mounted) return;
                await showPurchaseSuccess(context, app, source: 'debug');
              },
            ),
            _LinkRow(
              label: app.isPlus ? 'Turn Astute+ off' : 'Turn Astute+ on',
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

/// The reader's own switch over measurement.
///
/// Stateful, alone on this stateless screen, because what it shows is not
/// part of AppState: it is a decision about this install rather than about
/// this reader, so it does not travel to a new phone with the backup and
/// there is no listener above to rebuild from.
class _UsageSwitch extends StatefulWidget {
  const _UsageSwitch();

  @override
  State<_UsageSwitch> createState() => _UsageSwitchState();
}

class _UsageSwitchState extends State<_UsageSwitch> {
  late bool _on = Analytics.collecting;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      radius: 18,
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.anonymousUsageLine,
              style: AppText.body(
                size: 12,
                height: 1.35,
                color: context.p.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 14),
          NudgeSwitch(
            value: _on,
            label: l.anonymousUsage,
            onChanged: (v) async {
              // The switch moves first. Waiting on a write to disk to show a
              // toggle is what makes a second tap look necessary.
              setState(() => _on = v);
              final messenger = ScaffoldMessenger.of(context);
              // Said while it can still be said: turning measurement off is
              // the last event, turning it on the first.
              if (!v) {
                Analytics.capture('usage sharing switched', {'on': false});
              }
              await Analytics.setCollecting(v);
              if (v) {
                Analytics.capture('usage sharing switched', {'on': true});
              }
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(v ? l.usageOn : l.usageOff)),
                );
            },
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool muted;

  const _LinkRow({
    required this.label,
    required this.onTap,
    this.muted = false,
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
            gap == null
                ? context.l10n.journeyOffNotYet(
                    kCalibrationFloor - app.judgements.length,
                  )
                : context.l10n.acrossNAnswersHowSure(app.calibratedAnswers),
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

/// The Astute+ offer, on the screen where the reader is already looking at
/// what the app knows about them.
class _PlusCard extends StatelessWidget {
  final AppState app;
  const _PlusCard({required this.app});

  @override
  Widget build(BuildContext context) {
    // The card is a piece of the other theme, so what sits on it comes from
    // the other theme too. The button and the badge were drawn in the card's
    // own colour, which left a label floating on a ledge and a badge with no
    // edge at all — in both themes.
    final Palette other = context.p.isDark ? Palette.light : Palette.dark;
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
                  color: context.p.onInverse.withValues(alpha: 0.08),
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
                switch (Subscription.instance.trialDays) {
                  final int days => context.l10n.trialDaysFree(days),
                  null => '',
                },
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
            context.l10n.plusCardHeadline,
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
            context.l10n.plusCardLine,
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
            fill: other.inverse,
            ink: other.onInverse,
            // The paywall's own edge for a cream face, so the two read as
            // one button.
            edge: other.isDark ? const Color(0xFFA8A59D) : null,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    PaywallScreen(app: app, source: 'see the plans'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One fact about the running app, for the debug section.
/// A plan as the store answered for it: the product, its price, and its
/// introductory offer — "P1W" free is the week the paywall promises.
String _packageLine(Package? package) {
  if (package == null) return 'not in the offering';
  final StoreProduct product = package.storeProduct;
  final IntroductoryPrice? intro = product.introductoryPrice;
  final String offer = intro == null
      ? ''
      : intro.price == 0
      ? ' · free ${intro.period}'
      : ' · intro ${intro.priceString} ${intro.period}';
  return '${product.identifier} · ${product.priceString}$offer';
}

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

/// The way into the journey: the level, the moves you keep missing, the
/// week in questions and every other number the app keeps about the reader,
/// on a screen of their own. The journey is Astute+, so on the free plan the
/// button carries the lock and opens the plans instead.
class _JourneyButton extends StatelessWidget {
  const _JourneyButton({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final bool locked = !app.isPlus;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('profile-journey'),
        behavior: HitTestBehavior.opaque,
        onTap: () => requirePlus(
          context,
          app,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (routeContext) => JourneyScreen(
                app: app,
                onBack: () => Navigator.of(routeContext).pop(),
              ),
            ),
          ),
          source: 'journey',
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            color: context.p.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.p.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.yourJourney,
                      style: AppText.display(
                        size: 21,
                        weight: FontWeight.w600,
                        height: 1.1,
                        spacing: -0.5,
                        color: context.p.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.journeyButtonLine,
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
              if (locked)
                const PlusLock(locked: true)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: context.p.inkFaint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
