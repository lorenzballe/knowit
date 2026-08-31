import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../firebase_options.dart';

/// What asking the phone for an identity produced.
enum IdentityOutcome {
  /// A credential, ready to be handed to Firebase.
  got,

  /// The reader backed out of the sheet. Not a failure, and it must never be
  /// reported as one.
  cancelled,

  /// There is no sheet to ask here, or this build is not configured for the
  /// one there is: Apple on Android, a phone without Play Services, a
  /// fingerprint that was never registered. The caller falls back to the
  /// browser flow, which needs nothing from the app.
  noSheet,

  /// A sheet was asked, and said no for a reason worth showing.
  failed,
}

/// An identity, or why there isn't one.
class IdentityResult {
  const IdentityResult(this.outcome, {this.credential, this.error});

  final IdentityOutcome outcome;

  /// Set only for [IdentityOutcome.got].
  final AuthCredential? credential;

  /// Why, in terms the debug section can print. Set for [IdentityOutcome.failed],
  /// and for a [IdentityOutcome.noSheet] that came from something going wrong
  /// rather than from the platform simply not having one.
  final String? error;
}

/// Where a sign-in identity comes from, before Firebase sees it.
///
/// Firebase can run the whole thing itself — `signInWithProvider` opens a
/// browser at the project's auth handler and comes back with a user — and for
/// a while that is what this app did. It works, and it is also why nobody
/// finished signing in: the sheet is titled `astuto-3d398.firebaseapp.com`
/// rather than Astuto, it opens a browser session that knows none of the
/// accounts the phone is signed into, and so it asks someone to type an email
/// address and a password to get into an app they have not decided to keep
/// yet. That is a lot to ask on the second screen.
///
/// The system sheets already know all of it. Apple's is a glance at Face ID;
/// Google's lists the accounts the phone is holding. So they are what gets
/// asked first, and the browser stays as the fallback for the places that
/// have no sheet of their own.
class Identity {
  Identity();

  /// Names this sign-in implementation, so the debug section can say which one
  /// is actually on the phone. Working out whether a build even carried the
  /// new code cost a round trip once — a screenshot should answer it. Bump it
  /// whenever this path changes.
  static const String implementation = 'native-sheets-1';

