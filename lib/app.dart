import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'ui/screens/welcome_screen.dart';

final logger = Logger();

class NeYesemApp extends StatelessWidget {
  const NeYesemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ne Yesem?',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2F80ED),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F80ED),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

