import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _favoritesKey = 'favorites';
  static const String _pantryKey = 'pantry';
  static const String _settingsKey = 'settings';

  Database? _database;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _database = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final path = await getApplicationDocumentsDirectory();
    return openDatabase(
      '${path.path}/ne_yesem.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            recipe_id TEXT PRIMARY KEY
          )
        ''');
        await db.execute('''
          CREATE TABLE pantry (
            ingredient_id TEXT PRIMARY KEY,
            quantity REAL,
            unit TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  // Favorites
  Future<void> addFavorite(String recipeId) async {
    await _database?.insert('favorites', {'recipe_id': recipeId}, conflictAlgorithm: ConflictAlgorithm.replace);
    await _prefs?.setStringList(_favoritesKey, (await getFavorites()).map((r) => r.id).toList());
  }

  Future<void> removeFavorite(String recipeId) async {
    await _database?.delete('favorites', where: 'recipe_id = ?', whereArgs: [recipeId]);
    await _prefs?.setStringList(_favoritesKey, (await getFavorites()).map((r) => r.id).toList());
  }

  Future<Set<String>> getFavoriteIds() async {
    final list = await _database?.query('favorites') ?? [];
    return list.map((e) => e['recipe_id'] as String).toSet();
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    final favoriteIds = await getFavoriteIds();
    if (favoriteIds.isEmpty) return [];

    final recipesJson = jsonDecode(await rootBundle.loadString('assets/recipes.json')) as List<dynamic>;
    final recipes = recipesJson.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    return recipes.where((r) => favoriteIds.contains(r.id)).toList();
  }

  // Pantry
  Future<void> updatePantryAmount(String ingredientId, double quantity, String unit) async {
    await _database?.insert(
      'pantry',
      {'ingredient_id': ingredientId, 'quantity': quantity, 'unit': unit},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Map<String, dynamic>>> getPantry() async {
    final list = await _database?.query('pantry') ?? [];
    return {
      for (final item in list)
        item['ingredient_id'] as String: {
          'quantity': item['quantity'] as double,
          'unit': item['unit'] as String,
        }
    };
  }

  // Settings
  Future<void> saveSetting(String key, String value) async {
    await _database?.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
    await _prefs?.setString(key, value);
  }

  Future<String?> getSetting(String key) async {
    return _prefs?.getString(key);
  }

  // Cache management
  Future<void> clearCache() async {
    await _database?.delete('favorites');
    await _database?.delete('pantry');
    await _prefs?.clear();
  }
}