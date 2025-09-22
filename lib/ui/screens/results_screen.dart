import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../widgets/score_bar.dart';
import 'recipe_detail_screen.dart';

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
          final maxScore = r.recipe.ingredients.length * 3 + 12; // Theoretical max score
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(r.recipe.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${r.recipe.timeMin} dk'),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${r.recipe.servings} kişi'),
                      const SizedBox(width: 16),
                      Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(r.recipe.difficulty),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ScoreBar(score: r.score, maxScore: maxScore),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${((r.score / maxScore) * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: r.score / maxScore >= 0.7 
                              ? Colors.green 
                              : r.score / maxScore >= 0.5 
                                  ? Colors.orange 
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (r.missingIngredientIds.isNotEmpty)
                    Text(
                      '${r.missingIngredientIds.length} eksik malzeme',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                ],
              ),
              trailing: r.missingIngredientIds.isEmpty
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : Icon(Icons.shopping_cart, color: Colors.orange[700]),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(result: r, ingredientById: ingredientById),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

