import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseService.initialize();
    runApp(const NeYesemApp());
  } catch (e) {
    // Fallback app if Firebase fails to initialize
    runApp(const NeYesemApp());
  }
}

