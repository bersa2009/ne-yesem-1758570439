import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../services/matching_service.dart';
import '../../services/ai_service.dart';
import 'results_screen.dart';

class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key});

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen> {
  final TextEditingController _controller = TextEditingController();
  final Set<String> _selectedIngredientIds = <String>{};
  late Future<List<Ingredient>> _ingredientsFuture;

  @override
  void initState() {
    super.initState();
    _ingredientsFuture = _loadIngredients();
  }

  Future<List<Ingredient>> _loadIngredients() async {
    final jsonStr = await DefaultAssetBundle.of(context).loadString('assets/ingredients.json');
    final list = (jsonDecode(jsonStr) as List<dynamic>).map((e) => Ingredient.fromJson(e as Map<String, dynamic>)).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Malzemeler')),
      body: FutureBuilder<List<Ingredient>>(
        future: _ingredientsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allIngredients = snapshot.data!;
          final query = _controller.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? allIngredients
              : allIngredients.where((i) => i.name.toLowerCase().contains(query) || i.aliases.any((a) => a.toLowerCase().contains(query))).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Malzeme ara: örn. domates'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ing = filtered[index];
                    final selected = _selectedIngredientIds.contains(ing.id);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(ing.name),
                      subtitle: Text(ing.category),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIngredientIds.add(ing.id);
                          } else {
                            _selectedIngredientIds.remove(ing.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectedIngredientIds.isEmpty
                            ? null
                            : () async {
                                final service = await MatchingService.loadFromAssets();
                                final results = service.match(
                                  userIngredientIds: _selectedIngredientIds,
                                  filters: const MatchFilters(maxTimeMinutes: 30),
                                );
                                if (!mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ResultsScreen(
                                      results: results,
                                      ingredientById: service.ingredientById,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.search),
                        label: const Text('Tarif Ara'),
                      ),
                      const SizedBox(height: 8),
                      Consumer(builder: (context, ref, _) {
                        final aiAsync = ref.watch(aiServiceProvider);
                        return ElevatedButton.icon(
                          onPressed: _selectedIngredientIds.isEmpty
                              ? null
                              : () async {
                                  final ai = await aiAsync.future;
                                  final results = await ai.matchSmart(
                                    userIngredientIds: _selectedIngredientIds,
                                    filters: const MatchFilters(maxTimeMinutes: 30),
                                  );
                                  if (!mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ResultsScreen(
                                        results: results,
                                        ingredientById: ai.classic.ingredientById,
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: aiAsync.when(
                            data: (ai) => Text(ai.isAiAvailable ? 'AI ile Öner' : 'AI ile Öner (Heuristik)'),
                            loading: () => const Text('AI Hazırlanıyor...'),
                            error: (e, st) => const Text('AI (Hata - Heuristik)'),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

