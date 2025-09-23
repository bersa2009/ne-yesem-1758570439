import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'matching_service.dart';

/// AI-powered recipe matching service that extends the basic MatchingService
/// with machine learning capabilities for personalized recommendations.
class AIService {
  final MatchingService _baseService;
  Map<String, dynamic>? _modelMetadata;
  Map<String, double> _userPreferences = {};
  List<UserFeedback> _feedbackHistory = [];
  Map<String, List<String>> _learnedSubstitutions = {};
  
  AIService(this._baseService);

  /// Initialize the AI service by loading model metadata and user preferences
  Future<void> initialize() async {
    try {
      // Load model metadata
      final metadataJson = await rootBundle.loadString('assets/models/model_metadata.json');
      _modelMetadata = jsonDecode(metadataJson);
      
      // Load user preferences and feedback history
      await _loadUserData();
      
      print('AI Service initialized successfully');
    } catch (e) {
      print('Warning: AI Service initialization failed: $e');
      // Continue without AI features if initialization fails
    }
  }

  /// Enhanced recipe matching with AI-powered scoring and personalization
  Future<List<MatchResult>> matchWithAI({
    required Set<String> userIngredientIds,
    MatchFilters filters = const MatchFilters(),
    Map<String, dynamic>? userContext,
  }) async {
    try {
      // Start with base matching
      final baseResults = _baseService.match(
        userIngredientIds: userIngredientIds,
        filters: filters,
      );

      // Apply AI enhancements
      final enhancedResults = await _enhanceWithAI(
        baseResults,
        userIngredientIds,
        filters,
        userContext,
      );

      // Apply personalization
      final personalizedResults = _applyPersonalization(enhancedResults);

      // Sort by enhanced scores
      personalizedResults.sort((a, b) => b.score.compareTo(a.score));

      return personalizedResults;
    } catch (e) {
      print('AI matching failed, falling back to base service: $e');
      return _baseService.match(userIngredientIds: userIngredientIds, filters: filters);
    }
  }

  /// Generate intelligent substitution suggestions based on user feedback and context
  List<SubstitutionSuggestion> generateSubstitutions({
    required String missingIngredientId,
    required Set<String> availableIngredients,
    Map<String, dynamic>? context,
  }) {
    final suggestions = <SubstitutionSuggestion>[];

    // Get base substitutions
    final baseSubstitutions = _baseService.substitutions
        .where((s) => s.ingredientId == missingIngredientId)
        .toList();

    // Add learned substitutions
    final learnedSubs = _learnedSubstitutions[missingIngredientId] ?? [];

    for (final sub in baseSubstitutions) {
      if (availableIngredients.contains(sub.substituteId)) {
        final confidence = _calculateSubstitutionConfidence(
          missingIngredientId,
          sub.substituteId,
          context,
        );
        
        suggestions.add(SubstitutionSuggestion(
          originalId: missingIngredientId,
          substituteId: sub.substituteId,
          confidence: confidence,
          reason: _getSubstitutionReason(missingIngredientId, sub.substituteId),
        ));
      }
    }

    // Add AI-learned substitutions
    for (final learnedSubId in learnedSubs) {
      if (availableIngredients.contains(learnedSubId)) {
        final confidence = _calculateLearnedSubstitutionConfidence(
          missingIngredientId,
          learnedSubId,
        );
        
        suggestions.add(SubstitutionSuggestion(
          originalId: missingIngredientId,
          substituteId: learnedSubId,
          confidence: confidence,
          reason: 'Learned from your preferences',
        ));
      }
    }

    // Sort by confidence
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.take(3).toList();
  }

  /// Record user feedback to improve future recommendations
  Future<void> recordFeedback(UserFeedback feedback) async {
    _feedbackHistory.add(feedback);
    
    // Update preferences based on feedback
    await _updatePreferencesFromFeedback(feedback);
    
    // Learn new substitutions if applicable
    _learnFromFeedback(feedback);
    
    // Save to persistent storage
    await _saveUserData();
  }

