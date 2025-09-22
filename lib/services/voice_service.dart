import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';

class VoiceService {
  static VoiceService? _instance;
  static VoiceService get instance => _instance ??= VoiceService._();
  VoiceService._();

  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = '';
  double _confidence = 0.0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastWords => _lastWords;
  double get confidence => _confidence;

  // Stream controllers for real-time updates
  final StreamController<VoiceRecognitionResult> _recognitionController = 
      StreamController<VoiceRecognitionResult>.broadcast();
  final StreamController<VoiceListeningState> _listeningController = 
      StreamController<VoiceListeningState>.broadcast();

  Stream<VoiceRecognitionResult> get recognitionStream => _recognitionController.stream;
  Stream<VoiceListeningState> get listeningStream => _listeningController.stream;

  /// Initialize voice services
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }

      // Initialize Speech to Text
      _speechToText = stt.SpeechToText();
      final available = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );

      if (!available) {
        return false;
      }

      // Initialize Text to Speech
      _flutterTts = FlutterTts();
      await _configureTts();

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      return false;
    }
  }

  /// Configure Text-to-Speech settings
  Future<void> _configureTts() async {
    await _flutterTts.setLanguage('tr-TR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint('TTS Error: $msg');
    });
  }

  /// Start listening for voice input
  Future<bool> startListening({
    String? localeId = 'tr-TR',
    Duration? timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized || _isListening) {
      return false;
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: timeout ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId ?? 'tr-TR',
        onSoundLevelChange: _onSoundLevelChange,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
      
      _isListening = true;
      _listeningController.add(VoiceListeningState(
        isListening: true,
        soundLevel: 0.0,
      ));
      
      return true;
    } catch (e) {
      debugPrint('Start listening error: $e');
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      _listeningController.add(VoiceListeningState(
        isListening: false,
        soundLevel: 0.0,
      ));
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speechToText.cancel();
      _isListening = false;
      _listeningController.add(VoiceListeningState(
        isListening: false,
        soundLevel: 0.0,
      ));
    }
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    if (!_isInitialized || _isSpeaking) {
      return;
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  /// Parse ingredients from voice input
  List<String> parseIngredientsFromSpeech(String speech) {
    // Clean the speech text
    String cleanText = speech.toLowerCase().trim();
    
    // Remove common voice command prefixes
    final prefixes = [
      'malzemeler',
      'malzemelerim',
      'evde var',
      'elimde var',
      'dolaptan çıkardım',
      'var olan',
    ];
    
    for (final prefix in prefixes) {
      if (cleanText.startsWith(prefix)) {
        cleanText = cleanText.substring(prefix.length).trim();
        if (cleanText.startsWith(':') || cleanText.startsWith(',')) {
          cleanText = cleanText.substring(1).trim();
        }
      }
    }

    // Split by common separators
    final separators = RegExp(r'[,;ve\s]+');
    final ingredients = cleanText
        .split(separators)
        .where((item) => item.isNotEmpty)
        .map((item) => item.trim())
        .where((item) => item.length > 1)
        .toList();

    return ingredients;
  }

  /// Get voice command suggestions
  List<String> getVoiceCommandSuggestions() {
    return [
      "Malzemeler: domates, yumurta, peynir",
      "Elimde var: patates, soğan, et",
      "Dolaptan çıkardım: süt, tereyağı, un",
      "Tarif öner",
      "Hızlı yemek istiyorum",
      "Vejetaryen tarif",
      "30 dakikada ne yapabilirim",
    ];
  }

  // Event handlers
  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    _confidence = result.confidence;

    final ingredients = parseIngredientsFromSpeech(_lastWords);
    
    _recognitionController.add(VoiceRecognitionResult(
      recognizedText: _lastWords,
      confidence: _confidence,
      isFinal: result.finalResult,
      detectedIngredients: ingredients,
      timestamp: DateTime.now(),
    ));
  }

  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _listeningController.add(VoiceListeningState(
        isListening: false,
        soundLevel: 0.0,
      ));
    }
  }

  void _onSpeechError(stt.SpeechRecognitionError error) {
    debugPrint('Speech error: ${error.errorMsg}');
    _isListening = false;
    _listeningController.add(VoiceListeningState(
      isListening: false,
      soundLevel: 0.0,
      error: error.errorMsg,
    ));
  }

  void _onSoundLevelChange(double level) {
    _listeningController.add(VoiceListeningState(
      isListening: _isListening,
      soundLevel: level,
    ));
  }

  /// Check if speech recognition is available
  Future<bool> hasSpeech() async {
    return await _speechToText.initialize();
  }

  /// Get available locales for speech recognition
  Future<List<stt.LocaleName>> getLocales() async {
    return await _speechToText.locales();
  }

  /// Dispose resources
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    _recognitionController.close();
    _listeningController.close();
  }
}

// Data classes for voice recognition results
class VoiceRecognitionResult {
  final String recognizedText;
  final double confidence;
  final bool isFinal;
  final List<String> detectedIngredients;
  final DateTime timestamp;

  VoiceRecognitionResult({
    required this.recognizedText,
    required this.confidence,
    required this.isFinal,
    required this.detectedIngredients,
    required this.timestamp,
  });
}

class VoiceListeningState {
  final bool isListening;
  final double soundLevel;
  final String? error;

  VoiceListeningState({
    required this.isListening,
    required this.soundLevel,
    this.error,
  });
}

// Voice command types
enum VoiceCommandType {
  addIngredients,
  findRecipes,
  quickRecipe,
  vegetarianRecipe,
  timeConstraint,
  unknown,
}

class VoiceCommand {
  final VoiceCommandType type;
  final String originalText;
  final Map<String, dynamic> parameters;

  VoiceCommand({
    required this.type,
    required this.originalText,
    required this.parameters,
  });

  static VoiceCommand parse(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('malzeme') || lowerText.contains('var') || lowerText.contains('elimde')) {
      return VoiceCommand(
        type: VoiceCommandType.addIngredients,
        originalText: text,
        parameters: {'ingredients': VoiceService.instance.parseIngredientsFromSpeech(text)},
      );
    }
    
    if (lowerText.contains('tarif öner') || lowerText.contains('ne yap')) {
      return VoiceCommand(
        type: VoiceCommandType.findRecipes,
        originalText: text,
        parameters: {},
      );
    }
    
    if (lowerText.contains('hızlı') || lowerText.contains('çabuk')) {
      return VoiceCommand(
        type: VoiceCommandType.quickRecipe,
        originalText: text,
        parameters: {'maxTime': 20},
      );
    }
    
    if (lowerText.contains('vejetaryen') || lowerText.contains('sebze')) {
      return VoiceCommand(
        type: VoiceCommandType.vegetarianRecipe,
        originalText: text,
        parameters: {'diet': 'vejetaryen'},
      );
    }
    
    if (lowerText.contains('dakika')) {
      final match = RegExp(r'(\d+)\s*dakika').firstMatch(lowerText);
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '');
        if (minutes != null) {
          return VoiceCommand(
            type: VoiceCommandType.timeConstraint,
            originalText: text,
            parameters: {'maxTime': minutes},
          );
        }
      }
    }
    
    return VoiceCommand(
      type: VoiceCommandType.unknown,
      originalText: text,
      parameters: {},
    );
  }
}