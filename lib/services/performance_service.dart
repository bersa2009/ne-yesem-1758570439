import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'matching_service.dart';

class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance => _instance ??= PerformanceService._();
  PerformanceService._();

  final Map<String, PerformanceMetric> _metrics = {};
  final List<ErrorReport> _errorReports = [];
  final StreamController<PerformanceReport> _reportController = 
      StreamController<PerformanceReport>.broadcast();

  Stream<PerformanceReport> get reportStream => _reportController.stream;

  /// Start performance tracking for an operation
  void startTracking(String operationName) {
    _metrics[operationName] = PerformanceMetric(
      name: operationName,
      startTime: DateTime.now(),
    );
  }

  /// End performance tracking for an operation
  void endTracking(String operationName, {bool success = true, String? error}) {
    final metric = _metrics[operationName];
    if (metric == null) return;

    metric.endTime = DateTime.now();
    metric.duration = metric.endTime!.difference(metric.startTime);
    metric.success = success;
    metric.error = error;

    // Report performance issue if operation took too long
    if (metric.duration.inSeconds > 3) {
      _reportPerformanceIssue(metric);
    }
  }

  /// Track memory usage
  void trackMemoryUsage(String context) {
    // This would use platform-specific memory tracking
    // For now, we'll use a placeholder implementation
    _metrics['memory_$context'] = PerformanceMetric(
      name: 'memory_$context',
      startTime: DateTime.now(),
      memoryUsage: _getCurrentMemoryUsage(),
    );
  }

  /// Get current memory usage (placeholder)
  int _getCurrentMemoryUsage() {
    // In a real implementation, this would call platform-specific APIs
    // For now, return a mock value
    return 50 * 1024 * 1024; // 50MB placeholder
  }

  /// Report performance issue
  void _reportPerformanceIssue(PerformanceMetric metric) {
    final report = PerformanceReport(
      type: PerformanceIssueType.slowOperation,
      message: 'Operation ${metric.name} took ${metric.duration.inSeconds}s',
      metric: metric,
      timestamp: DateTime.now(),
    );

    _reportController.add(report);
  }

  /// Run recipe matching in isolate for better performance
  static Future<List<MatchResult>> matchRecipesInIsolate({
    required Set<String> userIngredientIds,
    required MatchFilters filters,
    required Map<String, Ingredient> ingredientById,
    required List<Recipe> recipes,
    required List<Substitution> substitutions,
  }) async {
    final receivePort = ReceivePort();
    
    final isolateData = {
      'sendPort': receivePort.sendPort,
      'userIngredientIds': userIngredientIds.toList(),
      'filters': _filtersToMap(filters),
      'ingredientById': ingredientById.map((k, v) => MapEntry(k, _ingredientToMap(v))),
      'recipes': recipes.map(_recipeToMap).toList(),
      'substitutions': substitutions.map(_substitutionToMap).toList(),
    };

    await Isolate.spawn(_matchRecipesIsolateEntry, isolateData);
    
    final completer = Completer<List<MatchResult>>();
    receivePort.listen((data) {
      if (data is List) {
        final results = data.map((item) => _mapToMatchResult(item)).toList();
        completer.complete(results);
      } else if (data is String && data.startsWith('error:')) {
        completer.completeError(data.substring(6));
      }
      receivePort.close();
    });

    return completer.future;
  }

  /// Isolate entry point for recipe matching
  static void _matchRecipesIsolateEntry(Map<String, dynamic> data) {
    try {
      final sendPort = data['sendPort'] as SendPort;
      final userIngredientIds = Set<String>.from(data['userIngredientIds']);
      final filters = _mapToFilters(data['filters']);
      
      // Reconstruct objects from maps
      final ingredientById = (data['ingredientById'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, _mapToIngredient(v)));
      final recipes = (data['recipes'] as List)
          .map((item) => _mapToRecipe(item))
          .toList();
      final substitutions = (data['substitutions'] as List)
          .map((item) => _mapToSubstitution(item))
          .toList();

      // Create matching service and perform matching
      final matchingService = MatchingService(
        ingredientById: ingredientById,
        recipes: recipes,
        substitutions: substitutions,
      );

      final results = matchingService.match(
        userIngredientIds: userIngredientIds,
        filters: filters,
      );

      // Convert results to maps for sending back
      final resultMaps = results.map(_matchResultToMap).toList();
      sendPort.send(resultMaps);
    } catch (e) {
      final sendPort = data['sendPort'] as SendPort;
      sendPort.send('error:$e');
    }
  }

  /// Optimize image for better performance
  static Future<Uint8List> optimizeImage(Uint8List imageBytes, {
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 80,
  }) async {
    return compute(_optimizeImageInCompute, {
      'imageBytes': imageBytes,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'quality': quality,
    });
  }

  /// Image optimization in compute isolate
  static Uint8List _optimizeImageInCompute(Map<String, dynamic> params) {
    // This would use image processing libraries like image package
    // For now, return original bytes as placeholder
    return params['imageBytes'] as Uint8List;
  }

  /// Debounce function for search optimization
  static Timer? _debounceTimer;
  static void debounce(Duration duration, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Cache management for better performance
  final Map<String, CacheEntry> _cache = {};
  
  void cacheData(String key, dynamic data, {Duration? ttl}) {
    _cache[key] = CacheEntry(
      data: data,
      createdAt: DateTime.now(),
      ttl: ttl ?? const Duration(minutes: 30),
    );
  }

  T? getCachedData<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (DateTime.now().difference(entry.createdAt) > entry.ttl) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data as T?;
  }

  void clearCache() {
    _cache.clear();
  }

  void clearExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => 
        now.difference(entry.createdAt) > entry.ttl);
  }

  /// Error reporting and handling
  void reportError(String context, dynamic error, StackTrace? stackTrace) {
    final errorReport = ErrorReport(
      context: context,
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
      deviceInfo: _getDeviceInfo(),
    );

    _errorReports.add(errorReport);
    
    // Keep only last 100 errors
    if (_errorReports.length > 100) {
      _errorReports.removeAt(0);
    }

    // Report critical errors
    if (_isCriticalError(error)) {
      _reportController.add(PerformanceReport(
        type: PerformanceIssueType.criticalError,
        message: 'Critical error in $context: $error',
        timestamp: DateTime.now(),
        errorReport: errorReport,
      ));
    }
  }

  bool _isCriticalError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('out of memory') ||
           errorString.contains('stackoverflow') ||
           errorString.contains('null pointer') ||
           errorString.contains('database');
  }

  Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': defaultTargetPlatform.name,
      'is_debug': kDebugMode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get performance statistics
  PerformanceStats getPerformanceStats() {
    final completedMetrics = _metrics.values.where((m) => m.endTime != null).toList();
    
    if (completedMetrics.isEmpty) {
      return PerformanceStats(
        averageResponseTime: Duration.zero,
        totalOperations: 0,
        successRate: 0.0,
        errorCount: _errorReports.length,
        cacheHitRate: 0.0,
      );
    }

    final totalDuration = completedMetrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    final averageMs = totalDuration / completedMetrics.length;
    final successCount = completedMetrics.where((m) => m.success).length;
    
    return PerformanceStats(
      averageResponseTime: Duration(milliseconds: averageMs.round()),
      totalOperations: completedMetrics.length,
      successRate: successCount / completedMetrics.length,
      errorCount: _errorReports.length,
      cacheHitRate: _calculateCacheHitRate(),
    );
  }

  double _calculateCacheHitRate() {
    // Placeholder implementation
    return 0.75; // 75% cache hit rate
  }

  /// Cleanup resources
  void dispose() {
    _debounceTimer?.cancel();
    _reportController.close();
    clearCache();
  }

  // Helper methods for isolate data conversion
  static Map<String, dynamic> _filtersToMap(MatchFilters filters) {
    return {
      'maxTimeMinutes': filters.maxTimeMinutes,
      'diet': filters.diet,
      'excludedEquipment': filters.excludedEquipment,
    };
  }

  static MatchFilters _mapToFilters(Map<String, dynamic> map) {
    return MatchFilters(
      maxTimeMinutes: map['maxTimeMinutes'],
      diet: map['diet'],
      excludedEquipment: List<String>.from(map['excludedEquipment'] ?? []),
    );
  }

  static Map<String, dynamic> _ingredientToMap(Ingredient ingredient) {
    return {
      'id': ingredient.id,
      'name': ingredient.name,
      'aliases': ingredient.aliases,
      'category': ingredient.category,
    };
  }

  static Ingredient _mapToIngredient(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      name: map['name'],
      aliases: List<String>.from(map['aliases']),
      category: map['category'],
    );
  }

  static Map<String, dynamic> _recipeToMap(Recipe recipe) {
    return {
      'id': recipe.id,
      'name': recipe.name,
      'description': recipe.description,
      'steps': recipe.steps,
      'timeMin': recipe.timeMin,
      'servings': recipe.servings,
      'difficulty': recipe.difficulty,
      'equipment': recipe.equipment,
      'dietTags': recipe.dietTags,
      'imageUrl': recipe.imageUrl,
      'popularityScore': recipe.popularityScore,
      'ingredients': recipe.ingredients.map(_recipeIngredientToMap).toList(),
    };
  }

  static Recipe _mapToRecipe(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      steps: List<String>.from(map['steps']),
      timeMin: map['timeMin'],
      servings: map['servings'],
      difficulty: map['difficulty'],
      equipment: List<String>.from(map['equipment']),
      dietTags: List<String>.from(map['dietTags']),
      imageUrl: map['imageUrl'],
      popularityScore: map['popularityScore'],
      ingredients: (map['ingredients'] as List)
          .map((item) => _mapToRecipeIngredient(item))
          .toList(),
    );
  }

  static Map<String, dynamic> _recipeIngredientToMap(RecipeIngredient ingredient) {
    return {
      'ingredientId': ingredient.ingredientId,
      'quantity': ingredient.quantity,
      'unit': ingredient.unit,
      'optional': ingredient.optional,
      'requiredFlag': ingredient.requiredFlag,
    };
  }

  static RecipeIngredient _mapToRecipeIngredient(Map<String, dynamic> map) {
    return RecipeIngredient(
      ingredientId: map['ingredientId'],
      quantity: map['quantity'],
      unit: map['unit'],
      optional: map['optional'],
      requiredFlag: map['requiredFlag'],
    );
  }

  static Map<String, dynamic> _substitutionToMap(Substitution substitution) {
    return {
      'ingredientId': substitution.ingredientId,
      'substituteId': substitution.substituteId,
      'strength': substitution.strength,
    };
  }

  static Substitution _mapToSubstitution(Map<String, dynamic> map) {
    return Substitution(
      ingredientId: map['ingredientId'],
      substituteId: map['substituteId'],
      strength: map['strength'],
    );
  }

  static Map<String, dynamic> _matchResultToMap(MatchResult result) {
    return {
      'recipe': _recipeToMap(result.recipe),
      'score': result.score,
      'missingIngredientIds': result.missingIngredientIds,
    };
  }

  static MatchResult _mapToMatchResult(Map<String, dynamic> map) {
    return MatchResult(
      recipe: _mapToRecipe(map['recipe']),
      score: map['score'],
      missingIngredientIds: List<String>.from(map['missingIngredientIds']),
    );
  }
}

