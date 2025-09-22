import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  Future<bool> initialize() async {
    final hasPermission = await Permission.microphone.request().isGranted;
    if (!hasPermission) return false;

    return await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
  }

  Future<void> startListening(Function(String) onResult) async {
    if (_isListening) return;

    final available = await initialize();
    if (!available) return;

    _isListening = true;
    _lastWords = '';

    await _speech.listen(
      onSoundLevelChange: (level) => print('Sound level: $level'),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        _lastWords = result.recognizedWords;
        onResult(_lastWords);
      },
    );
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    await _speech.stop();
  }

  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  // Parse spoken ingredients
  List<String> parseIngredients(String text) {
    // Simple parsing: split by common separators
    final separators = RegExp(r'[,;ve|veya]');
    final words = text.toLowerCase()
        .split(separators)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return words;
  }

  // Check if ingredient exists in our database
  bool isValidIngredient(String ingredientName, List<String> availableIngredients) {
    return availableIngredients.any((available) =>
        available.toLowerCase().contains(ingredientName.toLowerCase()) ||
        ingredientName.toLowerCase().contains(available.toLowerCase()));
  }
}