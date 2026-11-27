import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../l10n/l10n.dart';

import 'package:flutter/services.dart';

import '../data/topics.dart';
import 'notes_screen.dart';
import 'mix_screen.dart';
import '../analytics.dart';
import '../cloud.dart';
import '../debug_flags.dart';
import '../legal.dart';
import '../models/place.dart';
import '../state/app_state.dart';
import '../state/debug_looks.dart';
import '../state/first_offers.dart' show FirstOffer;
import '../state/music_sound.dart';
import '../state/progress.dart' show kCalibrationFloor;
import '../sync/identity.dart';
import '../sync/invite.dart';
import '../sync/place_finder.dart';
import '../sync/served.dart';
import '../sync/trace.dart';
import '../sync/account.dart';
import '../sync/subscription.dart';
import '../utils/reminders.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/day_moment.dart' show DayMoment, DayMomentMemory;
import '../widgets/place_ask.dart';
import '../widgets/profile_menu.dart';
import '../widgets/profile_top.dart';
import '../widgets/record_share_sheet.dart';
import '../widgets/sign_in_sheet.dart';
import '../widgets/source_foot.dart' show builtSourceFoot, footPickOf;
import '../widgets/subject_icon.dart';
import '../widgets/top_edge.dart' show UnderStatusBar;
import '../widgets/ui.dart';
import 'archive_screen.dart';
import 'saved_screen.dart';
import 'how_screen.dart';
import 'paywall_screen.dart';
import '../widgets/aim_picker.dart';
import '../widgets/learn_looks.dart';
import 'topics_screen.dart';
import 'tune_screen.dart';
import '../widgets/hand_glass.dart';
import '../widgets/invite_sheet.dart';

class ProfileScreen extends StatelessWidget {
  final AppState app;
  final Account account;
  final VoidCallback onSignedOut;

  /// Takes the reader to the Today tab: the shell's, since a tab cannot
  /// change tabs on its own. Told where on the screen the tile tapped for
  /// it is, so Today can open out of it; null from anywhere else. Null
  /// where Profile stands alone.
  final ValueChanged<Rect?>? onToday;

  const ProfileScreen({
    super.key,
    required this.app,
    required this.account,
    required this.onSignedOut,
    this.onToday,
  });

  /// Opens the privacy policy or the terms, and says which.
  void _openLegal(String page, String url) {
    Analytics.capture('legal page opened', {'page': page, 'from': 'profile'});
    openLink(url);
  }

  /// "Back to today's five", from an empty shelf: everything open over the
  /// tabs is put away and the reader lands on Today, which is what the
  /// button says. It used to pop the shelf and leave them on Profile.
  void _backToToday(BuildContext routeContext) {
    Navigator.of(routeContext).popUntil((route) => route.isFirst);
    onToday?.call(null);
  }

