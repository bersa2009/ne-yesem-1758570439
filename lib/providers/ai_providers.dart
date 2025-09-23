import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/matching_service.dart';
import '../services/ai_service.dart';
import '../models/models.dart';

/// Provider for the base matching service
final matchingServiceProvider = FutureProvider<MatchingService>((ref) async {
  return await MatchingService.loadFromAssets();
});

/// Provider for the AI service
final aiServiceProvider = FutureProvider<AIService>((ref) async {
  final matchingService = await ref.watch(matchingServiceProvider.future);
  final aiService = AIService(matchingService);
  await aiService.initialize();
  return aiService;
});

/// State provider for current user ingredients
final userIngredientsProvider = StateProvider<Set<String>>((ref) => {});

/// State provider for match filters
final matchFiltersProvider = StateProvider<MatchFilters>((ref) => const MatchFilters());

/// Provider for AI-powered recipe matching results
final aiMatchResultsProvider = FutureProvider<List<MatchResult>>((ref) async {
  final aiService = await ref.watch(aiServiceProvider.future);
  final userIngredients = ref.watch(userIngredientsProvider);
  final filters = ref.watch(matchFiltersProvider);
  
  if (userIngredients.isEmpty) {
    return <MatchResult>[];
  }
  
  return await aiService.matchWithAI(
    userIngredientIds: userIngredients,
    filters: filters,
  );
});

/// Provider for personalized recipe recommendations
final personalizedRecommendationsProvider = FutureProvider<List<String>>((ref) async {
  final aiService = await ref.watch(aiServiceProvider.future);
  final userIngredients = ref.watch(userIngredientsProvider);
  
  return aiService.getPersonalizedRecommendations(
    availableIngredients: userIngredients,
    limit: 5,
  );
});

/// Provider for substitution suggestions
final substitutionSuggestionsProvider = FutureProvider.family<List<SubstitutionSuggestion>, String>((ref, missingIngredientId) async {
  final aiService = await ref.watch(aiServiceProvider.future);
  final userIngredients = ref.watch(userIngredientsProvider);
  
  return aiService.generateSubstitutions(
    missingIngredientId: missingIngredientId,
    availableIngredients: userIngredients,
  );
});

/// State notifier for managing AI features
class AIFeaturesNotifier extends StateNotifier<AIFeaturesState> {
  final AIService _aiService;
  
  AIFeaturesNotifier(this._aiService) : super(const AIFeaturesState());
  
  /// Record user feedback for a recipe
  Future<void> recordFeedback(UserFeedback feedback) async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _aiService.recordFeedback(feedback);
      state = state.copyWith(
        isLoading: false,
        lastFeedback: feedback,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Enable/disable AI features
  void toggleAIFeatures(bool enabled) {
    state = state.copyWith(aiEnabled: enabled);
  }
}

/// Provider for AI features state management
final aiFeaturesProvider = StateNotifierProvider<AIFeaturesNotifier, AIFeaturesState>((ref) {
  final aiService = ref.watch(aiServiceProvider).maybeWhen(
    data: (service) => service,
    orElse: () => throw UnimplementedError('AI Service not ready'),
  );
  
  return AIFeaturesNotifier(aiService);
});

/// State class for AI features
class AIFeaturesState {
  final bool isLoading;
  final bool aiEnabled;
  final String? error;
  final UserFeedback? lastFeedback;
  
  const AIFeaturesState({
    this.isLoading = false,
    this.aiEnabled = true,
    this.error,
    this.lastFeedback,
  });
  
  AIFeaturesState copyWith({
    bool? isLoading,
    bool? aiEnabled,
    String? error,
    UserFeedback? lastFeedback,
  }) {
    return AIFeaturesState(
      isLoading: isLoading ?? this.isLoading,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      error: error ?? this.error,
      lastFeedback: lastFeedback ?? this.lastFeedback,
    );
  }
}

/// Provider for checking if AI features are available
final aiAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    await ref.watch(aiServiceProvider.future);
    return true;
  } catch (e) {
    return false;
  }
});

/// Provider for AI service status
final aiServiceStatusProvider = Provider<AsyncValue<String>>((ref) {
  return ref.watch(aiServiceProvider).when(
    data: (_) => const AsyncValue.data('AI Service Ready'),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error('AI Service Error: $error', stack),
  );
});