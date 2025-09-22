import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccessibilityService {
  static const MethodChannel _channel = MethodChannel('com.neyesem/accessibility');

  // Text-to-speech
  static Future<void> speak(String text, {String language = 'tr-TR'}) async {
    try {
      await _channel.invokeMethod('speak', {'text': text, 'language': language});
    } catch (e) {
      print('TTS not available: $e');
    }
  }

  // Stop text-to-speech
  static Future<void> stopSpeaking() async {
    try {
      await _channel.invokeMethod('stopSpeaking');
    } catch (e) {
      print('Stop TTS failed: $e');
    }
  }

  // Haptic feedback
  static Future<void> provideHapticFeedback(HapticFeedbackType type) async {
    try {
      HapticFeedback.vibrate();
    } catch (e) {
      print('Haptic feedback failed: $e');
    }
  }

  // Focus management for screen readers
  static void announceToScreenReader(String announcement) {
    SemanticsService.announce(announcement, TextDirection.ltr);
  }

  // Large text support
  static double getLargeTextScale(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.textScaleFactor > 1.2 ? mediaQuery.textScaleFactor : 1.0;
  }

  // High contrast mode detection
  static bool isHighContrastMode(BuildContext context) {
    // TODO: Detect system high contrast mode
    return MediaQuery.of(context).highContrast;
  }

  // Reduced motion detection
  static bool isReducedMotion(BuildContext context) {
    // TODO: Detect system reduced motion preference
    return MediaQuery.of(context).disableAnimations;
  }

  // Semantic labels for UI elements
  static String getSemanticLabel(String element, String context) {
    final labels = {
      'search_button': 'Tarif ara, seçili malzemelerle tarif önerisi al',
      'speech_button': 'Sesli giriş, konuşarak malzeme ekle',
      'camera_button': 'Kamera ile malzeme tanıma',
      'favorite_button': 'Tarifi favorilere ekle veya çıkar',
      'ingredients_list': 'Mevcut malzemeler listesi',
      'recipe_card': 'Tarif detayı, dokunarak aç',
    };

    return labels['$element'] ?? element;
  }

  // Keyboard navigation support
  static Map<LogicalKeySet, Intent> getKeyboardShortcuts() {
    return {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const SearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const FavoriteIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH): const HelpIntent(),
    };
  }

  // Color contrast helpers
  static Color getAccessibleColor(Color background, Color lightColor, Color darkColor) {
    // Calculate luminance and return appropriate contrast color
    final backgroundLuminance = _calculateLuminance(background);
    return backgroundLuminance > 0.5 ? darkColor : lightColor;
  }

  static double _calculateLuminance(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final rsRGB = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055) * ((r + 0.055) / 1.055);
    final gsRGB = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055) * ((g + 0.055) / 1.055);
    final bsRGB = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055) * ((b + 0.055) / 1.055);

    return 0.2126 * rsRGB + 0.7152 * gsRGB + 0.0722 * bsRGB;
  }
}

// Custom intents for keyboard shortcuts
class SearchIntent extends Intent {
  const SearchIntent();
}

class FavoriteIntent extends Intent {
  const FavoriteIntent();
}

class HelpIntent extends Intent {
  const HelpIntent();
}