import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/favorites_service.dart';

class FavoritesProvider with ChangeNotifier {
  List<FavoriteRecipe> _favorites = [];
  bool _isLoading = false;

  List<FavoriteRecipe> get favorites => _favorites;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await FavoritesService.getFavorites();
    } catch (e) {
      // Handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> isFavorite(String recipeId) async {
    try {
      return await FavoritesService.isFavorite(recipeId);
    } catch (e) {
      return false;
    }
  }

  Future<void> addFavorite(String recipeId, String recipeName) async {
    try {
      final favorite = FavoriteRecipe(
        id: '${recipeId}_${DateTime.now().millisecondsSinceEpoch}',
        recipeId: recipeId,
        recipeName: recipeName,
        addedAt: DateTime.now(),
      );
      await FavoritesService.addFavorite(favorite);
      await loadFavorites(); // Refresh list
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> removeFavorite(String recipeId) async {
    try {
      await FavoritesService.removeFavorite(recipeId);
      await loadFavorites(); // Refresh list
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
}