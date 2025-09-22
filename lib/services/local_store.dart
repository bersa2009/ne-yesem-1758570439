import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

// Minimal in-memory store for MVP (no SQLite yet)
class LocalStore {
  final Set<String> favoriteRecipeIds = <String>{};
  final Map<String, double> pantryAmounts = <String, double>{};

  Future<void> addFavorite(String recipeId) async {
    favoriteRecipeIds.add(recipeId);
  }

  Future<void> removeFavorite(String recipeId) async {
    favoriteRecipeIds.remove(recipeId);
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    final recipesJson = jsonDecode(await rootBundle.loadString('assets/recipes.json')) as List<dynamic>;
    final recipes = recipesJson.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    return recipes.where((r) => favoriteRecipeIds.contains(r.id)).toList();
  }
}

