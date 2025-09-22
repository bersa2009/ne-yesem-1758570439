import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class ShoppingListService {
  static const String _shoppingListCollection = 'shopping_list';

  static String get _userShoppingListCollection => '${_shoppingListCollection}_${FirebaseService.currentUser?.uid}';

  static Future<List<ShoppingListItem>> getShoppingList() async {
    final snapshot = await FirebaseService.firestore
        .collection(_userShoppingListCollection)
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ShoppingListItem.fromJson(doc.data()))
        .toList();
  }

  static Future<void> addShoppingItem(ShoppingListItem item) async {
    await FirebaseService.firestore
        .collection(_userShoppingListCollection)
        .doc(item.id)
        .set(item.toJson());
  }

  static Future<void> updateShoppingItem(ShoppingListItem item) async {
    await FirebaseService.firestore
        .collection(_userShoppingListCollection)
        .doc(item.id)
        .update(item.toJson());
  }

  static Future<void> removeShoppingItem(String itemId) async {
    await FirebaseService.firestore
        .collection(_userShoppingListCollection)
        .doc(itemId)
        .delete();
  }

  static Future<void> toggleItemChecked(String itemId, bool checked) async {
    await FirebaseService.firestore
        .collection(_userShoppingListCollection)
        .doc(itemId)
        .update({'checked': checked});
  }

  static Future<void> clearCompletedItems() async {
    final snapshot = await FirebaseService.firestore
        .collection(_userShoppingListCollection)
        .where('checked', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  static Stream<List<ShoppingListItem>> getShoppingListStream() {
    return FirebaseService.firestore
        .collection(_userShoppingListCollection)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingListItem.fromJson(doc.data()))
            .toList());
  }
}