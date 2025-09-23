import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/models.dart';
import 'matching_service.dart';

/// Lightweight AI layer over the classic [MatchingService].
///
/// It tries to use a local TensorFlow Lite model if available. If model loading
/// fails (e.g. placeholder model or missing file), it seamlessly falls back to
/// an improved heuristic scoring that accounts for substitutions, user
/// preferences and diet filters.
class UserProfile {
  final Set<String> favoriteRecipeIds;
  final String? dietPreference; // e.g., 'vegan', 'vegetarian'
  const UserProfile({this.favoriteRecipeIds = const {}, this.dietPreference});
}

class AIService {
  final MatchingService classic;
  final Interpreter? _interpreter;
  final Map<String, Map<String, double>> _learnedSubstituteBonusByIngredient = <String, Map<String, double>>{};

  bool get isAiAvailable => _interpreter != null;

  AIService._({required this.classic, required Interpreter? interpreter}) : _interpreter = interpreter;

  static Future<AIService> bootstrap() async {
    final classic = await MatchingService.loadFromAssets();
    Interpreter? interpreter;
    try {
      // Will throw if asset is a placeholder or missing; we catch and fallback.
      interpreter = await Interpreter.fromAsset('assets/data/ai_matcher.tflite');
      // Try a tiny warm-up with a best-effort shape. If it fails, disable AI.
      try {
        final inputShape = interpreter.getInputTensor(0).shape;
        final length = inputShape.fold<int>(1, (p, e) => p * e);
        final input = List<double>.filled(length, 0);
        final outputs = <int, Object>{};
        final outputShape = interpreter.getOutputTensor(0).shape;
        final outLen = outputShape.fold<int>(1, (p, e) => p * e);
        outputs[0] = List<double>.filled(outLen, 0);
        interpreter.runForMultipleInputs([input], outputs);
      } catch (_) {
        interpreter.close();
        interpreter = null;
      }
    } catch (_) {
      interpreter = null;
    }

    return AIService._(classic: classic, interpreter: interpreter);
  }

  /// Public API to compute AI-powered matches.
  /// If AI model isn't usable, falls back to improved heuristic scoring.
  Future<List<MatchResult>> matchSmart({
    required Set<String> userIngredientIds,
    MatchFilters filters = const MatchFilters(),
    UserProfile userProfile = const UserProfile(),
    Duration timeout = const Duration(seconds: 3),
  }) async {
    // Start with classic results and then blend AI/personalization signals.
    final baseResults = classic.match(userIngredientIds: userIngredientIds, filters: filters);

    Future<List<MatchResult>> compute() async {
      final subMap = _buildSubstitutionMap();
      final enhanced = <MatchResult>[];

      for (final r in baseResults) {
        int bonus = 0;

        // Personalization: favorites and diet.
        if (userProfile.favoriteRecipeIds.contains(r.recipe.id)) {
          bonus += 10; // strong bias for favorites
        }
        if (userProfile.dietPreference != null && r.recipe.dietTags.contains(userProfile.dietPreference)) {
          bonus += 6; // prioritize matching diet
        }

        // Learned substitutions: if any missing ingredient has a known
        // substitution that the user possesses, grant dynamic credit.
        for (final ri in r.recipe.ingredients) {
          if (userIngredientIds.contains(ri.ingredientId)) continue;
          final substitutes = subMap[ri.ingredientId] ?? const <Substitution>[];
          for (final s in substitutes) {
            if (userIngredientIds.contains(s.substituteId)) {
              final learned = _learnedSubstituteBonusByIngredient[ri.ingredientId]?[s.substituteId] ?? 0.0;
              // Base partial credit from static strength plus learned bonus.
              final partial = (2.0 * s.strength + learned).clamp(0.0, 3.0);
              bonus += partial.round();
              break;
            }
          }
        }

        // If AI model exists and is usable, try to get a small additional boost
        // based on ingredient coverage representation.
        final aiBoost = await _predictBoostSafe(userIngredientIds: userIngredientIds, recipe: r.recipe);
        if (aiBoost != null) {
          bonus += aiBoost;
        }

        enhanced.add(MatchResult(recipe: r.recipe, score: r.score + bonus, missingIngredientIds: r.missingIngredientIds));
      }

      enhanced.sort((a, b) => b.score.compareTo(a.score));
      return enhanced;
    }

    try {
      return await compute().timeout(timeout);
    } on TimeoutException {
      // As per requirement: cap matching around ~3s; fallback to base.
      return baseResults;
    } catch (_) {
      // Safety net: never fail the user experience.
      return baseResults;
    }
  }

