// Placeholder firebase_options. Replace with real values via FlutterFire CLI.
// flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'demo',
        appId: 'demo',
        messagingSenderId: 'demo',
        projectId: 'demo',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'demo',
          appId: 'demo',
          messagingSenderId: 'demo',
          projectId: 'demo',
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return const FirebaseOptions(
          apiKey: 'demo',
          appId: 'demo',
          messagingSenderId: 'demo',
          projectId: 'demo',
        );
      default:
        return const FirebaseOptions(
          apiKey: 'demo',
          appId: 'demo',
          messagingSenderId: 'demo',
          projectId: 'demo',
        );
    }
  }
}

