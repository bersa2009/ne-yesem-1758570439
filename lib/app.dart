import 'package:flutter/material.dart';
import 'ui/screens/welcome_screen.dart';

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

