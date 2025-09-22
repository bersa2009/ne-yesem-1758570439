import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/matching_service.dart';
import '../services/storage_service.dart';
import '../services/camera_service.dart';
import '../services/speech_service.dart';
import '../services/security_service.dart';

// State providers
final selectedIngredientsProvider = StateProvider<Set<String>>((ref) => <String>{});
final favoritesProvider = StateProvider<Set<String>>((ref) => <String>{});
final userPreferencesProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'language': 'tr',
  'theme': 'light',
  'notifications': true,
});

// Async providers
final matchingServiceProvider = FutureProvider<MatchingService>((ref) async {
  return MatchingService.loadFromAssets();
});

final ingredientsProvider = FutureProvider<List<Ingredient>>((ref) async {
  final service = await ref.watch(matchingServiceProvider.future);
  return service.ingredientById.values.toList();
});

final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final service = await ref.watch(matchingServiceProvider.future);
  return service.recipes;
});

// Storage providers
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Camera and Speech providers
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

// Security provider
final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

// Match results provider
final matchResultsProvider = StateProvider<List<MatchResult>>((ref) => []);