// Performance data classes
class PerformanceMetric {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  Duration duration = Duration.zero;
  bool success = true;
  String? error;
  int? memoryUsage;

  PerformanceMetric({
    required this.name,
    required this.startTime,
    this.memoryUsage,
  });
}

class CacheEntry {
  final dynamic data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.createdAt,
    required this.ttl,
  });
}

class ErrorReport {
  final String context;
  final String error;
  final String? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic> deviceInfo;

  ErrorReport({
    required this.context,
    required this.error,
    this.stackTrace,
    required this.timestamp,
    required this.deviceInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'context': context,
      'error': error,
      'stack_trace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'device_info': deviceInfo,
    };
  }
}

enum PerformanceIssueType {
  slowOperation,
  memoryLeak,
  criticalError,
  cacheIssue,
}

class PerformanceReport {
  final PerformanceIssueType type;
  final String message;
  final DateTime timestamp;
  final PerformanceMetric? metric;
  final ErrorReport? errorReport;

  PerformanceReport({
    required this.type,
    required this.message,
    required this.timestamp,
    this.metric,
    this.errorReport,
  });
}

class PerformanceStats {
  final Duration averageResponseTime;
  final int totalOperations;
  final double successRate;
  final int errorCount;
  final double cacheHitRate;

  PerformanceStats({
    required this.averageResponseTime,
    required this.totalOperations,
    required this.successRate,
    required this.errorCount,
    required this.cacheHitRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'average_response_time_ms': averageResponseTime.inMilliseconds,
      'total_operations': totalOperations,
      'success_rate': successRate,
      'error_count': errorCount,
      'cache_hit_rate': cacheHitRate,
    };
  }
}