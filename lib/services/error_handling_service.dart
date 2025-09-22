import 'package:flutter/material.dart';

class ErrorHandlingService {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Global error handler
  static void handleError(BuildContext context, Object error, StackTrace? stackTrace) {
    print('Error: $error');
    print('StackTrace: $stackTrace');

    String message = 'Bir hata oluştu';
    if (error.toString().contains('permission')) {
      message = 'Kamera veya mikrofon izni gerekli';
    } else if (error.toString().contains('network')) {
      message = 'İnternet bağlantınızı kontrol edin';
    } else if (error.toString().contains('camera')) {
      message = 'Kamera kullanılamıyor';
    } else if (error.toString().contains('speech')) {
      message = 'Ses tanıma çalışmıyor';
    }

    showError(context, message);
  }

  // Retry mechanism
  static Future<T> withRetry<T>(
    Future<T> Function() operation,
    BuildContext context, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxAttempts) {
          handleError(context, e, null);
          rethrow;
        }
        await Future.delayed(delay * attempt);
      }
    }
    throw Exception('Max retry attempts reached');
  }
}