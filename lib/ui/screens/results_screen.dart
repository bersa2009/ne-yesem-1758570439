import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'recipe_detail_screen.dart';

class ResultsScreen extends StatelessWidget {
  final List<MatchResult> results;
  final Map<String, Ingredient> ingredientById;
  final bool isAIMode;

  const ResultsScreen({
    super.key,
    required this.results,
    required this.ingredientById,
    this.isAIMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAIMode ? 'AI Tarif Önerileri' : 'Tarif Önerileri'),
        backgroundColor: isAIMode ? Colors.orange : null,
        actions: [
          if (isAIMode)
            IconButton(
              icon: const Icon(Icons.smart_toy),
              onPressed: () => _showAIModeInfo(context),
            ),
        ],
      ),
      body: results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAIMode ? Icons.smart_toy_outlined : Icons.search_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAIMode
                        ? 'AI hiç tarif bulamadı 😔'
                        : 'Hiç tarif bulunamadı 😔',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Farklı malzemeler deneyin veya filtreleri genişletin.'),
                ],
              ),
            )
          : ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = results[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAIMode ? Colors.orange.withOpacity(0.1) : null,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    r.recipe.name,
                    style: TextStyle(
                      fontWeight: isAIMode ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Skor: ${r.score} • Süre: ${r.recipe.timeMin} dk'),
                      if (isAIMode) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Zorluk: ${r.recipe.difficulty} • Popülerlik: ${r.recipe.popularityScore}%',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      r.missingIngredientIds.isEmpty
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : Text(
                              '${r.missingIngredientIds.length} eksik',
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                      if (isAIMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(
                        result: r,
                        ingredientById: ingredientById,
                        isAIMode: isAIMode,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAIModeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Tarif Önerileri'),
        content: const Text(
          'Yapay zeka, malzemelerinizi analiz ederek en uygun tarifleri önerir. '
          'Kullanıcı tercihleri ve geçmiş deneyimlerden öğrenerek önerileri kişiselleştirir. '
          'AI skorları, malzeme uyumu, süre ve popülerlik gibi faktörlere göre hesaplanır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
    );
  }
}

