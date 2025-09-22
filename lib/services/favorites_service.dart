import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class FavoritesService {
  static const String _favoritesCollection = 'favorites';

  static String get _userFavoritesCollection => '${_favoritesCollection}_${FirebaseService.currentUser?.uid}';

  static Future<List<FavoriteRecipe>> getFavorites() async {
    final snapshot = await FirebaseService.firestore
        .collection(_userFavoritesCollection)
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FavoriteRecipe.fromJson(doc.data()))
        .toList();
  }

  static Future<void> addFavorite(FavoriteRecipe favorite) async {
    await FirebaseService.firestore
        .collection(_userFavoritesCollection)
        .doc(favorite.id)
        .set(favorite.toJson());
  }

  static Future<void> removeFavorite(String recipeId) async {
    final snapshot = await FirebaseService.firestore
        .collection(_userFavoritesCollection)
        .where('recipeId', isEqualTo: recipeId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  static Future<bool> isFavorite(String recipeId) async {
    final snapshot = await FirebaseService.firestore
        .collection(_userFavoritesCollection)
        .where('recipeId', isEqualTo: recipeId)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  static Stream<List<FavoriteRecipe>> getFavoritesStream() {
    return FirebaseService.firestore
        .collection(_userFavoritesCollection)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FavoriteRecipe.fromJson(doc.data()))
            .toList());
  }
}