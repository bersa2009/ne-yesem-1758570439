import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class PantryService {
  static const String _pantryCollection = 'pantry';

  static String get _userPantryCollection => '${_pantryCollection}_${FirebaseService.currentUser?.uid}';

  static Future<List<PantryItem>> getPantryItems() async {
    final snapshot = await FirebaseService.firestore
        .collection(_userPantryCollection)
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PantryItem.fromJson(doc.data()))
        .toList();
  }

  static Future<void> addPantryItem(PantryItem item) async {
    await FirebaseService.firestore
        .collection(_userPantryCollection)
        .doc(item.id)
        .set(item.toJson());
  }

  static Future<void> updatePantryItem(PantryItem item) async {
    await FirebaseService.firestore
        .collection(_userPantryCollection)
        .doc(item.id)
        .update(item.toJson());
  }

  static Future<void> removePantryItem(String itemId) async {
    await FirebaseService.firestore
        .collection(_userPantryCollection)
        .doc(itemId)
        .delete();
  }

  static Stream<List<PantryItem>> getPantryItemsStream() {
    return FirebaseService.firestore
        .collection(_userPantryCollection)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PantryItem.fromJson(doc.data()))
            .toList());
  }

  static Future<List<PantryItem>> getExpiringSoonItems({int days = 7}) async {
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: days));

    final snapshot = await FirebaseService.firestore
        .collection(_userPantryCollection)
        .where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(expiryDate))
        .where('expiryDate', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiryDate')
        .get();

    return snapshot.docs
        .map((doc) => PantryItem.fromJson(doc.data()))
        .toList();
  }
}