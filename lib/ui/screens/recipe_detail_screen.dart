import 'package:flutter/material.dart';
import '../../models/models.dart';

class RecipeDetailScreen extends StatelessWidget {
  final MatchResult result;
  final Map<String, Ingredient> ingredientById;
  final bool isAIMode;

  const RecipeDetailScreen({
    super.key,
    required this.result,
    required this.ingredientById,
    this.isAIMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final recipe = result.recipe;
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        backgroundColor: isAIMode ? Colors.orange : null,
        actions: [
          if (isAIMode)
            IconButton(
              icon: const Icon(Icons.smart_toy),
              onPressed: () => _showAIScoreInfo(context),
              tooltip: 'AI Skor Detayları',
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
          if (isAIMode) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.smart_toy, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'AI Analizi',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Toplam AI Skor: ${result.score}'),
                  Text('Malzeme Uyumu: ${result.missingIngredientIds.isEmpty ? "Mükemmel" : "${result.recipe.ingredients.length - result.missingIngredientIds.length}/${result.recipe.ingredients.length}"}'),
                  Text('Hazırlama Süresi: ${recipe.timeMin} dakika'),
                  Text('Popülerlik: ${recipe.popularityScore}%'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Eksikleri listeye ekle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Favorilere ekle'),
                  style: isAIMode
                      ? ElevatedButton.styleFrom(backgroundColor: Colors.orange)
                      : null,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showAIScoreInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Skor Analizi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Skor: ${result.score}'),
            const SizedBox(height: 8),
            Text('• Malzeme Eşleşmesi: +${(result.score * 0.6).round()}'),
            Text('• Zaman Bonus: +5'),
            Text('• Diyet Uyumu: +5'),
            Text('• Popülerlik: +${(result.recipe.popularityScore / 50).round()}'),
            Text('• Benzerlik: +${(result.score * 0.2).round()}'),
            if (result.missingIngredientIds.isNotEmpty)
              Text('• Eksik Malzemeler: -${result.missingIngredientIds.length * 2}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