  /// Get personalized recipe recommendations based on user history
  List<String> getPersonalizedRecommendations({
    required Set<String> availableIngredients,
    int limit = 5,
  }) {
    final recommendations = <String, double>{};

    // Analyze user preferences from feedback
    for (final feedback in _feedbackHistory) {
      if (feedback.rating >= 4.0) {
        final recipe = _baseService.recipes.firstWhere(
          (r) => r.id == feedback.recipeId,
          orElse: () => Recipe(
            id: '',
            name: '',
            description: '',
            steps: [],
            timeMin: 0,
            servings: 0,
            difficulty: '',
            equipment: [],
            dietTags: [],
            imageUrl: '',
            popularityScore: 0,
            ingredients: [],
          ),
        );
        
        if (recipe.id.isNotEmpty) {
          // Boost recipes with similar ingredients or diet tags
          for (final otherRecipe in _baseService.recipes) {
            if (otherRecipe.id != recipe.id) {
              double similarity = _calculateRecipeSimilarity(recipe, otherRecipe);
              recommendations[otherRecipe.id] = 
                  (recommendations[otherRecipe.id] ?? 0.0) + similarity * feedback.rating;
            }
          }
        }
      }
    }

    // Sort and return top recommendations
    final sortedRecs = recommendations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedRecs.take(limit).map((e) => e.key).toList();
  }

  // Private methods for AI functionality

  Future<List<MatchResult>> _enhanceWithAI(
    List<MatchResult> baseResults,
    Set<String> userIngredientIds,
    MatchFilters filters,
    Map<String, dynamic>? context,
  ) async {
    if (_modelMetadata == null) return baseResults;

    final enhancedResults = <MatchResult>[];

    for (final result in baseResults) {
      // Calculate AI score using simplified neural network approach
      final aiScore = _calculateAIScore(result.recipe, userIngredientIds, context);
      
      // Combine base score with AI score
      final enhancedScore = (result.score * 0.6 + aiScore * 0.4).round();
      
      enhancedResults.add(MatchResult(
        recipe: result.recipe,
        score: enhancedScore,
        missingIngredientIds: result.missingIngredientIds,
      ));
    }

    return enhancedResults;
  }

  double _calculateAIScore(
    Recipe recipe,
    Set<String> userIngredientIds,
    Map<String, dynamic>? context,
  ) {
    if (_modelMetadata == null) return 50.0;

    // Simplified neural network calculation
    final ingredientToIdx = _modelMetadata!['ingredient_to_idx'] as Map<String, dynamic>;
    final recipeToIdx = _modelMetadata!['recipe_to_idx'] as Map<String, dynamic>;
    
    // Create feature vector
    final features = List<double>.filled(30, 0.0);
    
    // Set ingredient features
    for (final ingredientId in userIngredientIds) {
      final idx = ingredientToIdx[ingredientId];
      if (idx != null && idx < 25) {
        features[idx] = 1.0;
      }
    }
    
    // Set recipe feature
    final recipeIdx = recipeToIdx[recipe.id];
    if (recipeIdx != null && recipeIdx < 5) {
      features[25 + recipeIdx] = 1.0;
    }
    
    // Simple neural network forward pass with hardcoded weights
    double score = _forwardPass(features);
    
    return score * 100; // Convert to 0-100 scale
  }

  double _forwardPass(List<double> features) {
    // Simplified 3-layer neural network
    final weights1 = _generateWeights(30, 16); // Input to hidden1
    final weights2 = _generateWeights(16, 8);  // Hidden1 to hidden2
    final weights3 = _generateWeights(8, 1);   // Hidden2 to output
    
    // Layer 1
    var hidden1 = List<double>.filled(16, 0.0);
    for (int i = 0; i < 16; i++) {
      double sum = 0.0;
      for (int j = 0; j < 30; j++) {
        sum += features[j] * weights1[j][i];
      }
      hidden1[i] = _relu(sum);
    }
    
    // Layer 2
    var hidden2 = List<double>.filled(8, 0.0);
    for (int i = 0; i < 8; i++) {
      double sum = 0.0;
      for (int j = 0; j < 16; j++) {
        sum += hidden1[j] * weights2[j][i];
      }
      hidden2[i] = _relu(sum);
    }
    
    // Output layer
    double output = 0.0;
    for (int j = 0; j < 8; j++) {
      output += hidden2[j] * weights3[j][0];
    }
    
    return _sigmoid(output);
  }

  List<List<double>> _generateWeights(int inputSize, int outputSize) {
    final random = Random(42); // Fixed seed for consistency
    return List.generate(inputSize, (i) =>
        List.generate(outputSize, (j) => random.nextDouble() * 2 - 1));
  }

  double _relu(double x) => x > 0 ? x : 0;
  double _sigmoid(double x) => 1 / (1 + exp(-x));

