// Generated from the two config files Firebase hands out, which live at
// ios/Runner/GoogleService-Info.plist and android/app/google-services.json.
// None of this is secret: it identifies the project rather than granting
// anything. Access is decided by the Firestore rules in firestore.rules.
//
// Regenerate with `flutterfire configure` if the project ever changes.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Astuto has no web Firebase app: the web build is the preview, and '
        'it runs on local state alone.',
      );
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => ios,
      TargetPlatform.android => android,
      _ => throw UnsupportedError(
        'No Firebase app is registered for $defaultTargetPlatform.',
      ),
    };
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDbs5xJNqlXV1Rk3L6cv0I39S82wYPiXLo',
    appId: '1:582789807174:ios:c47ac811f38d652f8ede47',
    messagingSenderId: '582789807174',
    projectId: 'astuto-3d398',
    storageBucket: 'astuto-3d398.firebasestorage.app',
    iosBundleId: 'com.astuto.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUAqeoKsZlQM7tJ7xksYy_JhxWnuPNmJQ',
    appId: '1:582789807174:android:b6e25efeabc2ecae8ede47',
    messagingSenderId: '582789807174',
    projectId: 'astuto-3d398',
    storageBucket: 'astuto-3d398.firebasestorage.app',
  );
}
