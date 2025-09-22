import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/matching_service.dart';
import 'results_screen.dart';
import '../../services/local_store.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final TextEditingController _controller = TextEditingController();
  final Set<String> _selectedIngredientIds = <String>{};
  late Future<List<Ingredient>> _ingredientsFuture;
  int? _maxTime;
  String? _diet;
  final Set<String> _excludedEquipment = <String>{};

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _maxTime,
                        decoration: const InputDecoration(labelText: 'Maks süre'),
                        items: const [null, 15, 30, 45, 60]
                            .map((v) => DropdownMenuItem<int>(value: v, child: Text(v == null ? 'Yok' : '$v dk')))
                            .toList(),
                        onChanged: (v) => setState(() => _maxTime = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _diet,
                        decoration: const InputDecoration(labelText: 'Diyet'),
                        items: const [null, 'vejetaryen', 'vegan', 'glutensiz']
                            .map((v) => DropdownMenuItem<String>(value: v, child: Text(v ?? 'Yok')))
                            .toList(),
                        onChanged: (v) => setState(() => _diet = v),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Tava yok'),
                      selected: _excludedEquipment.contains('tava'),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _excludedEquipment.add('tava');
                        } else {
                          _excludedEquipment.remove('tava');
                        }
                      }),
                    ),
                    FilterChip(
                      label: const Text('Fırın yok'),
                      selected: _excludedEquipment.contains('firin'),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _excludedEquipment.add('firin');
                        } else {
                          _excludedEquipment.remove('firin');
                        }
                      }),
                    ),
                    FilterChip(
                      label: const Text('Blender yok'),
                      selected: _excludedEquipment.contains('blender'),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _excludedEquipment.add('blender');
                        } else {
                          _excludedEquipment.remove('blender');
                        }
                      }),
                    ),
                  ],
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
                  child: ElevatedButton.icon(
                    onPressed: _selectedIngredientIds.isEmpty ? null : () async {
                      final service = await MatchingService.loadFromAssets();
                      await LocalStore.instance.addSearchQuery(_controller.text.trim());
                      final results = service.match(
                        userIngredientIds: _selectedIngredientIds,
                        filters: MatchFilters(maxTimeMinutes: _maxTime, diet: _diet, excludedEquipment: _excludedEquipment.toList()),
                      );
                      if (!mounted) return;
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultsScreen(results: results, ingredientById: service.ingredientById)));
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Tarif Ara'),
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

