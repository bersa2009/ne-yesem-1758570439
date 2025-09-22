import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/matching_service.dart';
import '../services/camera_service.dart';
import '../services/voice_service.dart';
import '../services/assistant_service.dart';
import '../services/database_service.dart';
import '../services/security_service.dart';
import '../services/performance_service.dart';
import '../services/error_service.dart';

// Service Providers
final matchingServiceProvider = FutureProvider<MatchingService>((ref) async {
  return await MatchingService.loadFromAssets();
});

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService.instance;
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService.instance;
});

final assistantServiceProvider = Provider<AssistantService>((ref) {
  return AssistantService.instance;
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService.instance;
});

final performanceServiceProvider = Provider<PerformanceService>((ref) {
  return PerformanceService.instance;
});

final errorServiceProvider = Provider<ErrorService>((ref) {
  return ErrorService.instance;
});

// State Providers
final selectedIngredientsProvider = StateNotifierProvider<SelectedIngredientsNotifier, Set<String>>((ref) {
  return SelectedIngredientsNotifier();
});

final searchFiltersProvider = StateNotifierProvider<SearchFiltersNotifier, MatchFilters>((ref) {
  return SearchFiltersNotifier();
});

final recipeResultsProvider = StateNotifierProvider<RecipeResultsNotifier, AsyncValue<List<MatchResult>>>((ref) {
  return RecipeResultsNotifier(ref);
});

final favoriteRecipesProvider = StateNotifierProvider<FavoriteRecipesNotifier, Set<String>>((ref) {
  return FavoriteRecipesNotifier(ref);
});

final userIngredientsProvider = StateNotifierProvider<UserIngredientsNotifier, List<UserIngredient>>((ref) {
  return UserIngredientsNotifier(ref);
});

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref);
});

final voiceRecognitionProvider = StateNotifierProvider<VoiceRecognitionNotifier, VoiceRecognitionState>((ref) {
  return VoiceRecognitionNotifier(ref);
});

final cameraStateProvider = StateNotifierProvider<CameraStateNotifier, CameraState>((ref) {
  return CameraStateNotifier(ref);
});

// Stream Providers
final voiceRecognitionStreamProvider = StreamProvider<VoiceRecognitionResult>((ref) {
  final voiceService = ref.watch(voiceServiceProvider);
  return voiceService.recognitionStream;
});

final assistantResponseStreamProvider = StreamProvider<AssistantResponse>((ref) {
  final assistantService = ref.watch(assistantServiceProvider);
  return assistantService.responseStream;
});

final errorStreamProvider = StreamProvider<AppError>((ref) {
  final errorService = ref.watch(errorServiceProvider);
  return errorService.errorStream;
});

// State Notifiers
class SelectedIngredientsNotifier extends StateNotifier<Set<String>> {
  SelectedIngredientsNotifier() : super(<String>{});

  void addIngredient(String ingredientId) {
    state = {...state, ingredientId};
  }

  void removeIngredient(String ingredientId) {
    state = state.where((id) => id != ingredientId).toSet();
  }

  void toggleIngredient(String ingredientId) {
    if (state.contains(ingredientId)) {
      removeIngredient(ingredientId);
    } else {
      addIngredient(ingredientId);
    }
  }

  void setIngredients(Set<String> ingredients) {
    state = ingredients;
  }

  void clearIngredients() {
    state = <String>{};
  }

  void addIngredientsFromList(List<String> ingredientNames, Map<String, Ingredient> ingredientById) {
    final newIngredients = <String>{};
    
    for (final name in ingredientNames) {
      final lowerName = name.toLowerCase();
      for (final ingredient in ingredientById.values) {
        if (ingredient.name.toLowerCase() == lowerName ||
            ingredient.aliases.any((alias) => alias.toLowerCase() == lowerName)) {
          newIngredients.add(ingredient.id);
          break;
        }
      }
    }
    
    state = {...state, ...newIngredients};
  }
}

class SearchFiltersNotifier extends StateNotifier<MatchFilters> {
  SearchFiltersNotifier() : super(const MatchFilters());

  void setMaxTime(int? minutes) {
    state = MatchFilters(
      maxTimeMinutes: minutes,
      diet: state.diet,
      excludedEquipment: state.excludedEquipment,
    );
  }

