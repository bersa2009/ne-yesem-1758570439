import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_service.dart';

class ErrorService {
  static ErrorService? _instance;
  static ErrorService get instance => _instance ??= ErrorService._();
  ErrorService._();

  final List<AppError> _errors = [];
  final StreamController<AppError> _errorController = StreamController<AppError>.broadcast();
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Stream<AppError> get errorStream => _errorController.stream;
  List<AppError> get errors => List.unmodifiable(_errors);
  bool get isInitialized => _isInitialized;

  /// Initialize error service
  Future<bool> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPersistedErrors();
      _setupGlobalErrorHandling();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error service initialization failed: $e');
      return false;
    }
  }

  /// Setup global error handling
  void _setupGlobalErrorHandling() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      reportError(
        AppError(
          type: ErrorType.framework,
          message: details.summary.toString(),
          details: details.toString(),
          stackTrace: details.stack?.toString(),
          context: 'Flutter Framework',
          severity: ErrorSeverity.high,
          timestamp: DateTime.now(),
        ),
      );
    };

    // Handle platform errors (iOS/Android)
    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(
        AppError(
          type: ErrorType.platform,
          message: error.toString(),
          stackTrace: stack.toString(),
          context: 'Platform',
          severity: ErrorSeverity.high,
          timestamp: DateTime.now(),
        ),
      );
      return true;
    };
  }

  /// Report an error
  void reportError(AppError error) {
    _errors.add(error);
    _errorController.add(error);

    // Keep only last 100 errors in memory
    if (_errors.length > 100) {
      _errors.removeAt(0);
    }

    // Persist critical errors
    if (error.severity == ErrorSeverity.critical) {
      _persistError(error);
    }

    // Auto-handle certain errors
    _autoHandleError(error);

    // Log error for debugging
    if (kDebugMode) {
      debugPrint('ERROR [${error.type.name}]: ${error.message}');
      if (error.stackTrace != null) {
        debugPrint('Stack trace: ${error.stackTrace}');
      }
    }
  }

  /// Report error with automatic context detection
  void reportErrorWithContext(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic>? metadata,
  }) {
    final appError = AppError(
      type: _detectErrorType(error),
      message: error.toString(),
      stackTrace: stackTrace?.toString(),
      context: context ?? _extractContextFromStackTrace(stackTrace),
      severity: severity,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    reportError(appError);
  }

  /// Detect error type from error object
  ErrorType _detectErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return ErrorType.network;
    } else if (errorString.contains('database') || errorString.contains('sql')) {
      return ErrorType.database;
    } else if (errorString.contains('permission')) {
      return ErrorType.permission;
    } else if (errorString.contains('camera') || errorString.contains('microphone')) {
      return ErrorType.hardware;
    } else if (errorString.contains('json') || errorString.contains('parse')) {
      return ErrorType.data;
    } else {
      return ErrorType.application;
    }
  }

  /// Extract context from stack trace
  String _extractContextFromStackTrace(StackTrace? stackTrace) {
    if (stackTrace == null) return 'Unknown';
    
    final stackString = stackTrace.toString();
    final lines = stackString.split('\n');
    
    for (final line in lines) {
      if (line.contains('lib/') && !line.contains('error_service.dart')) {
        final match = RegExp(r'lib/([^/]+/[^/]+)').firstMatch(line);
        if (match != null) {
          return match.group(1) ?? 'Unknown';
        }
      }
    }
    
    return 'Unknown';
  }

  /// Auto-handle certain errors
  void _autoHandleError(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        _handleNetworkError(error);
        break;
      case ErrorType.permission:
        _handlePermissionError(error);
        break;
      case ErrorType.database:
        _handleDatabaseError(error);
        break;
      default:
        break;
    }
  }

  /// Handle network errors
  void _handleNetworkError(AppError error) {
    // Queue for retry when network is available
    _queueForRetry(error);
  }

  /// Handle permission errors
  void _handlePermissionError(AppError error) {
    // Show permission request dialog
    _showPermissionDialog(error);
  }

  /// Handle database errors
  void _handleDatabaseError(AppError error) {
    // Attempt database recovery
    _attemptDatabaseRecovery(error);
  }

  /// Queue error for retry
  void _queueForRetry(AppError error) {
    // Implementation for retry queue
    debugPrint('Queued error for retry: ${error.message}');
  }

  /// Show permission dialog
  void _showPermissionDialog(AppError error) {
    // Implementation for permission dialog
    debugPrint('Permission error detected: ${error.message}');
  }

  /// Attempt database recovery
  void _attemptDatabaseRecovery(AppError error) {
    // Implementation for database recovery
    debugPrint('Attempting database recovery for: ${error.message}');
  }

  /// Persist critical errors
  void _persistError(AppError error) async {
    if (_prefs == null) return;
    
    try {
      final errors = await _getPersistedErrors();
      errors.add(error);
      
      // Keep only last 50 persisted errors
      if (errors.length > 50) {
        errors.removeAt(0);
      }
      
      final jsonString = jsonEncode(errors.map((e) => e.toMap()).toList());
      await _prefs!.setString('persisted_errors', jsonString);
    } catch (e) {
      debugPrint('Failed to persist error: $e');
    }
  }

  /// Load persisted errors
  Future<void> _loadPersistedErrors() async {
    if (_prefs == null) return;
    
    try {
      final errors = await _getPersistedErrors();
      _errors.addAll(errors);
    } catch (e) {
      debugPrint('Failed to load persisted errors: $e');
    }
  }

  /// Get persisted errors
  Future<List<AppError>> _getPersistedErrors() async {
    if (_prefs == null) return [];
    
    try {
      final jsonString = _prefs!.getString('persisted_errors');
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => AppError.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Failed to parse persisted errors: $e');
      return [];
    }
  }

  /// Get errors by type
  List<AppError> getErrorsByType(ErrorType type) {
    return _errors.where((error) => error.type == type).toList();
  }

  /// Get errors by severity
  List<AppError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errors.where((error) => error.severity == severity).toList();
  }

  /// Get recent errors
  List<AppError> getRecentErrors({Duration? since}) {
    final cutoff = since != null 
        ? DateTime.now().subtract(since)
        : DateTime.now().subtract(const Duration(hours: 24));
    
    return _errors.where((error) => error.timestamp.isAfter(cutoff)).toList();
  }

  /// Clear all errors
  void clearErrors() {
    _errors.clear();
    _prefs?.remove('persisted_errors');
  }

  /// Clear errors by type
  void clearErrorsByType(ErrorType type) {
    _errors.removeWhere((error) => error.type == type);
  }

  /// Get error statistics
  ErrorStatistics getErrorStatistics() {
    if (_errors.isEmpty) {
      return ErrorStatistics(
        totalErrors: 0,
        errorsByType: {},
        errorsBySeverity: {},
        averageErrorsPerDay: 0.0,
        mostCommonError: null,
      );
    }

    final errorsByType = <ErrorType, int>{};
    final errorsBySeverity = <ErrorSeverity, int>{};
    final errorMessages = <String, int>{};

    for (final error in _errors) {
      errorsByType[error.type] = (errorsByType[error.type] ?? 0) + 1;
      errorsBySeverity[error.severity] = (errorsBySeverity[error.severity] ?? 0) + 1;
      errorMessages[error.message] = (errorMessages[error.message] ?? 0) + 1;
    }

    final mostCommonErrorEntry = errorMessages.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    final oldestError = _errors.reduce(
        (a, b) => a.timestamp.isBefore(b.timestamp) ? a : b);
    final daysSinceOldest = DateTime.now().difference(oldestError.timestamp).inDays;
    final averageErrorsPerDay = daysSinceOldest > 0 ? _errors.length / daysSinceOldest : 0.0;

    return ErrorStatistics(
      totalErrors: _errors.length,
      errorsByType: errorsByType,
      errorsBySeverity: errorsBySeverity,
      averageErrorsPerDay: averageErrorsPerDay,
      mostCommonError: mostCommonErrorEntry.key,
    );
  }

  /// Generate error report
  Map<String, dynamic> generateErrorReport() {
    final stats = getErrorStatistics();
    final recentErrors = getRecentErrors(since: const Duration(days: 7));
    
    return {
      'statistics': {
        'total_errors': stats.totalErrors,
        'errors_by_type': stats.errorsByType.map((k, v) => MapEntry(k.name, v)),
        'errors_by_severity': stats.errorsBySeverity.map((k, v) => MapEntry(k.name, v)),
        'average_errors_per_day': stats.averageErrorsPerDay,
        'most_common_error': stats.mostCommonError,
      },
      'recent_errors': recentErrors.map((e) => e.toMap()).toList(),
      'report_generated_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0', // This should come from package info
      'platform': defaultTargetPlatform.name,
    };
  }

  /// Create user-friendly error messages
  String getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      case ErrorType.permission:
        return 'Bu özelliği kullanmak için gerekli izinleri verin.';
      case ErrorType.camera:
        return 'Kamera erişimi için izin gerekli. Ayarlardan izin verin.';
      case ErrorType.microphone:
        return 'Mikrofon erişimi için izin gerekli. Ayarlardan izin verin.';
      case ErrorType.database:
        return 'Veri kaydedilirken bir sorun oluştu. Tekrar deneyin.';
      case ErrorType.data:
        return 'Veriler işlenirken bir hata oluştu.';
      case ErrorType.hardware:
        return 'Cihaz özelliği kullanılamıyor.';
      case ErrorType.application:
        return 'Bir hata oluştu. Uygulamayı yeniden başlatmayı deneyin.';
      case ErrorType.framework:
        return 'Teknik bir sorun oluştu. Geliştiriciler bilgilendirildi.';
      case ErrorType.platform:
        return 'Sistem hatası oluştu. Cihazınızı yeniden başlatmayı deneyin.';
    }
  }

  /// Check if error should be reported to user
  bool shouldShowToUser(AppError error) {
    // Don't show debug/low severity errors to users
    if (error.severity == ErrorSeverity.low) return false;
    
    // Don't show framework errors (too technical)
    if (error.type == ErrorType.framework) return false;
    
    // Don't show duplicate errors within 5 minutes
    final recentSimilarErrors = _errors.where((e) => 
        e.message == error.message &&
        DateTime.now().difference(e.timestamp).inMinutes < 5).length;
    
    return recentSimilarErrors <= 1;
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
  }
}

