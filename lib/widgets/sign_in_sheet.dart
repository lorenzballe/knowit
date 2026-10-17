import 'package:flutter/material.dart';

import '../analytics.dart';
import '../debug_flags.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../sync/account.dart';
import '../sync/subscription.dart';
import '../theme.dart';
import 'profile_menu.dart' show GoogleMark;
import 'ui.dart';

/// Where an account is offered from. Each door says it in its own words,
/// and the funnel counts them apart.
enum SignInDoor {
  /// The intro's quiet "Already have an account? Sign in": a reader coming
  /// back, on the dark ground the intro keeps whatever the theme.
  intro('intro'),

  /// Profile's "Keep your streak on a new phone".
  profile('profile'),

  /// Once, after the first finished day, when there is a streak to keep.
  firstDay('day done');

  const SignInDoor(this.from);

  /// What the door is called in the funnel.
  final String from;
}

/// How quickly a sign-in comes back "cancelled" when no sheet was ever on
/// the screen. A person who sees Apple's or Google's sheet and backs out of
/// it takes longer than this; the cancellations App Review's phones sent
/// came back in three milliseconds, and the reader saw a button that did
/// nothing at all.
const Duration kNoSheetWithin = Duration(milliseconds: 1000);

/// One sign-in, as every door runs it: counted on the way in and on the way
/// out, the store told who the reader now is, and the funnel too.
///
/// [noSheet] is a cancellation that came back too fast to have been a
/// person's: the screen says something for it, as for a failure, rather
/// than leaving a tap that did nothing.
Future<({SignInOutcome outcome, bool noSheet})> runSignIn({
  required Account account,
  required AppState app,
  required String method,
  required String from,
}) async {
  // One at a time. A second flow started while the first sheet is up
  // cancels both, and a reader who tapped twice would get nothing.
  if (account.busy) return (outcome: SignInOutcome.cancelled, noSheet: false);
  Analytics.capture('sign in started', {'method': method, 'from': from});
  final Stopwatch took = Stopwatch()..start();
  final SignInOutcome outcome = method == 'Apple'
      ? await account.signInWithApple(app)
      : await account.signInWithGoogle(app);
  final int ms = took.elapsedMilliseconds;
  final bool noSheet =
      outcome == SignInOutcome.cancelled && ms < kNoSheetWithin.inMilliseconds;
  final String? error = account.lastError;
  Analytics.capture('sign in ended', {
    'method': method,
    'outcome': outcome.name,
    'from': from,
    'ms': ms,
    if (outcome == SignInOutcome.cancelled) 'no_sheet': noSheet,
    // Which road it took — the phone's own sheet or Firebase's browser.
    // Two rounds were spent working that out by hand once already.
    'route': account.lastRoute,
    // Why it failed, as Apple, Google or Firebase put it: an error code and
    // its sentence, never anything the reader typed. Without it, 71 failed
    // sign-ins in a row from App Review's phones said only "failed", and
    // the one place the reason showed was a snackbar on a phone nobody here
    // was holding.
    'error':
        (outcome == SignInOutcome.failed ||
                outcome == SignInOutcome.unavailable) &&
            error != null
        ? Analytics.short(error)
        : null,
  });
  if (outcome == SignInOutcome.signedIn) {
    // The account id may have changed, and the plan belongs to the reader
    // rather than to the phone.
    await Subscription.instance.switchTo(account.uid);
    final String? uid = account.uid;
    if (uid != null) {
      await Analytics.identify(
        uid,
        anonymous: !account.signedInForReal,
        method: method,
      );
    }
  }
  return (outcome: outcome, noSheet: noSheet);
}

/// Offers an account: Apple and Google on one sheet, and a way past it.
/// Returns true once the reader is signed in, and false for "Not now", a
/// sheet swiped away, or a sign-in that did not end in one.
///
/// A sign-in that fails, or a sheet that never opened, is said on this
/// sheet, under the buttons, in the reader's language: the reader is never
/// left with a button that did nothing. Backing out of Apple's or Google's
/// own sheet says nothing, because nothing went wrong.
Future<bool> showSignInSheet(
  BuildContext context, {
  required Account account,
  required AppState app,
  required SignInDoor door,
}) async {
  Analytics.capture('sign in sheet shown', {'from': door.from});
  final bool? signedIn = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) {
      final Widget sheet = SignInSheet(account: account, app: app, door: door);
      // The intro is black whatever the theme, and a paper sheet rising
      // over it would be a second app; everywhere else the sheet follows
      // the reader's choice.
      return door == SignInDoor.intro
          ? Theme(data: buildAstutoTheme(Brightness.dark), child: sheet)
          : sheet;
    },
  );
  Analytics.capture('sign in sheet closed', {
    'from': door.from,
    'signed_in': signedIn ?? false,
  });
  return signedIn ?? false;
}

