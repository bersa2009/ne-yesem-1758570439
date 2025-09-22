import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

class MatchingService {
  final Map<String, Ingredient> ingredientById;
  final List<Recipe> recipes;
  final List<Substitution> substitutions;

  MatchingService({
    required this.ingredientById,
    required this.recipes,
    required this.substitutions,
  });

  static Future<MatchingService> loadFromAssets() async {
    final ingredientsJson = jsonDecode(await rootBundle.loadString('assets/data/ingredients.json')) as List<dynamic>;
    final recipesJson = jsonDecode(await rootBundle.loadString('assets/data/recipes.json')) as List<dynamic>;
    final subsJson = jsonDecode(await rootBundle.loadString('assets/data/substitutions.json')) as List<dynamic>;

    final ingredients = ingredientsJson.map((e) => Ingredient.fromJson(e as Map<String, dynamic>)).toList();
    final ingredientById = {for (final i in ingredients) i.id: i};

    final recipes = recipesJson.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    final substitutions = subsJson.map((e) => Substitution.fromJson(e as Map<String, dynamic>)).toList();

    return MatchingService(
      ingredientById: ingredientById,
      recipes: recipes,
      substitutions: substitutions,
    );
  }

  List<MatchResult> match({
    required Set<String> userIngredientIds,
    MatchFilters filters = const MatchFilters(),
  }) {
    final subMap = _buildSubstitutionMap();
    final results = <MatchResult>[];

    for (final recipe in recipes) {
      final recipeIngredientIds = recipe.ingredients.map((ri) => ri.ingredientId).toSet();

      int score = 0;
      final missing = <String>[];

      for (final ri in recipe.ingredients) {
        final hasExact = userIngredientIds.contains(ri.ingredientId);
        if (hasExact) {
          score += 3;
          continue;
        }
        final substitutes = subMap[ri.ingredientId] ?? const <Substitution>[];
        final hasSub = substitutes.any((s) => userIngredientIds.contains(s.substituteId));
        if (hasSub) {
          score += 2; // partial credit for substitution
        } else {
          if (ri.requiredFlag) {
            score -= 2;
            missing.add(ri.ingredientId);
          } else if (ri.optional) {
            score -= 1;
          } else {
            score -= 2;
            missing.add(ri.ingredientId);
          }
        }
      }

      // Filters bonuses
      if (filters.maxTimeMinutes != null && recipe.timeMin <= filters.maxTimeMinutes!) {
        score += 5;
      }
      if (filters.diet != null && recipe.dietTags.contains(filters.diet)) {
        score += 5;
      }
      if (recipe.equipment.every((e) => !filters.excludedEquipment.contains(e))) {
        score += 2;
      }

      // Popularity boost (lightly)
      score += (recipe.popularityScore / 50).round();

      // Threshold: show only if score > 50% of theoretical max
      final theoreticalMax = recipe.ingredients.length * 3 + 5 + 5 + 2 + (recipe.popularityScore / 50).round();
      final meetsThreshold = score >= (theoreticalMax * 0.5).round();
      if (!meetsThreshold) continue;

      results.add(MatchResult(recipe: recipe, score: score, missingIngredientIds: missing));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  Map<String, List<Substitution>> _buildSubstitutionMap() {
    final map = <String, List<Substitution>>{};
    for (final s in substitutions) {
      map.putIfAbsent(s.ingredientId, () => <Substitution>[]).add(s);
    }
    return map;
  }
}

