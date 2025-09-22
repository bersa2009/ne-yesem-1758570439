import 'package:flutter/material.dart';
import 'ingredients_screen.dart';
import '../../services/matching_service.dart';
import 'shopping_list_screen.dart';

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
              child: OutlinedButton.icon(
                onPressed: () async {
                  final service = await MatchingService.loadFromAssets();
                  if (!context.mounted) return;
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShoppingListScreen(ingredientById: service.ingredientById)));
                },
                icon: const Icon(Icons.playlist_add_check),
                label: const Text('Alışveriş listesi'),
              ),
            ),
            const SizedBox(height: 12),
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

