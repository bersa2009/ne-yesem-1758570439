import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  Database? _database;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Database? get database => _database;

  /// Initialize database and shared preferences
  Future<bool> initialize() async {
    try {
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      
      // Initialize SQLite database
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'ne_yesem.db');
      
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Database initialization error: $e');
      return false;
    }
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Ingredients table
    await db.execute('''
      CREATE TABLE ingredients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        aliases TEXT NOT NULL,
        category TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Recipes table
    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        steps TEXT NOT NULL,
        time_min INTEGER NOT NULL,
        servings INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        equipment TEXT NOT NULL,
        diet_tags TEXT NOT NULL,
        image_url TEXT,
        popularity_score INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_favorite INTEGER DEFAULT 0,
        last_cooked INTEGER
      )
    ''');

    // Recipe ingredients table
    await db.execute('''
      CREATE TABLE recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id TEXT NOT NULL,
        ingredient_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        optional INTEGER DEFAULT 0,
        required_flag INTEGER DEFAULT 1,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id),
        FOREIGN KEY (ingredient_id) REFERENCES ingredients (id)
      )
    ''');

    // Substitutions table
    await db.execute('''
      CREATE TABLE substitutions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient_id TEXT NOT NULL,
        substitute_id TEXT NOT NULL,
        strength REAL NOT NULL,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients (id),
        FOREIGN KEY (substitute_id) REFERENCES ingredients (id)
      )
    ''');

    // User ingredients table (what user has)
    await db.execute('''
      CREATE TABLE user_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient_id TEXT NOT NULL,
        quantity REAL,
        unit TEXT,
        expiry_date INTEGER,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients (id)
      )
    ''');

    // Recipe history table
    await db.execute('''
      CREATE TABLE recipe_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id TEXT NOT NULL,
        cooked_at INTEGER NOT NULL,
        rating INTEGER,
        notes TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id)
      )
    ''');

    // Search history table
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        results_count INTEGER NOT NULL,
        searched_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_recipes_time ON recipes (time_min)');
    await db.execute('CREATE INDEX idx_recipes_difficulty ON recipes (difficulty)');
    await db.execute('CREATE INDEX idx_recipe_ingredients_recipe ON recipe_ingredients (recipe_id)');
    await db.execute('CREATE INDEX idx_recipe_ingredients_ingredient ON recipe_ingredients (ingredient_id)');
    await db.execute('CREATE INDEX idx_user_ingredients_ingredient ON user_ingredients (ingredient_id)');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // CRUD Operations for Ingredients
  Future<int> insertIngredient(Ingredient ingredient) async {
    if (_database == null) return 0;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    return await _database!.insert(
      'ingredients',
      {
        'id': ingredient.id,
        'name': ingredient.name,
        'aliases': jsonEncode(ingredient.aliases),
        'category': ingredient.category,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Ingredient>> getAllIngredients() async {
    if (_database == null) return [];
    
    final maps = await _database!.query('ingredients', orderBy: 'name');
    return maps.map((map) => Ingredient(
      id: map['id'] as String,
      name: map['name'] as String,
      aliases: List<String>.from(jsonDecode(map['aliases'] as String)),
      category: map['category'] as String,
    )).toList();
  }

  Future<Ingredient?> getIngredientById(String id) async {
    if (_database == null) return null;
    
    final maps = await _database!.query(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    final map = maps.first;
    return Ingredient(
      id: map['id'] as String,
      name: map['name'] as String,
      aliases: List<String>.from(jsonDecode(map['aliases'] as String)),
      category: map['category'] as String,
    );
  }

  // CRUD Operations for Recipes
  Future<int> insertRecipe(Recipe recipe) async {
    if (_database == null) return 0;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final recipeId = await _database!.insert(
      'recipes',
      {
        'id': recipe.id,
        'name': recipe.name,
        'description': recipe.description,
        'steps': jsonEncode(recipe.steps),
        'time_min': recipe.timeMin,
        'servings': recipe.servings,
        'difficulty': recipe.difficulty,
        'equipment': jsonEncode(recipe.equipment),
        'diet_tags': jsonEncode(recipe.dietTags),
        'image_url': recipe.imageUrl,
        'popularity_score': recipe.popularityScore,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insert recipe ingredients
    for (final ingredient in recipe.ingredients) {
      await _database!.insert(
        'recipe_ingredients',
        {
          'recipe_id': recipe.id,
          'ingredient_id': ingredient.ingredientId,
          'quantity': ingredient.quantity,
          'unit': ingredient.unit,
          'optional': ingredient.optional ? 1 : 0,
          'required_flag': ingredient.requiredFlag ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    return recipeId;
  }

  Future<List<Recipe>> getAllRecipes() async {
    if (_database == null) return [];
    
    final recipeMaps = await _database!.query('recipes', orderBy: 'popularity_score DESC');
    final recipes = <Recipe>[];
    
    for (final recipeMap in recipeMaps) {
      final ingredients = await _getRecipeIngredients(recipeMap['id'] as String);
      
      recipes.add(Recipe(
        id: recipeMap['id'] as String,
        name: recipeMap['name'] as String,
        description: recipeMap['description'] as String? ?? '',
        steps: List<String>.from(jsonDecode(recipeMap['steps'] as String)),
        timeMin: recipeMap['time_min'] as int,
        servings: recipeMap['servings'] as int,
        difficulty: recipeMap['difficulty'] as String,
        equipment: List<String>.from(jsonDecode(recipeMap['equipment'] as String)),
        dietTags: List<String>.from(jsonDecode(recipeMap['diet_tags'] as String)),
        imageUrl: recipeMap['image_url'] as String? ?? '',
        popularityScore: recipeMap['popularity_score'] as int? ?? 0,
        ingredients: ingredients,
      ));
    }
    
    return recipes;
  }

  Future<Recipe?> getRecipeById(String id) async {
    if (_database == null) return null;
    
    final maps = await _database!.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    final map = maps.first;
    final ingredients = await _getRecipeIngredients(id);
    
    return Recipe(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      steps: List<String>.from(jsonDecode(map['steps'] as String)),
      timeMin: map['time_min'] as int,
      servings: map['servings'] as int,
      difficulty: map['difficulty'] as String,
      equipment: List<String>.from(jsonDecode(map['equipment'] as String)),
      dietTags: List<String>.from(jsonDecode(map['diet_tags'] as String)),
      imageUrl: map['image_url'] as String? ?? '',
      popularityScore: map['popularity_score'] as int? ?? 0,
      ingredients: ingredients,
    );
  }

  Future<List<RecipeIngredient>> _getRecipeIngredients(String recipeId) async {
    if (_database == null) return [];
    
    final maps = await _database!.query(
      'recipe_ingredients',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
    
    return maps.map((map) => RecipeIngredient(
      ingredientId: map['ingredient_id'] as String,
      quantity: map['quantity'] as double,
      unit: map['unit'] as String,
      optional: (map['optional'] as int) == 1,
      requiredFlag: (map['required_flag'] as int) == 1,
    )).toList();
  }

  // User Ingredients Management
  Future<int> addUserIngredient(String ingredientId, {double? quantity, String? unit, DateTime? expiryDate}) async {
    if (_database == null) return 0;
    
    return await _database!.insert(
      'user_ingredients',
      {
        'ingredient_id': ingredientId,
        'quantity': quantity,
        'unit': unit,
        'expiry_date': expiryDate?.millisecondsSinceEpoch,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UserIngredient>> getUserIngredients() async {
    if (_database == null) return [];
    
    final maps = await _database!.rawQuery('''
      SELECT ui.*, i.name, i.category
      FROM user_ingredients ui
      JOIN ingredients i ON ui.ingredient_id = i.id
      ORDER BY ui.added_at DESC
    ''');
    
    return maps.map((map) => UserIngredient(
      id: map['id'] as int,
      ingredientId: map['ingredient_id'] as String,
      ingredientName: map['name'] as String,
      category: map['category'] as String,
      quantity: map['quantity'] as double?,
      unit: map['unit'] as String?,
      expiryDate: map['expiry_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['expiry_date'] as int)
          : null,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
    )).toList();
  }

  Future<int> removeUserIngredient(int id) async {
    if (_database == null) return 0;
    
    return await _database!.delete(
      'user_ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Recipe History and Favorites
  Future<int> markRecipeAsCooked(String recipeId, {int? rating, String? notes}) async {
    if (_database == null) return 0;
    
    // Update recipe last_cooked
    await _database!.update(
      'recipes',
      {'last_cooked': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [recipeId],
    );
    
    // Add to history
    return await _database!.insert(
      'recipe_history',
      {
        'recipe_id': recipeId,
        'cooked_at': DateTime.now().millisecondsSinceEpoch,
        'rating': rating,
        'notes': notes,
      },
    );
  }

  Future<int> toggleRecipeFavorite(String recipeId) async {
    if (_database == null) return 0;
    
    final maps = await _database!.query(
      'recipes',
      columns: ['is_favorite'],
      where: 'id = ?',
      whereArgs: [recipeId],
      limit: 1,
    );
    
    if (maps.isEmpty) return 0;
    
    final currentFavorite = (maps.first['is_favorite'] as int) == 1;
    return await _database!.update(
      'recipes',
      {'is_favorite': currentFavorite ? 0 : 1},
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    if (_database == null) return [];
    
    final recipeMaps = await _database!.query(
      'recipes',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'name',
    );
    
    final recipes = <Recipe>[];
    for (final recipeMap in recipeMaps) {
      final ingredients = await _getRecipeIngredients(recipeMap['id'] as String);
      
      recipes.add(Recipe(
        id: recipeMap['id'] as String,
        name: recipeMap['name'] as String,
        description: recipeMap['description'] as String? ?? '',
        steps: List<String>.from(jsonDecode(recipeMap['steps'] as String)),
        timeMin: recipeMap['time_min'] as int,
        servings: recipeMap['servings'] as int,
        difficulty: recipeMap['difficulty'] as String,
        equipment: List<String>.from(jsonDecode(recipeMap['equipment'] as String)),
        dietTags: List<String>.from(jsonDecode(recipeMap['diet_tags'] as String)),
        imageUrl: recipeMap['image_url'] as String? ?? '',
        popularityScore: recipeMap['popularity_score'] as int? ?? 0,
        ingredients: ingredients,
      ));
    }
    
    return recipes;
  }

  // Search History
  Future<int> saveSearchHistory(String query, List<String> ingredients, int resultsCount) async {
    if (_database == null) return 0;
    
    return await _database!.insert(
      'search_history',
      {
        'query': query,
        'ingredients': jsonEncode(ingredients),
        'results_count': resultsCount,
        'searched_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<List<SearchHistoryItem>> getSearchHistory({int limit = 20}) async {
    if (_database == null) return [];
    
    final maps = await _database!.query(
      'search_history',
      orderBy: 'searched_at DESC',
      limit: limit,
    );
    
    return maps.map((map) => SearchHistoryItem(
      id: map['id'] as int,
      query: map['query'] as String,
      ingredients: List<String>.from(jsonDecode(map['ingredients'] as String)),
      resultsCount: map['results_count'] as int,
      searchedAt: DateTime.fromMillisecondsSinceEpoch(map['searched_at'] as int),
    )).toList();
  }

  // Preferences Management using SharedPreferences
  Future<void> setPreference(String key, dynamic value) async {
    if (_prefs == null) return;
    
    if (value is String) {
      await _prefs!.setString(key, value);
    } else if (value is int) {
      await _prefs!.setInt(key, value);
    } else if (value is double) {
      await _prefs!.setDouble(key, value);
    } else if (value is bool) {
      await _prefs!.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs!.setStringList(key, value);
    } else {
      await _prefs!.setString(key, jsonEncode(value));
    }
  }

  T? getPreference<T>(String key, {T? defaultValue}) {
    if (_prefs == null) return defaultValue;
    
    if (T == String) {
      return _prefs!.getString(key) as T? ?? defaultValue;
    } else if (T == int) {
      return _prefs!.getInt(key) as T? ?? defaultValue;
    } else if (T == double) {
      return _prefs!.getDouble(key) as T? ?? defaultValue;
    } else if (T == bool) {
      return _prefs!.getBool(key) as T? ?? defaultValue;
    } else {
      final stringValue = _prefs!.getString(key);
      if (stringValue != null) {
        try {
          return jsonDecode(stringValue) as T;
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }
  }

  // Data Synchronization and Backup
  Future<Map<String, dynamic>> exportUserData() async {
    if (_database == null) return {};
    
    final userIngredients = await getUserIngredients();
    final favoriteRecipes = await getFavoriteRecipes();
    final searchHistory = await getSearchHistory();
    
    return {
      'user_ingredients': userIngredients.map((e) => e.toMap()).toList(),
      'favorite_recipes': favoriteRecipes.map((e) => e.id).toList(),
      'search_history': searchHistory.map((e) => e.toMap()).toList(),
      'preferences': _prefs?.getKeys().fold<Map<String, dynamic>>({}, (map, key) {
        map[key] = _prefs!.get(key);
        return map;
      }) ?? {},
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  Future<bool> importUserData(Map<String, dynamic> data) async {
    if (_database == null) return false;
    
    try {
      // Import user ingredients
      final userIngredients = data['user_ingredients'] as List<dynamic>? ?? [];
      for (final ingredientData in userIngredients) {
        final ingredient = UserIngredient.fromMap(ingredientData);
        await addUserIngredient(
          ingredient.ingredientId,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          expiryDate: ingredient.expiryDate,
        );
      }
      
      // Import favorite recipes
      final favoriteRecipeIds = List<String>.from(data['favorite_recipes'] ?? []);
      for (final recipeId in favoriteRecipeIds) {
        await toggleRecipeFavorite(recipeId);
      }
      
      // Import preferences
      final preferences = data['preferences'] as Map<String, dynamic>? ?? {};
      for (final entry in preferences.entries) {
        await setPreference(entry.key, entry.value);
      }
      
      return true;
    } catch (e) {
      debugPrint('Import user data error: $e');
      return false;
    }
  }

  // Security: Encrypt sensitive data
  String _encryptData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Cleanup old data
  Future<void> cleanupOldData() async {
    if (_database == null) return;
    
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    
    // Clean old search history
    await _database!.delete(
      'search_history',
      where: 'searched_at < ?',
      whereArgs: [thirtyDaysAgo],
    );
    
    // Clean expired user ingredients
    await _database!.delete(
      'user_ingredients',
      where: 'expiry_date IS NOT NULL AND expiry_date < ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );
  }

  /// Close database connection
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInitialized = false;
  }
}

// Additional data classes for database operations
class UserIngredient {
  final int id;
  final String ingredientId;
  final String ingredientName;
  final String category;
  final double? quantity;
  final String? unit;
  final DateTime? expiryDate;
  final DateTime addedAt;

  UserIngredient({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.category,
    this.quantity,
    this.unit,
    this.expiryDate,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ingredient_id': ingredientId,
      'ingredient_name': ingredientName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiry_date': expiryDate?.millisecondsSinceEpoch,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }

  factory UserIngredient.fromMap(Map<String, dynamic> map) {
    return UserIngredient(
      id: map['id'] ?? 0,
      ingredientId: map['ingredient_id'] ?? '',
      ingredientName: map['ingredient_name'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity']?.toDouble(),
      unit: map['unit'],
      expiryDate: map['expiry_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['expiry_date'])
          : null,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] ?? 0),
    );
  }
}

class SearchHistoryItem {
  final int id;
  final String query;
  final List<String> ingredients;
  final int resultsCount;
  final DateTime searchedAt;

  SearchHistoryItem({
    required this.id,
    required this.query,
    required this.ingredients,
    required this.resultsCount,
    required this.searchedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'ingredients': ingredients,
      'results_count': resultsCount,
      'searched_at': searchedAt.millisecondsSinceEpoch,
    };
  }

  factory SearchHistoryItem.fromMap(Map<String, dynamic> map) {
    return SearchHistoryItem(
      id: map['id'] ?? 0,
      query: map['query'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      resultsCount: map['results_count'] ?? 0,
      searchedAt: DateTime.fromMillisecondsSinceEpoch(map['searched_at'] ?? 0),
    );
  }
}