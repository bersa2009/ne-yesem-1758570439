import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../voice/voice_service.dart';

class AssistantService {
  static final AssistantService _instance = AssistantService._internal();
  factory AssistantService() => _instance;
  AssistantService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final VoiceService _voiceService = VoiceService();
  
  bool _isInitialized = false;

  // Initialize assistant services
  Future<bool> initialize() async {
    try {
      // Initialize notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);
      
      // Initialize voice service
      await _voiceService.initialize();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Assistant service initialization error: $e');
      return false;
    }
  }

  // Handle Siri shortcuts (iOS)
  Future<void> setupSiriShortcuts() async {
    try {
      // Register app intents for Siri
      const platform = MethodChannel('com.neyesem.app/siri');
      await platform.invokeMethod('setupShortcuts', {
        'shortcuts': [
          {
            'identifier': 'search_recipes',
            'phrase': 'Ne yesem tarif ara',
            'title': 'Tarif Ara',
            'description': 'Mevcut malzemelerle tarif ara'
          },
          {
            'identifier': 'add_ingredient',
            'phrase': 'Ne yesem malzeme ekle',
            'title': 'Malzeme Ekle',
            'description': 'Yeni malzeme ekle'
          },
          {
            'identifier': 'open_camera',
            'phrase': 'Ne yesem fotoğraf çek',
            'title': 'Fotoğraf Çek',
            'description': 'Malzeme fotoğrafı çek'
          }
        ]
      });
    } catch (e) {
      debugPrint('Siri shortcuts setup error: $e');
    }
  }

  // Handle Google Assistant actions (Android)
  Future<void> setupGoogleAssistant() async {
    try {
      const platform = MethodChannel('com.neyesem.app/assistant');
      await platform.invokeMethod('setupActions', {
        'actions': [
          {
            'name': 'search_recipes',
            'query': 'Ne yesem ile tarif ara',
            'description': 'Mevcut malzemelerle tarif ara'
          },
          {
            'name': 'add_ingredient',
            'query': 'Ne yesem ile malzeme ekle',
            'description': 'Yeni malzeme ekle'
          }
        ]
      });
    } catch (e) {
      debugPrint('Google Assistant setup error: $e');
    }
  }

  // Process assistant intents
  Future<void> processIntent(String action, Map<String, dynamic>? parameters) async {
    switch (action) {
      case 'search_recipes':
        await _handleSearchRecipes(parameters);
        break;
      case 'add_ingredient':
        await _handleAddIngredient(parameters);
        break;
      case 'open_camera':
        await _handleOpenCamera();
        break;
      case 'voice_command':
        await _handleVoiceCommand(parameters);
        break;
      default:
        debugPrint('Unknown intent: $action');
    }
  }

  // Handle search recipes intent
  Future<void> _handleSearchRecipes(Map<String, dynamic>? parameters) async {
    try {
      // Send notification to open app
      await _showNotification(
        'Tarif Arama',
        'Ne Yesem uygulamasında tarif aranıyor...',
        'search_recipes'
      );
      
      // Open app with deep link
      await _openAppWithAction('search_recipes');
    } catch (e) {
      debugPrint('Search recipes intent error: $e');
    }
  }

  // Handle add ingredient intent
  Future<void> _handleAddIngredient(Map<String, dynamic>? parameters) async {
    try {
      String? ingredient = parameters?['ingredient'];
      
      await _showNotification(
        'Malzeme Ekleme',
        ingredient != null 
          ? '$ingredient malzemesi ekleniyor...'
          : 'Malzeme ekleme ekranı açılıyor...',
        'add_ingredient'
      );
      
      await _openAppWithAction('add_ingredient', {'ingredient': ingredient});
    } catch (e) {
      debugPrint('Add ingredient intent error: $e');
    }
  }

  // Handle open camera intent
  Future<void> _handleOpenCamera() async {
    try {
      await _showNotification(
        'Kamera',
        'Malzeme fotoğrafı çekmek için kamera açılıyor...',
        'open_camera'
      );
      
      await _openAppWithAction('open_camera');
    } catch (e) {
      debugPrint('Open camera intent error: $e');
    }
  }

  // Handle voice command
  Future<void> _handleVoiceCommand(Map<String, dynamic>? parameters) async {
    try {
      String? command = parameters?['command'];
      if (command != null) {
        final voiceCommand = _voiceService.processVoiceCommand(command);
        if (voiceCommand != null) {
          await processIntent(_voiceCommandToAction(voiceCommand), parameters);
        }
      }
    } catch (e) {
      debugPrint('Voice command error: $e');
    }
  }

