import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../cloud.dart';
import '../state/app_state.dart';
import 'identity.dart';
import 'reader_snapshot.dart';
import 'reader_store.dart';

/// How a sign-in ended, in terms the screen can act on.
enum SignInOutcome { signedIn, cancelled, unavailable, failed }

/// The reader's account, and the one place that folds a phone into it.
///
/// The app works signed out and always has: this only decides whether what
/// the phone knows also lives somewhere it survives the phone.
class Account extends ChangeNotifier {
  /// The seams the tests use. Left null, the account reaches for the real
  /// Firebase — and finds nothing unless Cloud.start() succeeded.
  Account({
    this.authOverride,
    this.storeOverride,
    this.uidOverride,
    Identity? identity,
  }) : _identity = identity ?? Identity();

  /// Stand-ins for the real Firebase, so a sign-in can be driven in a test
  /// without a project, a network or a device. Null in the app.
  final FirebaseAuth? authOverride;
  final ReaderStore? storeOverride;

  /// Stands in for a signed-in reader. FirebaseAuth cannot be faked, so
  /// without this seam the backing-up path could only be tested on a phone.
  final String? uidOverride;

  /// Where an identity comes from before Firebase sees it: the phone's own
  /// sign-in sheets, or a stand-in under a test.
  final Identity _identity;

  bool _busy = false;

  /// The last thing that went wrong, kept for the debug section. A silent
  /// failure is the hardest kind to report.
  String? lastError;
  AppState? _watching;
  Timer? _pending;

  /// How long the app waits after a change before backing it up. Long enough
  /// that answering five cards is one write rather than five, short enough
  /// that closing the app straight after still catches it — and a close
  /// flushes immediately anyway.
  static const Duration _settle = Duration(seconds: 4);

  /// True while a sign-in is in flight, so the button can say so.
  bool get busy => _busy;

  FirebaseAuth? get _firebase =>
      authOverride ?? (Cloud.ready ? FirebaseAuth.instance : null);

  ReaderStore? get _readers =>
      storeOverride ?? (Cloud.ready ? FirestoreReaderStore() : null);

  User? get user => _firebase?.currentUser;

  /// Who is signed in, if anyone. Everything that writes goes through this.
  String? get uid => uidOverride ?? user?.uid;

  bool get signedIn => uid != null;

  /// Whether a person signed in, rather than the phone having been given an
  /// account to write to. The profile asks this one.
  bool get signedInForReal => user != null && !user!.isAnonymous;

