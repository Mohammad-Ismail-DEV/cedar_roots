// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBfa_34MItxWyWYF_Ck_QCwELJIxBv-v5U',
    appId: '1:344338108473:web:32df62ac876f925345bde8',
    messagingSenderId: '344338108473',
    projectId: 'cedar-roots-453719',
    authDomain: 'cedar-roots-453719.firebaseapp.com',
    storageBucket: 'cedar-roots-453719.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBPFOdyk21yAZNhMfsV4GqFJK833yuIBGQ',
    appId: '1:344338108473:android:4f42e475e0f5942b45bde8',
    messagingSenderId: '344338108473',
    projectId: 'cedar-roots-453719',
    storageBucket: 'cedar-roots-453719.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvoPvnfElmO5QxIMPimnssoxKkP0iflLU',
    appId: '1:344338108473:ios:1a26bce6d2e618a245bde8',
    messagingSenderId: '344338108473',
    projectId: 'cedar-roots-453719',
    storageBucket: 'cedar-roots-453719.firebasestorage.app',
    iosBundleId: 'com.example.cedarRoots',
  );
}
