import 'package:flutter/material.dart';
import 'ui/screens/welcome_screen.dart';
import 'services/firebase_service.dart';
import 'ui/screens/auth_gate.dart';

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
      home: FutureBuilder<void>(
        future: FirebaseService.instance.init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // If Firebase init failed, continue without AuthGate for offline demo
          if (!FirebaseService.instance.available) {
            return const WelcomeScreen();
          }
          return const AuthGate(child: WelcomeScreen());
        },
      ),
    );
  }
}

