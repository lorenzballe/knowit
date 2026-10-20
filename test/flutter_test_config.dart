import 'dart:async';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/remote/remote.dart';

/// Runs before every test file in this directory.
///
/// The bank refreshes itself over HTTP at start-up. Under test that is a
/// request nobody wants: the harness would answer it with a 400 and move
/// on, quietly, which is exactly the kind of silence that hides a hang
/// when it stops being quiet. So the fetcher is a stub here, and a test
/// that wants a download provides its own. The same goes for the remote
/// document, which every launch and every return to the app asks for.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PillBank.fetch = (url) async => null;
  Remote.fetch = (url) async => null;
  await testMain();
}