/// The sheet: what an account keeps, the two ways to make one, what went
/// wrong if something did, and the way past. Public so a test can lay it
/// out in every language.
class SignInSheet extends StatefulWidget {
  const SignInSheet({
    super.key,
    required this.account,
    required this.app,
    required this.door,
  });

  final Account account;
  final AppState app;
  final SignInDoor door;

  @override
  State<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<SignInSheet> {
  /// The provider being signed in with, while it runs: its button says so,
  /// and neither takes a second tap.
  String? _running;

  /// What went wrong last, said under the buttons until the next try; and,
  /// while the debug tools are on, what actually went wrong, under that. A
  /// polite sentence is the right thing for a reader and the wrong thing
  /// for the person trying to fix it.
  String? _note;
  String? _detail;

  Future<void> _go(String method) async {
    if (_running != null || widget.account.busy) return;
    setState(() {
      _running = method;
      _note = null;
      _detail = null;
    });
    final result = await runSignIn(
      account: widget.account,
      app: widget.app,
      method: method,
      from: widget.door.from,
    );
    if (!mounted) return;
    if (result.outcome == SignInOutcome.signedIn) {
      Navigator.of(context).pop(true);
      return;
    }
    final String? note = _noteFor(
      method,
      result.outcome,
      noSheet: result.noSheet,
    );
    final String? raw = widget.account.lastError;
    setState(() {
      _running = null;
      _note = note;
      _detail = note != null && debugToolsOn && raw != null
          ? '$method: $raw'
          : null;
    });
  }

  /// What the reader is told, in their language.
  String? _noteFor(
    String method,
    SignInOutcome outcome, {
    required bool noSheet,
  }) {
    final l = context.l10n;
    final String failed = widget.door == SignInDoor.intro
        ? l.couldNotSignInCarryOn(method)
        : l.couldNotSignInWith(method);
    return switch (outcome) {
      SignInOutcome.signedIn => null,
      SignInOutcome.cancelled => noSheet ? failed : null,
      SignInOutcome.failed => failed,
      SignInOutcome.unavailable => l.signInNotAvailableBuild,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final bool back = widget.door == SignInDoor.intro;
    final (String title, String line) = switch (widget.door) {
      SignInDoor.intro => (l.signInWelcomeTitle, l.signInWelcomeLine),
      SignInDoor.profile => (l.keepStreakOnNewPhone, l.keepStreakLine),
      SignInDoor.firstDay => (l.keepStreakTitle, l.keepStreakLine),
    };
    final String? note = _note;
    final String? detail = _detail;
    return Container(
      key: const ValueKey('sign-in-sheet'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: p.lineStrong,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              line,
              style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
            ),
            const SizedBox(height: 20),
            _ProviderButton(
              key: const ValueKey('sign-in-apple'),
              label: _running == 'Apple'
                  ? l.signingIn
                  : back
                  ? l.continueWithApple
                  : l.signInWithApple,
              leading: (ink) => Icon(Icons.apple, size: 21, color: ink),
              enabled: _running == null,
              onTap: () => _go('Apple'),
            ),
            const SizedBox(height: 10),
            _ProviderButton(
              key: const ValueKey('sign-in-google'),
              label: _running == 'Google'
                  ? l.signingIn
                  : back
                  ? l.continueWithGoogle
                  : l.signInWithGoogle,
              leading: (_) => const GoogleMark(size: 19),
              enabled: _running == null,
              onTap: () => _go('Google'),
            ),
            // Said where the reader is looking, and read out as it changes.
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    note,
                    key: const ValueKey('sign-in-note'),
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 13.5,
                      weight: FontWeight.w500,
                      height: 1.4,
                      color: p.alert,
                    ),
                  ),
                ),
              ),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SelectableText(
                  detail,
                  key: const ValueKey('sign-in-detail'),
                  textAlign: TextAlign.center,
                  style: AppText.body(size: 11.5, color: p.inkFaint),
                ),
              ),
            const SizedBox(height: 6),
            QuietButton(
              key: const ValueKey('sign-in-not-now'),
              label: l.signInNotNow,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apple's or Google's way in: the mark and the words, on the page's own
/// reversed pair — white on the intro's black and in the dark theme, black
/// on paper. A finger high at least, and as tall again as a longer
/// language or a larger text size needs: the words wrap rather than end in
/// dots.
class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    super.key,
    required this.label,
    required this.leading,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Widget Function(Color ink) leading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Color ink = p.onInverse;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.55,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: p.inverse,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading(ink),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 16,
                      weight: FontWeight.w600,
                      spacing: -0.2,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