// Error data classes
enum ErrorType {
  network,
  database,
  permission,
  camera,
  microphone,
  hardware,
  data,
  application,
  framework,
  platform,
}

enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? details;
  final String? stackTrace;
  final String context;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AppError({
    required this.type,
    required this.message,
    this.details,
    this.stackTrace,
    required this.context,
    required this.severity,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'message': message,
      'details': details,
      'stack_trace': stackTrace,
      'context': context,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory AppError.fromMap(Map<String, dynamic> map) {
    return AppError(
      type: ErrorType.values.firstWhere((e) => e.name == map['type']),
      message: map['message'] ?? '',
      details: map['details'],
      stackTrace: map['stack_trace'],
      context: map['context'] ?? 'Unknown',
      severity: ErrorSeverity.values.firstWhere((e) => e.name == map['severity']),
      timestamp: DateTime.parse(map['timestamp']),
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, context: $context, severity: $severity)';
  }
}

class ErrorStatistics {
  final int totalErrors;
  final Map<ErrorType, int> errorsByType;
  final Map<ErrorSeverity, int> errorsBySeverity;
  final double averageErrorsPerDay;
  final String? mostCommonError;

  ErrorStatistics({
    required this.totalErrors,
    required this.errorsByType,
    required this.errorsBySeverity,
    required this.averageErrorsPerDay,
    this.mostCommonError,
  });
}