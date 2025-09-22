import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/security_service.dart';
import 'services/performance_service.dart';
import 'services/error_service.dart';
import 'services/voice_service.dart';
import 'services/camera_service.dart';
import 'services/assistant_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize core services
  await _initializeServices();
  
  runApp(
    const ProviderScope(
      child: NeYesemApp(),
    ),
  );
}

Future<void> _initializeServices() async {
  try {
    // Initialize error service first to catch any initialization errors
    await ErrorService.instance.initialize();
    
    // Initialize security service
    await SecurityService.instance.initialize();
    
    // Initialize database service
    await DatabaseService.instance.initialize();
    
    // Initialize performance service
    // PerformanceService is a singleton, no async initialization needed
    
    // Initialize voice service (will be initialized when first used)
    // VoiceService.instance.initialize() is called on demand
    
    // Initialize camera service (will be initialized when first used)
    // CameraService.instance.initialize() is called on demand
    
    // Initialize assistant service
    await AssistantService.instance.initialize();
    
  } catch (e, stackTrace) {
    // Log initialization errors
    debugPrint('Service initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Report to error service if it's available
    if (ErrorService.instance.isInitialized) {
      ErrorService.instance.reportErrorWithContext(
        e,
        stackTrace,
        context: 'App Initialization',
        severity: ErrorSeverity.critical,
      );
    }
  }
}

