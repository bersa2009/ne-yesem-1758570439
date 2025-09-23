import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/ai_providers.dart';
import '../../services/ai_service.dart';
import 'recipe_detail_screen.dart';

class AIResultsScreen extends ConsumerStatefulWidget {
  const AIResultsScreen({super.key});

  @override
  ConsumerState<AIResultsScreen> createState() => _AIResultsScreenState();
}

class _AIResultsScreenState extends ConsumerState<AIResultsScreen> {
  bool _showPersonalized = false;

  @override
  Widget build(BuildContext context) {
    final aiMatchResults = ref.watch(aiMatchResultsProvider);
    final personalizedRecs = ref.watch(personalizedRecommendationsProvider);
    final matchingService = ref.watch(matchingServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Önerileri'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'personalized') {
                setState(() {
                  _showPersonalized = !_showPersonalized;
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'personalized',
                child: Row(
                  children: [
                    Icon(_showPersonalized ? Icons.person : Icons.person_outline),
                    const SizedBox(width: 8),
                    Text(_showPersonalized ? 'Tüm Sonuçlar' : 'Kişiselleştirilmiş'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Destekli Eşleştirme',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Text(
                        'Makine öğrenmesi ile kişiselleştirilmiş öneriler',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Toggle Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showPersonalized = false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_showPersonalized 
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : null,
                    ),
                    child: const Text('AI Eşleştirme'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showPersonalized = true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _showPersonalized 
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : null,
                    ),
                    child: const Text('Kişisel Öneriler'),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _showPersonalized 
                ? _buildPersonalizedRecommendations(personalizedRecs, matchingService)
                : _buildAIMatchResults(aiMatchResults, matchingService),
          ),
        ],
      ),
    );
  }

  Widget _buildAIMatchResults(
    AsyncValue<List<MatchResult>> aiMatchResults,
    AsyncValue<MatchingService> matchingService,
  ) {
    return aiMatchResults.when(
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Hiç tarif bulunamadı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Daha fazla malzeme ekleyerek tekrar deneyin',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return matchingService.when(
          data: (service) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final result = results[index];
              return _buildResultCard(result, service.ingredientById);
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Hata: $error'),
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI tariflerinizi analiz ediyor...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('AI Hatası: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(aiMatchResultsProvider),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedRecommendations(
    AsyncValue<List<String>> personalizedRecs,
    AsyncValue<MatchingService> matchingService,
  ) {
    return personalizedRecs.when(
      data: (recipeIds) {
        if (recipeIds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Henüz kişisel öneriniz yok',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Tarifleri değerlendirmeye başlayın',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return matchingService.when(
          data: (service) {
            final recipes = recipeIds
                .map((id) => service.recipes.firstWhere(
                      (r) => r.id == id,
                      orElse: () => Recipe(
                        id: '',
                        name: '',
                        description: '',
                        steps: [],
                        timeMin: 0,
                        servings: 0,
                        difficulty: '',
                        equipment: [],
                        dietTags: [],
                        imageUrl: '',
                        popularityScore: 0,
                        ingredients: [],
                      ),
                    ))
                .where((r) => r.id.isNotEmpty)
                .toList();

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return _buildPersonalizedCard(recipe, service.ingredientById);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Hata: $error'),
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Kişisel önerileriniz hazırlanıyor...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Text('Hata: $error'),
      ),
    );
  }

  Widget _buildResultCard(MatchResult result, Map<String, Ingredient> ingredientById) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(
              result: result,
              ingredientById: ingredientById,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.recipe.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getScoreColor(result.score),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'AI: ${result.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.recipe.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${result.recipe.timeMin} dk'),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${result.recipe.servings} kişi'),
                  const Spacer(),
                  if (result.missingIngredientIds.isEmpty)
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('Tamamı mevcut', style: TextStyle(color: Colors.green)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${result.missingIngredientIds.length} eksik',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ],
                    ),
                ],
              ),
              if (result.missingIngredientIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildSubstitutionSuggestions(result.missingIngredientIds.first),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalizedCard(Recipe recipe, Map<String, Ingredient> ingredientById) {
    return Card(
      child: InkWell(
        onTap: () {
          // Create a dummy MatchResult for navigation
          final matchResult = MatchResult(
            recipe: recipe,
            score: 85, // Default score for personalized recommendations
            missingIngredientIds: [],
          );
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                result: matchResult,
                ingredientById: ingredientById,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Sizin İçin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${recipe.timeMin} dk'),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${recipe.servings} kişi'),
                  const Spacer(),
                  if (recipe.dietTags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recipe.dietTags.first,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubstitutionSuggestions(String missingIngredientId) {
    return Consumer(
      builder: (context, ref, child) {
        final substitutions = ref.watch(substitutionSuggestionsProvider(missingIngredientId));
        
        return substitutions.when(
          data: (suggestions) {
            if (suggestions.isEmpty) return const SizedBox.shrink();
            
            final topSuggestion = suggestions.first;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Öneri: ${topSuggestion.reason}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${(topSuggestion.confidence * 100).round()}%',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}