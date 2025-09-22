import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRepository {
  FirestoreRepository._internal();
  static final FirestoreRepository _instance = FirestoreRepository._internal();
  factory FirestoreRepository() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _userCollectionPath(String userId) => 'users/$userId';

  // Favorites
  Future<void> setFavorite({required String userId, required String recipeId, required bool isFavorite}) async {
    try {
      final doc = _db.doc('${_userCollectionPath(userId)}/favorites/$recipeId');
      if (isFavorite) {
        await doc.set(<String, Object?>{'createdAt': FieldValue.serverTimestamp()});
      } else {
        await doc.delete();
      }
    } catch (_) {}
  }

  Future<Set<String>> getFavoriteRecipeIds({required String userId}) async {
    try {
      final snap = await _db.collection('${_userCollectionPath(userId)}/favorites').get();
      return snap.docs.map((d) => d.id).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  // Pantry amounts (by ingredientId -> amount)
  Future<void> upsertPantryAmount({required String userId, required String ingredientId, required double amount}) async {
    try {
      await _db.doc('${_userCollectionPath(userId)}/pantry/$ingredientId').set(<String, Object?>{'amount': amount, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  Future<Map<String, double>> getPantry({required String userId}) async {
    try {
      final snap = await _db.collection('${_userCollectionPath(userId)}/pantry').get();
      return {for (final d in snap.docs) d.id: (d.data()['amount'] as num?)?.toDouble() ?? 0.0};
    } catch (_) {
      return <String, double>{};
    }
  }

  // Search history
  Future<void> addSearchHistory({required String userId, required List<String> ingredientIds}) async {
    try {
      await _db.collection('${_userCollectionPath(userId)}/search_history').add(<String, Object?>{
        'ingredientIds': ingredientIds,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // Shopping list: missing ingredientIds for a recipe
  Future<void> addToShoppingList({required String userId, required String recipeId, required List<String> ingredientIds}) async {
    try {
      final doc = _db.doc('${_userCollectionPath(userId)}/shopping/$recipeId');
      await doc.set(<String, Object?>{
        'ingredientIds': ingredientIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<Map<String, List<String>>> getShoppingList({required String userId}) async {
    try {
      final snap = await _db.collection('${_userCollectionPath(userId)}/shopping').get();
      final map = <String, List<String>>{};
      for (final d in snap.docs) {
        final ids = (d.data()['ingredientIds'] as List<dynamic>? ?? const <dynamic>[]).cast<String>();
        map[d.id] = ids;
      }
      return map;
    } catch (_) {
      return <String, List<String>>{};
    }
  }
}

