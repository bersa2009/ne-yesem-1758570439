import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/ai_providers.dart';
import 'results_screen.dart';
import 'ai_results_screen.dart';

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
                child: Column(
                  children: [
                    // AI Status Indicator
                    Consumer(
                      builder: (context, ref, child) {
                        final aiStatus = ref.watch(aiServiceStatusProvider);
                        return aiStatus.when(
                          data: (status) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.smart_toy, size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'AI Aktif',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          loading: () => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.orange.shade700),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'AI Yükleniyor...',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          error: (error, stack) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Temel Mod',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Search Button with AI Integration
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedIngredientIds.isEmpty ? null : () async {
                          // Update user ingredients in provider
                          ref.read(userIngredientsProvider.notifier).state = _selectedIngredientIds;
                          
                          // Navigate to results screen
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AIResultsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.smart_toy),
                        label: const Text('AI ile Tarif Ara'),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Traditional Search Button (Fallback)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _selectedIngredientIds.isEmpty ? null : () async {
                          final matchingService = await ref.read(matchingServiceProvider.future);
                          final results = matchingService.match(
                            userIngredientIds: _selectedIngredientIds,
                            filters: const MatchFilters(maxTimeMinutes: 30),
                          );
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ResultsScreen(
                                results: results,
                                ingredientById: matchingService.ingredientById,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Geleneksel Arama'),
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

