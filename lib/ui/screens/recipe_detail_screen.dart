import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/ai_providers.dart';
import '../../services/ai_service.dart';
import '../widgets/feedback_dialog.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final MatchResult result;
  final Map<String, Ingredient> ingredientById;

  const RecipeDetailScreen({
    super.key,
    required this.result,
    required this.ingredientById,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = result.recipe;
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
          
          // AI Feedback Section
          Consumer(
            builder: (context, ref, child) {
              return ref.watch(aiAvailableProvider).when(
                data: (available) => available 
                    ? _buildAIFeedbackSection(context, ref)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              );
            },
          ),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Add missing ingredients to shopping list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Özellik yakında eklenecek!')),
                    );
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Eksikleri listeye ekle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add to favorites
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Favorilere eklendi!')),
                    );
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

  Widget _buildAIFeedbackSection(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'AI Geri Bildirim',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu tarifi denediniz mi? Deneyiminizi paylaşın, AI önerilerini geliştirsin!',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showFeedbackDialog(context, ref),
                icon: const Icon(Icons.rate_review),
                label: const Text('Tarifi Değerlendir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(
        recipe: result.recipe,
        missingIngredients: result.missingIngredientIds,
        ingredientById: ingredientById,
        onFeedbackSubmitted: (feedback) async {
          try {
            await ref.read(aiFeaturesProvider.notifier).recordFeedback(feedback);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Geri bildiriminiz kaydedildi! Teşekkürler.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

