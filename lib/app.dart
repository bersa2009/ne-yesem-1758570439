import 'package:flutter/material.dart';
import 'ui/screens/welcome_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/ai_service.dart';

class NeYesemApp extends StatelessWidget {
  const NeYesemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ne Yesem?',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

