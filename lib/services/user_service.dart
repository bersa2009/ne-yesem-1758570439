import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class UserService {
  static const String _usersCollection = 'users';

  static Future<User?> getCurrentUser() async {
    final user = FirebaseService.currentUser;
    if (user == null) return null;

    final doc = await FirebaseService.firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    return User.fromJson(doc.data()!);
  }

  static Future<void> createUserProfile(User userProfile) async {
    await FirebaseService.firestore
        .collection(_usersCollection)
        .doc(userProfile.id)
        .set(userProfile.toJson());
  }

  static Future<void> updateUserProfile(User userProfile) async {
    await FirebaseService.firestore
        .collection(_usersCollection)
        .doc(userProfile.id)
        .update(userProfile.toJson());
  }

  static Future<void> incrementSearchCount(String userId) async {
    await FirebaseService.firestore
        .collection(_usersCollection)
        .doc(userId)
        .update({'dailySearchCount': FieldValue.increment(1)});
  }

  static Future<void> resetDailySearchCount(String userId) async {
    await FirebaseService.firestore
        .collection(_usersCollection)
        .doc(userId)
        .update({'dailySearchCount': 0});
  }

  static Stream<User?> getUserProfile(String userId) {
    return FirebaseService.firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? User.fromJson(doc.data()!) : null);
  }
}