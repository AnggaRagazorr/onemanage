// File generated manually based on user input and google-services.json
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
    apiKey: 'AIzaSyDahPhudNz8RydRD_-rGq6Jj17C-0XFTB0',
    appId: '1:884699382927:web:a3c02b10c4bca29ff2dcfa',
    messagingSenderId: '884699382927',
    projectId: 'sekuriti',
    authDomain: 'sekuriti.firebaseapp.com',
    storageBucket: 'sekuriti.firebasestorage.app',
    measurementId: 'G-7R5QBM0PEN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcl1NfTIkcB-ZPHXymo07D-g3BSqs2N9k',
    appId: '1:884699382927:android:93857db78a0bd55cf2dcfa',
    messagingSenderId: '884699382927',
    projectId: 'sekuriti',
    storageBucket: 'sekuriti.firebasestorage.app',
  );
}
