import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class LocalStore {
  static Database? _database;
  static const String _dbName = 'ne_yesem.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Recipes cache table
    await db.execute('''
      CREATE TABLE recipes_cache (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        last_updated INTEGER NOT NULL
      )
    ''');

    // Offline search results table
    await db.execute('''
      CREATE TABLE offline_search (
        id TEXT PRIMARY KEY,
        ingredient_ids TEXT NOT NULL,
        result_count INTEGER NOT NULL,
        last_updated INTEGER NOT NULL
      )
    ''');
  }

  // Recipe caching methods
  static Future<void> cacheRecipe(Recipe recipe) async {
    final db = await database;
    final data = jsonEncode(recipe.toJson());
    await db.insert(
      'recipes_cache',
      {
        'id': recipe.id,
        'data': data,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Recipe?> getCachedRecipe(String recipeId) async {
    final db = await database;
    final results = await db.query(
      'recipes_cache',
      where: 'id = ?',
      whereArgs: [recipeId],
    );

    if (results.isEmpty) return null;

    final data = jsonDecode(results.first['data'] as String) as Map<String, dynamic>;
    return Recipe.fromJson(data);
  }

  static Future<List<Recipe>> getCachedRecipes() async {
    final db = await database;
    final results = await db.query('recipes_cache', orderBy: 'last_updated DESC');

    return results.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return Recipe.fromJson(data);
    }).toList();
  }

  // Offline search methods
  static Future<void> cacheSearchResult(List<String> ingredientIds, List<MatchResult> results) async {
    final db = await database;
    final id = ingredientIds.join('_');
    await db.insert(
      'offline_search',
      {
        'id': id,
        'ingredient_ids': jsonEncode(ingredientIds),
        'result_count': results.length,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Cache the actual recipes
    for (final result in results) {
      await cacheRecipe(result.recipe);
    }
  }

  static Future<List<MatchResult>?> getCachedSearchResult(List<String> ingredientIds) async {
    final db = await database;
    final id = ingredientIds.join('_');

    final results = await db.query(
      'offline_search',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final cachedRecipes = await getCachedRecipes();
    final recipeMap = {for (final recipe in cachedRecipes) recipe.id: recipe};

    return results.map((row) {
      // For now, return empty list - in a real app you'd store the actual search results
      return <MatchResult>[];
    }).toList();
  }

  // Cleanup old cache
  static Future<void> cleanupOldCache({int daysOld = 30}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: daysOld)).millisecondsSinceEpoch;

    await db.delete(
      'recipes_cache',
      where: 'last_updated < ?',
      whereArgs: [cutoff],
    );

    await db.delete(
      'offline_search',
      where: 'last_updated < ?',
      whereArgs: [cutoff],
    );
  }

  // In-memory fallback for favorites (until we implement user system)
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

