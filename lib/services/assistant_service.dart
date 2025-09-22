import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_shortcuts/flutter_app_shortcuts.dart';
import 'voice_service.dart';
import 'matching_service.dart';
import '../models/models.dart';

class AssistantService {
  static AssistantService? _instance;
  static AssistantService get instance => _instance ??= AssistantService._();
  AssistantService._();

  static const MethodChannel _channel = MethodChannel('ne_yesem/assistant');
  
  bool _isInitialized = false;
  final StreamController<AssistantResponse> _responseController = 
      StreamController<AssistantResponse>.broadcast();

  bool get isInitialized => _isInitialized;
  Stream<AssistantResponse> get responseStream => _responseController.stream;

  /// Initialize assistant service
  Future<bool> initialize() async {
    try {
      // Setup app shortcuts for quick access
      await _setupAppShortcuts();
      
      // Setup method channel handlers
      _channel.setMethodCallHandler(_handleMethodCall);
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Assistant service initialization error: $e');
      return false;
    }
  }

  /// Setup app shortcuts for quick access
  Future<void> _setupAppShortcuts() async {
    try {
      await FlutterAppShortcuts.initialize(
        shortcuts: [
          AppShortcut(
            id: 'add_ingredients',
            shortLabel: 'Malzeme Ekle',
            longLabel: 'Sesle Malzeme Ekle',
            iconResourceName: 'ic_add_ingredients',
            action: 'ADD_INGREDIENTS',
          ),
          AppShortcut(
            id: 'find_recipes',
            shortLabel: 'Tarif Bul',
            longLabel: 'Hızlı Tarif Bul',
            iconResourceName: 'ic_find_recipes',
            action: 'FIND_RECIPES',
          ),
          AppShortcut(
            id: 'voice_search',
            shortLabel: 'Sesli Arama',
            longLabel: 'Sesle Ne Yesem?',
            iconResourceName: 'ic_voice_search',
            action: 'VOICE_SEARCH',
          ),
          AppShortcut(
            id: 'quick_recipe',
            shortLabel: 'Hızlı Tarif',
            longLabel: '15 Dakikada Tarif',
            iconResourceName: 'ic_quick_recipe',
            action: 'QUICK_RECIPE',
          ),
        ],
      );
    } catch (e) {
      debugPrint('App shortcuts setup error: $e');
    }
  }

  /// Handle method calls from native platforms
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'handleSiriIntent':
        return await _handleSiriIntent(call.arguments);
      case 'handleGoogleAssistantIntent':
        return await _handleGoogleAssistantIntent(call.arguments);
      case 'handleAppShortcut':
        return await _handleAppShortcut(call.arguments);
      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  /// Handle Siri intents
  Future<Map<String, dynamic>> _handleSiriIntent(Map<dynamic, dynamic> arguments) async {
    try {
      final intentName = arguments['intentName'] as String?;
      final parameters = arguments['parameters'] as Map<dynamic, dynamic>? ?? {};

      AssistantResponse response;

      switch (intentName) {
        case 'AddIngredientsIntent':
          response = await _handleAddIngredientsIntent(parameters);
          break;
        case 'FindRecipesIntent':
          response = await _handleFindRecipesIntent(parameters);
          break;
        case 'GetQuickRecipeIntent':
          response = await _handleQuickRecipeIntent(parameters);
          break;
        default:
          response = AssistantResponse(
            type: AssistantResponseType.error,
            message: 'Bilinmeyen komut: $intentName',
            data: {},
          );
      }

      _responseController.add(response);
      return response.toMap();
    } catch (e) {
      final errorResponse = AssistantResponse(
        type: AssistantResponseType.error,
        message: 'Siri komutu işlenirken hata oluştu: $e',
        data: {},
      );
      _responseController.add(errorResponse);
      return errorResponse.toMap();
    }
  }

