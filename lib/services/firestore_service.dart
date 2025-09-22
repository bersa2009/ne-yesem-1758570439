import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_service.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  bool get _canUse => FirebaseService.instance.available && FirebaseAuth.instance.currentUser != null;

  CollectionReference<Map<String, dynamic>> _userDoc() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('data');
  }

  Future<void> pushFavorites(Set<String> favoriteIds) async {
    if (!_canUse) return;
    await _userDoc().doc('favorites').set({'ids': favoriteIds.toList(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<Set<String>> pullFavorites() async {
    if (!_canUse) return <String>{};
    final snap = await _userDoc().doc('favorites').get();
    if (!snap.exists) return <String>{};
    final data = snap.data();
    final List<dynamic> ids = (data?['ids'] as List<dynamic>? ?? <dynamic>[]);
    return ids.map((e) => e.toString()).toSet();
  }

  Future<void> pushPantry(Map<String, double> pantry) async {
    if (!_canUse) return;
    await _userDoc().doc('pantry').set({'items': pantry, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<Map<String, double>> pullPantry() async {
    if (!_canUse) return <String, double>{};
    final snap = await _userDoc().doc('pantry').get();
    if (!snap.exists) return <String, double>{};
    final map = (snap.data()?['items'] as Map<String, dynamic>? ?? <String, dynamic>{});
    return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> pushShoppingList(List<Map<String, dynamic>> items) async {
    if (!_canUse) return;
    await _userDoc().doc('shopping_list').set({'items': items, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<List<Map<String, dynamic>>> pullShoppingList() async {
    if (!_canUse) return <Map<String, dynamic>>[];
    final snap = await _userDoc().doc('shopping_list').get();
    if (!snap.exists) return <Map<String, dynamic>>[];
    final List<dynamic> items = (snap.data()?['items'] as List<dynamic>? ?? <dynamic>[]);
    return items.cast<Map<String, dynamic>>();
  }
}

