import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'ai_service.dart';
import 'local_store.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final aiService = AIService();
  // AI servisini başlat
  aiService.initialize().catchError((e) {
    // Hata durumunda log veya fallback
    print('AI Service initialization error: $e');
  });
  return aiService;
});

final localStoreProvider = Provider<LocalStore>((ref) {
  return LocalStore();
});

final userHistoryProvider = StateNotifierProvider<UserHistoryNotifier, Map<String, int>>((ref) {
  final localStore = ref.watch(localStoreProvider);
  return UserHistoryNotifier(localStore);
});

final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, Map<String, Map<String, double>>>((ref) {
  final localStore = ref.watch(localStoreProvider);
  return UserPreferencesNotifier(localStore);
});

final aiMatchResultsProvider = FutureProvider.family<List<MatchResult>, MatchRequest>((ref, request) async {
  final aiService = ref.watch(aiServiceProvider);
  final userHistory = ref.watch(userHistoryProvider);
  final userPreferences = ref.watch(userPreferencesProvider);

  // AI servisini başlat (eğer henüz başlatılmadıysa)
  await aiService.initialize();

  // Tarifleri eşleştir
  return aiService.matchRecipes(
    userIngredientIds: request.userIngredientIds,
    filters: request.filters,
    userHistory: userHistory,
    userPreferences: userPreferences,
  );
});

class UserHistoryNotifier extends StateNotifier<Map<String, int>> {
  final LocalStore _localStore;

  UserHistoryNotifier(this._localStore) : super({});

  void addRecipeRating(String recipeId, int rating) {
    state = {...state, recipeId: rating};
    // Local storage'a kaydet (şimdilik memory'de)
  }

  void incrementRecipeUsage(String recipeId) {
    final currentUsage = state[recipeId] ?? 0;
    state = {...state, recipeId: currentUsage + 1};
  }
}

class UserPreferencesNotifier extends StateNotifier<Map<String, Map<String, double>>> {
  final LocalStore _localStore;

  UserPreferencesNotifier(this._localStore) : super({});

  void updateSubstitutionPreference(String ingredientId, String substituteId, double strength) {
    final currentPrefs = state[ingredientId] ?? {};
    state = {
      ...state,
      ingredientId: {...currentPrefs, substituteId: strength}
    };
  }

  void learnFromRecipeChoice(String recipeId, Set<String> userIngredientIds, bool wasGoodMatch) {
    // Kullanıcı geri bildiriminden öğren (V2 için)
    // Bu kısım daha gelişmiş öğrenme için kullanılacak
  }
}

class MatchRequest {
  final Set<String> userIngredientIds;
  final MatchFilters filters;

  const MatchRequest({
    required this.userIngredientIds,
    this.filters = const MatchFilters(),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchRequest &&
          runtimeType == other.runtimeType &&
          userIngredientIds == other.userIngredientIds &&
          filters == other.filters;

  @override
  int get hashCode => userIngredientIds.hashCode ^ filters.hashCode;
}