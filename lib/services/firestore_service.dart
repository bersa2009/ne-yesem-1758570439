import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // User Profile operations
  Future<void> createUserProfile(UserProfile profile) async {
    if (_userId == null) return;
    
    await _db.collection('users').doc(_userId).set(profile.toJson());
  }

  Future<UserProfile?> getUserProfile() async {
    if (_userId == null) return null;
    
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(_userId).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    if (_userId == null) return;
    
    await _db.collection('users').doc(_userId).update(profile.toJson());
  }

  // Favorites operations
  Future<void> addFavorite(String recipeId) async {
    if (_userId == null) return;
    
    final favorite = FavoriteRecipe(
      recipeId: recipeId,
      addedAt: DateTime.now(),
    );
    
    await _db
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc(recipeId)
        .set(favorite.toJson());
  }

  Future<void> removeFavorite(String recipeId) async {
    if (_userId == null) return;
    
    await _db
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc(recipeId)
        .delete();
  }

  Future<List<FavoriteRecipe>> getFavorites() async {
    if (_userId == null) return [];
    
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => FavoriteRecipe.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  Future<bool> isFavorite(String recipeId) async {
    if (_userId == null) return false;
    
    try {
      DocumentSnapshot doc = await _db
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(recipeId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Pantry operations
  Future<void> addPantryItem(PantryItem item) async {
    if (_userId == null) return;
    
    await _db
        .collection('users')
        .doc(_userId)
        .collection('pantry')
        .doc(item.ingredientId)
        .set(item.toJson());
  }

  Future<void> removePantryItem(String ingredientId) async {
    if (_userId == null) return;
    
    await _db
        .collection('users')
        .doc(_userId)
        .collection('pantry')
        .doc(ingredientId)
        .delete();
  }

  Future<void> updatePantryItem(PantryItem item) async {
    if (_userId == null) return;
    
    await _db
        .collection('users')
        .doc(_userId)
        .collection('pantry')
        .doc(item.ingredientId)
        .update(item.toJson());
  }

  Future<List<PantryItem>> getPantryItems() async {
    if (_userId == null) return [];
    
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('pantry')
          .orderBy('addedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PantryItem.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting pantry items: $e');
      return [];
    }
  }

  // Shopping List operations
  Future<void> addShoppingListItem(ShoppingListItem item) async {
    if (_userId == null) return;
    
    await _db
        .collection('users')
        .doc(_userId)
        .collection('shopping_list')
        .doc(item.ingredientId)
        .set(item.toJson());
  }

  Future<void> removeShoppingListItem(String ingredientId) async {
    if (_userId == null) return;
    
    await _db
        .collection('users')
        .doc(_userId)
        .collection('shopping_list')
        .doc(ingredientId)
        .delete();
  }

  Future<void> updateShoppingListItem(ShoppingListItem item) async {
    if (_userId == null) return;
    
    await _db
        .collection('users')
        .doc(_userId)
        .collection('shopping_list')
        .doc(item.ingredientId)
        .update(item.toJson());
  }

  Future<List<ShoppingListItem>> getShoppingListItems() async {
    if (_userId == null) return [];
    
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('shopping_list')
          .orderBy('addedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ShoppingListItem.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting shopping list: $e');
      return [];
    }
  }

  // Clear purchased items from shopping list
  Future<void> clearPurchasedItems() async {
    if (_userId == null) return;
    
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('shopping_list')
          .where('purchased', isEqualTo: true)
          .get();
      
      WriteBatch batch = _db.batch();
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing purchased items: $e');
    }
  }

  // Search History operations
  Future<void> addSearchHistory(SearchHistoryItem item) async {
    if (_userId == null) return;
    
    await _db
        .collection('users')
        .doc(_userId)
        .collection('search_history')
        .doc(item.id)
        .set(item.toJson());
  }

  Future<List<SearchHistoryItem>> getSearchHistory({int limit = 10}) async {
    if (_userId == null) return [];
    
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('search_history')
          .orderBy('searchedAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => SearchHistoryItem.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting search history: $e');
      return [];
    }
  }

  Future<void> clearSearchHistory() async {
    if (_userId == null) return;
    
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('search_history')
          .get();
      
      WriteBatch batch = _db.batch();
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }

  // Batch operations for adding missing ingredients to shopping list
  Future<void> addMissingIngredientsToShoppingList(List<RecipeIngredient> missingIngredients) async {
    if (_userId == null || missingIngredients.isEmpty) return;
    
    try {
      WriteBatch batch = _db.batch();
      final now = DateTime.now();
      
      for (final ingredient in missingIngredients) {
        final item = ShoppingListItem(
          ingredientId: ingredient.ingredientId,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          addedAt: now,
        );
        
        final docRef = _db
            .collection('users')
            .doc(_userId)
            .collection('shopping_list')
            .doc(ingredient.ingredientId);
        
        batch.set(docRef, item.toJson(), SetOptions(merge: true));
      }
      
      await batch.commit();
    } catch (e) {
      print('Error adding missing ingredients to shopping list: $e');
    }
  }
}