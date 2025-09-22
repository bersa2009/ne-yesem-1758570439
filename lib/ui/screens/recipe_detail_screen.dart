import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/local_store.dart';
import '../widgets/score_bar.dart';
import 'shopping_list_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final MatchResult result;
  final Map<String, Ingredient> ingredientById;

  const RecipeDetailScreen({
    super.key,
    required this.result,
    required this.ingredientById,
  });

  @override
  Widget build(BuildContext context) {
    final recipe = result.recipe;
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShoppingListScreen()));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (recipe.imageUrl.isNotEmpty) Image.network(recipe.imageUrl, height: 200, fit: BoxFit.cover),
          const SizedBox(height: 12),
          Text(recipe.description),
          const SizedBox(height: 12),
          ScoreBar(score: result.score, maxScore: result.maxScore),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('Süre: ${recipe.timeMin} dk')),
              Chip(label: Text('Porsiyon: ${recipe.servings}')),
              Chip(label: Text('Zorluk: ${recipe.difficulty}')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Malzemeler', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...recipe.ingredients.map((ri) {
            final ing = ingredientById[ri.ingredientId];
            final isMissing = result.missingIngredientIds.contains(ri.ingredientId);
            return ListTile(
              dense: true,
              leading: Icon(isMissing ? Icons.remove_circle : Icons.check_circle, color: isMissing ? Colors.red : Colors.green),
              title: Text('${ing?.name ?? ri.ingredientId} • ${ri.quantity} ${ri.unit}'),
              subtitle: ri.optional ? const Text('Opsiyonel') : null,
            );
          }),
          const SizedBox(height: 12),
          Text('Adımlar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...List.generate(recipe.steps.length, (i) => ListTile(leading: CircleAvatar(child: Text('${i + 1}')), title: Text(recipe.steps[i]))),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await LocalStore.instance.addMissingIngredientsToShoppingList(
                      missingIngredientIds: result.missingIngredientIds,
                      ingredientById: ingredientById,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eksikler alışveriş listesine eklendi')));
                    }
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Eksikleri listeye ekle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final isFav = await LocalStore.instance.isFavorite(recipe.id);
                    if (isFav) {
                      await LocalStore.instance.removeFavorite(recipe.id);
                    } else {
                      await LocalStore.instance.addFavorite(recipe.id);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isFav ? 'Favorilerden çıkarıldı' : 'Favorilere eklendi')),
                      );
                    }
                  },
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Favorilere ekle'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

