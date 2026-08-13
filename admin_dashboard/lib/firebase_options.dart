import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Only web is supported for admin dashboard.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDCse7FB79lRhQFH7EOxlaY9P3UWBN_gdo',
    appId: '1:730507191669:web:3c46732f3a8a7008679f3c',
    messagingSenderId: '730507191669',
    projectId: 'campuscore-5658f',
    storageBucket: 'campuscore-5658f.firebasestorage.app',
    authDomain: 'campuscore-5658f.firebaseapp.com',
    measurementId: 'G-YL0C7J16FW',
  );
}