  /// Handle Google Assistant intents
  Future<Map<String, dynamic>> _handleGoogleAssistantIntent(Map<dynamic, dynamic> arguments) async {
    try {
      final action = arguments['action'] as String?;
      final parameters = arguments['parameters'] as Map<dynamic, dynamic>? ?? {};

      AssistantResponse response;

      switch (action) {
        case 'ADD_INGREDIENTS':
          response = await _handleAddIngredientsIntent(parameters);
          break;
        case 'FIND_RECIPES':
          response = await _handleFindRecipesIntent(parameters);
          break;
        case 'QUICK_RECIPE':
          response = await _handleQuickRecipeIntent(parameters);
          break;
        default:
          response = AssistantResponse(
            type: AssistantResponseType.error,
            message: 'Bilinmeyen aksiyon: $action',
            data: {},
          );
      }

      _responseController.add(response);
      return response.toMap();
    } catch (e) {
      final errorResponse = AssistantResponse(
        type: AssistantResponseType.error,
        message: 'Google Assistant komutu işlenirken hata oluştu: $e',
        data: {},
      );
      _responseController.add(errorResponse);
      return errorResponse.toMap();
    }
  }

  /// Handle app shortcuts
  Future<Map<String, dynamic>> _handleAppShortcut(Map<dynamic, dynamic> arguments) async {
    try {
      final shortcutId = arguments['shortcutId'] as String?;
      
      AssistantResponse response;

      switch (shortcutId) {
        case 'add_ingredients':
          response = await _startVoiceIngredientInput();
          break;
        case 'find_recipes':
          response = await _handleFindRecipesIntent({});
          break;
        case 'voice_search':
          response = await _startVoiceSearch();
          break;
        case 'quick_recipe':
          response = await _handleQuickRecipeIntent({'maxTime': 15});
          break;
        default:
          response = AssistantResponse(
            type: AssistantResponseType.error,
            message: 'Bilinmeyen kısayol: $shortcutId',
            data: {},
          );
      }

      _responseController.add(response);
      return response.toMap();
    } catch (e) {
      final errorResponse = AssistantResponse(
        type: AssistantResponseType.error,
        message: 'Kısayol işlenirken hata oluştu: $e',
        data: {},
      );
      _responseController.add(errorResponse);
      return errorResponse.toMap();
    }
  }

  /// Handle add ingredients intent
  Future<AssistantResponse> _handleAddIngredientsIntent(Map<dynamic, dynamic> parameters) async {
    try {
      final ingredientsText = parameters['ingredients'] as String?;
      
      if (ingredientsText == null || ingredientsText.isEmpty) {
        // Start voice input for ingredients
        return await _startVoiceIngredientInput();
      }

      // Parse ingredients from text
      final ingredients = VoiceService.instance.parseIngredientsFromSpeech(ingredientsText);
      
      if (ingredients.isEmpty) {
        return AssistantResponse(
          type: AssistantResponseType.clarification,
          message: 'Hangi malzemeleri eklemek istiyorsunuz? Örneğin: "domates, yumurta, peynir"',
          data: {'action': 'add_ingredients'},
        );
      }

      return AssistantResponse(
        type: AssistantResponseType.success,
        message: 'Şu malzemeler eklendi: ${ingredients.join(", ")}',
        data: {
          'action': 'ingredients_added',
          'ingredients': ingredients,
        },
      );
    } catch (e) {
      return AssistantResponse(
        type: AssistantResponseType.error,
        message: 'Malzemeler eklenirken hata oluştu: $e',
        data: {},
      );
    }
  }