  /// What to show on the profile: the email if the provider shared one,
  /// otherwise nothing useful — Apple lets people hide theirs, and inventing
  /// a label for that case would be worse than saying "signed in".
  String? get email {
    final String? value = user?.email;
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<SignInOutcome> signInWithApple(AppState app) => _signIn(
    app,
    'Apple',
    _identity.apple,
    () => AppleAuthProvider()
      ..addScope('email')
      ..addScope('name'),
  );

  Future<SignInOutcome> signInWithGoogle(AppState app) => _signIn(
    app,
    'Google',
    _identity.google,
    () => GoogleAuthProvider()..addScope('email'),
  );

  /// Both providers do the same thing: get an identity from the phone, hand
  /// it to Firebase, then fold this phone into whatever the account holds.
  ///
  /// [ask] is the system sheet. Where there is none — Apple on Android, a
  /// phone the Google sheet cannot run on — it says so instead of failing,
  /// and [build] is the browser flow Firebase runs itself.
  Future<SignInOutcome> _signIn(
    AppState app,
    String label,
    Future<IdentityResult> Function() ask,
    AuthProvider Function() build,
  ) async {
    final FirebaseAuth? auth = _firebase;
    if (auth == null) {
      lastError = Cloud.failure ?? 'Firebase is not running on this build.';
      return SignInOutcome.unavailable;
    }

    // A second tap while the first sheet is still up starts a second flow,
    // and the two cancel each other — so a reader who taps twice gets nothing
    // at all. One at a time.
    if (_busy) return SignInOutcome.cancelled;

    lastError = null;
    _busy = true;
    notifyListeners();
    try {
      final IdentityResult identity = await ask();
      switch (identity.outcome) {
        case IdentityOutcome.cancelled:
          return SignInOutcome.cancelled;
        case IdentityOutcome.failed:
          lastError = identity.error;
          debugPrint('$label sign-in failed: $lastError');
          return SignInOutcome.failed;
        case IdentityOutcome.noSheet:
          // Worth a line: falling back is not a failure, but "the sheet was
          // skipped, and here is what it said" is the difference between a
          // fixable misconfiguration and a browser flow nobody ordered.
          if (identity.error != null) {
            debugPrint('$label has no sheet here: ${identity.error}');
          }
          break;
        case IdentityOutcome.got:
          break;
      }

      final AuthCredential? held = identity.credential;
      final UserCredential credential = held == null
          ? await _throughTheBrowser(auth, build)
          : await _withCredential(auth, held);

      final User? signed = credential.user;
      if (signed == null) return SignInOutcome.failed;
      await foldInto(app, signed.uid);
      return SignInOutcome.signedIn;
    } on FirebaseAuthException catch (error) {
      if (isCancellation(error.code)) return SignInOutcome.cancelled;
      lastError = '${error.code}: ${error.message}';
      debugPrint('$label sign-in failed: $lastError');
      return SignInOutcome.failed;
    } catch (error) {
      lastError = '$error';
      debugPrint('$label sign-in failed: $error');
      return SignInOutcome.failed;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Signs in with an identity a system sheet has already produced.
  Future<UserCredential> _withCredential(
    FirebaseAuth auth,
    AuthCredential credential,
  ) async {
    final User? current = auth.currentUser;
    if (current == null || !current.isAnonymous) {
      return auth.signInWithCredential(credential);
    }
    // Promote the account the phone has been writing to, rather than opening
    // a second one — linking keeps the uid, so nothing has to be moved and
    // nothing can be dropped on the way.
    try {
      return await current.linkWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (!identityIsSpokenFor(error.code)) rethrow;
      // This identity already has an account of its own. Firebase hands back
      // the credential it refused, so the reader is not shown the sheet a
      // second time to say what they have just said. The uid changes, and the
      // fold below is what carries this phone's work across.
      return auth.signInWithCredential(error.credential ?? credential);
    }
  }

  /// The same thing where there was no sheet to ask, and Firebase runs the
  /// whole flow itself in a browser.
  Future<UserCredential> _throughTheBrowser(
    FirebaseAuth auth,
    AuthProvider Function() build,
  ) async {
    final User? current = auth.currentUser;
    if (current == null || !current.isAnonymous) {
      return auth.signInWithProvider(build());
    }
    try {
      return await current.linkWithProvider(build());
    } on FirebaseAuthException catch (error) {
      if (!identityIsSpokenFor(error.code)) rethrow;
      final AuthCredential? held = error.credential;
      return held == null
          ? await auth.signInWithProvider(build())
          : await auth.signInWithCredential(held);
    }
  }

  /// Backing out of a sheet is not a failure and must not be reported as one.
  /// Every layer underneath spells it differently, and one missed spelling is
  /// an error message shown to somebody who simply changed their mind.
  @visibleForTesting
  static bool isCancellation(String code) => const {
    'canceled',
    'cancelled',
    'user-canceled',
    'user-cancelled',
    'web-context-canceled',
    'web-context-cancelled',
    'sign-in-cancelled',
    'popup-closed-by-user',
  }.contains(code);

  /// Whether a link failed because the identity already has an account of its
  /// own — in which case signing into that one is the answer, not an error.
  @visibleForTesting
  static bool identityIsSpokenFor(String code) => const {
    'credential-already-in-use',
    'email-already-in-use',
    'provider-already-linked',
  }.contains(code);

  /// Folds this phone into the account, then writes the result back.
  ///
  /// Both directions matter. A reader who has used the app for a week before
  /// signing in must not lose that week, and a reader arriving on a new
  /// phone must not overwrite what the account already holds.
  @visibleForTesting
  Future<ReaderSnapshot?> foldInto(AppState app, String uid) async {
    final ReaderStore? store = _readers;
    if (store == null) return null;

    final ReaderSnapshot local = app.snapshot();
    final ReaderSnapshot remote =
        await store.read(uid) ?? const ReaderSnapshot();
    final ReaderSnapshot merged = mergeSnapshots(local, remote);

    await app.adopt(merged);
    await store.write(uid, merged);
    return merged;
  }

  /// Pushes what the phone knows, for a reader who is already signed in.
  Future<void> push(AppState app) async {
    final String? who = uid;
    final ReaderStore? store = _readers;
    if (who == null || store == null) return;
    try {
      await store.write(who, app.snapshot());
    } catch (error) {
      // A backup that fails is not something to interrupt a reader over.
      debugPrint('Could not push the snapshot: $error');
    }
  }

  /// Gives this phone an account of its own, before anyone signs in.
  ///
  /// Without it a reader who has not signed in has nowhere to keep anything
  /// — no backup, and no address to send a notification to. Since the app
  /// asks for a real account late on purpose, that is most readers for most
  /// of their first week.
  ///
  /// It is not a sign-in and must never look like one: nothing is shown, the
  /// profile still offers Apple and Google, and [signedInForReal] is what the
  /// screens ask about.
  Future<void> ensureAnonymous(AppState app) async {
    final FirebaseAuth? auth = _firebase;
    if (auth == null || auth.currentUser != null) return;
    try {
      final credential = await auth.signInAnonymously();
      final User? signed = credential.user;
      if (signed != null) await foldInto(app, signed.uid);
      notifyListeners();
    } catch (error) {
      // An anonymous provider that is switched off leaves the app exactly
      // where it was before this existed: local only.
      lastError = '$error';
      debugPrint('No anonymous account, carrying on locally: $error');
    }
  }

  /// Starts backing this phone up whenever it changes.
  ///
  /// Signing in only ever uploaded the moment it happened, which made the
  /// account a photograph of that day. Everything after it has to travel too,
  /// or a new phone restores a week that stopped a week ago.
  void watch(AppState app) {
    if (identical(_watching, app)) return;
    _watching?.removeListener(_onAppChanged);
    _watching = app..addListener(_onAppChanged);
  }

  void _onAppChanged() {
    // Nothing to back up to, so nothing to schedule — and in particular no
    // timer left running under a test.
    if (!signedIn || _readers == null) return;
    _pending?.cancel();
    _pending = Timer(_settle, flush);
  }

  /// Writes now rather than in a few seconds. Called when the app goes to the
  /// background, which is the last moment anything is certain to run.
  Future<void> flush() async {
    _pending?.cancel();
    _pending = null;
    final AppState? app = _watching;
    if (app != null) await push(app);
  }

  Future<void> signOut() async {
    _pending?.cancel();
    _pending = null;
    await _firebase?.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _pending?.cancel();
    _watching?.removeListener(_onAppChanged);
    super.dispose();
  }
}