  // Convert voice command to action
  String _voiceCommandToAction(VoiceCommand command) {
    switch (command) {
      case VoiceCommand.searchRecipes:
        return 'search_recipes';
      case VoiceCommand.addIngredient:
        return 'add_ingredient';
      case VoiceCommand.openCamera:
        return 'open_camera';
      case VoiceCommand.openMenu:
        return 'open_menu';
      case VoiceCommand.goBack:
        return 'go_back';
      case VoiceCommand.help:
        return 'help';
    }
  }

  // Show notification
  Future<void> _showNotification(String title, String body, String payload) async {
    const androidDetails = AndroidNotificationDetails(
      'neyesem_channel',
      'Ne Yesem Bildirimleri',
      channelDescription: 'Ne Yesem uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Open app with specific action
  Future<void> _openAppWithAction(String action, [Map<String, dynamic>? parameters]) async {
    try {
      String url = 'neyesem://action/$action';
      if (parameters != null && parameters.isNotEmpty) {
        final queryParams = parameters.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        url += '?$queryParams';
      }
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Open app with action error: $e');
    }
  }

  // Get cooking suggestions based on time and context
  List<String> getCookingSuggestions({
    required List<String> availableIngredients,
    int? timeOfDay,
    String? mood,
  }) {
    List<String> suggestions = [];
    
    // Time-based suggestions
    final hour = timeOfDay ?? DateTime.now().hour;
    
    if (hour >= 6 && hour < 11) {
      // Breakfast suggestions
      suggestions.addAll([
        'Günaydın! Kahvaltı için menemen nasıl olur?',
        'Sabah için omlet önerim var.',
        'Tost ya da börek yapabilirsin.'
      ]);
    } else if (hour >= 11 && hour < 15) {
      // Lunch suggestions
      suggestions.addAll([
        'Öğle yemeği için pilav nasıl?',
        'Makarna yapsan güzel olur.',
        'Salata ile hafif bir öğle yemeği?'
      ]);
    } else if (hour >= 15 && hour < 18) {
      // Afternoon snack
      suggestions.addAll([
        'İkindi çayı için börek?',
        'Tatlı bir şeyler nasıl?'
      ]);
    } else {
      // Dinner suggestions
      suggestions.addAll([
        'Akşam için et yemeği nasıl?',
        'Çorba ile başlayalım mı?',
        'Sebze yemeği sağlıklı olur.'
      ]);
    }
    
    // Ingredient-based suggestions
    if (availableIngredients.contains('domates')) {
      suggestions.add('Domatesli yemekler harika olur!');
    }
    if (availableIngredients.contains('tavuk')) {
      suggestions.add('Tavuklu pilav her zaman iyi fikir.');
    }
    
    return suggestions.take(3).toList();
  }

  // Get smart recipe recommendations
  Map<String, dynamic> getSmartRecommendations({
    required List<String> userIngredients,
    List<String>? previousRecipes,
    String? dietaryPreference,
  }) {
    return {
      'quickRecipes': [
        'Hızlı omlet (5 dakika)',
        'Basit makarna (10 dakika)',
        'Pratik salata (5 dakika)'
      ],
      'healthyOptions': [
        'Sebze çorbası',
        'Izgara tavuk',
        'Mevsim salatası'
      ],
      'comfortFood': [
        'Ev yapımı pilav',
        'Sıcak çorba',
        'Geleneksel börek'
      ],
      'seasonal': _getSeasonalRecommendations(),
    };
  }

  // Get seasonal recipe recommendations
  List<String> _getSeasonalRecommendations() {
    final month = DateTime.now().month;
    
    if (month >= 3 && month <= 5) {
      // Spring
      return ['Bahar salatası', 'Taze fasulye', 'Enginar yemeği'];
    } else if (month >= 6 && month <= 8) {
      // Summer
      return ['Soğuk çorba', 'Meyve salatası', 'Izgara sebze'];
    } else if (month >= 9 && month <= 11) {
      // Autumn
      return ['Kabak çorbası', 'Etli sebze', 'Sıcak pilav'];
    } else {
      // Winter
      return ['Sıcak çorba', 'Etli yemek', 'Sıcak tatlı'];
    }
  }

  // Dispose resources
  void dispose() {
    _voiceService.dispose();
  }

  // Getters
  bool get isInitialized => _isInitialized;
}