  /// The time of the daily nudge, on the phone's own clock. Chosen once on
  /// the sheet that asked, it was then shown here and could not be moved.
  Future<void> _pickNudgeTime(BuildContext context) async {
    final List<String> parts = app.notifyTime.split(':');
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 8,
        minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 30) : 30,
      ),
    );
    if (picked == null || !context.mounted) return;
    final String at =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    if (at == app.notifyTime) return;
    await app.setNotifyTime(at);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.dailyNudgeMovedTo(clockTime(context, at))),
      ),
    );
  }

  Future<void> _editTopics(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => TopicsScreen(
          initial: app.pickedTopics,
          isOnboarding: false,
          onBack: () => Navigator.of(routeContext).pop(),
          onFineTune: (picked) => Navigator.of(routeContext).push<Set<String>>(
            MaterialPageRoute(
              builder: (_) => TuneScreen(app: app, picked: picked),
            ),
          ),
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
          // Where the subscription deleting does not cancel is managed: the
          // reader's own store, named.
          l.deleteAccountBody(switch (Theme.of(context).platform) {
            TargetPlatform.iOS || TargetPlatform.macOS => 'apple',
            TargetPlatform.android => 'google',
            _ => 'other',
          }),
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

  /// Apple and Google, on the sheet every door to an account opens. What
  /// goes wrong is said on the sheet; what goes right, here, once it has
  /// closed.
  Future<void> _signIn(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final String done = context.l10n.signedInRecordOnAccount;
    final bool signedIn = await showSignInSheet(
      context,
      account: account,
      app: app,
      door: SignInDoor.profile,
    );
    if (signedIn) messenger?.showSnackBar(SnackBar(content: Text(done)));
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
    // The list runs on under the status bar, going soft and dissolving into
    // the page there as Explore's shelves do, rather than being cut at a
    // line under the time.
    return UnderStatusBar(
      child: ListView(
        // The foot clears a glass tab bar the list runs under.
        padding: EdgeInsets.fromLTRB(
          22,
          MediaQuery.paddingOf(context).top + 8,
          22,
          24 + (barGlass ? MediaQuery.paddingOf(context).bottom : 0),
        ),
        children: [
          // The record, not an identity. This screen used to open with a
          // circle of initials nobody typed, a name nobody set, and four
          // boxes reading zero; then with the streak, said twice, over a
          // line of five more numbers. It opens now on the number about the
          // reader — the Astute score, on either plan — with the way into
          // the journey that holds the rest of it, and the week, which goes
          // to Today's five (lib/widgets/profile_top.dart).
          ProfileTopView(app: app, onToday: onToday),
          _TrialNotice(app: app),
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
          // The mix is everybody's: it is what the free day's cards are
          // dealt from, the reader's own and the ones at random, so gating
          // it would gate the one thing the free day has to show.
          //
          // The whole block opens the editor. "Edit" alone was a target
          // 24 points by 18, beside chips that looked like buttons and did
          // nothing; now the chips are the way in, and "Edit" says so.
          Semantics(
            container: true,
            button: true,
            label: context.l10n.yourTopics,
            hint: context.l10n.edit,
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('profile-topics'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _editTopics(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Eyebrow(context.l10n.yourTopics),
                      Text(
                        context.l10n.edit,
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: context.p.link,
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
                      final Color ink = live
                          ? inkOn(subject.color)
                          : context.p.ink.withValues(alpha: 0.34);
                      return Container(
                        padding: const EdgeInsets.fromLTRB(10, 9, 13, 9),
                        decoration: BoxDecoration(
                          color: live
                              ? subject.color
                              : context.p.inverse.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        // The subject's own mark before its name, as on the
                        // mix it was chosen on: the colour says which one at
                        // a glance, the mark says it to anyone who does not
                        // remember the colours.
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SubjectIcon(
                              subject: subject.name,
                              size: 14,
                              ink: ink,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.subjectOf(subject.name),
                              style: AppText.body(
                                size: 12.5,
                                weight: FontWeight.w500,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          // Where the reader wants to see more clearly, beside the subjects
          // because both decide what they are dealt: the six areas of a life
          // the cards name, each in its own colour, one picked
          // (lib/widgets/aim_picker.dart).
          const SizedBox(height: 22),
          ProfileAim(app: app),
          // What the reader is training, under what they read: not a second
          // wall of coloured pills, but the skills picked with their levels;
          // or what What to learn's look the developer tools try puts here
          // (lib/widgets/learn_looks.dart), with the gap above it.
          LearnProfileBox(app: app),
          // Nothing to cover until something has been read: a list of
          // twenty subjects all reading zero is the same wall of nothing
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
          // How well you know yourself is the one measurement kept down
          // here. Everything else the app counts — the level, the moves you
          // keep missing, the week in questions, whether the gap is closing
          // — is the journey, whose way in now sits under the score at the
          // top: a second button down here said the same thing twice.
          const SizedBox(height: 22),
          Eyebrow(context.l10n.dailyNudge),
          const SizedBox(height: 11),
          PaperCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            radius: 18,
            child: Row(
              children: [
                Expanded(
                  // The time is the reader's to move while the nudge is on:
                  // a tap on it opens the clock.
                  child: Semantics(
                    button: app.nudgeShownOn,
                    child: GestureDetector(
                      key: const ValueKey('nudge-time'),
                      behavior: HitTestBehavior.opaque,
                      onTap: app.nudgeShownOn
                          ? () => _pickNudgeTime(context)
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  context.l10n.everyDayAt(
                                    clockTime(context, app.notifyTime),
                                  ),
                                  style: AppText.body(
                                    size: 14.5,
                                    weight: FontWeight.w500,
                                    height: 1.2,
                                    color: context.p.ink,
                                  ),
                                ),
                              ),
                              if (app.nudgeShownOn) ...[
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.expand_more_rounded,
                                  size: 18,
                                  color: context.p.inkMuted,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          // The first coffee only where the nudge comes
                          // before ten: the sheet now starts on the hour the
                          // reader reads at, and for most that is evening.
                          Text(
                            !remindersSupported
                                ? context.l10n.browserOnlySpeaksOpen
                                : app.notifyTime.compareTo('10:00') < 0 &&
                                      app.notifyTime.compareTo('05:00') >= 0
                                ? context.l10n.yourFivePillsBeforeCoffee
                                : context.l10n.reminderAskLine,
                            style: AppText.body(
                              size: 12,
                              height: 1.3,
                              color: context.p.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                NudgeSwitch(
                  value: app.nudgeShownOn,
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
                              ? context.l10n.nudgeOnEveryDayAt(
                                  clockTime(context, app.notifyTime),
                                )
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
          // What is the reader's own, then the account, then how the app
          // works, and the way out at the very end. Every row says what is
          // behind it before it is opened — how many cards, how far back,
          // which city, which plan — where a list of bare labels made each
          // one a door to try.
          ProfileHeader(context.l10n.yourCards, top: 30, bottom: 12),
          // Your own shelf, which is a thing you own and not a place to go
          // looking — so it lives here, with the rest of what is yours,
          // rather than taking one of three tabs. Shown as a hand of its own
          // cards, the newest on top.
          ShelfRow(
            key: const ValueKey('profile-saved'),
            mark: ProfileMarks.bookmark,
            title: context.l10n.saved,
            hint: context.l10n.emptySavedHint,
            tint: kSpectrum[8],
            ids: app.savedIds,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (routeContext) => Scaffold(
                  backgroundColor: context.p.surface,
                  body: SafeArea(
                    child: SavedScreen(
                      app: app,
                      onBack: () => Navigator.of(routeContext).pop(),
                      onBackToToday: () => _backToToday(routeContext),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // And the other shelf: not what you want to find again, but
          // what you liked — which is also what the app deals more of.
          ShelfRow(
            key: const ValueKey('profile-liked'),
            mark: ProfileMarks.heart,
            title: context.l10n.liked,
            hint: context.l10n.emptyLikedHint,
            // Human body's red, whose heart the like is.
            tint: kSpectrum[14],
            ids: app.likedIds,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (routeContext) => Scaffold(
                  backgroundColor: context.p.surface,
                  body: SafeArea(
                    child: SavedScreen(
                      app: app,
                      shelf: Shelf.liked,
                      onBack: () => Navigator.of(routeContext).pop(),
                      onBackToToday: () => _backToToday(routeContext),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ProfileBox(
            children: [
              // The archive, on either plan: a week of it on the free plan,
              // and the lock on everything before that, inside. Locked at
              // this door, the free week was never seen, and nor was the row
              // that says what Astute+ keeps.
              ProfileRow(
                key: const ValueKey('profile-archive'),
                mark: ProfileMarks.clock,
                label: context.l10n.archive,
                value: _archiveHolds(context, app),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (routeContext) => ArchiveScreen(
                      app: app,
                      onBack: () => Navigator.of(routeContext).pop(),
                    ),
                  ),
                ),
              ),
              // The reader's notes on cards, each written on a card's own
              // page: all of them in one place.
              ProfileRow(
                key: const ValueKey('profile-notes'),
                mark: ProfileMarks.quill,
                label: context.l10n.notesTitle,
                value: app.notedIds.isEmpty ? null : '${app.notedIds.length}',
                onTap: () => NotesScreen.open(context, app),
              ),
              // Where the reader lives: the city kept, or off, and the way
              // to change either. Only where a place can be read, or one is
              // kept — the web has neither, and a switch that leads nowhere
              // is not one.
              if (PlaceFinder.instance.canAsk || app.place != null)
                _PlaceRow(app: app),
              const _SoundRow(),
            ],
          ),
          // Invita un amico, while the server has it on: a week of Astute+
          // for the reader and a friend, and the row for a friend's code.
          _InviteBox(app: app),
          ProfileHeader(context.l10n.accountSection),
          // The account changes under this screen — a sign-in that lands, a
          // sheet still up — and none of it is worth leaving the profile to
          // see.
          ListenableBuilder(
            listenable: account,
            builder: (context, _) => ProfileBox(
              children: [
                ProfileRow(
                  key: const ValueKey('profile-plan'),
                  mark: ProfileMarks.plan,
                  label: context.l10n.manageSubscription,
                  value: app.isPlus
                      ? context.l10n.plusName
                      : context.l10n.freePlan,
                  // A subscriber wants to cancel, change plan or ask for a
                  // refund, and none of that belongs on a screen built to
                  // sell. RevenueCat's customer centre does all of it; the
                  // paywall is for everyone else.
                  onTap: () {
                    Analytics.capture('manage subscription opened', {
                      'is_plus': app.isPlus,
                    });
                    app.isPlus
                        ? Subscription.instance.presentCustomerCenter()
                        : Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PaywallScreen(
                                app: app,
                                source: 'manage plan',
                              ),
                            ),
                          );
                  },
                ),
                if (account.signedInForReal)
                  ProfileRow(
                    key: const ValueKey('profile-sign-out'),
                    mark: ProfileMarks.exit,
                    label: context.l10n.signOut,
                    chevron: false,
                    onTap: () => _confirmSignOut(context),
                  )
                // While a sheet is up, say so and take no second tap. Two
                // flows at once cancel each other, so a reader tapping again
                // because nothing seemed to happen would end up with nothing.
                else if (account.busy)
                  ProfileRow(
                    key: const ValueKey('profile-signing-in'),
                    mark: ProfileMarks.enter,
                    label: context.l10n.signingIn,
                    color: context.p.inkMuted,
                    chevron: false,
                    onTap: () {},
                  )
                // What an account is for, rather than whose button it is:
                // the sheet behind the row has Apple and Google, and says
                // what goes wrong if anything does.
                else
                  ProfileRow(
                    key: const ValueKey('profile-keep-streak'),
                    mark: ProfileMarks.enter,
                    label: context.l10n.keepStreakOnNewPhone,
                    onTap: () => _signIn(context),
                  ),
              ],
            ),
          ),
          ProfileHeader(context.l10n.aboutSection),
          ProfileBox(
            children: [
              ProfileRow(
                key: const ValueKey('profile-how'),
                mark: ProfileMarks.quill,
                label: context.l10n.howPillsAreWritten,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const HowScreen())),
              ),
              // What the reader agreed to, a tap away and not only on the
              // first screen: the privacy policy, and the terms — Apple's
              // licence on an iPhone, the site's own everywhere else.
              ProfileRow(
                key: const ValueKey('profile-privacy'),
                mark: ProfileMarks.shield,
                label: context.l10n.privacyPolicy,
                onTap: () => _openLegal('privacy', kPrivacyUrl),
              ),
              ProfileRow(
                key: const ValueKey('profile-terms'),
                mark: ProfileMarks.page,
                label: context.l10n.termsOfUse,
                onTap: () => _openLegal(
                  'terms',
                  termsUrlFor(Theme.of(context).platform),
                ),
              ),
              _UsageSwitch(app: app),
            ],
          ),
          // Deleting the account, for anyone who has one — the phone makes
          // one of its own before anybody signs in, and that one holds a
          // backup too. In a box of its own at the very end, in red: where a
          // reader looking for it finds it, and where nobody trips on it.
          ListenableBuilder(
            listenable: account,
            builder: (context, _) {
              if (!account.signedIn) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 26),
                child: ProfileBox(
                  children: [
                    ProfileRow(
                      key: const ValueKey('profile-delete'),
                      mark: ProfileMarks.bin,
                      label: account.deleting
                          ? context.l10n.deletingAccount
                          : context.l10n.deleteAccount,
                      color: context.p.alert,
                      chevron: false,
                      onTap: account.deleting
                          ? () {}
                          : () => _confirmDelete(context),
                    ),
                  ],
                ),
              );
            },
          ),
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
            // Looks to set side by side on the phone itself, first in the
            // section, where they are found: each shows at once and is kept
            // on the phone (DebugLooks).
            _DebugLooksPanel(app: app),
            // The paywall the look picked above shows, on any plan: a phone
            // already on Astute+ has no locked door left to open it by.
            _LinkRow(
              key: const ValueKey('debug-open-paywall'),
              label: 'Open the paywall',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PaywallScreen(app: app, source: 'debug'),
                ),
              ),
            ),
            // The first week's page and the first month's, with sample
            // numbers, on any plan: only looked at, nothing kept or
            // counted (lib/state/first_offers.dart says when they come).
            _LinkRow(
              key: const ValueKey('debug-first-week'),
              label: 'Preview: your first week',
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                FirstOfferScreen.route(app, FirstOffer.week, preview: true),
              ),
            ),
            _LinkRow(
              key: const ValueKey('debug-first-month'),
              label: 'Preview: your first month',
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                FirstOfferScreen.route(app, FirstOffer.month, preview: true),
              ),
            ),
            const SizedBox(height: 14),
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

/// Invita un amico (lib/sync/invite.dart): "Invite a friend", which opens
/// the sheet with the reader's code and sends it; and, for a new reader who
/// has never held Astute+, "Have a code?" — or, once a code is taken, that
/// its week starts with the first day. Nothing at all while the server has
/// the switch off, the build cannot take part, or the server says
/// invitations are not set up. Asks the server once as it is first shown,
/// and says once, here, the weeks friends earned the reader since.
class _InviteBox extends StatefulWidget {
  const _InviteBox({required this.app});

  final AppState app;

  @override
  State<_InviteBox> createState() => _InviteBoxState();
}

class _InviteBoxState extends State<_InviteBox> {
  @override
  void initState() {
    super.initState();
    Invites.instance.addListener(_heard);
    if (inviteShown(widget.app)) Invites.instance.refresh();
  }

  @override
  void dispose() {
    Invites.instance.removeListener(_heard);
    super.dispose();
  }

  /// Weeks friends earned the reader since the profile last said so: said
  /// once, quietly, at the foot of the screen.
  void _heard() {
    final int weeks = Invites.instance.newWeeks;
    if (weeks == 0 || !mounted || !inviteShown(widget.app)) return;
    Invites.instance.saidNewWeeks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(context.l10n.inviteEarned(weeks)),
          duration: const Duration(seconds: 6),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Invites.instance, Subscription.instance]),
      builder: (context, _) {
        final AppState app = widget.app;
        if (!inviteShown(app)) return const SizedBox.shrink();
        final Invites invites = Invites.instance;
        final InviteRedeem? redeem = invites.state?.redeem;
        final Subscription store = Subscription.instance;
        // A code of a friend's is for an account the server calls new, that
        // has never held Astute+ — the store's word, once it has spoken —
        // or one a link has brought, which the server judges when it is used.
        final bool neverPlus =
            !app.isPlus && !(store.ready && store.everHeldPlus);
        final bool codeOpen =
            neverPlus &&
            (redeem == InviteRedeem.open ||
                (redeem == null && invites.held != null));
        final bool accepted =
            redeem == InviteRedeem.waiting || redeem == InviteRedeem.granting;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(context.l10n.inviteSection),
            ProfileBox(
              children: [
                ProfileRow(
                  key: const ValueKey('profile-invite'),
                  mark: ProfileMarks.letter,
                  label: context.l10n.inviteRow,
                  value: context.l10n.inviteRowLine,
                  onTap: () => showInviteSheet(context, app),
                ),
                if (codeOpen)
                  ProfileRow(
                    key: const ValueKey('profile-invite-code'),
                    mark: ProfileMarks.ticket,
                    label: context.l10n.inviteCodeRow,
                    onTap: () => showInviteCodeSheet(
                      context,
                      app,
                      code: invites.held,
                      from: invites.held == null ? 'typed' : 'link',
                    ),
                  )
                else if (accepted)
                  ProfileRow(
                    key: const ValueKey('profile-invite-accepted'),
                    mark: ProfileMarks.ticket,
                    label: context.l10n.inviteCodeAccepted,
                    value: context.l10n.inviteCodeAcceptedLine,
                    chevron: false,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// What the archive row says is behind it. On Astute+, the days it keeps:
/// every one the reader finished. On the free plan, the week it shows
/// (kFreeArchiveDays, which the words say): the days before it are there
/// too, under the lock, and counting them would count what cannot be
/// opened. Nothing on Astute+ before a first day is finished, where "0
/// days" would read as an archive that is broken rather than one that has
/// not started.
String? _archiveHolds(BuildContext context, AppState app) {
  if (!app.isPlus) return context.l10n.lastSevenDays;
  final int days = app.completedDates.toSet().length;
  return days == 0 ? null : context.l10n.streakDays(days);
}

/// Where the reader lives, as the app keeps it: the city — or the region or
/// the country, when the phone named no city — or Off. A tap on a place
/// offers to read it again or remove it; a tap on Off is the sheet that
/// asks, the same one Explore's shelf opens. That only the city is kept,
/// never the position, is said on both sheets, where the choice is made,
/// rather than under the row.
class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Place? place = app.place;
    return ProfileRow(
      key: const ValueKey('place-row'),
      mark: ProfileMarks.pin,
      label: l.placeRowTitle,
      value: place == null ? l.placeRowOff : placeName(place),
      onTap: () => place == null
          ? askForPlace(context, app, from: 'profile')
          : showPlaceOptions(context, app),
    );
  }
}

/// The reader's own switch over measurement.
///
/// Stateful, alone on this stateless screen, because what it shows is not
/// part of AppState: it is a decision about this install rather than about
/// this reader, so it does not travel to a new phone with the backup and
/// there is no listener above to rebuild from.
/// The music cards' notes: off until the reader turns them on, here or
/// from a card's Listen. The whole row is the switch.
class _SoundRow extends StatelessWidget {
  const _SoundRow();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ValueListenableBuilder<bool>(
      valueListenable: MusicSound.on,
      builder: (context, on, _) => ProfileRow(
        key: const ValueKey('profile-sound'),
        mark: ProfileMarks.sound,
        label: l.musicSound,
        toggled: on,
        chevron: false,
        onTap: () => MusicSound.set(!on, from: 'profile'),
        trailing: NudgeSwitch(
          value: on,
          label: l.musicSound,
          onChanged: (v) => MusicSound.set(v, from: 'profile'),
        ),
      ),
    );
  }
}

/// The reader's answer to whether Astute may measure how the app is used —
/// the same answer the intro and the sheet after the first finished day
/// ask for, kept in the same place (Analytics.setCollecting). Off until the
/// reader has said yes.
class _UsageSwitch extends StatefulWidget {
  const _UsageSwitch({required this.app});

  final AppState app;

  @override
  State<_UsageSwitch> createState() => _UsageSwitchState();
}

class _UsageSwitchState extends State<_UsageSwitch> {
  late bool _on = Analytics.collecting;

  Future<void> _set(bool v) async {
    final l = context.l10n;
    // The switch moves first. Waiting on a write to disk to show a toggle
    // is what makes a second tap look necessary.
    setState(() => _on = v);
    final messenger = ScaffoldMessenger.of(context);
    // Said while it can still be said: turning measurement off is the last
    // event, turning it on the first.
    if (!v) {
      Analytics.capture('usage sharing switched', {'on': false});
    }
    await Analytics.setCollecting(v);
    if (v) {
      Analytics.capture('usage sharing switched', {'on': true});
      // A yes may just have started measurement: the reader's profile is
      // said now that there is somewhere to say it.
      if (widget.app.ready) widget.app.refreshAnalytics();
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(v ? l.usageOn : l.usageOff)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // A row of the About box, with what it measures under it. The whole
    // row is the switch, so the target is a finger's height and not only
    // the switch's thirty points.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileRow(
          key: const ValueKey('profile-usage'),
          mark: ProfileMarks.chart,
          label: l.anonymousUsage,
          toggled: _on,
          chevron: false,
          onTap: () => _set(!_on),
          trailing: NudgeSwitch(
            value: _on,
            label: l.anonymousUsage,
            onChanged: _set,
          ),
        ),
        ProfileRowNote(l.anonymousUsageLine),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkRow({super.key, required this.label, required this.onTap});

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
                        color: context.p.ink,
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
                    kCalibrationFloor - app.calibratedAnswers,
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
                  context.l10n.elided(
                    context.l10n.rightPercentOf(
                      bucket.actual.round(),
                      bucket.right,
                      bucket.count,
                    ),
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
    // A segmented control in glass, as iOS 26 draws one: the track is
    // glass, the chosen segment solid.
    final Widget row = Row(
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
                constraints: const BoxConstraints(minHeight: 44),
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
                    color: selected ? context.p.onInverse : context.p.inkMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
    return PaperCard(padding: const EdgeInsets.all(6), radius: 18, child: row);
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
              const SizedBox(width: 12),
              // Room for the free days whatever their length: in Russian,
              // at a larger text size on a small phone, they pushed the
              // row past the card's edge.
              Expanded(
                child: Text(
                  switch (Subscription.instance.trialDays) {
                    final int days => context.l10n.trialDaysFree(days),
                    null => '',
                  },
                  textAlign: TextAlign.end,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: context.p.onInverse.withValues(alpha: 0.6),
                  ),
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

/// The looks the developer tools try on this phone ([DebugLooks]): the
/// finished day without the row over its card, where the day is sent from
/// and the picture it is sent as, which top the profile opens on, how a
/// card's foot is set, how a hard card looks, What to learn's look, and
/// which paywall. English, as the rest of the section is.
class _DebugLooksPanel extends StatelessWidget {
  const _DebugLooksPanel({required this.app});

  /// For the day's moment, shown from here to be looked at.
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: DebugLooks.noTopRow,
            builder: (context, on, _) => _DebugSwitchRow(
              key: const ValueKey('debug-no-top-row'),
              label: 'Today, day read: no top row',
              note:
                  'No "Day 4" row over the finished day, so the card is '
                  'bigger. See again and Share go to the ends of the dots.',
              value: on,
              onChanged: DebugLooks.setNoTopRow,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: ValueListenableBuilder<ShareDayPick>(
              valueListenable: DebugLooks.shareDay,
              builder: (context, pick, _) =>
                  _ShareDayLook(app: app, pick: pick),
            ),
          ),
          Container(
            key: const ValueKey('debug-share-picture'),
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Share picture',
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w500,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'The picture the day is sent as, from Share your day. A: the '
                  'old one, drawings cut to squares. B: the first drawn card '
                  'whole and lit, the five whole on the list. C: no drawings, '
                  'black lit by the day\'s colours, subject marks. C ships.',
                  style: AppText.body(
                    size: 12,
                    height: 1.35,
                    color: p.inkFaint,
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<SharePictureLook>(
                  valueListenable: DebugLooks.sharePicture,
                  builder: (context, look, _) =>
                      _SharePicturePicker(look: look),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profile top',
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w500,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Auto is the plan\'s own: A for free readers, C for '
                  'Astute+.',
                  style: AppText.body(
                    size: 12,
                    height: 1.35,
                    color: p.inkFaint,
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<ProfileTopPick>(
                  valueListenable: DebugLooks.profileTop,
                  builder: (context, pick, _) => _ProfileTopPicker(pick: pick),
                ),
              ],
            ),
          ),
          Container(
            key: const ValueKey('debug-card-foot'),
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Card foot',
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w500,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'How the back of a card ends: Go deeper and its source, '
                  'and Why this card. On cards in words and drawn ones. '
                  'A is how the app ships.',
                  style: AppText.body(
                    size: 12,
                    height: 1.35,
                    color: p.inkFaint,
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<CardFootPick?>(
                  valueListenable: DebugLooks.cardFoot,
                  builder: (context, pick, _) => _CardFootPicker(
                    pick: pick ?? footPickOf(builtSourceFoot),
                  ),
                ),
              ],
            ),
          ),
          Container(
            key: const ValueKey('debug-hard-cards'),
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hard cards',
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w500,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ringed: a hard card, wherever it is read, dark and ringed '
                  'in its subject\'s colour with HARD on it, as Explore\'s '
                  'shelf of the hardest draws it; front and back, in words '
                  'and drawn. As today is how the app ships.',
                  style: AppText.body(
                    size: 12,
                    height: 1.35,
                    color: p.inkFaint,
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<HardCardLook>(
                  valueListenable: DebugLooks.hardCards,
                  builder: (context, look, _) => _HardCardsPicker(look: look),
                ),
              ],
            ),
          ),
          Container(
            key: const ValueKey('debug-learn'),
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'What to learn',
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w500,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Now is as it ships: skills picked, a score in each, their '
                  'mark on cards. A: the Astute score alone. B: the aim '
                  'alone, asked at the end of the first run too (wipe to see '
                  'it), its week in Your journey. C: no picking; where the '
                  'answers say you are strong. D: the aim read: where you '
                  'see clearly and your blind spot, under the question. E: '
                  'one of the aim\'s skills a week, its mark on cards, a '
                  'shelf on Explore, and Sunday\'s result.',
                  style: AppText.body(
                    size: 12,
                    height: 1.35,
                    color: p.inkFaint,
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<LearnLook>(
                  valueListenable: DebugLooks.learn,
                  builder: (context, look, _) => _LearnPicker(look: look),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Paywall',
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w500,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'A is the paywall as it ships. B: real cards for the marks '
                  'and the free days on a line. C: B opening on the reader\'s '
                  'goal and subjects. D: B in two steps, the plans in a sheet.',
                  style: AppText.body(
                    size: 12,
                    height: 1.35,
                    color: p.inkFaint,
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<PaywallLook>(
                  valueListenable: DebugLooks.paywall,
                  builder: (context, look, _) => _PaywallLookPicker(look: look),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Now, A, B, C, D or E, as What to learn's look: a segmented control like
/// the profile top's, each choice with what it is under its letter, in two
/// rows of three, where six in one would leave each too narrow for its
/// word.
class _LearnPicker extends StatelessWidget {
  const _LearnPicker({required this.look});

  final LearnLook look;

  static const _options = [
    (look: LearnLook.today, name: 'Now', note: 'skills'),
    (look: LearnLook.score, name: 'A', note: 'score'),
    (look: LearnLook.aim, name: 'B', note: 'the aim'),
    (look: LearnLook.profile, name: 'C', note: 'strengths'),
    (look: LearnLook.aimProfile, name: 'D', note: 'aim, read'),
    (look: LearnLook.weekly, name: 'E', note: 'a week'),
  ];

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.all(5),
      radius: 16,
      child: Column(
        children: [
          for (int row = 0; row < _options.length; row += 3)
            _row(context, _options.sublist(row, row + 3)),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    List<({LearnLook look, String name, String note})> options,
  ) {
    final p = context.p;
    return Row(
      children: [
        for (final option in options)
          Expanded(
            child: Builder(
              builder: (context) {
                final bool selected = option.look == look;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: '${option.name}, ${option.note}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: ValueKey('debug-learn-${option.look.name}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (selected) return;
                      HapticFeedback.selectionClick();
                      DebugLooks.setLearn(option.look);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? p.inverse : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            option.name,
                            maxLines: 1,
                            style: AppText.body(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: selected ? p.onInverse : p.ink,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            option.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              size: 10.5,
                              weight: FontWeight.w500,
                              color: (selected ? p.onInverse : p.inkMuted)
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// A, B, C or D, as the paywall: a segmented control like the profile
/// top's, each choice with what it is under its letter.
class _PaywallLookPicker extends StatelessWidget {
  const _PaywallLookPicker({required this.look});

  final PaywallLook look;

  static const _options = [
    (look: PaywallLook.a, name: 'A', note: 'the old one'),
    (look: PaywallLook.b, name: 'B', note: 'cards, days'),
    (look: PaywallLook.c, name: 'C', note: 'for you, ships'),
    (look: PaywallLook.d, name: 'D', note: 'two steps'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return PaperCard(
      padding: const EdgeInsets.all(5),
      radius: 16,
      child: Row(
        children: [
          for (final option in _options)
            Expanded(
              child: Builder(
                builder: (context) {
                  final bool selected = option.look == look;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: 'Paywall ${option.name}, ${option.note}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey('debug-paywall-${option.look.name}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (selected) return;
                        HapticFeedback.selectionClick();
                        DebugLooks.setPaywall(option.look);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? p.inverse : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              option.name,
                              maxLines: 1,
                              style: AppText.body(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: selected ? p.onInverse : p.ink,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              option.note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(
                                size: 10.5,
                                weight: FontWeight.w500,
                                color: (selected ? p.onInverse : p.inkMuted)
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// A row of the debug section that is a switch, the whole row: its name,
/// what it does under it, and the switch at its end.
class _DebugSwitchRow extends StatelessWidget {
  const _DebugSwitchRow({
    super.key,
    required this.label,
    required this.note,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String note;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w500,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    note,
                    style: AppText.body(
                      size: 12,
                      height: 1.35,
                      color: p.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            NudgeSwitch(value: value, label: label, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// One choice of a debug picker: what it picks, its letter or name, what
/// it is under it, how a screen reader says it, and how much of the row it
/// takes.
typedef _DebugChoice<T> = ({
  T pick,
  String name,
  String note,
  String said,
  int flex,
});

/// A segmented control like the appearance's, each choice with what it is
/// under its letter: the debug section's way of picking one look of a few.
class _DebugPicker<T> extends StatelessWidget {
  const _DebugPicker({
    required this.choices,
    required this.picked,
    required this.keyOf,
    required this.onPick,
  });

  final List<_DebugChoice<T>> choices;
  final T picked;

  /// Each choice's key: `debug-card-foot-d`.
  final String Function(T pick) keyOf;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return PaperCard(
      padding: const EdgeInsets.all(5),
      radius: 16,
      child: Row(
        children: [
          for (final _DebugChoice<T> choice in choices)
            Expanded(
              flex: choice.flex,
              child: Builder(
                builder: (context) {
                  final bool selected = choice.pick == picked;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: choice.said,
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey(keyOf(choice.pick)),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (selected) return;
                        HapticFeedback.selectionClick();
                        onPick(choice.pick);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? p.inverse : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              choice.name,
                              maxLines: 1,
                              style: AppText.body(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: selected ? p.onInverse : p.ink,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              choice.note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(
                                size: 10.5,
                                weight: FontWeight.w500,
                                color: (selected ? p.onInverse : p.inkMuted)
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// A, B, C or D, as the foot of a card's back (source_foot.dart): the one
/// picked, or the build's own while none is.
class _CardFootPicker extends StatelessWidget {
  const _CardFootPicker({required this.pick});

  final CardFootPick pick;

  static const List<_DebugChoice<CardFootPick>> _choices = [
    (pick: CardFootPick.a, name: 'A', note: 'line', said: 'A, line', flex: 1),
    (
      pick: CardFootPick.b,
      name: 'B',
      note: 'two lines',
      said: 'B, two lines',
      flex: 1,
    ),
    (
      pick: CardFootPick.c,
      name: 'C',
      note: 'buttons',
      said: 'C, buttons',
      flex: 1,
    ),
    (pick: CardFootPick.d, name: 'D', note: 'links', said: 'D, links', flex: 1),
  ];

  @override
  Widget build(BuildContext context) => _DebugPicker<CardFootPick>(
    choices: _choices,
    picked: pick,
    keyOf: (pick) => 'debug-card-foot-${pick.name}',
    onPick: DebugLooks.setCardFoot,
  );
}

/// A, B or C, as the picture the day is sent as (share_looks.dart).
class _SharePicturePicker extends StatelessWidget {
  const _SharePicturePicker({required this.look});

  final SharePictureLook look;

  static const List<_DebugChoice<SharePictureLook>> _choices = [
    (
      pick: SharePictureLook.a,
      name: 'A',
      note: 'the old one',
      said: 'Share picture A, the old one',
      flex: 1,
    ),
    (
      pick: SharePictureLook.b,
      name: 'B',
      note: 'cards',
      said: 'Share picture B, cards',
      flex: 1,
    ),
    (
      pick: SharePictureLook.c,
      name: 'C',
      note: 'light, ships',
      said: 'Share picture C, light, ships',
      flex: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) => _DebugPicker<SharePictureLook>(
    choices: _choices,
    picked: look,
    keyOf: (pick) => 'debug-share-picture-${pick.name}',
    onPick: DebugLooks.setSharePicture,
  );
}

/// As today or ringed, as a hard card wherever it is read (hard_ring.dart).
class _HardCardsPicker extends StatelessWidget {
  const _HardCardsPicker({required this.look});

  final HardCardLook look;

  static const List<_DebugChoice<HardCardLook>> _choices = [
    (
      pick: HardCardLook.today,
      name: 'As today',
      note: 'like any card',
      said: 'Hard cards as today',
      flex: 1,
    ),
    (
      pick: HardCardLook.ringed,
      name: 'Ringed',
      note: 'dark, HARD',
      said: 'Hard cards ringed',
      flex: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) => _DebugPicker<HardCardLook>(
    choices: _choices,
    picked: look,
    keyOf: (pick) => 'debug-hard-cards-${pick.name}',
    onPick: DebugLooks.setHardCards,
  );
}

/// Auto, A, B or C, as the profile's top: a segmented control like the
/// appearance's, each choice with what it is under its letter.
class _ProfileTopPicker extends StatelessWidget {
  const _ProfileTopPicker({required this.pick});

  final ProfileTopPick pick;

  static const _options = [
    (pick: ProfileTopPick.auto, name: 'Auto', note: 'A free · C Astute+'),
    (pick: ProfileTopPick.a, name: 'A', note: 'score'),
    (pick: ProfileTopPick.b, name: 'B', note: 'week'),
    (pick: ProfileTopPick.c, name: 'C', note: 'board'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return PaperCard(
      padding: const EdgeInsets.all(5),
      radius: 16,
      child: Row(
        children: [
          for (final option in _options)
            Expanded(
              // Auto carries the most words.
              flex: option.pick == ProfileTopPick.auto ? 2 : 1,
              child: Builder(
                builder: (context) {
                  final bool selected = option.pick == pick;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: option.pick == ProfileTopPick.auto
                        ? 'Auto (${option.note})'
                        : '${option.name}, ${option.note}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey('debug-profile-top-${option.pick.name}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (selected) return;
                        HapticFeedback.selectionClick();
                        DebugLooks.setProfileTop(option.pick);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? p.inverse : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              option.name,
                              maxLines: 1,
                              style: AppText.body(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: selected ? p.onInverse : p.ink,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              option.note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(
                                size: 10.5,
                                weight: FontWeight.w500,
                                color: (selected ? p.onInverse : p.inkMuted)
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Where the finished day is sent from, A to D, the four ways drawn for the
/// owner (DebugLooks.shareDay): a segmented control like the profile top's,
/// what the one picked does under it, and, for the day's moment, a way to
/// see it now rather than at the end of tomorrow's five.
class _ShareDayLook extends StatelessWidget {
  const _ShareDayLook({required this.app, required this.pick});

  final AppState app;
  final ShareDayPick pick;

  static const _options = [
    (
      pick: ShareDayPick.a,
      name: 'A',
      note: 'today',
      says:
          'As it ships: See again and the share mark at the end of the '
          '"Day 4" row.',
    ),
    (
      pick: ShareDayPick.b,
      name: 'B',
      note: 'mark',
      says:
          'See again leaves Today (Explore keeps "Your five from today"); '
          'only the share mark stays at the end of the row.',
    ),
    (
      pick: ShareDayPick.c,
      name: 'C',
      note: 'moment',
      says:
          'Right after the five, a screen of its own: the day\'s picture, '
          '"Share your day" and "Later". Once a day, only when the day is '
          'finished in that sitting, never on the evening of a new level, '
          'and no more after three Laters in a row. The shelf after it has '
          'the share mark alone.',
    ),
    (
      pick: ShareDayPick.d,
      name: 'D',
      note: 'card',
      says:
          'The day as a card after the five on the shelf, "Your day": its '
          'picture and Share. The shelf lands on it the evening the day is '
          'finished. Nothing at the end of the row.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final String says = _options.firstWhere((o) => o.pick == pick).says;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Today, day read: share the day',
          style: AppText.body(size: 14, weight: FontWeight.w500, color: p.ink),
        ),
        const SizedBox(height: 3),
        Text(
          'Where the finished day is sent from. A is the app as it ships.',
          style: AppText.body(size: 12, height: 1.35, color: p.inkFaint),
        ),
        const SizedBox(height: 10),
        PaperCard(
          padding: const EdgeInsets.all(5),
          radius: 16,
          child: Row(
            children: [
              for (final option in _options)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final bool selected = option.pick == pick;
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: '${option.name}, ${option.note}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          key: ValueKey('debug-share-day-${option.pick.name}'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (selected) return;
                            HapticFeedback.selectionClick();
                            DebugLooks.setShareDay(option.pick);
                            // Picked again, the moment is as new: the owner
                            // trying it is not a reader who said Later.
                            if (option.pick == ShareDayPick.c) {
                              DayMomentMemory.forget();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? p.inverse : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  option.name,
                                  maxLines: 1,
                                  style: AppText.body(
                                    size: 13.5,
                                    weight: FontWeight.w700,
                                    color: selected ? p.onInverse : p.ink,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  option.note,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(
                                    size: 10.5,
                                    weight: FontWeight.w500,
                                    color: (selected ? p.onInverse : p.inkMuted)
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          says,
          key: const ValueKey('debug-share-day-says'),
          style: AppText.body(size: 12, height: 1.35, color: p.inkFaint),
        ),
        if (pick == ShareDayPick.c) ...[
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GestureDetector(
              key: const ValueKey('debug-share-day-moment'),
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(
                context,
                rootNavigator: true,
              ).push(DayMoment.route(app, preview: true)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Show the moment now  →',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: p.link,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
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

/// A free trial's last two days, said once and quietly under the profile's
/// top, to a reader the warning before the charge does not reach
/// (AppState.trialNoticeDays). It is that warning, shorter: when the trial
/// ends, and the way to manage it — the store's own screen, which the
/// Manage subscription row further down opens too.
class _TrialNotice extends StatelessWidget {
  const _TrialNotice({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final int? days = app.trialNoticeDays();
    if (days == null) return const SizedBox.shrink();
    final l = context.l10n;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('trial-notice'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Analytics.capture('manage subscription opened', {
            'is_plus': app.isPlus,
            'from': 'trial notice',
            'days_left': days,
          });
          Subscription.instance.presentCustomerCenter();
        },
        // A whole line to tap, of a height a finger finds.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l.trialEndsNotice(days)),
                  const TextSpan(text: '  ·  '),
                  TextSpan(
                    text: l.trialNoticeManage,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: context.p.link,
                    ),
                  ),
                ],
              ),
              style: AppText.body(size: 13, color: context.p.inkMuted),
            ),
          ),
        ),
      ),
    );
  }
}
