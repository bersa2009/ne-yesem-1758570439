import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/models.dart';

class AIService {
  static const String _modelPath = 'assets/data/recipe_model.tflite';
  static const String _trainingDataPath = 'assets/data/training_data.json';

  late Interpreter _interpreter;
  late Map<String, List<double>> _ingredientVectors;
  late List<Map<String, dynamic>> _trainingExamples;
  late List<Recipe> _recipes;
  late Map<String, Ingredient> _ingredientById;
  late List<Substitution> _substitutions;
  late bool _useTensorFlowLite;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TensorFlow Lite modelini yükle
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _useTensorFlowLite = true;
      print('✅ TensorFlow Lite modeli başarıyla yüklendi');
    } catch (e) {
      print('⚠️ TensorFlow Lite modeli yüklenemedi, KNN tabanlı yaklaşım kullanılacak: $e');
      _useTensorFlowLite = false;
    }

    try {
      // Eğitim verilerini yükle
      final trainingDataJson = await rootBundle.loadString(_trainingDataPath);
      final trainingData = jsonDecode(trainingDataJson) as Map<String, dynamic>;

      _ingredientVectors = {
        for (final item in trainingData['ingredients'])
          item['id'] as String: List<double>.from(item['vector'] as List<dynamic>)
      };

      _trainingExamples = List<Map<String, dynamic>>.from(trainingData['training_examples']);
      _recipes = (trainingData['recipes'] as List<dynamic>)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();

      print('✅ Eğitim verileri başarıyla yüklendi');
    } catch (e) {
      print('❌ Eğitim verileri yüklenemedi: $e');
      throw Exception('Eğitim verileri yüklenemedi: $e');
    }

    try {
      // Mevcut servis verilerini yükle
      final ingredientsJson = jsonDecode(await rootBundle.loadString('assets/ingredients.json')) as List<dynamic>;
      final recipesJson = jsonDecode(await rootBundle.loadString('assets/recipes.json')) as List<dynamic>;
      final subsJson = jsonDecode(await rootBundle.loadString('assets/substitutions.json')) as List<dynamic>;

      _ingredientById = {for (final i in ingredientsJson.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))) i.id: i};
      _substitutions = subsJson.map((e) => Substitution.fromJson(e as Map<String, dynamic>)).toList();

      print('✅ Servis verileri başarıyla yüklendi');
      _isInitialized = true;
    } catch (e) {
      print('❌ Servis verileri yüklenemedi: $e');
      throw Exception('Servis verileri yüklenemedi: $e');
    }
  }

  Future<void> _initializeKNN() async {
    // KNN için eğitim verilerini hazırla
    final trainingDataJson = await rootBundle.loadString(_trainingDataPath);
    final trainingData = jsonDecode(trainingDataJson) as Map<String, dynamic>;

    _ingredientVectors = {
      for (final item in trainingData['ingredients'])
        item['id'] as String: List<double>.from(item['vector'] as List<dynamic>)
    };

    _trainingExamples = List<Map<String, dynamic>>.from(trainingData['training_examples']);
    _recipes = (trainingData['recipes'] as List<dynamic>)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();

    // Mevcut servis verilerini yükle
    final ingredientsJson = jsonDecode(await rootBundle.loadString('assets/ingredients.json')) as List<dynamic>;
    final recipesJson = jsonDecode(await rootBundle.loadString('assets/recipes.json')) as List<dynamic>;
    final subsJson = jsonDecode(await rootBundle.loadString('assets/substitutions.json')) as List<dynamic>;

    _ingredientById = {for (final i in ingredientsJson.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))) i.id: i};
    _substitutions = subsJson.map((e) => Substitution.fromJson(e as Map<String, dynamic>)).toList();

    _isInitialized = true;
  }

  List<MatchResult> matchRecipes({
    required Set<String> userIngredientIds,
    MatchFilters filters = const MatchFilters(),
    Map<String, int>? userHistory, // Kullanıcı geçmişi (favoriler, puanlar)
    Map<String, Map<String, double>>? userPreferences, // Kullanıcı tercihleri (ikame skorları)
  }) {
    if (!_isInitialized) {
      throw StateError('AI Service not initialized. Call initialize() first.');
    }

    final results = <MatchResult>[];

    for (final recipe in _recipes) {
      final score = _calculateRecipeScore(
        recipe,
        userIngredientIds,
        filters,
        userHistory ?? {},
        userPreferences ?? {},
      );

      if (score < 50) continue; // Minimum skor eşiği

      final missingIngredientIds = _getMissingIngredients(recipe, userIngredientIds);
      results.add(MatchResult(
        recipe: recipe,
        score: score,
        missingIngredientIds: missingIngredientIds,
      ));
    }

    // Skora göre sırala (yüksekten düşüğe)
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  int _calculateRecipeScore(
    Recipe recipe,
    Set<String> userIngredientIds,
    MatchFilters filters,
    Map<String, int> userHistory,
    Map<String, Map<String, double>> userPreferences,
  ) {
    int score = 0;

    // Temel malzeme eşleştirme (KNN veya TFLite tabanlı)
    final recipeIngredients = recipe.ingredients.map((ri) => ri.ingredientId).toSet();
    final matchingIngredients = userIngredientIds.intersection(recipeIngredients);

    // Tam eşleşme bonusu
    score += matchingIngredients.length * 3;

    // Eksik malzemeler için ceza
    final missingIngredients = recipeIngredients.difference(userIngredientIds);
    for (final missing in missingIngredients) {
      final recipeIngredient = recipe.ingredients.firstWhere((ri) => ri.ingredientId == missing);

      if (recipeIngredient.requiredFlag) {
        score -= 2;
      } else if (recipeIngredient.optional) {
        score -= 1;
      }
    }

    // İkame malzemeler için bonus
    for (final recipeIngredient in recipe.ingredients) {
      if (!userIngredientIds.contains(recipeIngredient.ingredientId)) {
        final substitutes = _getBestSubstitutes(recipeIngredient.ingredientId, userPreferences);
        for (final substitute in substitutes) {
          if (userIngredientIds.contains(substitute.ingredientId)) {
            final substituteBonus = (substitute.strength * 2).round();
            score += substituteBonus;
            break;
          }
        }
      }
    }

    // Zaman filtresi bonusu
    if (filters.maxTimeMinutes != null && recipe.timeMin <= filters.maxTimeMinutes!) {
      score += 5;
    }

    // Diyet filtresi bonusu
    if (filters.diet != null && recipe.dietTags.contains(filters.diet)) {
      score += 5;
    }

    // Ekipman bonusu
    if (recipe.equipment.every((e) => !filters.excludedEquipment.contains(e))) {
      score += 2;
    }

    // Popülerlik bonusu
    score += (recipe.popularityScore / 50).round();

    // Kullanıcı geçmişi bonusu
    if (userHistory.containsKey(recipe.id)) {
      score += userHistory[recipe.id]! ~/ 10; // Geçmiş puanları skora ekle
    }

    // AI öğrenme bonusu (KNN veya TFLite benzerlik tabanlı)
    final similarityScore = _calculateSimilarityScore(userIngredientIds, recipe);
    score += (similarityScore * 10).round();

    return score;
  }

  double _calculateSimilarityScore(Set<String> userIngredientIds, Recipe recipe) {
    if (_ingredientVectors.isEmpty) return 0.0;

    // TFLite modelini kullan (eğer mevcutsa)
    if (_useTensorFlowLite) {
      try {
        return _calculateSimilarityWithTFLite(userIngredientIds, recipe);
      } catch (e) {
        print('⚠️ TFLite hesaplama hatası, KNN kullanılıyor: $e');
      }
    }

    // Fallback: KNN tabanlı cosine similarity
    return _calculateSimilarityWithKNN(userIngredientIds, recipe);
  }

  double _calculateSimilarityWithTFLite(Set<String> userIngredientIds, Recipe recipe) {
    // TFLite modelini kullanarak similarity hesapla
    // Bu kısım gerçek model olduğunda implemente edilecek

    // Şimdilik KNN fallback'i kullan
    return _calculateSimilarityWithKNN(userIngredientIds, recipe);
  }

  double _calculateSimilarityWithKNN(Set<String> userIngredientIds, Recipe recipe) {
    final recipeVectors = recipe.ingredients
        .map((ri) => _ingredientVectors[ri.ingredientId])
        .where((v) => v != null)
        .toList();

    if (recipeVectors.isEmpty) return 0.0;

    final userVectors = userIngredientIds
        .map((id) => _ingredientVectors[id])
        .where((v) => v != null)
        .toList();

    if (userVectors.isEmpty) return 0.0;

    // Cosine similarity hesapla
    double totalSimilarity = 0.0;
    int comparisons = 0;

    for (final userVec in userVectors) {
      for (final recipeVec in recipeVectors) {
        totalSimilarity += _cosineSimilarity(userVec!, recipeVec!);
        comparisons++;
      }
    }

    return comparisons > 0 ? totalSimilarity / comparisons : 0.0;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  List<Substitution> _getBestSubstitutes(String ingredientId, Map<String, Map<String, double>> userPreferences) {
    final substitutes = _substitutions.where((s) => s.ingredientId == ingredientId).toList();

    // Kullanıcı tercihlerine göre sırala
    if (userPreferences.containsKey(ingredientId)) {
      substitutes.sort((a, b) {
        final aPref = userPreferences[ingredientId]![a.substituteId] ?? a.strength;
        final bPref = userPreferences[ingredientId]![b.substituteId] ?? b.strength;
        return bPref.compareTo(aPref);
      });
    } else {
      substitutes.sort((a, b) => b.strength.compareTo(a.strength));
    }

    return substitutes.take(3).toList(); // En iyi 3 ikameyi döndür
  }

  List<String> _getMissingIngredients(Recipe recipe, Set<String> userIngredientIds) {
    return recipe.ingredients
        .where((ri) => !userIngredientIds.contains(ri.ingredientId) && ri.requiredFlag)
        .map((ri) => ri.ingredientId)
        .toList();
  }

  // Kullanıcı geri bildiriminden öğrenme
  void learnFromFeedback(String recipeId, Set<String> userIngredientIds, int userRating) {
    // KNN için yeni örnek ekle
    final newExample = {
      'user_ingredients': userIngredientIds.toList(),
      'recipe_id': recipeId,
      'score': userRating,
    };

    _trainingExamples.add(newExample);

    // Kullanıcı tercihlerini güncelle
    // Bu kısım daha gelişmiş bir öğrenme sistemi için V2'de kullanılacak
  }

  void dispose() {
    if (_isInitialized && _useTensorFlowLite) {
      try {
        _interpreter.close();
        print('✅ AI Service başarıyla kapatıldı');
      } catch (e) {
        print('⚠️ AI Service kapatma hatası: $e');
      }
    }
  }
}