  /// Handle find recipes intent
  Future<AssistantResponse> _handleFindRecipesIntent(Map<dynamic, dynamic> parameters) async {
    try {
      final maxTime = parameters['maxTime'] as int?;
      final diet = parameters['diet'] as String?;
      final ingredients = parameters['ingredients'] as List<String>? ?? [];

      if (ingredients.isEmpty) {
        return AssistantResponse(
          type: AssistantResponseType.clarification,
          message: 'Hangi malzemeleriniz var? Sesle söyleyebilir veya yazabilirsiniz.',
          data: {'action': 'need_ingredients'},
        );
      }

      // Load matching service and find recipes
      final matchingService = await MatchingService.loadFromAssets();
      final ingredientIds = _mapIngredientsToIds(ingredients, matchingService.ingredientById);
      
      final filters = MatchFilters(
        maxTimeMinutes: maxTime,
        diet: diet,
      );

      final results = matchingService.match(
        userIngredientIds: ingredientIds.toSet(),
        filters: filters,
      );

      if (results.isEmpty) {
        return AssistantResponse(
          type: AssistantResponseType.noResults,
          message: 'Bu malzemelerle uygun tarif bulunamadı. Başka malzemeler eklemek ister misiniz?',
          data: {'ingredients': ingredients},
        );
      }

      final topRecipe = results.first;
      return AssistantResponse(
        type: AssistantResponseType.recipeFound,
        message: 'En uygun tarif: ${topRecipe.recipe.name} (${topRecipe.recipe.timeMin} dakika)',
        data: {
          'recipe': topRecipe.recipe,
          'score': topRecipe.score,
          'allResults': results.take(3).toList(),
        },
      );
    } catch (e) {
      return AssistantResponse(
        type: AssistantResponseType.error,
        message: 'Tarif aranırken hata oluştu: $e',
        data: {},
      );
    }
  }

  /// Handle quick recipe intent
  Future<AssistantResponse> _handleQuickRecipeIntent(Map<dynamic, dynamic> parameters) async {
    try {
      final maxTime = parameters['maxTime'] as int? ?? 15;
      
      // Load matching service
      final matchingService = await MatchingService.loadFromAssets();
      
      // Get all quick recipes (under specified time)
      final quickRecipes = matchingService.recipes
          .where((recipe) => recipe.timeMin <= maxTime)
          .toList();

      if (quickRecipes.isEmpty) {
        return AssistantResponse(
          type: AssistantResponseType.noResults,
          message: '$maxTime dakikada yapılabilecek tarif bulunamadı.',
          data: {'maxTime': maxTime},
        );
      }

      // Sort by popularity and time
      quickRecipes.sort((a, b) {
        final scoreA = a.popularityScore - a.timeMin;
        final scoreB = b.popularityScore - b.timeMin;
        return scoreB.compareTo(scoreA);
      });

      final topRecipe = quickRecipes.first;
      return AssistantResponse(
        type: AssistantResponseType.recipeFound,
        message: '$maxTime dakikada yapabileceğiniz en iyi tarif: ${topRecipe.name}',
        data: {
          'recipe': topRecipe,
          'allQuickRecipes': quickRecipes.take(5).toList(),
        },
      );
    } catch (e) {
      return AssistantResponse(
        type: AssistantResponseType.error,
        message: 'Hızlı tarif aranırken hata oluştu: $e',
        data: {},
      );
    }
  }

  /// Start voice ingredient input
  Future<AssistantResponse> _startVoiceIngredientInput() async {
    try {
      final voiceService = VoiceService.instance;
      
      if (!voiceService.isInitialized) {
        final initialized = await voiceService.initialize();
        if (!initialized) {
          return AssistantResponse(
            type: AssistantResponseType.error,
            message: 'Ses tanıma servisi başlatılamadı. Mikrofon iznini kontrol edin.',
            data: {},
          );
        }
      }

      // Start listening
      await voiceService.speak('Hangi malzemeleriniz var? Dinliyorum...');
      final started = await voiceService.startListening();
      
      if (!started) {
        return AssistantResponse(
          type: AssistantResponseType.error,
          message: 'Ses tanıma başlatılamadı.',
          data: {},
        );
      }

      return AssistantResponse(
        type: AssistantResponseType.listening,
        message: 'Malzemelerinizi söyleyebilirsiniz...',
        data: {'action': 'voice_listening'},
      );
    } catch (e) {
      return AssistantResponse(
        type: AssistantResponseType.error,
        message: 'Sesli giriş başlatılırken hata oluştu: $e',
        data: {},
      );
    }
  }

