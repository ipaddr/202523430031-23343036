import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;

/// Configuration untuk Firebase di berbagai platform
/// Update konfigurasi ini dengan Firebase credentials dari Google Cloud Console
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions tidak didukung untuk platform ini.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD...',
    appId: '1:...:web:...',
    messagingSenderId: '...',
    projectId: '...',
    authDomain: '....firebaseapp.com',
    databaseURL: 'https://....firebasedatabase.app',
    storageBucket: '....appspot.com',
    measurementId: 'G-...',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD...',
    appId: '1:...:android:...',
    messagingSenderId: '...',
    projectId: '...',
    databaseURL: 'https://....firebasedatabase.app',
    storageBucket: '....appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD...',
    appId: '1:...:ios:...',
    messagingSenderId: '...',
    projectId: '...',
    databaseURL: 'https://....firebasedatabase.app',
    storageBucket: '....appspot.com',
    iosBundleId: 'com.example.pertemuan1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD...',
    appId: '1:...:ios:...',
    messagingSenderId: '...',
    projectId: '...',
    databaseURL: 'https://....firebasedatabase.app',
    storageBucket: '....appspot.com',
    iosBundleId: 'com.example.pertemuan1.RunnerTests',
  );
}

// Import untuk defaultTargetPlatform
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
