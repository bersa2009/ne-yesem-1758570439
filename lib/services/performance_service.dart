import 'dart:async';
import 'dart:isolate';
import '../models/models.dart';

class PerformanceService {
  static const int _maxConcurrentIsolates = 2;
  static const Duration _cacheExpiry = Duration(hours: 1);
  final Map<String, _CacheEntry> _cache = {};
  int _activeIsolates = 0;

  // Isolate-based matching for better performance
  Future<List<MatchResult>> matchRecipesIsolate(
    Set<String> userIngredientIds,
    MatchingService matchingService,
    MatchFilters filters,
  ) async {
    if (_activeIsolates >= _maxConcurrentIsolates) {
      // Fallback to main thread if too many isolates
      return matchingService.match(
        userIngredientIds: userIngredientIds,
        filters: filters,
      );
    }

    final completer = Completer<List<MatchResult>>();
    final receivePort = ReceivePort();

    _activeIsolates++;

    receivePort.listen((message) {
      _activeIsolates--;
      if (message is List<MatchResult>) {
        completer.complete(message);
      } else {
        completer.completeError(message);
      }
      receivePort.close();
    });

    await Isolate.spawn(
      _matchRecipesInIsolate,
      _IsolateData(
        userIngredientIds: userIngredientIds.toList(),
        recipes: matchingService.recipes,
        ingredientById: matchingService.ingredientById,
        substitutions: matchingService.substitutions,
        filters: filters,
        sendPort: receivePort.sendPort,
      ),
    );

    return completer.future;
  }

  // Cache management
  String _getCacheKey(Set<String> ingredients, MatchFilters filters) {
    final sortedIngredients = ingredients.toList()..sort();
    return '${sortedIngredients.join(',')}_${filters.maxTimeMinutes}_${filters.diet}';
  }

  List<MatchResult>? getCachedResults(Set<String> ingredients, MatchFilters filters) {
    final key = _getCacheKey(ingredients, filters);
    final entry = _cache[key];

    if (entry != null && DateTime.now().difference(entry.timestamp) < _cacheExpiry) {
      return entry.results;
    }

    _cache.remove(key);
    return null;
  }

  void cacheResults(Set<String> ingredients, MatchFilters filters, List<MatchResult> results) {
    final key = _getCacheKey(ingredients, filters);
    _cache[key] = _CacheEntry(results: results, timestamp: DateTime.now());

    // Limit cache size
    if (_cache.length > 100) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }

  // Memory management
  void clearCache() {
    _cache.clear();
  }

  int get cacheSize => _cache.length;
}

// Isolate data structure
class _IsolateData {
  final List<String> userIngredientIds;
  final List<Recipe> recipes;
  final Map<String, Ingredient> ingredientById;
  final List<Substitution> substitutions;
  final MatchFilters filters;
  final SendPort sendPort;

  _IsolateData({
    required this.userIngredientIds,
    required this.recipes,
    required this.ingredientById,
    required this.substitutions,
    required this.filters,
    required this.sendPort,
  });
}

// Cache entry
class _CacheEntry {
  final List<MatchResult> results;
  final DateTime timestamp;

  _CacheEntry({required this.results, required this.timestamp});
}

// Isolate function
void _matchRecipesInIsolate(_IsolateData data) {
  try {
    // Rebuild matching service in isolate
    final service = MatchingService(
      ingredientById: data.ingredientById,
      recipes: data.recipes,
      substitutions: data.substitutions,
    );

    final results = service.match(
      userIngredientIds: data.userIngredientIds.toSet(),
      filters: data.filters,
    );

    data.sendPort.send(results);
  } catch (e) {
    data.sendPort.send(e);
  }
}