  List<MatchResult> _applyPersonalization(List<MatchResult> results) {
    final personalizedResults = <MatchResult>[];

    for (final result in results) {
      double personalizedScore = result.score.toDouble();

      // Apply diet preferences
      for (final dietTag in result.recipe.dietTags) {
        final preference = _userPreferences['diet_$dietTag'] ?? 1.0;
        personalizedScore *= preference;
      }

      // Apply time preferences
      final timePreference = _userPreferences['time_preference'] ?? 1.0;
      if (result.recipe.timeMin <= 20) {
        personalizedScore *= timePreference;
      }

      // Apply difficulty preferences
      final difficultyPreference = _userPreferences['difficulty_${result.recipe.difficulty}'] ?? 1.0;
      personalizedScore *= difficultyPreference;

      personalizedResults.add(MatchResult(
        recipe: result.recipe,
        score: personalizedScore.round(),
        missingIngredientIds: result.missingIngredientIds,
      ));
    }

    return personalizedResults;
  }

  double _calculateSubstitutionConfidence(
    String originalId,
    String substituteId,
    Map<String, dynamic>? context,
  ) {
    // Base confidence from substitution strength
    final substitution = _baseService.substitutions.firstWhere(
      (s) => s.ingredientId == originalId && s.substituteId == substituteId,
      orElse: () => Substitution(ingredientId: '', substituteId: '', strength: 0.5),
    );

    double confidence = substitution.strength;

    // Boost confidence based on user feedback
    final feedbackBoost = _getFeedbackBoost(originalId, substituteId);
    confidence = (confidence + feedbackBoost).clamp(0.0, 1.0);

    return confidence;
  }

  double _calculateLearnedSubstitutionConfidence(
    String originalId,
    String substituteId,
  ) {
    // Calculate confidence based on frequency in feedback
    int successCount = 0;
    int totalCount = 0;

    for (final feedback in _feedbackHistory) {
      if (feedback.substitutions.containsKey(originalId) &&
          feedback.substitutions[originalId] == substituteId) {
        totalCount++;
        if (feedback.rating >= 4.0) {
          successCount++;
        }
      }
    }

    if (totalCount == 0) return 0.5;
    return successCount / totalCount;
  }

  String _getSubstitutionReason(String originalId, String substituteId) {
    // Get ingredient names for better UX
    final original = _baseService.ingredientById[originalId]?.name ?? originalId;
    final substitute = _baseService.ingredientById[substituteId]?.name ?? substituteId;
    
    return '$substitute can replace $original in most recipes';
  }

  double _getFeedbackBoost(String originalId, String substituteId) {
    double boost = 0.0;
    int count = 0;

    for (final feedback in _feedbackHistory) {
      if (feedback.substitutions.containsKey(originalId) &&
          feedback.substitutions[originalId] == substituteId) {
        boost += (feedback.rating - 3.0) * 0.1; // Scale rating to boost
        count++;
      }
    }

    return count > 0 ? boost / count : 0.0;
  }

  Future<void> _updatePreferencesFromFeedback(UserFeedback feedback) async {
    final recipe = _baseService.recipes.firstWhere(
      (r) => r.id == feedback.recipeId,
      orElse: () => Recipe(
        id: '',
        name: '',
        description: '',
        steps: [],
        timeMin: 0,
        servings: 0,
        difficulty: '',
        equipment: [],
        dietTags: [],
        imageUrl: '',
        popularityScore: 0,
        ingredients: [],
      ),
    );

    if (recipe.id.isEmpty) return;

    // Update diet preferences
    for (final dietTag in recipe.dietTags) {
      final key = 'diet_$dietTag';
      final currentPref = _userPreferences[key] ?? 1.0;
      final adjustment = (feedback.rating - 3.0) * 0.05; // Small adjustments
      _userPreferences[key] = (currentPref + adjustment).clamp(0.5, 2.0);
    }

    // Update time preferences
    if (recipe.timeMin <= 20) {
      final key = 'time_preference';
      final currentPref = _userPreferences[key] ?? 1.0;
      final adjustment = (feedback.rating - 3.0) * 0.05;
      _userPreferences[key] = (currentPref + adjustment).clamp(0.5, 2.0);
    }

    // Update difficulty preferences
    final difficultyKey = 'difficulty_${recipe.difficulty}';
    final currentPref = _userPreferences[difficultyKey] ?? 1.0;
    final adjustment = (feedback.rating - 3.0) * 0.05;
    _userPreferences[difficultyKey] = (currentPref + adjustment).clamp(0.5, 2.0);
  }

