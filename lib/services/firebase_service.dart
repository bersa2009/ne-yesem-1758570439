import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  bool _initialized = false;
  bool _available = false;

  bool get initialized => _initialized;
  bool get available => _available;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _available = true;
    } catch (_) {
      _available = false;
    } finally {
      _initialized = true;
    }
  }
}

