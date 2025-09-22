import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/matching_service.dart';
import 'results_screen.dart';

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
  int? _minServings;
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(_maxTime == null ? 'Süre ≤ ...' : 'Süre ≤ ${_maxTime} dk'),
                      selected: _maxTime != null,
                      onSelected: (_) async {
                        final val = await _pickNumber(context, title: 'Maks süre (dk)', initial: _maxTime ?? 30);
                        setState(() => _maxTime = val);
                      },
                      onDeleted: _maxTime != null ? () => setState(() => _maxTime = null) : null,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(_minServings == null ? 'Porsiyon ≥ ...' : 'Porsiyon ≥ $_minServings'),
                      selected: _minServings != null,
                      onSelected: (_) async {
                        final val = await _pickNumber(context, title: 'Minimum porsiyon', initial: _minServings ?? 2);
                        setState(() => _minServings = val);
                      },
                      onDeleted: _minServings != null ? () => setState(() => _minServings = null) : null,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(_diet ?? 'Diyet'),
                      selected: _diet != null,
                      onSelected: (_) async {
                        final val = await _pickDiet(context, initial: _diet);
                        setState(() => _diet = val);
                      },
                      onDeleted: _diet != null ? () => setState(() => _diet = null) : null,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Ekipmansız (fırın)'),
                      selected: _excludedEquipment.contains('oven'),
                      onSelected: (s) => setState(() {
                        if (s) {
                          _excludedEquipment.add('oven');
                        } else {
                          _excludedEquipment.remove('oven');
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
                      final results = service.match(
                        userIngredientIds: _selectedIngredientIds,
                        filters: MatchFilters(
                          maxTimeMinutes: _maxTime,
                          minServings: _minServings,
                          diet: _diet,
                          excludedEquipment: _excludedEquipment.toList(),
                        ),
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

  Future<int?> _pickNumber(BuildContext context, {required String title, required int initial}) async {
    final controller = TextEditingController(text: '$initial');
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Sayı girin'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Temizle')),
          TextButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text)), child: const Text('Tamam')),
        ],
      ),
    );
    return result;
  }

  Future<String?> _pickDiet(BuildContext context, {String? initial}) async {
    final diets = <String?>[null, 'vegan', 'vegetarian', 'gluten_free'];
    String? selected = initial;
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diyet seçin'),
        content: StatefulBuilder(
          builder: (context, setStateSB) => Column(
            mainAxisSize: MainAxisSize.min,
            children: diets.map((d) => RadioListTile<String?>(
              value: d,
              groupValue: selected,
              title: Text(d ?? 'Yok'),
              onChanged: (v) => setStateSB(() => selected = v),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Temizle')),
          TextButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Tamam')),
        ],
      ),
    );
    return result;
  }
}

