import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  // Callbacks
  Function(String)? onSpeechResult;
  Function(bool)? onListeningStateChanged;

  // Initialize voice services
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        return false;
      }

      // Initialize speech to text
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech error: $error');
          _isListening = false;
          onListeningStateChanged?.call(false);
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            onListeningStateChanged?.call(false);
          }
        },
      );

      // Configure TTS
      await _flutterTts.setLanguage('tr-TR');
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      return _speechEnabled;
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      return false;
    }
  }

  // Start listening for speech
  Future<void> startListening() async {
    if (!_speechEnabled) {
      await initialize();
    }

    if (_speechEnabled && !_isListening) {
      _isListening = true;
      onListeningStateChanged?.call(true);
      
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          onSpeechResult?.call(_lastWords);
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'tr_TR',
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  // Speak text
  Future<void> speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  // Process voice input for ingredients
  List<String> processIngredientsFromSpeech(String speechText) {
    final text = speechText.toLowerCase().trim();
    
    // Common Turkish ingredient keywords
    final ingredientKeywords = {
      'domates': ['domates', 'dometes'],
      'soğan': ['soğan', 'sogan'],
      'sarımsak': ['sarımsak', 'sarimsak'],
      'biber': ['biber', 'sivri biber', 'dolmalık biber'],
      'patates': ['patates', 'patates'],
      'havuç': ['havuç', 'havuc', 'karot'],
      'kabak': ['kabak', 'sakız kabağı'],
      'patlıcan': ['patlıcan', 'patlican'],
      'salatalık': ['salatalık', 'salatalik', 'hıyar'],
      'marul': ['marul', 'yeşillik'],
      'maydanoz': ['maydanoz'],
      'dereotu': ['dereotu', 'dere otu'],
      'nane': ['nane'],
      'et': ['et', 'kıyma', 'dana eti', 'kuzu eti'],
      'tavuk': ['tavuk', 'piliç'],
      'balık': ['balık', 'balik'],
      'yumurta': ['yumurta'],
      'peynir': ['peynir', 'beyaz peynir', 'kaşar'],
      'süt': ['süt', 'sut'],
      'yoğurt': ['yoğurt', 'yogurt'],
      'pirinç': ['pirinç', 'princ', 'pilav'],
      'makarna': ['makarna', 'spagetti'],
      'bulgur': ['bulgur'],
      'un': ['un', 'buğday unu'],
      'şeker': ['şeker', 'seker'],
      'tuz': ['tuz'],
      'karabiber': ['karabiber', 'kara biber', 'biber'],
      'zeytinyağı': ['zeytinyağı', 'zeytin yağı'],
      'tereyağı': ['tereyağı', 'tere yağı'],
      'limon': ['limon'],
      'elma': ['elma'],
      'muz': ['muz'],
      'portakal': ['portakal']
    };

    List<String> foundIngredients = [];
    
    for (String ingredient in ingredientKeywords.keys) {
      for (String keyword in ingredientKeywords[ingredient]!) {
        if (text.contains(keyword)) {
          if (!foundIngredients.contains(ingredient)) {
            foundIngredients.add(ingredient);
          }
          break;
        }
      }
    }

    return foundIngredients;
  }

  // Voice command processing
  VoiceCommand? processVoiceCommand(String speechText) {
    final text = speechText.toLowerCase().trim();

    if (text.contains('tarif ara') || text.contains('tarif bul')) {
      return VoiceCommand.searchRecipes;
    } else if (text.contains('malzeme ekle') || text.contains('malzeme add')) {
      return VoiceCommand.addIngredient;
    } else if (text.contains('fotoğraf çek') || text.contains('kamera aç')) {
      return VoiceCommand.openCamera;
    } else if (text.contains('menü aç') || text.contains('menu ac')) {
      return VoiceCommand.openMenu;
    } else if (text.contains('geri git') || text.contains('geri don')) {
      return VoiceCommand.goBack;
    } else if (text.contains('yardım') || text.contains('help')) {
      return VoiceCommand.help;
    }

    return null;
  }

  // Get available voice commands help text
  String getVoiceCommandsHelp() {
    return '''
Sesli Komutlar:
• "Malzeme ekle [malzeme adı]" - Malzeme ekler
• "Tarif ara" - Tarif arama yapar
• "Fotoğraf çek" - Kamera açar
• "Menü aç" - Ana menüyü açar
• "Geri git" - Önceki sayfaya döner
• "Yardım" - Bu yardım metnini okur
    ''';
  }

  // Getters
  bool get isListening => _isListening;
  bool get isEnabled => _speechEnabled;
  String get lastWords => _lastWords;

  // Dispose resources
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
}

enum VoiceCommand {
  searchRecipes,
  addIngredient,
  openCamera,
  openMenu,
  goBack,
  help,
}