  /// Start general voice search
  Future<AssistantResponse> _startVoiceSearch() async {
    try {
      final voiceService = VoiceService.instance;
      
      if (!voiceService.isInitialized) {
        final initialized = await voiceService.initialize();
        if (!initialized) {
          return AssistantResponse(
            type: AssistantResponseType.error,
            message: 'Ses tanıma servisi başlatılamadı.',
            data: {},
          );
        }
      }

      await voiceService.speak('Ne yapmak istiyorsunuz?');
      final started = await voiceService.startListening();
      
      if (!started) {
        return AssistantResponse(
          type: AssistantResponseType.error,
          message: 'Ses tanıma başlatılamadı.',
          data: {},
        );
      }

      return AssistantResponse(
        type: AssistantResponseType.listening,
        message: 'Komutunuzu bekliyorum...',
        data: {'action': 'general_voice_search'},
      );
    } catch (e) {
      return AssistantResponse(
        type: AssistantResponseType.error,
        message: 'Sesli arama başlatılırken hata oluştu: $e',
        data: {},
      );
    }
  }

  /// Map ingredient names to IDs
  List<String> _mapIngredientsToIds(List<String> ingredientNames, Map<String, Ingredient> ingredientById) {
    final ids = <String>[];
    
    for (final name in ingredientNames) {
      final lowerName = name.toLowerCase();
      
      // Find exact match or alias match
      for (final ingredient in ingredientById.values) {
        if (ingredient.name.toLowerCase() == lowerName ||
            ingredient.aliases.any((alias) => alias.toLowerCase() == lowerName)) {
          ids.add(ingredient.id);
          break;
        }
      }
    }
    
    return ids;
  }

  /// Process voice command
  Future<AssistantResponse> processVoiceCommand(String command) async {
    final voiceCommand = VoiceCommand.parse(command);
    
    switch (voiceCommand.type) {
      case VoiceCommandType.addIngredients:
        return await _handleAddIngredientsIntent({
          'ingredients': voiceCommand.parameters['ingredients']?.join(', ') ?? '',
        });
      case VoiceCommandType.findRecipes:
        return await _handleFindRecipesIntent(voiceCommand.parameters);
      case VoiceCommandType.quickRecipe:
        return await _handleQuickRecipeIntent(voiceCommand.parameters);
      case VoiceCommandType.vegetarianRecipe:
        return await _handleFindRecipesIntent(voiceCommand.parameters);
      case VoiceCommandType.timeConstraint:
        return await _handleQuickRecipeIntent(voiceCommand.parameters);
      default:
        return AssistantResponse(
          type: AssistantResponseType.clarification,
          message: 'Komutunuzu anlayamadım. "Malzemeler: domates, yumurta" veya "Tarif öner" diyebilirsiniz.',
          data: {'originalCommand': command},
        );
    }
  }

  /// Dispose resources
  void dispose() {
    _responseController.close();
  }
}

// Assistant response types
enum AssistantResponseType {
  success,
  error,
  clarification,
  noResults,
  recipeFound,
  listening,
}

class AssistantResponse {
  final AssistantResponseType type;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  AssistantResponse({
    required this.type,
    required this.message,
    required this.data,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'message': message,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AssistantResponse.fromMap(Map<String, dynamic> map) {
    return AssistantResponse(
      type: AssistantResponseType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AssistantResponseType.error,
      ),
      message: map['message'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }
}

// App shortcut data class
class AppShortcut {
  final String id;
  final String shortLabel;
  final String longLabel;
  final String iconResourceName;
  final String action;

  AppShortcut({
    required this.id,
    required this.shortLabel,
    required this.longLabel,
    required this.iconResourceName,
    required this.action,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shortLabel': shortLabel,
      'longLabel': longLabel,
      'iconResourceName': iconResourceName,
      'action': action,
    };
  }
}