  void setDiet(String? diet) {
    state = MatchFilters(
      maxTimeMinutes: state.maxTimeMinutes,
      diet: diet,
      excludedEquipment: state.excludedEquipment,
    );
  }

  void setExcludedEquipment(List<String> equipment) {
    state = MatchFilters(
      maxTimeMinutes: state.maxTimeMinutes,
      diet: state.diet,
      excludedEquipment: equipment,
    );
  }

  void clearFilters() {
    state = const MatchFilters();
  }
}

class RecipeResultsNotifier extends StateNotifier<AsyncValue<List<MatchResult>>> {
  final Ref ref;

  RecipeResultsNotifier(this.ref) : super(const AsyncValue.data([]));

  Future<void> searchRecipes() async {
    state = const AsyncValue.loading();
    
    try {
      final selectedIngredients = ref.read(selectedIngredientsProvider);
      final filters = ref.read(searchFiltersProvider);
      
      if (selectedIngredients.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      final matchingService = await ref.read(matchingServiceProvider.future);
      
      // Use performance service for optimization
      final performanceService = ref.read(performanceServiceProvider);
      performanceService.startTracking('recipe_search');
      
      List<MatchResult> results;
      
      // Use isolate for heavy computation if many ingredients
      if (selectedIngredients.length > 10) {
        results = await PerformanceService.matchRecipesInIsolate(
          userIngredientIds: selectedIngredients,
          filters: filters,
          ingredientById: matchingService.ingredientById,
          recipes: matchingService.recipes,
          substitutions: matchingService.substitutions,
        );
      } else {
        results = matchingService.match(
          userIngredientIds: selectedIngredients,
          filters: filters,
        );
      }

      performanceService.endTracking('recipe_search', success: true);
      
      // Save search history
      final databaseService = ref.read(databaseServiceProvider);
      if (databaseService.isInitialized) {
        final ingredientNames = selectedIngredients
            .map((id) => matchingService.ingredientById[id]?.name ?? id)
            .toList();
        await databaseService.saveSearchHistory(
          'Recipe search',
          ingredientNames,
          results.length,
        );
      }
      
      state = AsyncValue.data(results);
    } catch (error, stackTrace) {
      final performanceService = ref.read(performanceServiceProvider);
      performanceService.endTracking('recipe_search', success: false, error: error.toString());
      
      final errorService = ref.read(errorServiceProvider);
      errorService.reportErrorWithContext(
        error,
        stackTrace,
        context: 'Recipe Search',
        severity: ErrorSeverity.medium,
      );
      
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearResults() {
    state = const AsyncValue.data([]);
  }
}

class FavoriteRecipesNotifier extends StateNotifier<Set<String>> {
  final Ref ref;

  FavoriteRecipesNotifier(this.ref) : super(<String>{}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      if (databaseService.isInitialized) {
        final favoriteRecipes = await databaseService.getFavoriteRecipes();
        state = favoriteRecipes.map((recipe) => recipe.id).toSet();
      }
    } catch (e) {
      final errorService = ref.read(errorServiceProvider);
      errorService.reportErrorWithContext(e, null, context: 'Load Favorites');
    }
  }

  Future<void> toggleFavorite(String recipeId) async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      if (databaseService.isInitialized) {
        await databaseService.toggleRecipeFavorite(recipeId);
        
        if (state.contains(recipeId)) {
          state = state.where((id) => id != recipeId).toSet();
        } else {
          state = {...state, recipeId};
        }
      }
    } catch (e) {
      final errorService = ref.read(errorServiceProvider);
      errorService.reportErrorWithContext(e, null, context: 'Toggle Favorite');
    }
  }

  bool isFavorite(String recipeId) {
    return state.contains(recipeId);
  }
}

class UserIngredientsNotifier extends StateNotifier<List<UserIngredient>> {
  final Ref ref;

  UserIngredientsNotifier(this.ref) : super([]) {
    _loadUserIngredients();
  }

