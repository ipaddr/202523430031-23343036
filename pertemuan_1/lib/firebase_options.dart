import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Configuration untuk Firebase di berbagai platform
/// Update konfigurasi ini dengan Firebase credentials dari Google Cloud Console
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      throw UnsupportedError(
        'DefaultFirebaseOptions belum dikonfigurasi untuk platform ini.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyBs8vIVfukeXGcyg2UXtqAprg7ltmj1Pls',
    appId: '1:121447373132:android:daf380ce5d78bf638bd7e9',
    messagingSenderId: '121447373132',
    projectId: 'mobileprogramminglanjut',
    storageBucket: 'mobileprogramminglanjut.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA20x0RKnlcRxN-0SZzN7Vc_OGcFZupJrY',
    appId: '1:121447373132:ios:e6bb403856dcf06f8bd7e9',
    messagingSenderId: '121447373132',
    projectId: 'mobileprogramminglanjut',
    storageBucket: 'mobileprogramminglanjut.firebasestorage.app',
    iosBundleId: 'com.example.pertemuan1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA20x0RKnlcRxN-0SZzN7Vc_OGcFZupJrY',
    appId: '1:121447373132:ios:e6bb403856dcf06f8bd7e9',
    messagingSenderId: '121447373132',
    projectId: 'mobileprogramminglanjut',
    storageBucket: 'mobileprogramminglanjut.firebasestorage.app',
    iosBundleId: 'com.example.pertemuan1',
  );
}
