import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cached_network_image/cached_network_image.dart';
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
  final ImagePicker _picker = ImagePicker();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _speechText = '';

  @override
  void initState() {
    super.initState();
    _ingredientsFuture = _loadIngredients();
    _speech = stt.SpeechToText();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _speechText = result.recognizedWords;
              _controller.text = _speechText;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        // Fotoğraftan metin tanıma (OCR) için burada işlem yapılabilir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fotoğraf analiz ediliyor...')),
          );
          // OCR servisi burada çağrılabilir
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera hatası: $e')),
        );
      }
    }
  }

  Future<List<Ingredient>> _loadIngredients() async {
    try {
      final jsonStr = await DefaultAssetBundle.of(context).loadString('assets/ingredients.json');
      final list = (jsonDecode(jsonStr) as List<dynamic>).map((e) => Ingredient.fromJson(e as Map<String, dynamic>)).toList();
      return list;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Malzemeler yüklenemedi: $e')),
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malzemeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _takePhoto,
            tooltip: 'Kamera ile ekle',
          ),
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _startListening,
            tooltip: 'Sesli ara',
          ),
        ],
      ),
      body: FutureBuilder<List<Ingredient>>(
        future: _ingredientsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Hata: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _ingredientsFuture = _loadIngredients();
                      });
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

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
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isListening ? const Icon(Icons.mic, color: Colors.red) : null,
                    hintText: 'Malzeme ara: örn. domates',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_selectedIngredientIds.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'Seçilen: ${_selectedIngredientIds.length} malzeme',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('"${_controller.text}" için sonuç bulunamadı'),
                            const SizedBox(height: 8),
                            Text('Başka bir malzeme aramayı deneyin', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final ing = filtered[index];
                          final selected = _selectedIngredientIds.contains(ing.id);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: CheckboxListTile(
                              value: selected,
                              title: Text(ing.name, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                              subtitle: Text(ing.category),
                              secondary: const Icon(Icons.kitchen),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIngredientIds.add(ing.id);
                                  } else {
                                    _selectedIngredientIds.remove(ing.id);
                                  }
                                });
                              },
                            ),
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
                      try {
                        final service = await MatchingService.loadFromAssets();
                        final results = service.match(userIngredientIds: _selectedIngredientIds, filters: const MatchFilters(maxTimeMinutes: 30));
                        if (!mounted) return;
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultsScreen(results: results, ingredientById: service.ingredientById)));
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tarifler aranamadı: $e')),
                          );
                        }
                      }
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

