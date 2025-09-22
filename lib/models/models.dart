class Ingredient {
  final String id;
  final String name;
  final List<String> aliases;
  final String category;

  Ingredient({
    required this.id,
    required this.name,
    required this.aliases,
    required this.category,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: json['id'] as String,
        name: json['name'] as String,
        aliases: List<String>.from(json['aliases'] as List<dynamic>),
        category: json['category'] as String,
      );
}

class RecipeIngredient {
  final String ingredientId;
  final double quantity;
  final String unit;
  final bool optional;
  final bool requiredFlag;

  RecipeIngredient({
    required this.ingredientId,
    required this.quantity,
    required this.unit,
    required this.optional,
    required this.requiredFlag,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
        ingredientId: json['ingredient_id'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        optional: json['optional'] as bool? ?? false,
        requiredFlag: json['required'] as bool? ?? true,
      );
}

class Recipe {
  final String id;
  final String name;
  final String description;
  final List<String> steps;
  final int timeMin;
  final int servings;
  final String difficulty;
  final List<String> equipment;
  final List<String> dietTags;
  final String imageUrl;
  final int popularityScore;
  final List<RecipeIngredient> ingredients;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    required this.timeMin,
    required this.servings,
    required this.difficulty,
    required this.equipment,
    required this.dietTags,
    required this.imageUrl,
    required this.popularityScore,
    required this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        steps: List<String>.from(json['steps'] as List<dynamic>),
        timeMin: json['time_min'] as int,
        servings: json['servings'] as int,
        difficulty: json['difficulty'] as String,
        equipment: List<String>.from(json['equipment'] as List<dynamic>),
        dietTags: List<String>.from(json['diet_tags'] as List<dynamic>),
        imageUrl: json['image_url'] as String? ?? '',
        popularityScore: json['popularity_score'] as int? ?? 0,
        ingredients: (json['recipe_ingredients'] as List<dynamic>)
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Substitution {
  final String ingredientId;
  final String substituteId;
  final double strength;

  Substitution({
    required this.ingredientId,
    required this.substituteId,
    required this.strength,
  });

  factory Substitution.fromJson(Map<String, dynamic> json) => Substitution(
        ingredientId: json['ingredient_id'] as String,
        substituteId: json['substitute_id'] as String,
        strength: (json['strength'] as num).toDouble(),
      );
}

class MatchFilters {
  final int? maxTimeMinutes;
  final String? diet;
  final List<String> excludedEquipment;

  const MatchFilters({
    this.maxTimeMinutes,
    this.diet,
    this.excludedEquipment = const [],
  });
}

class MatchResult {
  final Recipe recipe;
  final int score;
  final List<String> missingIngredientIds;

  const MatchResult({
    required this.recipe,
    required this.score,
    required this.missingIngredientIds,
  });
}

