import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

// Enhanced local storage with persistence
class LocalStore {
  static const String _favoritesFile = 'favorites.json';
  static const String _pantryFile = 'pantry.json';
  final Set<String> favoriteRecipeIds = <String>{};
  final Map<String, double> pantryAmounts = <String, double>{};

  LocalStore() {
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadFavorites();
    await _loadPantry();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _favoritesFilePath async {
    final localPath = await _localPath;
    return File(path.join(localPath, _favoritesFile));
  }

  Future<File> get _pantryFilePath async {
    final localPath = await _localPath;
    return File(path.join(localPath, _pantryFile));
  }

  Future<void> _loadFavorites() async {
    try {
      final file = await _favoritesFilePath;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = jsonDecode(content);
        favoriteRecipeIds.addAll(data.map((e) => e.toString()));
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _loadPantry() async {
    try {
      final file = await _pantryFilePath;
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        pantryAmounts.addAll(data.map((k, v) => MapEntry(k, v.toDouble())));
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final file = await _favoritesFilePath;
      final data = favoriteRecipeIds.toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _savePantry() async {
    try {
      final file = await _pantryFilePath;
      await file.writeAsString(jsonEncode(pantryAmounts));
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> addFavorite(String recipeId) async {
    favoriteRecipeIds.add(recipeId);
    await _saveFavorites();
  }

  Future<void> removeFavorite(String recipeId) async {
    favoriteRecipeIds.remove(recipeId);
    await _saveFavorites();
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    final recipesJson = jsonDecode(await rootBundle.loadString('assets/recipes.json')) as List<dynamic>;
    final recipes = recipesJson.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    return recipes.where((r) => favoriteRecipeIds.contains(r.id)).toList();
  }

  Future<void> updatePantryAmount(String ingredientId, double amount) async {
    pantryAmounts[ingredientId] = amount;
    await _savePantry();
  }

  Future<void> removeFromPantry(String ingredientId) async {
    pantryAmounts.remove(ingredientId);
    await _savePantry();
  }

  Map<String, double> getPantryItems() {
    return Map.from(pantryAmounts);
  }
}

