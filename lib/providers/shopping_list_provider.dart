import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/shopping_list_service.dart';

class ShoppingListProvider with ChangeNotifier {
  List<ShoppingListItem> _shoppingList = [];
  bool _isLoading = false;

  List<ShoppingListItem> get shoppingList => _shoppingList;
  bool get isLoading => _isLoading;

  ShoppingListProvider() {
    loadShoppingList();
  }

  Future<void> loadShoppingList() async {
    _isLoading = true;
    notifyListeners();

    try {
      _shoppingList = await ShoppingListService.getShoppingList();
    } catch (e) {
      // Handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addShoppingItem(String name, String category) async {
    try {
      final item = ShoppingListItem(
        id: '${name}_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: category,
        checked: false,
        addedAt: DateTime.now(),
      );
      await ShoppingListService.addShoppingItem(item);
      await loadShoppingList(); // Refresh list
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> toggleItemChecked(String itemId, bool checked) async {
    try {
      await ShoppingListService.toggleItemChecked(itemId, checked);
      await loadShoppingList(); // Refresh list
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> removeShoppingItem(String itemId) async {
    try {
      await ShoppingListService.removeShoppingItem(itemId);
      await loadShoppingList(); // Refresh list
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> clearCompletedItems() async {
    try {
      await ShoppingListService.clearCompletedItems();
      await loadShoppingList(); // Refresh list
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
}