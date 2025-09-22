import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Global error handler for uncaught exceptions
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };
  }

  static void _handleFlutterError(FlutterErrorDetails details) {
    // Log error details
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack Trace: ${details.stack}');
    
    // In production, you might want to send this to a crash reporting service
    // like Firebase Crashlytics, Sentry, etc.
  }

  // Handle network errors
  static String handleNetworkError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'İnternet bağlantınızı kontrol edin';
    } else if (error.toString().contains('TimeoutException')) {
      return 'İstek zaman aşımına uğradı';
    } else if (error.toString().contains('FormatException')) {
      return 'Veri formatı hatası';
    } else {
      return 'Ağ hatası oluştu';
    }
  }

  // Handle camera errors
  static String handleCameraError(dynamic error) {
    if (error.toString().contains('CameraAccessDenied')) {
      return 'Kamera izni gerekli';
    } else if (error.toString().contains('CameraException')) {
      return 'Kamera hatası oluştu';
    } else {
      return 'Fotoğraf çekme hatası';
    }
  }

  // Handle voice/microphone errors
  static String handleVoiceError(dynamic error) {
    if (error.toString().contains('speech_to_text')) {
      return 'Ses tanıma hatası';
    } else if (error.toString().contains('MicrophoneAccessDenied')) {
      return 'Mikrofon izni gerekli';
    } else if (error.toString().contains('SpeechRecognitionNotAvailable')) {
      return 'Ses tanıma özelliği mevcut değil';
    } else {
      return 'Sesli giriş hatası';
    }
  }

  // Handle file system errors
  static String handleFileError(dynamic error) {
    if (error.toString().contains('FileSystemException')) {
      return 'Dosya sistemi hatası';
    } else if (error.toString().contains('PathNotFoundException')) {
      return 'Dosya bulunamadı';
    } else if (error.toString().contains('PermissionDenied')) {
      return 'Dosya izni gerekli';
    } else {
      return 'Dosya hatası';
    }
  }

  // Handle general errors with user-friendly messages
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('socket')) {
      return handleNetworkError(error);
    } else if (errorString.contains('camera')) {
      return handleCameraError(error);
    } else if (errorString.contains('voice') || errorString.contains('speech') || errorString.contains('mic')) {
      return handleVoiceError(error);
    } else if (errorString.contains('file') || errorString.contains('path')) {
      return handleFileError(error);
    } else if (errorString.contains('permission')) {
      return 'İzin gerekli';
    } else if (errorString.contains('timeout')) {
      return 'İşlem zaman aşımına uğradı';
    } else {
      return 'Beklenmeyen bir hata oluştu';
    }
  }

  // Show error dialog
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Kapat',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show retry dialog
  static void showRetryDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onRetry,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  // Handle permission errors specifically
  static Future<void> handlePermissionError(
    BuildContext context,
    String permission,
    VoidCallback onSettings,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İzin Gerekli'),
        content: Text('$permission izni gerekli. Ayarlardan izin verebilirsiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSettings();
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  // Vibrate for haptic feedback on errors
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  // Log error for debugging
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('Error in $context: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
}