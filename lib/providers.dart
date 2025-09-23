import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/models.dart';
import 'services/matching_service.dart';
import 'services/ai_service.dart';

final matchingServiceProvider = FutureProvider<MatchingService>((ref) async {
  return MatchingService.loadFromAssets();
});

final aiServiceProvider = FutureProvider<AIService>((ref) async {
  return AIService.loadFromAssets();
});

final favoriteRecipeIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

final matchFiltersProvider = StateProvider<MatchFilters>((ref) => const MatchFilters());

