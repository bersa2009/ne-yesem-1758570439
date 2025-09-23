import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';
import 'matching_service.dart';
import 'ai/tflite_loader.dart';

/// AI-powered matcher that extends the baseline [MatchingService].
/// It attempts to use a TensorFlow Lite model when available; otherwise
/// it falls back to an enhanced heuristic scoring.
class AIService extends MatchingService {
  final Object? _interpreter;

  // Learned substitution weights keyed by "ingredientId->substituteId"
  final Map<String, double> _learnedSubstitutionWeights;

  AIService({
    required super.ingredientById,
    required super.recipes,
    required super.substitutions,
    Object? interpreter,
    Map<String, double>? learnedSubstitutionWeights,
  })  : _interpreter = interpreter,
        _learnedSubstitutionWeights = learnedSubstitutionWeights ?? <String, double>{};

  static Future<AIService> loadFromAssets() async {
    final base = await MatchingService.loadFromAssets();
    Object? interpreter;
    try {
      // Try local asset first using conditional bridge (returns null on web)
      interpreter = await tfliteLoadFromAsset('assets/data/recipe_matcher.tflite');
    } catch (_) {
      // If model missing or invalid, stay null. We keep the app fully functional.
      interpreter = null;
    }

    Map<String, double> learnedWeights = <String, double>{};
    try {
      final raw = await rootBundle.loadString('assets/data/labels.json');
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      final lw = jsonMap['learned_weights'] as Map<String, dynamic>?;
      if (lw != null) {
        learnedWeights = lw.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
    } catch (_) {
      // optional file; ignore
    }

    return AIService(
      ingredientById: base.ingredientById,
      recipes: base.recipes,
      substitutions: base.substitutions,
      interpreter: interpreter,
      learnedSubstitutionWeights: learnedWeights,
    );
  }

  /// Public entry: AI-driven matching with safety fallback.
  Future<List<MatchResult>> aiMatch({
    required Set<String> userIngredientIds,
    MatchFilters filters = const MatchFilters(),
    Set<String> favoriteRecipeIds = const <String>{},
  }) async {
    // Simulate small compute time to avoid blocking UI and mimic model run
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      if (_interpreter == null) {
        return _heuristicMatch(userIngredientIds: userIngredientIds, filters: filters, favoriteRecipeIds: favoriteRecipeIds);
      }
      // Run AI per recipe to get a probability score [0,1].
      final subMap = _buildSubstitutionMap();
      final results = <MatchResult>[];

      for (final recipe in recipes) {
        final featureVector = _buildFeatures(
          recipe: recipe,
          userIngredientIds: userIngredientIds,
          subMap: subMap,
          filters: filters,
          favoriteRecipeIds: favoriteRecipeIds,
        );

        // Prepare input/output for model. We assume a simple dense NN with N inputs and 1 output.
        final input = [featureVector];
        final output = List.filled(1, List.filled(1, 0.0));
        try {
          // Dynamic invoke to keep web builds working without tflite dependency
          // ignore: avoid_dynamic_calls
          (_interpreter as dynamic).run(input, output);
          final probability = (output[0][0] as num).toDouble().clamp(0.0, 1.0);
          final score = (probability * 100).round();
          final missing = _missingIngredients(recipe, userIngredientIds, subMap);
          if (probability >= 0.5) {
            results.add(MatchResult(recipe: recipe, score: score, missingIngredientIds: missing));
          }
        } catch (_) {
          // If model invocation fails at runtime (e.g., placeholder model), gracefully fallback per recipe
          final fallback = _heuristicScore(
            recipe: recipe,
            userIngredientIds: userIngredientIds,
            subMap: subMap,
            filters: filters,
            favoriteRecipeIds: favoriteRecipeIds,
          );
          final missing = _missingIngredients(recipe, userIngredientIds, subMap);
          final theoreticalMax = recipe.ingredients.length * 3 + 20;
          final meets = fallback >= (theoreticalMax * 0.5).round();
          if (meets) {
            results.add(MatchResult(recipe: recipe, score: fallback, missingIngredientIds: missing));
          }
        }
      }

      results.sort((a, b) => b.score.compareTo(a.score));
      return results;
    } catch (_) {
      // Last-resort fallback: enhanced heuristic
      return _heuristicMatch(userIngredientIds: userIngredientIds, filters: filters, favoriteRecipeIds: favoriteRecipeIds);
    }
  }

  // --- Learning API (V2-ready) ---
  void recordPositiveSubstitution({required String ingredientId, required String substituteId}) {
    final key = '$ingredientId->$substituteId';
    final current = _learnedSubstitutionWeights[key] ?? 0.0;
    _learnedSubstitutionWeights[key] = (current + 0.1).clamp(0.0, 1.5);
  }

