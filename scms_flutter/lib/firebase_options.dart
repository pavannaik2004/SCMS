// GENERATED FILE — DO NOT EDIT MANUALLY.
//
// Run the following command to replace this file with real Firebase config:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// Until then the app will throw at Firebase.initializeApp() on launch.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run `flutterfire configure` to generate real values.',
        );
    }
  }

  // ── Replace all values below by running `flutterfire configure` ──────────

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_REAL_VALUE',
    appId: 'REPLACE_WITH_REAL_VALUE',
    messagingSenderId: 'REPLACE_WITH_REAL_VALUE',
    projectId: 'REPLACE_WITH_REAL_VALUE',
    storageBucket: 'REPLACE_WITH_REAL_VALUE',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_REAL_VALUE',
    appId: 'REPLACE_WITH_REAL_VALUE',
    messagingSenderId: 'REPLACE_WITH_REAL_VALUE',
    projectId: 'REPLACE_WITH_REAL_VALUE',
    storageBucket: 'REPLACE_WITH_REAL_VALUE',
    iosClientId: 'REPLACE_WITH_REAL_VALUE',
    iosBundleId: 'REPLACE_WITH_REAL_VALUE',
  );
}
