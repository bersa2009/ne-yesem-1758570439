import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/pantry_service.dart';

class PantryProvider with ChangeNotifier {
  List<PantryItem> _pantryItems = [];
  bool _isLoading = false;

  List<PantryItem> get pantryItems => _pantryItems;
  bool get isLoading => _isLoading;

  PantryProvider() {
    loadPantryItems();
  }

  Future<void> loadPantryItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pantryItems = await PantryService.getPantryItems();
    } catch (e) {
      // Handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPantryItem(PantryItem item) async {
    try {
      await PantryService.addPantryItem(item);
      await loadPantryItems(); // Refresh list
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> updatePantryItem(PantryItem item) async {
    try {
      await PantryService.updatePantryItem(item);
      await loadPantryItems(); // Refresh list
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> removePantryItem(String itemId) async {
    try {
      await PantryService.removePantryItem(itemId);
      await loadPantryItems(); // Refresh list
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  List<String> getIngredientIds() {
    return _pantryItems.map((item) => item.ingredientId).toSet().toList();
  }
}