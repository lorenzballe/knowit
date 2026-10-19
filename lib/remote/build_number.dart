/// The build number this phone runs, read once at start for Remote.build.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Asks the platform for the build number as it writes it. Replaceable, so
/// a test can be any build without a phone.
typedef BuildReader = Future<String> Function();

/// The build number this app was released as — the `+n` of its version,
/// which the App Store calls CFBundleVersion and Google Play versionCode —
/// as the phone's own record of the release says it, or 0 when it will not
/// say.
///
/// Read from main(), before anything reads an audience: the update gate and
/// every rule asking for `minBuild` are measured against it. 0 is the safe
/// answer to a platform that fails or takes too long: no rule asking for a
/// build at least something holds, and the gate never sends a phone whose
/// build it does not know to the store (UpdateGate). Never throws, and waits
/// no longer than [wait], which a phone answers in a few milliseconds and
/// the web build, which reads its `version.json`, in a hundred or so.
Future<int> readBuildNumber({
  BuildReader? read,
  Duration wait = const Duration(seconds: 1),
}) async {
  try {
    return parseBuildNumber(await (read ?? _fromPlatform)().timeout(wait));
  } catch (error) {
    debugPrint('Astute: the build number did not read: $error');
    return 0;
  }
}

/// A build number as a platform writes it, or 0 for anything that is not a
/// whole number of at least 1: an empty string, a version name, a negative.
int parseBuildNumber(String raw) {
  final int? n = int.tryParse(raw.trim());
  return n == null || n < 1 ? 0 : n;
}

Future<String> _fromPlatform() async =>
    (await PackageInfo.fromPlatform()).buildNumber;
