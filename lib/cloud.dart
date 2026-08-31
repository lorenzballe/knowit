import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Whether Firebase started, and the one place that decides it.
///
/// The app is local-first and stays that way: the phone holds the truth and
/// the cloud is a copy. So a Firebase that will not start is a degraded
/// state, not a dead app — the reader still gets their cards, they just are
/// not backed up. Everything that talks to the cloud asks [ready] first.
///
/// It is also what keeps the widget tests honest: they pump AstutoApp
/// directly and never call [start], so [ready] is false and no test reaches
/// the network.
class Cloud {
  const Cloud._();

  static bool _ready = false;
  static String? _failure;

  static bool get ready => _ready;

  /// Why Firebase is not up, when it is not. Shown in the debug section,
  /// because "nothing happens" is the least useful bug report there is.
  static String? get failure => _failure;

  /// Called once from main(). Never throws: a project that is misconfigured,
  /// offline or missing on this platform must not stop the app opening.
  static Future<void> start() async {
    // The web build is the public preview and has no Firebase app registered.
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _ready = true;
      _failure = null;
    } catch (error, stack) {
      _ready = false;
      _failure = '$error';
      debugPrint('Firebase did not start, carrying on locally: $error');
      debugPrintStack(stackTrace: stack);
    }
  }

  @visibleForTesting
  static void setReadyForTest(bool value) => _ready = value;
}