  // --- Internal helpers ---
  List<double> _buildFeatures({
    required Recipe recipe,
    required Set<String> userIngredientIds,
    required Map<String, List<Substitution>> subMap,
    required MatchFilters filters,
    required Set<String> favoriteRecipeIds,
  }) {
    final recipeIngredientIds = recipe.ingredients.map((ri) => ri.ingredientId).toSet();

    int exactMatches = 0;
    int substitutionMatches = 0;
    int missingRequired = 0;
    int missingOptional = 0;

    for (final ri in recipe.ingredients) {
      final hasExact = userIngredientIds.contains(ri.ingredientId);
      if (hasExact) {
        exactMatches++;
        continue;
      }
      final substitutes = subMap[ri.ingredientId] ?? const <Substitution>[];
      final hasSub = substitutes.any((s) => userIngredientIds.contains(s.substituteId));
      if (hasSub) {
        substitutionMatches++;
      } else {
        if (ri.requiredFlag && !ri.optional) {
          missingRequired++;
        } else {
          missingOptional++;
        }
      }
    }

    final timeBonus = (filters.maxTimeMinutes != null && recipe.timeMin <= filters.maxTimeMinutes!) ? 1.0 : 0.0;
    final dietBonus = (filters.diet != null && recipe.dietTags.contains(filters.diet)) ? 1.0 : 0.0;
    final favoriteBoost = favoriteRecipeIds.contains(recipe.id) ? 1.0 : 0.0;
    final equipmentOk = recipe.equipment.every((e) => !filters.excludedEquipment.contains(e)) ? 1.0 : 0.0;
    final popularity = (recipe.popularityScore / 100).clamp(0.0, 1.0);

    return <double>[
      exactMatches / math.max(1, recipeIngredientIds.length),
      substitutionMatches / math.max(1, recipeIngredientIds.length),
      missingRequired / math.max(1, recipeIngredientIds.length),
      missingOptional / math.max(1, recipeIngredientIds.length),
      timeBonus,
      dietBonus,
      favoriteBoost,
      equipmentOk,
      popularity,
    ];
  }

  List<String> _missingIngredients(Recipe recipe, Set<String> userIngredientIds, Map<String, List<Substitution>> subMap) {
    final missing = <String>[];
    for (final ri in recipe.ingredients) {
      final hasExact = userIngredientIds.contains(ri.ingredientId);
      if (hasExact) continue;
      final substitutes = subMap[ri.ingredientId] ?? const <Substitution>[];
      final hasSub = substitutes.any((s) => userIngredientIds.contains(s.substituteId));
      if (!hasSub) {
        missing.add(ri.ingredientId);
      }
    }
    return missing;
  }

  List<MatchResult> _heuristicMatch({
    required Set<String> userIngredientIds,
    required MatchFilters filters,
    required Set<String> favoriteRecipeIds,
  }) {
    final subMap = _buildSubstitutionMap();
    final results = <MatchResult>[];

    for (final recipe in recipes) {
      final score = _heuristicScore(
        recipe: recipe,
        userIngredientIds: userIngredientIds,
        subMap: subMap,
        filters: filters,
        favoriteRecipeIds: favoriteRecipeIds,
      );
      final missing = _missingIngredients(recipe, userIngredientIds, subMap);

      final theoreticalMax = recipe.ingredients.length * 3 + 20;
      final meetsThreshold = score >= (theoreticalMax * 0.5).round();
      if (!meetsThreshold) continue;

      results.add(MatchResult(recipe: recipe, score: score, missingIngredientIds: missing));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  int _heuristicScore({
    required Recipe recipe,
    required Set<String> userIngredientIds,
    required Map<String, List<Substitution>> subMap,
    required MatchFilters filters,
    required Set<String> favoriteRecipeIds,
  }) {
    int score = 0;

    for (final ri in recipe.ingredients) {
      final hasExact = userIngredientIds.contains(ri.ingredientId);
      if (hasExact) {
        score += 3; // exact
        continue;
      }
      final substitutes = subMap[ri.ingredientId] ?? const <Substitution>[];
      final subHit = substitutes.firstWhere(
        (s) => userIngredientIds.contains(s.substituteId),
        orElse: () => Substitution(ingredientId: ri.ingredientId, substituteId: '', strength: 0.0),
      );
      if (subHit.substituteId.isNotEmpty) {
        // Base partial + learned weight bonus
        final key = '${ri.ingredientId}->${subHit.substituteId}';
        final learned = _learnedSubstitutionWeights[key] ?? 0.0;
        score += (2 + (subHit.strength * 1.5) + learned).round();
      } else {
        score += ri.requiredFlag ? -2 : -1;
      }
    }

    if (filters.maxTimeMinutes != null && recipe.timeMin <= filters.maxTimeMinutes!) {
      score += 5;
    }
    if (filters.diet != null && recipe.dietTags.contains(filters.diet)) {
      score += 7; // prioritize diet stronger
    }
    if (recipe.equipment.every((e) => !filters.excludedEquipment.contains(e))) {
      score += 2;
    }
    score += (recipe.popularityScore / 40).round();
    if (favoriteRecipeIds.contains(recipe.id)) {
      score += 8;
    }

    return score;
  }

  Map<String, List<Substitution>> _buildSubstitutionMap() {
    final map = <String, List<Substitution>>{};
    for (final s in substitutions) {
      map.putIfAbsent(s.ingredientId, () => <Substitution>[]).add(s);
    }
    return map;
  }

  // V2 hook: Attempt to download a fresher model from Firebase (not invoked by default)
  // Keeping this method here prepares the project for online learning.
  Future<void> tryUpdateModelFromFirebase() async {
    if (kIsWeb) return; // Not supported on web
    try {
      // Lazy import to avoid requiring Firebase initialization at runtime
      // ignore: avoid_dynamic_calls
      final downloader = await _loadDownloader();
      if (downloader == null) return;
      final model = await downloader.getModel('recipe_matcher', androidDownloadType: const Object());
      // No-op: Using local asset for now. This is a placeholder for V2.
      model.toString();
    } catch (_) {
      // Silently ignore in V1
    }
  }

  // Using dynamic to avoid hard dependency during runtime if Firebase is not set up
  Future<dynamic> _loadDownloader() async {
    try {
      // Defer import via reflection-like access
      // ignore: avoid_dynamic_calls
      return null; // Implemented in V2 with Firebase setup
    } catch (_) {
      return null;
    }
  }
}

