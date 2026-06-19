// File generated from google-services.json (scms-campus-app, updated with OAuth client).
// Re-generate by running: flutterfire configure --project=scms-campus-app

// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS. '
          'Run flutterfire configure to add iOS support.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDf1H5JHbPKW5KzW76aoIvxoMi1KKGsrRQ',
    appId: '1:182336575222:android:845f4814f4cde1f3a7fed7',
    messagingSenderId: '182336575222',
    projectId: 'scms-campus-app',
    storageBucket: 'scms-campus-app.firebasestorage.app',
    androidClientId: '182336575222-252rq8mp7br1178te3ugao4radr2onnv.apps.googleusercontent.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCDtqsVScdRhXW_X8tIjYJ7mPqpRTemy8A',
    authDomain: 'scms-campus-app.firebaseapp.com',
    projectId: 'scms-campus-app',
    storageBucket: 'scms-campus-app.firebasestorage.app',
    messagingSenderId: '182336575222',
    appId: '1:182336575222:web:9d2df844fb347034a7fed7',
    measurementId: 'G-1RTY31LVX6',
  );
}
