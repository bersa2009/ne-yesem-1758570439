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
  final int? minServings;
  final int? maxServings;
  final String? diet;
  final String? difficulty;
  final List<String> excludedEquipment;

  const MatchFilters({
    this.maxTimeMinutes,
    this.minServings,
    this.maxServings,
    this.diet,
    this.difficulty,
    this.excludedEquipment = const [],
  });

  Map<String, dynamic> toJson() => {
    'maxTimeMinutes': maxTimeMinutes,
    'minServings': minServings,
    'maxServings': maxServings,
    'diet': diet,
    'difficulty': difficulty,
    'excludedEquipment': excludedEquipment,
  };

  factory MatchFilters.fromJson(Map<String, dynamic> json) => MatchFilters(
    maxTimeMinutes: json['maxTimeMinutes'] as int?,
    minServings: json['minServings'] as int?,
    maxServings: json['maxServings'] as int?,
    diet: json['diet'] as String?,
    difficulty: json['difficulty'] as String?,
    excludedEquipment: List<String>.from(json['excludedEquipment'] ?? []),
  );
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

// New models for persistent data
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String?,
    photoUrl: json['photoUrl'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    lastLoginAt: DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt'] as int),
  );
}

class PantryItem {
  final String ingredientId;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;
  final DateTime addedAt;

  PantryItem({
    required this.ingredientId,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    'quantity': quantity,
    'unit': unit,
    'expiryDate': expiryDate?.millisecondsSinceEpoch,
    'addedAt': addedAt.millisecondsSinceEpoch,
  };

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
    ingredientId: json['ingredientId'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] as String,
    expiryDate: json['expiryDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['expiryDate'] as int)
        : null,
    addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAt'] as int),
  );
}

class SearchHistoryItem {
  final String id;
  final List<String> ingredientIds;
  final MatchFilters filters;
  final DateTime searchedAt;
  final int resultCount;

  SearchHistoryItem({
    required this.id,
    required this.ingredientIds,
    required this.filters,
    required this.searchedAt,
    required this.resultCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ingredientIds': ingredientIds,
    'filters': filters.toJson(),
    'searchedAt': searchedAt.millisecondsSinceEpoch,
    'resultCount': resultCount,
  };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) => SearchHistoryItem(
    id: json['id'] as String,
    ingredientIds: List<String>.from(json['ingredientIds'] as List<dynamic>),
    filters: MatchFilters.fromJson(json['filters'] as Map<String, dynamic>),
    searchedAt: DateTime.fromMillisecondsSinceEpoch(json['searchedAt'] as int),
    resultCount: json['resultCount'] as int,
  );
}

class ShoppingListItem {
  final String ingredientId;
  final double quantity;
  final String unit;
  final bool purchased;
  final DateTime addedAt;

  ShoppingListItem({
    required this.ingredientId,
    required this.quantity,
    required this.unit,
    this.purchased = false,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    'quantity': quantity,
    'unit': unit,
    'purchased': purchased,
    'addedAt': addedAt.millisecondsSinceEpoch,
  };

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) => ShoppingListItem(
    ingredientId: json['ingredientId'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] as String,
    purchased: json['purchased'] as bool? ?? false,
    addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAt'] as int),
  );
}

class FavoriteRecipe {
  final String recipeId;
  final DateTime addedAt;
  final int? personalRating;

  FavoriteRecipe({
    required this.recipeId,
    required this.addedAt,
    this.personalRating,
  });

  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    'addedAt': addedAt.millisecondsSinceEpoch,
    'personalRating': personalRating,
  };

  factory FavoriteRecipe.fromJson(Map<String, dynamic> json) => FavoriteRecipe(
    recipeId: json['recipeId'] as String,
    addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAt'] as int),
    personalRating: json['personalRating'] as int?,
  );
}

