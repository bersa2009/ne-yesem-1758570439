import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/matching_service.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<FavoriteRecipe> _favorites = [];
  Map<String, Recipe> _recipesById = {};
  Map<String, Ingredient> _ingredientById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      // Load recipes and ingredients
      final matchingService = await MatchingService.loadFromAssets();
      _ingredientById = matchingService.ingredientById;
      _recipesById = {for (final recipe in matchingService.recipes) recipe.id: recipe};
      
      // Load favorites
      _favorites = await _firestoreService.getFavorites();
    } catch (e) {
      print('Error loading favorites: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeFavorite(String recipeId) async {
    await _firestoreService.removeFavorite(recipeId);
    await _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favorilerden çıkarıldı')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriler'),
      ),
      body: _favorites.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Henüz favori tarifiniz yok',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tarif detaylarından beğendiğiniz tarifleri favorilere ekleyebilirsiniz',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final favorite = _favorites[index];
                final recipe = _recipesById[favorite.recipeId];
                
                if (recipe == null) {
                  return const SizedBox.shrink(); // Recipe not found
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      recipe.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${recipe.timeMin} dk'),
                            const SizedBox(width: 16),
                            Icon(Icons.people, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${recipe.servings} kişi'),
                            const SizedBox(width: 16),
                            Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(recipe.difficulty),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipe.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Favorilere eklendi: ${_formatDate(favorite.addedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'remove') {
                          _showRemoveDialog(recipe);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.favorite_border, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Favorilerden Çıkar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Create a dummy MatchResult for navigation
                      final matchResult = MatchResult(
                        recipe: recipe,
                        score: 100, // Max score for favorites
                        missingIngredientIds: [], // Assume no missing ingredients
                      );
                      
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                            result: matchResult,
                            ingredientById: _ingredientById,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRemoveDialog(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Favorilerden Çıkar'),
        content: Text('${recipe.name} tarifini favorilerden çıkarmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeFavorite(recipe.id);
            },
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );
  }
}