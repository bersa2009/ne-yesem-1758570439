import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../widgets/score_bar.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favori Tarifler')),
      body: Consumer2<AuthProvider, FavoritesProvider>(
        builder: (context, authProvider, favoritesProvider, child) {
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Favorileri görmek için giriş yapın'),
                  SizedBox(height: 16),
                  Text('Favori tarifleriniz burada görünecek'),
                ],
              ),
            );
          }

          if (favoritesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favoritesProvider.favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz favori tarifiniz yok', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Beğendiğiniz tarifleri favorilere ekleyin'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favoritesProvider.favorites.length,
            itemBuilder: (context, index) {
              final favorite = favoritesProvider.favorites[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(favorite.recipeName),
                  subtitle: Text('Eklenme: ${_formatDate(favorite.addedAt)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      // TODO: Remove from favorites
                      favoritesProvider.removeFavorite(favorite.recipeId);
                    },
                  ),
                  onTap: () {
                    // TODO: Navigate to recipe detail
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${favorite.recipeName} detayı yakında gelecek')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}