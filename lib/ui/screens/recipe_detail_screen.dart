import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/shopping_list_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final MatchResult result;
  final Map<String, Ingredient> ingredientById;

  const RecipeDetailScreen({
    super.key,
    required this.result,
    required this.ingredientById,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ShoppingListService _shoppingListService = ShoppingListService();
  bool _isFavorite = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      _isFavorite = await _firestoreService.isFavorite(widget.result.recipe.id);
    } catch (e) {
      print('Error checking favorite status: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _firestoreService.removeFavorite(widget.result.recipe.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorilerden çıkarıldı')),
        );
      } else {
        await _firestoreService.addFavorite(widget.result.recipe.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorilere eklendi')),
        );
      }
      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _addMissingToShoppingList() async {
    try {
      final missingIngredients = widget.result.missingIngredientIds
          .map((id) => widget.result.recipe.ingredients.firstWhere((ri) => ri.ingredientId == id))
          .toList();
      
      await _shoppingListService.addMissingIngredientsToShoppingList(missingIngredients);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${missingIngredients.length} malzeme alışveriş listesine eklendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.result.recipe;
    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (recipe.imageUrl.isNotEmpty) Image.network(recipe.imageUrl, height: 200, fit: BoxFit.cover),
          const SizedBox(height: 12),
          Text(recipe.description),
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
            final ing = widget.ingredientById[ri.ingredientId];
            final isMissing = widget.result.missingIngredientIds.contains(ri.ingredientId);
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
              if (widget.result.missingIngredientIds.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addMissingToShoppingList,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Eksikleri listeye ekle'),
                  ),
                ),
              if (widget.result.missingIngredientIds.isNotEmpty)
                const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _toggleFavorite,
                  icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                  label: Text(_isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

