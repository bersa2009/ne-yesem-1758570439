import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'recipe_detail_screen.dart';
import '../widgets/score_bar.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Öneriler')),
      body: ListView.separated(
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final r = results[index];
          final theoreticalMax = r.recipe.ingredients.length * 3 + 12; // rough for progress bar
          return ListTile(
            title: Text(r.recipe.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Skor: ${r.score} • Süre: ${r.recipe.timeMin} dk'),
                const SizedBox(height: 6),
                ScoreBar(score: r.score, maxScore: theoreticalMax),
              ],
            ),
            trailing: r.missingIngredientIds.isEmpty
                ? const Icon(Icons.check_circle, color: Colors.green)
                : Text('${r.missingIngredientIds.length} eksik', style: const TextStyle(color: Colors.red)),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(result: r, ingredientById: ingredientById),
              ),
            ),
          );
        },
      ),
    );
  }
}

