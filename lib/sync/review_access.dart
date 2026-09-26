import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// A way into Astute+ for Google Play's reviewers, and only for them.
///
/// Google reviews every part of an Android app, what is sold included, but
/// its reviewers may not pay and may not use a free trial, and Astute has no
/// sign-in to lend them. So the Android app takes one code, written only into
/// Play Console's App access, which turns Astute+ on for the phone it is
/// typed into: long-press the ASTUTE+ badge on the Astute+ screen.
///
/// Only the code's SHA-256 is in the app — the code itself lives in Play
/// Console, not in this repository — and it is long enough that the hash
/// cannot be walked back to it. A new code is a new hash and a new build.
///
/// An iPhone never asks: Apple's reviewers buy in the sandbox, and Apple does
/// not allow a code to open what the app otherwise sells.
const String kReviewCodeSha256 = String.fromEnvironment(
  'REVIEW_CODE_SHA256',
  defaultValue:
      '09acab327019b7a39d94e46dfc9d9ca7147f852c70526560d5d3e800be5ff4c6',
);

/// Where a phone remembers that its reviewer got in.
const String kReviewAccessPref = 'knowit.reviewAccess';

/// Whether this build offers the code at all: Android only.
bool get reviewCodeOffered =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// The code as it is compared: capitals, without the spaces and dashes it is
/// written with, so it can be typed however it reads.
String normaliseReviewCode(String entered) =>
    entered.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

/// Whether [entered] is the code whose hash is [hash].
bool reviewCodeMatches(String entered, {String hash = kReviewCodeSha256}) {
  final String code = normaliseReviewCode(entered);
  if (code.isEmpty) return false;
  return sha256.convert(utf8.encode(code)).toString() == hash;
}
