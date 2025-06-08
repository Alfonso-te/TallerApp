
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] 

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
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAto0JfqnAzhtcsx7h6UYmIaLBmi4tGwSU',
    appId: '1:665104505999:web:b34a81989d159ea5fd64fa',
    messagingSenderId: '665104505999',
    projectId: 'taller-mecanico-d9608',
    authDomain: 'taller-mecanico-d9608.firebaseapp.com',
    storageBucket: 'taller-mecanico-d9608.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCPBLK1Ty2rkz_He9dZJNhdff7WHnmGkoo',
    appId: '1:665104505999:android:bf3ee477aa29f0f9fd64fa',
    messagingSenderId: '665104505999',
    projectId: 'taller-mecanico-d9608',
    storageBucket: 'taller-mecanico-d9608.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAto0JfqnAzhtcsx7h6UYmIaLBmi4tGwSU',
    appId: '1:665104505999:web:3a3e09abc72f6dd0fd64fa',
    messagingSenderId: '665104505999',
    projectId: 'taller-mecanico-d9608',
    authDomain: 'taller-mecanico-d9608.firebaseapp.com',
    storageBucket: 'taller-mecanico-d9608.firebasestorage.app',
  );
}
