import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'database_service.dart';

/// Enhanced local storage service with SQLite integration
class LocalStore {
  static LocalStore? _instance;
  static LocalStore get instance => _instance ??= LocalStore._();
  LocalStore._();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize local storage
  Future<bool> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Store simple key-value data
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _prefs?.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  /// Store complex objects as JSON
  Future<void> setObject(String key, Map<String, dynamic> object) async {
    await _prefs?.setString(key, jsonEncode(object));
  }

  Map<String, dynamic>? getObject(String key) {
    final jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Remove a key
  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  /// Clear all data
  Future<void> clear() async {
    await _prefs?.clear();
  }

  /// Get all keys
  Set<String> getKeys() {
    return _prefs?.getKeys() ?? {};
  }

  /// Check if key exists
  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  // Legacy methods for backward compatibility
  final Set<String> favoriteRecipeIds = <String>{};
  final Map<String, double> pantryAmounts = <String, double>{};

  Future<void> addFavorite(String recipeId) async {
    favoriteRecipeIds.add(recipeId);
    // Also save to database if available
    if (DatabaseService.instance.isInitialized) {
      await DatabaseService.instance.toggleRecipeFavorite(recipeId);
    }
  }

  Future<void> removeFavorite(String recipeId) async {
    favoriteRecipeIds.remove(recipeId);
    // Also remove from database if available
    if (DatabaseService.instance.isInitialized) {
      await DatabaseService.instance.toggleRecipeFavorite(recipeId);
    }
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    // Try to get from database first
    if (DatabaseService.instance.isInitialized) {
      return await DatabaseService.instance.getFavoriteRecipes();
    }
    
    // Fallback to asset loading
    final recipesJson = jsonDecode(await rootBundle.loadString('assets/data/recipes.json')) as List<dynamic>;
    final recipes = recipesJson.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    return recipes.where((r) => favoriteRecipeIds.contains(r.id)).toList();
  }

  /// Sync local data with database
  Future<void> syncWithDatabase() async {
    if (!DatabaseService.instance.isInitialized) return;

    try {
      // Sync favorites
      for (final recipeId in favoriteRecipeIds) {
        await DatabaseService.instance.toggleRecipeFavorite(recipeId);
      }
      
      // Clear local cache after sync
      favoriteRecipeIds.clear();
      pantryAmounts.clear();
    } catch (e) {
      // Keep local data if sync fails
    }
  }
}

