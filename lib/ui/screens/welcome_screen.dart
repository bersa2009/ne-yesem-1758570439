import 'package:flutter/material.dart';
import 'ingredients_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text('Ne Yesem?', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Dolapta ne varsa, sofrada lezzet olsun!', style: TextStyle(fontSize: 16)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IngredientsScreen()));
                  },
                  child: const Text('Malzemelerini ekle'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

