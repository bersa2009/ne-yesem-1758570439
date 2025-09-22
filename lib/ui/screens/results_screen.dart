import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/shopping_list_provider.dart';
import '../widgets/score_bar.dart';
import 'recipe_detail_screen.dart';
import 'main_screen.dart';

class ResultsScreen extends StatelessWidget {
  final List<MatchResult> results;
  final Map<String, Ingredient> ingredientById;

  const ResultsScreen({
    super.key,
    required this.results,
    required this.ingredientById,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate theoretical max score for each recipe
    final resultsWithMaxScore = results.map((r) {
      final theoreticalMax = r.recipe.ingredients.length * 3 + 5 + 5 + 2 + (r.recipe.popularityScore / 50).round();
      return (result: r, maxScore: theoreticalMax);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarif Önerileri'),
        actions: [
          Text('${results.length} sonuç'),
        ],
      ),
      body: ListView.builder(
        itemCount: resultsWithMaxScore.length,
        itemBuilder: (context, index) {
          final item = resultsWithMaxScore[index];
          final r = item.result;

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    r.recipe.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.recipe.timeMin} dk • ${r.recipe.servings} porsiyon'),
                      const SizedBox(height: 4),
                      ScoreBar(
                        score: r.score,
                        maxScore: item.maxScore,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (r.missingIngredientIds.isEmpty)
                            const Icon(Icons.check_circle, color: Colors.green, size: 16)
                          else
                            const Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            r.missingIngredientIds.isEmpty
                                ? 'Tüm malzemeler mevcut'
                                : '${r.missingIngredientIds.length} malzeme eksik',
                            style: TextStyle(
                              color: r.missingIngredientIds.isEmpty ? Colors.green : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                result: r,
                                ingredientById: ingredientById,
                              ),
                            ),
                          );
                          break;
                        case 'add_to_shopping':
                          _addMissingToShoppingList(context, r);
                          break;
                        case 'favorite':
                          // TODO: Add to favorites
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Favorilere ekleme yakında gelecek')),
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('Görüntüle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add_to_shopping',
                        child: Row(
                          children: [
                            Icon(Icons.add_shopping_cart),
                            SizedBox(width: 8),
                            Text('Alışverişe Ekle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(Icons.favorite),
                            SizedBox(width: 8),
                            Text('Favorilere Ekle'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(
                        result: r,
                        ingredientById: ingredientById,
                      ),
                    ),
                  ),
                ),

                if (r.missingIngredientIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: r.missingIngredientIds.map((id) {
                        final ingredient = ingredientById[id];
                        return Chip(
                          label: Text(ingredient?.name ?? 'Bilinmeyen'),
                          backgroundColor: Colors.red.shade100,
                          labelStyle: TextStyle(color: Colors.red.shade800),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addMissingToShoppingList(BuildContext context, MatchResult result) {
    final shoppingProvider = context.read<ShoppingListProvider>();
    final ingredientById = this.ingredientById;

    for (final ingredientId in result.missingIngredientIds) {
      final ingredient = ingredientById[ingredientId];
      if (ingredient != null) {
        shoppingProvider.addShoppingItem(
          ingredient.name,
          ingredient.category,
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.missingIngredientIds.length} malzeme alışveriş listesine eklendi'),
        action: SnackBarAction(
          label: 'Görüntüle',
          onPressed: () {
            // Navigate to shopping list
            final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
            if (mainScreenState != null) {
              mainScreenState.setState(() {
                mainScreenState._currentIndex = 3; // Shopping list tab
              });
            }
          },
        ),
      ),
    );
  }
}

