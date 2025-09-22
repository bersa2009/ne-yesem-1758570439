import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqliteService {
  static final SqliteService instance = SqliteService._internal();

  SqliteService._internal();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(docsDir.path, 'neyesem.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        recipe_id TEXT PRIMARY KEY
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pantry (
        ingredient_id TEXT PRIMARY KEY,
        amount REAL NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient_id TEXT,
        name TEXT NOT NULL,
        quantity REAL,
        unit TEXT,
        checked INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      );
    ''');
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('SqliteService not initialized');
    }
    return db;
  }

  // Favorites
  Future<void> addFavorite(String recipeId) async {
    await _database.insert(
      'favorites',
      {'recipe_id': recipeId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFavorite(String recipeId) async {
    await _database.delete('favorites', where: 'recipe_id = ?', whereArgs: [recipeId]);
  }

  Future<Set<String>> listFavoriteIds() async {
    final rows = await _database.query('favorites');
    return rows.map((e) => e['recipe_id'] as String).toSet();
  }

  // Pantry
  Future<void> setPantryAmount({required String ingredientId, required double amount}) async {
    await _database.insert(
      'pantry',
      {'ingredient_id': ingredientId, 'amount': amount},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFromPantry(String ingredientId) async {
    await _database.delete('pantry', where: 'ingredient_id = ?', whereArgs: [ingredientId]);
  }

  Future<Map<String, double>> listPantry() async {
    final rows = await _database.query('pantry');
    final Map<String, double> result = <String, double>{};
    for (final row in rows) {
      result[row['ingredient_id'] as String] = (row['amount'] as num).toDouble();
    }
    return result;
  }

  // Search history
  Future<void> addSearchQuery(String query) async {
    await _database.insert('search_history', {
      'query': query,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<String>> recentSearches({int limit = 20}) async {
    final rows = await _database.query(
      'search_history',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map((e) => e['query'] as String).toList();
  }

  // Shopping list
  Future<int> addShoppingItem({
    String? ingredientId,
    required String name,
    double? quantity,
    String? unit,
  }) async {
    return _database.insert('shopping_list', {
      'ingredient_id': ingredientId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'checked': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> addShoppingItemsBulk(List<Map<String, Object?>> items) async {
    final batch = _database.batch();
    for (final item in items) {
      batch.insert('shopping_list', {
        'ingredient_id': item['ingredient_id'],
        'name': item['name'],
        'quantity': item['quantity'],
        'unit': item['unit'],
        'checked': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<ShoppingListItem>> listShoppingItems() async {
    final rows = await _database.query('shopping_list', orderBy: 'checked ASC, created_at DESC');
    return rows.map((e) => ShoppingListItem.fromRow(e)).toList();
  }

  Future<void> toggleShoppingItemChecked({required int id, required bool checked}) async {
    await _database.update('shopping_list', {'checked': checked ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> removeShoppingItem(int id) async {
    await _database.delete('shopping_list', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCheckedShoppingItems() async {
    await _database.delete('shopping_list', where: 'checked = 1');
  }
}

class ShoppingListItem {
  final int id;
  final String? ingredientId;
  final String name;
  final double? quantity;
  final String? unit;
  final bool checked;
  final DateTime createdAt;

  ShoppingListItem({
    required this.id,
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.checked,
    required this.createdAt,
  });

  factory ShoppingListItem.fromRow(Map<String, Object?> row) {
    return ShoppingListItem(
      id: row['id'] as int,
      ingredientId: row['ingredient_id'] as String?,
      name: row['name'] as String,
      quantity: (row['quantity'] as num?)?.toDouble(),
      unit: row['unit'] as String?,
      checked: (row['checked'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }
}