  Future<void> _loadUserIngredients() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      if (databaseService.isInitialized) {
        final ingredients = await databaseService.getUserIngredients();
        state = ingredients;
      }
    } catch (e) {
      final errorService = ref.read(errorServiceProvider);
      errorService.reportErrorWithContext(e, null, context: 'Load User Ingredients');
    }
  }

  Future<void> addIngredient(String ingredientId, {double? quantity, String? unit, DateTime? expiryDate}) async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      if (databaseService.isInitialized) {
        await databaseService.addUserIngredient(
          ingredientId,
          quantity: quantity,
          unit: unit,
          expiryDate: expiryDate,
        );
        await _loadUserIngredients();
      }
    } catch (e) {
      final errorService = ref.read(errorServiceProvider);
      errorService.reportErrorWithContext(e, null, context: 'Add User Ingredient');
    }
  }

  Future<void> removeIngredient(int id) async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      if (databaseService.isInitialized) {
        await databaseService.removeUserIngredient(id);
        state = state.where((ingredient) => ingredient.id != id).toList();
      }
    } catch (e) {
      final errorService = ref.read(errorServiceProvider);
      errorService.reportErrorWithContext(e, null, context: 'Remove User Ingredient');
    }
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final Ref ref;

  AppSettingsNotifier(this.ref) : super(AppSettings.defaultSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      if (databaseService.isInitialized) {
        final settings = AppSettings(
          language: databaseService.getPreference<String>('language', defaultValue: 'tr') ?? 'tr',
          theme: ThemeMode.values.firstWhere(
            (mode) => mode.name == databaseService.getPreference<String>('theme', defaultValue: 'system'),
            orElse: () => ThemeMode.system,
          ),
          voiceEnabled: databaseService.getPreference<bool>('voice_enabled', defaultValue: true) ?? true,
          cameraEnabled: databaseService.getPreference<bool>('camera_enabled', defaultValue: true) ?? true,
          notificationsEnabled: databaseService.getPreference<bool>('notifications_enabled', defaultValue: true) ?? true,
          analyticsEnabled: databaseService.getPreference<bool>('analytics_enabled', defaultValue: false) ?? false,
        );
        state = settings;
      }
    } catch (e) {
      final errorService = ref.read(errorServiceProvider);
      errorService.reportErrorWithContext(e, null, context: 'Load Settings');
    }
  }

  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  Future<void> updateTheme(ThemeMode theme) async {
    state = state.copyWith(theme: theme);
    await _saveSettings();
  }

  Future<void> updateVoiceEnabled(bool enabled) async {
    state = state.copyWith(voiceEnabled: enabled);
    await _saveSettings();
  }

  Future<void> updateCameraEnabled(bool enabled) async {
    state = state.copyWith(cameraEnabled: enabled);
    await _saveSettings();
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> updateAnalyticsEnabled(bool enabled) async {
    state = state.copyWith(analyticsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      if (databaseService.isInitialized) {
        await databaseService.setPreference('language', state.language);
        await databaseService.setPreference('theme', state.theme.name);
        await databaseService.setPreference('voice_enabled', state.voiceEnabled);
        await databaseService.setPreference('camera_enabled', state.cameraEnabled);
        await databaseService.setPreference('notifications_enabled', state.notificationsEnabled);
        await databaseService.setPreference('analytics_enabled', state.analyticsEnabled);
      }
    } catch (e) {
      final errorService = ref.read(errorServiceProvider);
      errorService.reportErrorWithContext(e, null, context: 'Save Settings');
    }
  }
}

class VoiceRecognitionNotifier extends StateNotifier<VoiceRecognitionState> {
  final Ref ref;

  VoiceRecognitionNotifier(this.ref) : super(VoiceRecognitionState.idle()) {
    _listenToVoiceService();
  }

  void _listenToVoiceService() {
    ref.listen(voiceRecognitionStreamProvider, (previous, next) {
      next.when(
        data: (result) {
          state = VoiceRecognitionState.recognized(result);
          
          // Auto-add detected ingredients
          if (result.detectedIngredients.isNotEmpty) {
            final matchingService = ref.read(matchingServiceProvider);
            matchingService.whenData((service) {
              ref.read(selectedIngredientsProvider.notifier)
                  .addIngredientsFromList(result.detectedIngredients, service.ingredientById);
            });
          }
        },
        loading: () {
          state = VoiceRecognitionState.listening();
        },
        error: (error, stack) {
          state = VoiceRecognitionState.error(error.toString());
        },
      );
    });
  }

  Future<void> startListening() async {
    try {
      final voiceService = ref.read(voiceServiceProvider);
      if (!voiceService.isInitialized) {
        await voiceService.initialize();
      }
      
      state = VoiceRecognitionState.listening();
      await voiceService.startListening();
    } catch (e) {
      state = VoiceRecognitionState.error(e.toString());
    }
  }

