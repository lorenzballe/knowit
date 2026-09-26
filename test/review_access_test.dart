import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/sync/review_access.dart';
import 'package:astuto/sync/subscription.dart';

// A code of the same shape as the real one, which is not in this repository:
// only its hash ships, and these tests bring their own.
const String _code = 'ABCD2345EFGH6789';
String _hashOf(String code) => sha256.convert(utf8.encode(code)).toString();

void main() {
  test('the code is read however a reviewer types it', () {
    final String hash = _hashOf(_code);
    for (final String typed in const [
      'ABCD-2345-EFGH-6789',
      'abcd 2345 efgh 6789',
      '  abcd2345efgh6789 ',
    ]) {
      expect(reviewCodeMatches(typed, hash: hash), isTrue, reason: typed);
    }
    expect(reviewCodeMatches('ABCD-2345-EFGH-6788', hash: hash), isFalse);
    expect(reviewCodeMatches('   ', hash: hash), isFalse);
  });

  test('what ships is a hash, and not of anything guessable', () {
    expect(kReviewCodeSha256, matches(RegExp(r'^[0-9a-f]{64}$')));
    for (final String guess in const ['', 'ASTUTE', 'REVIEW', 'ASTUTEPLUS']) {
      expect(reviewCodeMatches(guess), isFalse, reason: guess);
    }
  });

  group('on Android', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('the right code opens Astute+, and it is still open after a '
        'relaunch', () async {
      final Subscription store = Subscription(keyOverride: '')
        ..reviewCodeHash = _hashOf(_code);
      expect(store.isPlus, isFalse);

      expect(await store.redeemReviewCode('ABCD-2345-EFGH-6788'), isFalse);
      expect(store.isPlus, isFalse);

      expect(await store.redeemReviewCode('abcd-2345-efgh-6789'), isTrue);
      expect(store.isPlus, isTrue);
      expect(store.reviewAccess, isTrue);

      final Subscription relaunched = Subscription(keyOverride: '');
      await relaunched.start(accountId: null);
      expect(relaunched.isPlus, isTrue);
    });
  });

  test('an iPhone never takes the code', () async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final Subscription store = Subscription(keyOverride: '')
      ..reviewCodeHash = _hashOf(_code);
    expect(await store.redeemReviewCode('ABCD-2345-EFGH-6789'), isFalse);
    expect(store.isPlus, isFalse);
  });
}
