import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class RecipeFeedbackService {
  static const String _feedbackCollection = 'recipe_feedback';

  static Future<void> submitFeedback(RecipeFeedback feedback) async {
    await FirebaseService.firestore
        .collection(_feedbackCollection)
        .doc(feedback.id)
        .set(feedback.toJson());
  }

  static Future<double> getRecipeHelpfulnessScore(String recipeId) async {
    final snapshot = await FirebaseService.firestore
        .collection(_feedbackCollection)
        .where('recipeId', isEqualTo: recipeId)
        .get();

    if (snapshot.docs.isEmpty) return 0.0;

    final feedbacks = snapshot.docs
        .map((doc) => RecipeFeedback.fromJson(doc.data()))
        .toList();

    final helpfulCount = feedbacks.where((f) => f.helpful).length;
    return helpfulCount / feedbacks.length;
  }

  static Future<bool> hasUserVoted(String recipeId, String userId) async {
    final snapshot = await FirebaseService.firestore
        .collection(_feedbackCollection)
        .where('recipeId', isEqualTo: recipeId)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}