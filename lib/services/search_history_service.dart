import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class SearchHistoryService {
  static const String _searchHistoryCollection = 'search_history';

  static String get _userSearchHistoryCollection => '${_searchHistoryCollection}_${FirebaseService.currentUser?.uid}';

  static Future<void> addSearchHistory(SearchHistory search) async {
    await FirebaseService.firestore
        .collection(_userSearchHistoryCollection)
        .doc(search.id)
        .set(search.toJson());
  }

  static Future<List<SearchHistory>> getRecentSearches({int limit = 10}) async {
    final snapshot = await FirebaseService.firestore
        .collection(_userSearchHistoryCollection)
        .orderBy('searchedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SearchHistory.fromJson(doc.data()))
        .toList();
  }

  static Future<void> clearSearchHistory() async {
    final snapshot = await FirebaseService.firestore
        .collection(_userSearchHistoryCollection)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  static Stream<List<SearchHistory>> getRecentSearchesStream({int limit = 10}) {
    return FirebaseService.firestore
        .collection(_userSearchHistoryCollection)
        .orderBy('searchedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SearchHistory.fromJson(doc.data()))
            .toList());
  }
}