import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../services/error_handling_service.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final MatchResult result;
  final Map<String, Ingredient> ingredientById;

  const RecipeDetailScreen({
    super.key,
    required this.result,
    required this.ingredientById,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  void _checkIfFavorite() async {
    final storage = ref.read(storageServiceProvider);
    final favoriteIds = await storage.getFavoriteIds();
    setState(() {
      _isFavorite = favoriteIds.contains(widget.result.recipe.id);
    });
  }

  void _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final storage = ref.read(storageServiceProvider);

      if (_isFavorite) {
        await storage.removeFavorite(widget.result.recipe.id);
        ErrorHandlingService.showInfo(context, 'Favorilerden çıkarıldı');
      } else {
        await storage.addFavorite(widget.result.recipe.id);
        ErrorHandlingService.showSuccess(context, 'Favorilere eklendi');
      }

      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      ErrorHandlingService.handleError(context, e, null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMissingToPantry() {
    final missingIds = widget.result.missingIngredientIds;
    if (missingIds.isEmpty) return;

    final ingredients = widget.ingredientById;

    for (final id in missingIds) {
      final ingredient = ingredients[id];
      if (ingredient != null) {
        // TODO: Show dialog to set quantity
        ref.read(storageServiceProvider).updatePantryAmount(id, 1.0, 'adet');
      }
    }

    ErrorHandlingService.showSuccess(context, 'Eksik malzemeler listeye eklendi');
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.result.recipe;
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (recipe.imageUrl.isNotEmpty)
            Image.network(
              recipe.imageUrl,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 50),
              ),
            ),
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
              leading: Icon(
                isMissing ? Icons.remove_circle : Icons.check_circle,
                color: isMissing ? Colors.red : Colors.green,
              ),
              title: Text('${ing?.name ?? ri.ingredientId} • ${ri.quantity} ${ri.unit}'),
              subtitle: ri.optional ? const Text('Opsiyonel') : null,
            );
          }),
          const SizedBox(height: 12),
          Text('Adımlar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...List.generate(recipe.steps.length, (i) =>
            ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(recipe.steps[i]),
            )
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.result.missingIngredientIds.isEmpty ? null : _addMissingToPantry,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Eksikleri listeye ekle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleFavorite,
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