  void _learnFromFeedback(UserFeedback feedback) {
    // Learn new substitutions from positive feedback
    if (feedback.rating >= 4.0) {
      for (final entry in feedback.substitutions.entries) {
        final originalId = entry.key;
        final substituteId = entry.value;
        
        _learnedSubstitutions.putIfAbsent(originalId, () => []);
        if (!_learnedSubstitutions[originalId]!.contains(substituteId)) {
          _learnedSubstitutions[originalId]!.add(substituteId);
        }
      }
    }
  }

  double _calculateRecipeSimilarity(Recipe recipe1, Recipe recipe2) {
    double similarity = 0.0;
    
    // Compare ingredients
    final ingredients1 = recipe1.ingredients.map((ri) => ri.ingredientId).toSet();
    final ingredients2 = recipe2.ingredients.map((ri) => ri.ingredientId).toSet();
    final commonIngredients = ingredients1.intersection(ingredients2);
    final totalIngredients = ingredients1.union(ingredients2);
    
    if (totalIngredients.isNotEmpty) {
      similarity += (commonIngredients.length / totalIngredients.length) * 0.5;
    }
    
    // Compare diet tags
    final dietTags1 = recipe1.dietTags.toSet();
    final dietTags2 = recipe2.dietTags.toSet();
    final commonDietTags = dietTags1.intersection(dietTags2);
    
    if (dietTags1.isNotEmpty || dietTags2.isNotEmpty) {
      final totalDietTags = dietTags1.union(dietTags2);
      similarity += (commonDietTags.length / totalDietTags.length) * 0.3;
    }
    
    // Compare difficulty and time
    if (recipe1.difficulty == recipe2.difficulty) {
      similarity += 0.1;
    }
    
    final timeDiff = (recipe1.timeMin - recipe2.timeMin).abs();
    if (timeDiff <= 10) {
      similarity += 0.1;
    }
    
    return similarity;
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load preferences
      final prefsJson = prefs.getString('ai_user_preferences');
      if (prefsJson != null) {
        final prefsMap = jsonDecode(prefsJson) as Map<String, dynamic>;
        _userPreferences = prefsMap.map((k, v) => MapEntry(k, v.toDouble()));
      }
      
      // Load feedback history
      final feedbackJson = prefs.getString('ai_feedback_history');
      if (feedbackJson != null) {
        final feedbackList = jsonDecode(feedbackJson) as List<dynamic>;
        _feedbackHistory = feedbackList
            .map((f) => UserFeedback.fromJson(f as Map<String, dynamic>))
            .toList();
      }
      
      // Load learned substitutions
      final subsJson = prefs.getString('ai_learned_substitutions');
      if (subsJson != null) {
        final subsMap = jsonDecode(subsJson) as Map<String, dynamic>;
        _learnedSubstitutions = subsMap.map((k, v) => 
            MapEntry(k, List<String>.from(v as List<dynamic>)));
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save preferences
      await prefs.setString('ai_user_preferences', jsonEncode(_userPreferences));
      
      // Save feedback history (keep only last 100 entries)
      final recentFeedback = _feedbackHistory.take(100).toList();
      await prefs.setString('ai_feedback_history', 
          jsonEncode(recentFeedback.map((f) => f.toJson()).toList()));
      
      // Save learned substitutions
      await prefs.setString('ai_learned_substitutions', jsonEncode(_learnedSubstitutions));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }
}

/// Represents a substitution suggestion with confidence and reasoning
class SubstitutionSuggestion {
  final String originalId;
  final String substituteId;
  final double confidence;
  final String reason;

  const SubstitutionSuggestion({
    required this.originalId,
    required this.substituteId,
    required this.confidence,
    required this.reason,
  });
}

/// Represents user feedback for a recipe attempt
class UserFeedback {
  final String recipeId;
  final double rating; // 1-5 stars
  final Map<String, String> substitutions; // original_id -> substitute_id
  final DateTime timestamp;
  final String? notes;

  const UserFeedback({
    required this.recipeId,
    required this.rating,
    required this.substitutions,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'recipe_id': recipeId,
    'rating': rating,
    'substitutions': substitutions,
    'timestamp': timestamp.toIso8601String(),
    'notes': notes,
  };

  factory UserFeedback.fromJson(Map<String, dynamic> json) => UserFeedback(
    recipeId: json['recipe_id'] as String,
    rating: (json['rating'] as num).toDouble(),
    substitutions: Map<String, String>.from(json['substitutions'] as Map<String, dynamic>),
    timestamp: DateTime.parse(json['timestamp'] as String),
    notes: json['notes'] as String?,
  );
}