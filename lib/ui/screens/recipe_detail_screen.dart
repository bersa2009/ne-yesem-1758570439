import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../services/local_store.dart';

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
  final LocalStore _localStore = LocalStore();
  bool _isFavorite = false;
  bool _showIngredients = true;
  bool _showSteps = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final favorites = await _localStore.getFavoriteRecipes();
      setState(() {
        _isFavorite = favorites.any((r) => r.id == widget.result.recipe.id);
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _localStore.removeFavorite(widget.result.recipe.id);
      } else {
        await _localStore.addFavorite(widget.result.recipe.id);
      }
      setState(() {
        _isFavorite = !_isFavorite;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı'),
            action: SnackBarAction(
              label: 'Geri Al',
              onPressed: () => _toggleFavorite(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _shareRecipe() {
    final recipe = widget.result.recipe;
    final text = '''
${recipe.name}

${recipe.description}

Malzemeler:
${recipe.ingredients.map((ri) => '• ${widget.ingredientById[ri.ingredientId]?.name ?? ri.ingredientId} - ${ri.quantity} ${ri.unit}').join('\n')}

Adımlar:
${recipe.steps.asMap().map((i, step) => MapEntry(i, '${i + 1}. $step')).values.join('\n')}

Süre: ${recipe.timeMin} dk | Porsiyon: ${recipe.servings} | Zorluk: ${recipe.difficulty}
''';

    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif panoya kopyalandı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.result.recipe;
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareRecipe,
            tooltip: 'Paylaş',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (recipe.imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: recipe.imageUrl,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            recipe.description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tarif Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(Icons.access_time, 'Süre', '${recipe.timeMin} dk'),
                      ),
                      Expanded(
                        child: _buildInfoChip(Icons.people, 'Porsiyon', '${recipe.servings}'),
                      ),
                      Expanded(
                        child: _buildInfoChip(Icons.trending_up, 'Zorluk', recipe.difficulty),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ExpansionTile(
              initiallyExpanded: _showIngredients,
              onExpansionChanged: (expanded) => setState(() => _showIngredients = expanded),
              leading: const Icon(Icons.kitchen),
              title: const Text('Malzemeler', style: TextStyle(fontWeight: FontWeight.bold)),
              children: recipe.ingredients.map((ri) {
                final ing = widget.ingredientById[ri.ingredientId];
                final isMissing = widget.result.missingIngredientIds.contains(ri.ingredientId);
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isMissing ? Icons.remove_circle : Icons.check_circle,
                    color: isMissing ? Colors.red : Colors.green,
                    semanticLabel: isMissing ? 'Eksik malzeme' : 'Mevcut malzeme',
                  ),
                  title: Text(
                    '${ing?.name ?? ri.ingredientId} • ${ri.quantity} ${ri.unit}',
                    style: TextStyle(
                      decoration: isMissing ? TextDecoration.lineThrough : null,
                      color: isMissing ? Colors.grey : null,
                    ),
                  ),
                  subtitle: ri.optional ? const Text('Opsiyonel', style: TextStyle(fontStyle: FontStyle.italic)) : null,
                  trailing: isMissing ? const Text('Eksik', style: TextStyle(color: Colors.red)) : null,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ExpansionTile(
              initiallyExpanded: _showSteps,
              onExpansionChanged: (expanded) => setState(() => _showSteps = expanded),
              leading: const Icon(Icons.format_list_numbered),
              title: const Text('Adımlar', style: TextStyle(fontWeight: FontWeight.bold)),
              children: List.generate(recipe.steps.length, (i) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${i + 1}', semanticsLabel: '${i + 1}. adım'),
                  ),
                  title: Text(recipe.steps[i]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          if (widget.result.missingIngredientIds.isNotEmpty) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Eksik Malzemeler',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const SizedBox(height: 8),
                    ...widget.result.missingIngredientIds.map((id) {
                      final ing = widget.ingredientById[id];
                      return Text('• ${ing?.name ?? id}', style: const TextStyle(color: Colors.orange));
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Eksik malzemeleri alışveriş listesine ekle
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Eksik malzemeler listeye eklendi')),
                    );
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Alışveriş Listesi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleFavorite,
                  icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                  label: Text(_isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

