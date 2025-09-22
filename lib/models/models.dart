import 'package:cloud_firestore/cloud_firestore.dart';

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

class User {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final DateTime createdAt;
  final int dailySearchCount;
  final bool isProUser;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.createdAt,
    required this.dailySearchCount,
    required this.isProUser,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        photoUrl: json['photoUrl'] as String? ?? '',
        createdAt: (json['createdAt'] as Timestamp).toDate(),
        dailySearchCount: json['dailySearchCount'] as int? ?? 0,
        isProUser: json['isProUser'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'dailySearchCount': dailySearchCount,
        'isProUser': isProUser,
      };
}

class PantryItem {
  final String id;
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;
  final DateTime addedAt;

  PantryItem({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    required this.addedAt,
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
        id: json['id'] as String,
        ingredientId: json['ingredientId'] as String,
        ingredientName: json['ingredientName'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        expiryDate: json['expiryDate'] != null ? (json['expiryDate'] as Timestamp).toDate() : null,
        addedAt: (json['addedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'ingredientName': ingredientName,
        'quantity': quantity,
        'unit': unit,
        'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
        'addedAt': Timestamp.fromDate(addedAt),
      };
}

class FavoriteRecipe {
  final String id;
  final String recipeId;
  final String recipeName;
  final DateTime addedAt;

  FavoriteRecipe({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.addedAt,
  });

  factory FavoriteRecipe.fromJson(Map<String, dynamic> json) => FavoriteRecipe(
        id: json['id'] as String,
        recipeId: json['recipeId'] as String,
        recipeName: json['recipeName'] as String,
        addedAt: (json['addedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'recipeName': recipeName,
        'addedAt': Timestamp.fromDate(addedAt),
      };
}

class SearchHistory {
  final String id;
  final List<String> ingredientIds;
  final DateTime searchedAt;
  final int resultCount;

  SearchHistory({
    required this.id,
    required this.ingredientIds,
    required this.searchedAt,
    required this.resultCount,
  });

  factory SearchHistory.fromJson(Map<String, dynamic> json) => SearchHistory(
        id: json['id'] as String,
        ingredientIds: List<String>.from(json['ingredientIds'] as List<dynamic>),
        searchedAt: (json['searchedAt'] as Timestamp).toDate(),
        resultCount: json['resultCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientIds': ingredientIds,
        'searchedAt': Timestamp.fromDate(searchedAt),
        'resultCount': resultCount,
      };
}

class ShoppingListItem {
  final String id;
  final String name;
  final String category;
  final bool checked;
  final DateTime addedAt;

  ShoppingListItem({
    required this.id,
    required this.name,
    required this.category,
    required this.checked,
    required this.addedAt,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) => ShoppingListItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        checked: json['checked'] as bool? ?? false,
        addedAt: (json['addedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'checked': checked,
        'addedAt': Timestamp.fromDate(addedAt),
      };
}

class RecipeFeedback {
  final String id;
  final String recipeId;
  final bool helpful;
  final DateTime createdAt;

  RecipeFeedback({
    required this.id,
    required this.recipeId,
    required this.helpful,
    required this.createdAt,
  });

  factory RecipeFeedback.fromJson(Map<String, dynamic> json) => RecipeFeedback(
        id: json['id'] as String,
        recipeId: json['recipeId'] as String,
        helpful: json['helpful'] as bool,
        createdAt: (json['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'helpful': helpful,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

