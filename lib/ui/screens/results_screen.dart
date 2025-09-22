import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import 'recipe_detail_screen.dart';

class ResultsScreen extends StatefulWidget {
  final List<MatchResult> results;
  final Map<String, Ingredient> ingredientById;

  const ResultsScreen({
    super.key,
    required this.results,
    required this.ingredientById,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late List<MatchResult> _filteredResults;
  String _sortBy = 'score';

  @override
  void initState() {
    super.initState();
    _filteredResults = widget.results;
    _sortResults();
  }

  void _sortResults() {
    setState(() {
      switch (_sortBy) {
        case 'score':
          _filteredResults.sort((a, b) => b.score.compareTo(a.score));
          break;
        case 'time':
          _filteredResults.sort((a, b) => a.recipe.timeMin.compareTo(b.recipe.timeMin));
          break;
        case 'difficulty':
          _filteredResults.sort((a, b) => a.recipe.difficulty.compareTo(b.recipe.difficulty));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öneriler'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortResults();
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'score',
                child: ListTile(
                  leading: Icon(Icons.star),
                  title: Text('Skora göre'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'time',
                child: ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('Süreye göre'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'difficulty',
                child: ListTile(
                  leading: Icon(Icons.trending_up),
                  title: Text('Zorluğa göre'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: widget.results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Hiç tarif bulunamadı'),
                  const SizedBox(height: 8),
                  Text('Başka malzemeler seçmeyi deneyin', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Geri Dön'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    '${widget.results.length} tarif bulundu',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filteredResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = _filteredResults[index];
                      final scorePercentage = (r.score / (r.recipe.ingredients.length * 3 + 10)).clamp(0.0, 1.0);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: r.recipe.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: r.recipe.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.image, size: 40),
                                  ),
                                )
                              : const Icon(Icons.restaurant, size: 40),
                          title: Text(
                            r.recipe.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Skor: ${r.score} • Süre: ${r.recipe.timeMin} dk'),
                              Text('Zorluk: ${r.recipe.difficulty} • Porsiyon: ${r.recipe.servings}'),
                              if (r.missingIngredientIds.isNotEmpty)
                                Text('${r.missingIngredientIds.length} eksik malzeme', style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                r.missingIngredientIds.isEmpty ? Icons.check_circle : Icons.warning,
                                color: r.missingIngredientIds.isEmpty ? Colors.green : Colors.orange,
                              ),
                              Text('${(scorePercentage * 100).round()}%', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(result: r, ingredientById: widget.ingredientById),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