  /// Whether landing in Firebase's browser flow is an acceptable answer here.
  ///
  /// On an iPhone it is not. Both sheets exist there, so ending up in Safari
  /// means something is wrong with the build — and that browser flow is the
  /// exact experience the sheets were brought in to replace: a page titled
  /// astuto-3d398.firebaseapp.com, holding no session, asking for an address
  /// to be typed. Saying what went wrong is worth more than offering a
  /// sign-in nobody finishes.
  ///
  /// Everywhere else the fallback is the real answer: Android has no Apple
  /// sheet at all, and its Google sheet wants a signing fingerprint this
  /// project has never registered.
  bool get browserIsAcceptable =>
      kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.macOS);

  /// The project's web OAuth client, out of `android/app/google-services.json`.
  /// Android's sheet mints its id token for this one — there is no Android
  /// client in the project, and asking for one would mean registering a
  /// signing fingerprint per build. Like everything else in the config files,
  /// it identifies the project rather than granting anything.
  static const String _googleServerClient =
      '582789807174-tu0hqj49009a3gituuhljqj5dnfto56g.apps.googleusercontent.com';

  /// [GoogleSignIn] wants to be initialised exactly once, before anything
  /// else touches it.
  Future<void>? _googleStarted;

  /// Whether this platform has an Apple sheet of its own. Android has one
  /// through a browser tab, but it needs a Services ID and a return URL that
  /// this app does not have — there, Firebase's own browser flow is the same
  /// thing with nothing to configure.
  bool get _hasAppleSheet =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<IdentityResult> apple() async {
    if (!_hasAppleSheet) return const IdentityResult(IdentityOutcome.noSheet);

    try {
      if (!await SignInWithApple.isAvailable()) {
        return const IdentityResult(IdentityOutcome.noSheet);
      }
    } catch (error) {
      // Asked in its own try on purpose. On a build where the plugin never
      // registered this throws rather than answering false, and an exception
      // escaping from here would be reported as a reader who could not sign
      // in — when what happened is that the sheet was never there.
      return IdentityResult(
        IdentityOutcome.noSheet,
        error: 'apple sheet did not answer: $error',
      );
    }

    // Apple mints its token against a nonce we choose, and Firebase checks
    // the two against each other. Apple is given the hash and Firebase the
    // string it was made from, so a token lifted off the wire is useless to
    // replay: whoever has it does not have the string that would prove it was
    // minted for them.
    final String rawNonce = generateNonce();
    try {
      final AuthorizationCredentialAppleID apple =
          await SignInWithApple.getAppleIDCredential(
            scopes: const [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
          );

      final String? idToken = apple.identityToken;
      if (idToken == null) {
        return const IdentityResult(
          IdentityOutcome.failed,
          error: 'Apple returned no identity token.',
        );
      }

      return IdentityResult(
        IdentityOutcome.got,
        // Apple hands over a name only on the very first authorisation, so it
        // travels with the credential or it is gone for good.
        credential: AppleAuthProvider.credentialWithIDToken(
          idToken,
          rawNonce,
          AppleFullPersonName(
            givenName: apple.givenName,
            familyName: apple.familyName,
          ),
        ),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const IdentityResult(IdentityOutcome.cancelled);
      }
      return IdentityResult(
        IdentityOutcome.failed,
        error: 'apple ${error.code.name}: ${error.message}',
      );
    } on SignInWithAppleNotSupportedException catch (error) {
      return IdentityResult(IdentityOutcome.noSheet, error: '$error');
    } catch (error) {
      return IdentityResult(IdentityOutcome.failed, error: '$error');
    }
  }

  Future<IdentityResult> google() async {
    if (kIsWeb) return const IdentityResult(IdentityOutcome.noSheet);

    try {
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return const IdentityResult(IdentityOutcome.noSheet);
      }
    } catch (error) {
      // Same reason as Apple's: with no platform implementation registered
      // this throws instead of answering, and that is a missing sheet rather
      // than a failed sign-in.
      return IdentityResult(
        IdentityOutcome.noSheet,
        error: 'google sheet did not answer: $error',
      );
    }

    try {
      await _startGoogle();
      // No scopes are asked for. The id token already carries the address,
      // and anything beyond it would put a consent screen in front of a
      // reader who has not decided to keep the app yet.
      final GoogleSignInAccount google = await GoogleSignIn.instance
          .authenticate();

      final String? idToken = google.authentication.idToken;
      if (idToken == null) {
        return const IdentityResult(
          IdentityOutcome.failed,
          error: 'Google returned no id token.',
        );
      }

      return IdentityResult(
        IdentityOutcome.got,
        // The id token alone is enough — Firebase verifies that, and the API
        // asks only that one of the two be present. But the iOS side of
        // firebase_auth hands Firebase an empty string where it has no access
        // token, so if one can be had for nothing it is worth having. This
        // asks without prompting: it returns null rather than putting a
        // consent screen in front of a reader who only wanted to sign in.
        credential: GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: await _quietAccessToken(google),
        ),
      );
    } on GoogleSignInException catch (error) {
      final String detail = 'google ${error.code.name}: ${error.description}';
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled => const IdentityResult(
          IdentityOutcome.cancelled,
        ),
        // A sheet that cannot run here is not a reader's problem: a phone
        // with no Play Services, a build whose fingerprint was never
        // registered, a screen the sheet cannot be shown over. Those are the
        // cases the browser flow exists for.
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError ||
        GoogleSignInExceptionCode.uiUnavailable => IdentityResult(
          IdentityOutcome.noSheet,
          error: detail,
        ),
        _ => IdentityResult(IdentityOutcome.failed, error: detail),
      };
    } catch (error) {
      return IdentityResult(IdentityOutcome.failed, error: '$error');
    }
  }

  /// An access token if the phone already holds one, and nothing if getting
  /// one would mean asking. Never throws: this is a bonus on top of a
  /// sign-in that already succeeded, and must not be able to undo it.
  Future<String?> _quietAccessToken(GoogleSignInAccount google) async {
    try {
      final GoogleSignInClientAuthorization? granted = await google
          .authorizationClient
          .authorizationForScopes(const ['email']);
      return granted?.accessToken;
    } catch (error) {
      debugPrint(
        'No quiet Google access token, carrying on with the id token: $error',
      );
      return null;
    }
  }

  Future<void> _startGoogle() async {
    final Future<void>? started = _googleStarted;
    if (started != null) return started;

    final Future<void> attempt = GoogleSignIn.instance.initialize(
      // iOS signs in against the same client the URL scheme in Info.plist
      // returns to; Android has no client of its own and uses the web one.
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
      serverClientId: _googleServerClient,
    );
    _googleStarted = attempt;
    try {
      await attempt;
    } catch (_) {
      // A start that failed must not be remembered as done, or every later
      // attempt would skip it and fail against something never configured.
      _googleStarted = null;
      rethrow;
    }
  }
}