  /// Record user feedback to improve substitution bonuses over time.
  /// This simply adjusts local weights; persist externally if desired.
  Future<void> learnFromFeedback({
    required String recipeId,
    required bool liked,
    List<Map<String, String>> usedSubstitutions = const <Map<String, String>>[],
  }) async {
    // Simple perceptron-like update rule on bonuses.
    final delta = liked ? 0.2 : -0.2; // bounded and conservative updates
    for (final pair in usedSubstitutions) {
      final ing = pair['ingredient_id'];
      final sub = pair['substitute_id'];
      if (ing == null || sub == null) continue;
      final bySub = _learnedSubstituteBonusByIngredient.putIfAbsent(ing, () => <String, double>{});
      final updated = (bySub[sub] ?? 0.0) + delta;
      bySub[sub] = updated.clamp(-1.0, 1.0);
    }
  }

  /// Export/import learned substitution bonuses for a future online training
  /// pipeline (e.g., Firebase). These snapshots can be persisted and later
  /// merged on the server.
  Map<String, dynamic> exportLearningSnapshot() {
    final out = <String, dynamic>{};
    _learnedSubstituteBonusByIngredient.forEach((ing, bySub) {
      out[ing] = bySub.map((k, v) => MapEntry(k, v));
    });
    return out;
  }

  void importLearningSnapshot(Map<String, dynamic> snapshot) {
    for (final entry in snapshot.entries) {
      final ing = entry.key;
      final bySub = <String, double>{};
      final map = entry.value as Map<String, dynamic>;
      map.forEach((k, v) {
        bySub[k] = (v as num).toDouble();
      });
      _learnedSubstituteBonusByIngredient[ing] = bySub;
    }
  }

  // ---------- Internals ----------

  Map<String, List<Substitution>> _buildSubstitutionMap() {
    final map = <String, List<Substitution>>{};
    for (final s in classic.substitutions) {
      map.putIfAbsent(s.ingredientId, () => <Substitution>[]).add(s);
    }
    return map;
  }

  Future<int?> _predictBoostSafe({required Set<String> userIngredientIds, required Recipe recipe}) async {
    if (_interpreter == null) return null;
    try {
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape; // e.g., [1, N] or [N]
      final ingredientUniverse = _collectIngredientUniverse();
      final n = ingredientUniverse.length;

      // Build a simple coverage vector: +1 if user has an ingredient the recipe needs,
      // 0 otherwise. Length fits min(n, expectedLen). If expected is larger, pad zeros.
      final expectedLen = inputShape.fold<int>(1, (p, e) => p * e);
      final vec = List<double>.filled(max(expectedLen, n), 0);

      final recipeIngredientIds = recipe.ingredients.map((ri) => ri.ingredientId).toSet();
      int i = 0;
      for (final id in ingredientUniverse) {
        if (i >= vec.length) break;
        vec[i] = (recipeIngredientIds.contains(id) && userIngredientIds.contains(id)) ? 1.0 : 0.0;
        i++;
      }

      final outputs = <int, Object>{};
      final outLen = _interpreter!.getOutputTensor(0).shape.fold<int>(1, (p, e) => p * e);
      outputs[0] = List<double>.filled(outLen, 0);

      _interpreter!.runForMultipleInputs([vec], outputs);

      final raw = outputs[0];
      if (raw is List) {
        // Convert mean of outputs to a small integer boost in [0, 8]
        final flat = _flattenDoubles(raw);
        if (flat.isEmpty) return null;
        final mean = flat.reduce((a, b) => a + b) / flat.length;
        return (mean * 8).round().clamp(0, 8);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<String> _collectIngredientUniverse() {
    return classic.ingredientById.keys.toList()..sort();
  }

  static List<double> _flattenDoubles(Object data) {
    final out = <double>[];
    void walk(Object o) {
      if (o is List) {
        for (final v in o) {
          walk(v as Object);
        }
      } else if (o is double) {
        out.add(o);
      } else if (o is num) {
        out.add(o.toDouble());
      }
    }
    walk(data);
    return out;
  }
}

/// Riverpod provider for the AI service.
final aiServiceProvider = FutureProvider<AIService>((ref) async {
  return AIService.bootstrap();
});

