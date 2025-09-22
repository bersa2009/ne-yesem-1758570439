import 'package:flutter/material.dart';
import '../../models/models.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Şimdilik örnek favori tarifler
  final List<Recipe> _favoriteRecipes = [];

  @override
  void initState() {
    super.initState();
    // Burada favori tarifler yüklenecek
    _loadFavorites();
  }

  void _loadFavorites() {
    // Şimdilik boş, gerçek uygulamada local storage'dan yüklenecek
    setState(() {
      // Örnek favori tarif eklenebilir
    });
  }

  void _toggleFavorite(Recipe recipe) {
    setState(() {
      if (_favoriteRecipes.contains(recipe)) {
        _favoriteRecipes.remove(recipe);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${recipe.name} favorilerden çıkarıldı'))
        );
      } else {
        _favoriteRecipes.add(recipe);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${recipe.name} favorilere eklendi'))
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriler'),
        actions: [
          IconButton(
            onPressed: () {
              // Favori tarifleri paylaş
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: _favoriteRecipes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz favori tarifiniz yok',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Beğendiğiniz tarifleri favorilere ekleyebilirsiniz',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Tarif Keşfet'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _favoriteRecipes.length,
              itemBuilder: (context, index) {
                final recipe = _favoriteRecipes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.restaurant_menu, color: Colors.red),
                    title: Text(recipe.name),
                    subtitle: Text('${recipe.timeMin} dk • ${recipe.servings} kişi'),
                    trailing: IconButton(
                      onPressed: () => _toggleFavorite(recipe),
                      icon: const Icon(Icons.favorite, color: Colors.red),
                    ),
                    onTap: () {
                      // Tarif detay sayfası henüz implementasyonsuz
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${recipe.name} detayları yakında eklenecek!'))
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}