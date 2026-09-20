import 'dart:async';

import 'package:astuto/data/pill_bank.dart';

/// Runs before every test file in this directory.
///
/// The bank refreshes itself over HTTP at start-up. Under test that is a
/// request nobody wants: the harness would answer it with a 400 and move
/// on, quietly, which is exactly the kind of silence that hides a hang
/// when it stops being quiet. So the fetcher is a stub here, and a test
/// that wants a download provides its own.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PillBank.fetch = (url) async => null;
  await testMain();
}