  Future<void> stopListening() async {
    try {
      final voiceService = ref.read(voiceServiceProvider);
      await voiceService.stopListening();
      state = VoiceRecognitionState.idle();
    } catch (e) {
      state = VoiceRecognitionState.error(e.toString());
    }
  }
}

class CameraStateNotifier extends StateNotifier<CameraState> {
  final Ref ref;

  CameraStateNotifier(this.ref) : super(CameraState.idle());

  Future<void> initializeCamera() async {
    try {
      state = CameraState.initializing();
      
      final cameraService = ref.read(cameraServiceProvider);
      final initialized = await cameraService.initialize();
      
      if (initialized) {
        state = CameraState.ready();
      } else {
        state = CameraState.error('Kamera başlatılamadı');
      }
    } catch (e) {
      state = CameraState.error(e.toString());
    }
  }

  Future<void> takePicture() async {
    try {
      state = CameraState.capturing();
      
      final cameraService = ref.read(cameraServiceProvider);
      final result = await cameraService.takePictureAndAnalyze();
      
      if (result.success) {
        state = CameraState.analyzed(result);
        
        // Auto-add detected ingredients
        if (result.detectedIngredients.isNotEmpty) {
          final ingredientIds = result.detectedIngredients.map((i) => i.ingredientId).toSet();
          ref.read(selectedIngredientsProvider.notifier).setIngredients(
            {...ref.read(selectedIngredientsProvider), ...ingredientIds}
          );
        }
      } else {
        state = CameraState.error(result.error ?? 'Fotoğraf analizi başarısız');
      }
    } catch (e) {
      state = CameraState.error(e.toString());
    }
  }

  void resetCamera() {
    state = CameraState.idle();
  }
}

// Data classes for state management
class AppSettings {
  final String language;
  final ThemeMode theme;
  final bool voiceEnabled;
  final bool cameraEnabled;
  final bool notificationsEnabled;
  final bool analyticsEnabled;

  const AppSettings({
    required this.language,
    required this.theme,
    required this.voiceEnabled,
    required this.cameraEnabled,
    required this.notificationsEnabled,
    required this.analyticsEnabled,
  });

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      language: 'tr',
      theme: ThemeMode.system,
      voiceEnabled: true,
      cameraEnabled: true,
      notificationsEnabled: true,
      analyticsEnabled: false,
    );
  }

  AppSettings copyWith({
    String? language,
    ThemeMode? theme,
    bool? voiceEnabled,
    bool? cameraEnabled,
    bool? notificationsEnabled,
    bool? analyticsEnabled,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}

// Voice Recognition State
class VoiceRecognitionState {
  final VoiceRecognitionStatus status;
  final VoiceRecognitionResult? result;
  final String? error;

  const VoiceRecognitionState._(this.status, {this.result, this.error});

  factory VoiceRecognitionState.idle() => const VoiceRecognitionState._(VoiceRecognitionStatus.idle);
  factory VoiceRecognitionState.listening() => const VoiceRecognitionState._(VoiceRecognitionStatus.listening);
  factory VoiceRecognitionState.recognized(VoiceRecognitionResult result) => 
      VoiceRecognitionState._(VoiceRecognitionStatus.recognized, result: result);
  factory VoiceRecognitionState.error(String error) => 
      VoiceRecognitionState._(VoiceRecognitionStatus.error, error: error);
}

enum VoiceRecognitionStatus { idle, listening, recognized, error }

// Camera State
class CameraState {
  final CameraStatus status;
  final CameraAnalysisResult? result;
  final String? error;

  const CameraState._(this.status, {this.result, this.error});

  factory CameraState.idle() => const CameraState._(CameraStatus.idle);
  factory CameraState.initializing() => const CameraState._(CameraStatus.initializing);
  factory CameraState.ready() => const CameraState._(CameraStatus.ready);
  factory CameraState.capturing() => const CameraState._(CameraStatus.capturing);
  factory CameraState.analyzed(CameraAnalysisResult result) => 
      CameraState._(CameraStatus.analyzed, result: result);
  factory CameraState.error(String error) => 
      CameraState._(CameraStatus.error, error: error);
}

enum CameraStatus { idle, initializing, ready, capturing, analyzed, error }