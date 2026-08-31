import 'dart:convert';

import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/identity.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:sign_in_with_apple_platform_interface/sign_in_with_apple_platform_interface.dart';

/// Stands in for the Apple sheet, so the whole flow can be driven without a
/// phone: what the sheet was asked, and what it answers.
class _FakeAppleSheet extends SignInWithApplePlatform {
  _FakeAppleSheet({
    this.available = true,
    this.answer,
    this.throws,
    this.availabilityThrows,
  });

  final bool available;
  final AuthorizationCredentialAppleID? answer;
  final Object? throws;

  /// What `isAvailable()` does on a build where the plugin never registered:
  /// it throws rather than answering.
  final Object? availabilityThrows;

  /// The nonce the sheet was handed. Apple embeds it in the token it mints.
  String? askedWithNonce;
  List<AppleIDAuthorizationScopes>? askedForScopes;

  @override
  Future<bool> isAvailable() async {
    if (availabilityThrows != null) throw availabilityThrows!;
    return available;
  }

  @override
  Future<AuthorizationCredentialAppleID> getAppleIDCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    WebAuthenticationOptions? webAuthenticationOptions,
    String? nonce,
    String? state,
  }) async {
    askedWithNonce = nonce;
    askedForScopes = scopes;
    if (throws != null) throw throws!;
    return answer!;
  }
}

/// Stands in for the Google sheet.
class _FakeGoogleSheet extends GoogleSignInPlatform {
  _FakeGoogleSheet({
    this.supported = true,
    this.answer,
    this.throws,
    this.supportThrows,
    this.quietAccessToken,
    this.authorizationThrows,
  });

  /// An access token the phone already holds, or null where getting one would
  /// mean prompting.
  final String? quietAccessToken;
  final Object? authorizationThrows;

  /// Whether the silent path was the one asked for. Prompting a reader who
  /// only wanted to sign in is the thing this must never do.
  bool? askedWithoutPrompting;

  final bool supported;
  final AuthenticationResults? answer;
  final Object? throws;

  /// What an unregistered platform implementation does when asked.
  final Object? supportThrows;

  InitParameters? startedWith;

  @override
  Future<void> init(InitParameters params) async => startedWith = params;

  @override
  bool supportsAuthenticate() {
    if (supportThrows != null) throw supportThrows!;
    return supported;
  }

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) {
    if (throws != null) return Future<AuthenticationResults>.error(throws!);
    return Future<AuthenticationResults>.value(answer!);
  }

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) => null;

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async {
    askedWithoutPrompting = !params.request.promptIfUnauthorized;
    if (authorizationThrows != null) throw authorizationThrows!;
    return quietAccessToken == null
        ? null
        : ClientAuthorizationTokenData(accessToken: quietAccessToken!);
  }

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<void> signOut(SignOutParams params) async {}

  @override
  Future<void> disconnect(DisconnectParams params) async {}
}

AuthorizationCredentialAppleID _appleAnswer({String? identityToken}) =>
    AuthorizationCredentialAppleID(
      userIdentifier: 'apple-user',
      givenName: 'Lorenzo',
      familyName: 'B',
      authorizationCode: 'code',
      email: 'reader@example.com',
      identityToken: identityToken,
      state: null,
    );

