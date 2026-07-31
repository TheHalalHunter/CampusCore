// Generated Firebase options for CampusCore
// Project: campuscore-5658f

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured yet.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC51CCYfdcw62gxb42CFr9AGraEWaljmUM',
    appId: '1:730507191669:android:d613c55e3b00417f679f3c',
    messagingSenderId: '730507191669',
    projectId: 'campuscore-5658f',
    storageBucket: 'campuscore-5658f.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC51CCYfdcw62gxb42CFr9AGraEWaljmUM',
    appId: '1:730507191669:android:d613c55e3b00417f679f3c',
    messagingSenderId: '730507191669',
    projectId: 'campuscore-5658f',
    storageBucket: 'campuscore-5658f.firebasestorage.app',
    authDomain: 'campuscore-5658f.firebaseapp.com',
  );
}
