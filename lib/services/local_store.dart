import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';
import 'sqlite_service.dart';

class LocalStore {
  static final LocalStore instance = LocalStore._internal();

  LocalStore._internal();

  final SqliteService _db = SqliteService.instance;

  Future<void> init() async {
    try {
      await _db.init();
    } catch (_) {
      // Ignore init errors on unsupported platforms (e.g., web)
    }
  }

  // Favorites
  Future<void> addFavorite(String recipeId) => _db.addFavorite(recipeId);
  Future<void> removeFavorite(String recipeId) => _db.removeFavorite(recipeId);

  Future<bool> isFavorite(String recipeId) async {
    final ids = await _db.listFavoriteIds();
    return ids.contains(recipeId);
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    final ids = await _db.listFavoriteIds();
    if (ids.isEmpty) return <Recipe>[];
    final recipesJson = jsonDecode(await rootBundle.loadString('assets/recipes.json')) as List<dynamic>;
    final recipes = recipesJson.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    return recipes.where((r) => ids.contains(r.id)).toList();
  }

  // Pantry
  Future<void> setPantryAmount(String ingredientId, double amount) => _db.setPantryAmount(ingredientId: ingredientId, amount: amount);
  Future<void> removeFromPantry(String ingredientId) => _db.removeFromPantry(ingredientId);
  Future<Map<String, double>> listPantry() => _db.listPantry();

  // Search history
  Future<void> addSearchQuery(String query) => _db.addSearchQuery(query);
  Future<List<String>> recentSearches({int limit = 20}) => _db.recentSearches(limit: limit);

  // Shopping list helpers
  Future<void> addMissingIngredientsToShoppingList({
    required List<String> missingIngredientIds,
    required Map<String, Ingredient> ingredientById,
  }) async {
    final items = missingIngredientIds.map((id) {
      final ing = ingredientById[id];
      return <String, Object?>{
        'ingredient_id': id,
        'name': ing?.name ?? id,
        'quantity': null,
        'unit': null,
      };
    }).toList();
    await _db.addShoppingItemsBulk(items);
  }

  Future<int> addShoppingItem({String? ingredientId, required String name, double? quantity, String? unit}) =>
      _db.addShoppingItem(ingredientId: ingredientId, name: name, quantity: quantity, unit: unit);
}

