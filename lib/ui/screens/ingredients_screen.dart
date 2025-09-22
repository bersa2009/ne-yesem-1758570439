import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/matching_service.dart';
import '../../services/voice/voice_service.dart';
import '../../services/camera/camera_service.dart';
import '../widgets/app_navigation.dart';
import 'results_screen.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final TextEditingController _controller = TextEditingController();
  final Set<String> _selectedIngredientIds = <String>{};
  final VoiceService _voiceService = VoiceService();
  final CameraService _cameraService = CameraService();
  late Future<List<Ingredient>> _ingredientsFuture;

  @override
  void initState() {
    super.initState();
    _ingredientsFuture = _loadIngredients();
    _initializeServices();
  }

  void _initializeServices() async {
    await _voiceService.initialize();
    await _cameraService.initialize();
  }

  Future<List<Ingredient>> _loadIngredients() async {
    final jsonStr = await DefaultAssetBundle.of(context).loadString('assets/ingredients.json');
    final list = (jsonDecode(jsonStr) as List<dynamic>).map((e) => Ingredient.fromJson(e as Map<String, dynamic>)).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        title: const Text('Malzemeler'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Malzeme ara: örn. domates',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _handleVoiceInput,
                                icon: const Icon(Icons.mic),
                                tooltip: 'Sesli giriş',
                              ),
                              IconButton(
                                onPressed: _handleCameraInput,
                                icon: const Icon(Icons.camera_alt),
                                tooltip: 'Fotoğraf çek',
                              ),
                            ],
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
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
                      final results = service.match(userIngredientIds: _selectedIngredientIds, filters: const MatchFilters(maxTimeMinutes: 30));
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

  void _handleVoiceInput() async {
    if (await _voiceService.initialize()) {
      showDialog(
        context: context,
        builder: (context) => VoiceInputDialog(voiceService: _voiceService),
      );
    } else {
      _showErrorSnackBar('Mikrofon izni gerekli');
    }
  }

  void _handleCameraInput() async {
    final file = await _cameraService.showImageSourceDialog(context);
    if (file != null) {
      final ingredients = await _cameraService.recognizeIngredients(file);
      if (ingredients.isNotEmpty && mounted) {
        _showRecognizedIngredientsDialog(ingredients);
      }
    }
  }

  void _showRecognizedIngredientsDialog(List<String> ingredients) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tanınan Malzemeler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ingredients.map((ingredient) => 
            CheckboxListTile(
              title: Text(ingredient),
              value: true,
              onChanged: (value) {
                // Add to selected ingredients
                Navigator.pop(context);
                _controller.text = ingredient;
                setState(() {});
              },
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add all recognized ingredients
              for (String ingredient in ingredients) {
                _controller.text = ingredient;
              }
              setState(() {});
            },
            child: const Text('Hepsini Ekle'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrele',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Kategoriye Göre'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Alfabetik Sıralama'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Popüler Malzemeler'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _voiceService.dispose();
    _cameraService.dispose();
    super.dispose();
  }
}

