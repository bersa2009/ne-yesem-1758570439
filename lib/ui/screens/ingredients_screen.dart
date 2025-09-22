import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/matching_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pantry_provider.dart';
import '../../services/search_history_service.dart';
import 'results_screen.dart';
import 'main_screen.dart';
import 'filter_screen.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<Ingredient>> _ingredientsFuture;
  MatchFilters _currentFilters = const MatchFilters();

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

  Future<void> _performSearch() async {
    final authProvider = context.read<AuthProvider>();
    final pantryProvider = context.read<PantryProvider>();

    // Check search limits for free users
    if (!authProvider.canPerformSearch()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Günlük 5 arama limitine ulaştınız. Pro olmak için profile bakın.'),
        ),
      );
      return;
    }

    final selectedIngredientIds = pantryProvider.getIngredientIds();
    if (selectedIngredientIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce kilerinize malzeme ekleyin.')),
      );
      return;
    }

    try {
      final service = await MatchingService.loadFromAssets();
      final results = service.match(
        userIngredientIds: selectedIngredientIds.toSet(),
        filters: _currentFilters,
      );

      // Save search history
      if (authProvider.isAuthenticated) {
        final searchHistory = SearchHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          ingredientIds: selectedIngredientIds,
          searchedAt: DateTime.now(),
          resultCount: results.length,
        );
        await SearchHistoryService.addSearchHistory(searchHistory);

        // Increment search count
        await authProvider.incrementSearchCount();
      }

      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultsScreen(
          results: results,
          ingredientById: service.ingredientById,
        ),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama yapılırken hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malzemeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtreler',
          ),
          Consumer<PantryProvider>(
            builder: (context, pantryProvider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    '${pantryProvider.pantryItems.length} malzeme',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Malzeme ara: örn. domates',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Consumer<PantryProvider>(
                builder: (context, pantryProvider, child) {
                  if (pantryProvider.pantryItems.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.kitchen, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                'Kileriniz boş!',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text('Kilerinizi doldurmak için "Kiler" sekmesine gidin.'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to pantry screen
                                  final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
                                  if (mainScreenState != null) {
                                    mainScreenState.setState(() {
                                      mainScreenState._currentIndex = 1; // Pantry tab
                                    });
                                  }
                                },
                                child: const Text('Kilere Git'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ing = filtered[index];
                        final inPantry = pantryProvider.pantryItems.any((item) => item.ingredientId == ing.id);
                        return ListTile(
                          title: Text(ing.name),
                          subtitle: Text(ing.category),
                          trailing: inPantry
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.add_circle_outline, color: Colors.grey),
                          onTap: () {
                            // Navigate to pantry to add this ingredient
                            final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
                            if (mainScreenState != null) {
                              mainScreenState.setState(() {
                                mainScreenState._currentIndex = 1; // Pantry tab
                              });
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              Consumer2<AuthProvider, PantryProvider>(
                builder: (context, authProvider, pantryProvider, child) {
                  final canSearch = authProvider.canPerformSearch();
                  final hasIngredients = pantryProvider.pantryItems.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        if (!canSearch && authProvider.isAuthenticated)
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Text(
                              'Günlük 5 arama limitine ulaştınız. Pro özellikler için profile bakın.',
                              style: TextStyle(color: Colors.orange, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (!canSearch || !hasIngredients) ? null : _performSearch,
                            icon: const Icon(Icons.search),
                            label: Text('Tarif Ara (${authProvider.userProfile?.dailySearchCount ?? 0}/5)'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterDialog() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FilterScreen(initialFilters: _currentFilters),
      ),
    );

    if (result != null && result is MatchFilters) {
      setState(() {
        _currentFilters = result;
      });
    }
  }
}

