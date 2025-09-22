import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AssistantService {
  // Siri Shortcuts (iOS)
  static const String _siriShortcutIdentifier = 'com.neyesem.recipe';

  // App Actions (Android)
  static const String _appActionsIntent = 'com.neyesem.RECIPE_SEARCH';

  // Check if platform supports assistant integration
  bool get supportsAssistantIntegration => Platform.isIOS || Platform.isAndroid;

  // Register Siri Shortcuts (iOS)
  Future<void> registerSiriShortcuts() async {
    if (!Platform.isIOS) return;

    // TODO: Use SiriKit or IntentsUI framework
    // This would require platform-specific code
    print('Siri shortcuts registered');
  }

  // Register App Actions (Android)
  Future<void> registerAppActions() async {
    if (!Platform.isAndroid) return;

    // TODO: Use Android App Actions API
    // This would require platform-specific code
    print('App Actions registered');
  }

  // Handle assistant command
  Future<void> handleAssistantCommand(String command, BuildContext context) async {
    // Parse common commands
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('tarif') || lowerCommand.contains('ne pişir')) {
      // Navigate to ingredients screen
      Navigator.of(context).pushNamed('/ingredients');
    } else if (lowerCommand.contains('favori')) {
      // Navigate to favorites
      Navigator.of(context).pushNamed('/favorites');
    } else if (lowerCommand.contains('yardım')) {
      _showAssistantHelp(context);
    }
  }

  // Show assistant help
  void _showAssistantHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sesli Asistan Komutları'),
        content: const Text(
          '• "Ne pişirsem?" - Malzeme girişine git\n'
          '• "Favori tariflerim" - Favori tarifleri göster\n'
          '• "Tarif ara" - Hızlı tarif arama\n'
          '• "Yardım" - Bu yardım mesajını göster'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Open assistant settings
  Future<void> openAssistantSettings() async {
    if (Platform.isIOS) {
      final url = 'App-Prefs:SHORTCUTS';
      if (await canLaunch(url)) {
        await launch(url);
      }
    } else if (Platform.isAndroid) {
      final url = 'package:com.google.android.googlequicksearchbox';
      if (await canLaunch(url)) {
        await launch(url);
      }
    }
  }

  // Check if assistant is available
  Future<bool> isAssistantAvailable() async {
    if (Platform.isIOS) {
      // Check if Siri is enabled
      return true; // Simplified for demo
    } else if (Platform.isAndroid) {
      // Check if Google Assistant is available
      return true; // Simplified for demo
    }
    return false;
  }

  // Custom assistant phrases
  static const Map<String, String> _assistantPhrases = {
    'tr': {
      'recipe_search': 'Ne pişirsem diye düşünme, malzemelerini söyle',
      'favorites': 'Favori tariflerin hazır',
      'help': 'Nasıl yardımcı olabilirim?',
    },
    'en': {
      'recipe_search': 'Don\'t worry about what to cook, tell me your ingredients',
      'favorites': 'Your favorite recipes are ready',
      'help': 'How can I help you?',
    },
  };

  String getAssistantPhrase(String key, String language) {
    return _assistantPhrases[language]?[key] ?? _assistantPhrases['tr']![key]!;
  }
}