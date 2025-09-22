import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await AuthService().ensureSignedInAnonymously();
  } catch (_) {
    // Firebase not configured; continue without backend
  }
  runApp(const NeYesemApp());
}

