import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../cloud.dart';
import '../state/app_state.dart';
import 'reader_snapshot.dart';
import 'reader_store.dart';

/// How a sign-in ended, in terms the screen can act on.
enum SignInOutcome { signedIn, cancelled, unavailable, failed }

/// The reader's account, and the one place that folds a phone into it.
///
/// The app works signed out and always has: this only decides whether what
/// the phone knows also lives somewhere it survives the phone.
class Account extends ChangeNotifier {
  /// The two seams the tests use. Left null, the account reaches for the
  /// real Firebase — and finds nothing unless Cloud.start() succeeded.
  Account({this.authOverride, this.storeOverride});

  /// Stand-ins for the real Firebase, so a sign-in can be driven in a test
  /// without a project, a network or a device. Null in the app.
  final FirebaseAuth? authOverride;
  final ReaderStore? storeOverride;

  bool _busy = false;

  /// True while a sign-in is in flight, so the button can say so.
  bool get busy => _busy;

  FirebaseAuth? get _firebase =>
      authOverride ?? (Cloud.ready ? FirebaseAuth.instance : null);

  ReaderStore? get _readers =>
      storeOverride ?? (Cloud.ready ? FirestoreReaderStore() : null);

  User? get user => _firebase?.currentUser;

  bool get signedIn => user != null;

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
    () => AppleAuthProvider()
      ..addScope('email')
      ..addScope('name'),
  );

  Future<SignInOutcome> signInWithGoogle(AppState app) =>
      _signIn(app, 'Google', () => GoogleAuthProvider()..addScope('email'));

  /// Both providers do the same thing: hand Firebase an identity, then fold
  /// this phone into whatever the account already holds.
  Future<SignInOutcome> _signIn(
    AppState app,
    String label,
    AuthProvider Function() build,
  ) async {
    final FirebaseAuth? auth = _firebase;
    if (auth == null) return SignInOutcome.unavailable;

    _busy = true;
    notifyListeners();
    try {
      final UserCredential credential = await auth.signInWithProvider(build());
      final User? signed = credential.user;
      if (signed == null) return SignInOutcome.failed;
      await foldInto(app, signed.uid);
      return SignInOutcome.signedIn;
    } on FirebaseAuthException catch (error) {
      // Backing out of the Apple sheet is not a failure and must not be
      // reported as one.
      const cancelled = {
        'canceled',
        'cancelled',
        'web-context-canceled',
        'user-cancelled',
      };
      if (cancelled.contains(error.code)) return SignInOutcome.cancelled;
      debugPrint('$label sign-in failed: ${error.code} ${error.message}');
      return SignInOutcome.failed;
    } catch (error) {
      debugPrint('$label sign-in failed: $error');
      return SignInOutcome.failed;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

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
    final User? signed = user;
    final ReaderStore? store = _readers;
    if (signed == null || store == null) return;
    try {
      await store.write(signed.uid, app.snapshot());
    } catch (error) {
      // A backup that fails is not something to interrupt a reader over.
      debugPrint('Could not push the snapshot: $error');
    }
  }

  Future<void> signOut() async {
    await _firebase?.signOut();
    notifyListeners();
  }
}