AuthenticationResults _googleAnswer({String? idToken}) => AuthenticationResults(
  user: const GoogleSignInUserData(
    email: 'reader@example.com',
    id: 'google-user',
  ),
  authenticationTokens: AuthenticationTokenData(idToken: idToken),
);

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('Apple', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test(
      'hands Apple the hash and Firebase the string it was made from',
      () async {
        // The replay guard: Apple mints its token against a nonce it is given,
        // Firebase re-hashes the one it is given and compares. A token lifted
        // off the wire is no use without the string behind the hash — so the
        // two must be the hash and its preimage, and never the same value.
        final sheet = _FakeAppleSheet(
          answer: _appleAnswer(identityToken: 'apple-id-token'),
        );
        SignInWithApplePlatform.instance = sheet;

        final IdentityResult result = await Identity().apple();

        expect(result.outcome, IdentityOutcome.got);
        final credential = result.credential! as OAuthCredential;
        expect(credential.providerId, 'apple.com');
        expect(credential.idToken, 'apple-id-token');

        final String rawNonce = credential.rawNonce!;
        expect(rawNonce, isNotEmpty);
        expect(
          sheet.askedWithNonce,
          sha256.convert(utf8.encode(rawNonce)).toString(),
        );
        expect(sheet.askedWithNonce, isNot(rawNonce));
      },
    );

    test('asks for the name too, which Apple gives only once', () async {
      final sheet = _FakeAppleSheet(
        answer: _appleAnswer(identityToken: 'apple-id-token'),
      );
      SignInWithApplePlatform.instance = sheet;

      final IdentityResult result = await Identity().apple();

      expect(sheet.askedForScopes, contains(AppleIDAuthorizationScopes.email));
      expect(
        sheet.askedForScopes,
        contains(AppleIDAuthorizationScopes.fullName),
      );
      final credential = result.credential! as OAuthCredential;
      expect(credential.appleFullPersonName?.givenName, 'Lorenzo');
    });

    test('a nonce is drawn fresh for every attempt', () async {
      final sheet = _FakeAppleSheet(
        answer: _appleAnswer(identityToken: 'apple-id-token'),
      );
      SignInWithApplePlatform.instance = sheet;

      final identity = Identity();
      await identity.apple();
      final String? first = sheet.askedWithNonce;
      await identity.apple();

      expect(sheet.askedWithNonce, isNot(first));
    });

    test('backing out of the sheet is not a failure', () async {
      SignInWithApplePlatform.instance = _FakeAppleSheet(
        throws: const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'The user canceled the authorization attempt',
        ),
      );

      final IdentityResult result = await Identity().apple();

      expect(result.outcome, IdentityOutcome.cancelled);
      expect(result.credential, isNull);
    });

    test('a sheet that fails says why, rather than nothing', () async {
      SignInWithApplePlatform.instance = _FakeAppleSheet(
        throws: const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.unknown,
          message: 'authorization attempt failed for an unknown reason',
        ),
      );

      final IdentityResult result = await Identity().apple();

      expect(result.outcome, IdentityOutcome.failed);
      expect(result.error, contains('unknown'));
    });

    test('a token-less answer is a failure, not a signed-in reader', () async {
      SignInWithApplePlatform.instance = _FakeAppleSheet(
        answer: _appleAnswer(identityToken: null),
      );

      final IdentityResult result = await Identity().apple();

      expect(result.outcome, IdentityOutcome.failed);
      expect(result.credential, isNull);
    });

    test(
      'where there is no Apple sheet, the browser is asked instead',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        SignInWithApplePlatform.instance = _FakeAppleSheet(
          answer: _appleAnswer(identityToken: 'apple-id-token'),
        );

        final IdentityResult result = await Identity().apple();

        expect(result.outcome, IdentityOutcome.noSheet);
        expect(result.credential, isNull);
      },
    );

    test('an iPhone too old for the sheet falls back too', () async {
      // Sign in with Apple starts at iOS 13. Below it the sheet is simply not
      // there, which is a reason to ask the browser rather than to tell
      // somebody their phone cannot have an account.
      SignInWithApplePlatform.instance = _FakeAppleSheet(available: false);

      final IdentityResult result = await Identity().apple();

      expect(result.outcome, IdentityOutcome.noSheet);
    });
  });

  group('Google', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test('carries the id token through to Firebase', () async {
      GoogleSignInPlatform.instance = _FakeGoogleSheet(
        answer: _googleAnswer(idToken: 'google-id-token'),
      );

      final IdentityResult result = await Identity().google();

      expect(result.outcome, IdentityOutcome.got);
      final credential = result.credential! as OAuthCredential;
      expect(credential.providerId, 'google.com');
      expect(credential.idToken, 'google-id-token');
    });

    test('iOS signs in against the client the URL scheme returns to', () async {
      final sheet = _FakeGoogleSheet(
        answer: _googleAnswer(idToken: 'google-id-token'),
      );
      GoogleSignInPlatform.instance = sheet;

      await Identity().google();

      // The reversed form of this is the CFBundleURLScheme in Info.plist.
      // Without the two agreeing the sheet has nowhere to come back to.
      expect(
        sheet.startedWith?.clientId,
        '582789807174-gqik2m8lr283qu6pr1s99gqgsj9lfas4.apps.googleusercontent.com',
      );
    });

    test('Android has no client of its own and uses the web one', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final sheet = _FakeGoogleSheet(
        answer: _googleAnswer(idToken: 'google-id-token'),
      );
      GoogleSignInPlatform.instance = sheet;

      await Identity().google();

      expect(sheet.startedWith?.clientId, isNull);
      expect(
        sheet.startedWith?.serverClientId,
        '582789807174-tu0hqj49009a3gituuhljqj5dnfto56g.apps.googleusercontent.com',
      );
    });

    test('the sheet is set up once, however often it is asked', () async {
      final sheet = _FakeGoogleSheet(
        answer: _googleAnswer(idToken: 'google-id-token'),
      );
      GoogleSignInPlatform.instance = sheet;

      final identity = Identity();
      await identity.google();
      sheet.startedWith = null;
      await identity.google();

      expect(sheet.startedWith, isNull);
    });

    test('backing out of the sheet is not a failure', () async {
      GoogleSignInPlatform.instance = _FakeGoogleSheet(
        throws: const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      );

      final IdentityResult result = await Identity().google();

      expect(result.outcome, IdentityOutcome.cancelled);
    });

    test(
      'a sheet that cannot run here falls back rather than refusing',
      () async {
        // A phone without Play Services, or a build whose signing fingerprint
        // was never registered. Neither is the reader's problem, and the
        // browser flow needs nothing from the app.
        GoogleSignInPlatform.instance = _FakeGoogleSheet(
          throws: const GoogleSignInException(
            code: GoogleSignInExceptionCode.clientConfigurationError,
            description: 'no such client',
          ),
        );

        final IdentityResult result = await Identity().google();

        expect(result.outcome, IdentityOutcome.noSheet);
        expect(result.error, contains('no such client'));
      },
    );

    test('anything else is a failure, and says why', () async {
      GoogleSignInPlatform.instance = _FakeGoogleSheet(
        throws: const GoogleSignInException(
          code: GoogleSignInExceptionCode.interrupted,
          description: 'the network went away',
        ),
      );

      final IdentityResult result = await Identity().google();

      expect(result.outcome, IdentityOutcome.failed);
      expect(result.error, contains('the network went away'));
    });

    test('an access token already held is carried too', () async {
      // firebase_auth's iOS side hands Firebase an empty string where it has
      // no access token. One that costs nothing to fetch is worth sending.
      final sheet = _FakeGoogleSheet(
        answer: _googleAnswer(idToken: 'google-id-token'),
        quietAccessToken: 'google-access-token',
      );
      GoogleSignInPlatform.instance = sheet;

      final IdentityResult result = await Identity().google();

      final credential = result.credential! as OAuthCredential;
      expect(credential.idToken, 'google-id-token');
      expect(credential.accessToken, 'google-access-token');
      // And it must never have been asked for in a way that could prompt.
      expect(sheet.askedWithoutPrompting, isTrue);
    });

    test(
      'no access token to be had quietly is fine — the id token stands',
      () async {
        GoogleSignInPlatform.instance = _FakeGoogleSheet(
          answer: _googleAnswer(idToken: 'google-id-token'),
        );

        final IdentityResult result = await Identity().google();

        expect(result.outcome, IdentityOutcome.got);
        final credential = result.credential! as OAuthCredential;
        expect(credential.idToken, 'google-id-token');
        expect(credential.accessToken, isNull);
      },
    );

    test(
      'a broken authorization call cannot undo a sign-in that worked',
      () async {
        GoogleSignInPlatform.instance = _FakeGoogleSheet(
          answer: _googleAnswer(idToken: 'google-id-token'),
          authorizationThrows: StateError('authorization blew up'),
        );

        final IdentityResult result = await Identity().google();

        expect(result.outcome, IdentityOutcome.got);
        expect(
          (result.credential! as OAuthCredential).idToken,
          'google-id-token',
        );
      },
    );

    test('a token-less answer is a failure', () async {
      GoogleSignInPlatform.instance = _FakeGoogleSheet(
        answer: _googleAnswer(idToken: null),
      );

      final IdentityResult result = await Identity().google();

      expect(result.outcome, IdentityOutcome.failed);
    });

    test(
      'where there is no Google sheet, the browser is asked instead',
      () async {
        GoogleSignInPlatform.instance = _FakeGoogleSheet(supported: false);

        final IdentityResult result = await Identity().google();

        expect(result.outcome, IdentityOutcome.noSheet);
      },
    );
  });

  group('A plugin that never registered', () {
    // Both probes used to sit outside the try, so a build where the native
    // side was missing threw straight past the fallback and was reported to
    // the reader as a failed sign-in.
    test(
      'Apple: an unanswerable probe is a missing sheet, not a failure',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        SignInWithApplePlatform.instance = _FakeAppleSheet(
          availabilityThrows: MissingPluginException(
            'No implementation found for method isAvailable',
          ),
        );

        final IdentityResult result = await Identity().apple();

        expect(result.outcome, IdentityOutcome.noSheet);
        expect(result.error, contains('isAvailable'));
      },
    );

    test(
      'Google: an unanswerable probe is a missing sheet, not a failure',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        GoogleSignInPlatform.instance = _FakeGoogleSheet(
          supportThrows: UnimplementedError('supportsAuthenticate'),
        );

        final IdentityResult result = await Identity().google();

        expect(result.outcome, IdentityOutcome.noSheet);
        expect(result.error, contains('supportsAuthenticate'));
      },
    );
  });

  group('Where the browser is an answer, and where it is not', () {
    test('on an iPhone it is not: both sheets exist there', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(Identity().browserIsAcceptable, isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(Identity().browserIsAcceptable, isFalse);
    });

    test('on Android it is: no Apple sheet, and no fingerprint for Google', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(Identity().browserIsAcceptable, isTrue);
    });
  });

  group('Reading Firebase back', () {
    test('every spelling of "the reader changed their mind" is one', () {
      // Each layer under this spells it differently, and one missed spelling
      // is an error message shown to somebody who simply backed out.
      for (final String code in const [
        'canceled',
        'cancelled',
        'user-canceled',
        'user-cancelled',
        'web-context-canceled',
        'web-context-cancelled',
        'sign-in-cancelled',
        'popup-closed-by-user',
      ]) {
        expect(Account.isCancellation(code), isTrue, reason: code);
      }
    });

    test('a real failure is not read as a cancellation', () {
      for (final String code in const [
        'invalid-credential',
        'network-request-failed',
        'operation-not-allowed',
        'account-exists-with-different-credential',
      ]) {
        expect(Account.isCancellation(code), isFalse, reason: code);
      }
    });

    test('an identity that already has an account is not an error', () {
      for (final String code in const [
        'credential-already-in-use',
        'email-already-in-use',
        'provider-already-linked',
      ]) {
        expect(Account.identityIsSpokenFor(code), isTrue, reason: code);
      }
      expect(Account.identityIsSpokenFor('invalid-credential'), isFalse);
    });
  });
}
