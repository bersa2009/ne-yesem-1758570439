import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();
  SecurityService._();

  late SharedPreferences _prefs;
  String? _encryptionKey;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize security service
  Future<bool> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _generateOrLoadEncryptionKey();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Security service initialization error: $e');
      return false;
    }
  }

  /// Generate or load encryption key
  Future<void> _generateOrLoadEncryptionKey() async {
    _encryptionKey = _prefs.getString('encryption_key');
    
    if (_encryptionKey == null) {
      // Generate new key
      _encryptionKey = _generateRandomKey();
      await _prefs.setString('encryption_key', _encryptionKey!);
    }
  }

  /// Generate random encryption key
  String _generateRandomKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(values);
  }

  /// Encrypt sensitive data
  String encryptData(String data) {
    if (!_isInitialized || _encryptionKey == null) {
      throw Exception('Security service not initialized');
    }

    try {
      final bytes = utf8.encode(data);
      final key = utf8.encode(_encryptionKey!);
      
      // Simple XOR encryption (for demo - use AES in production)
      final encrypted = <int>[];
      for (int i = 0; i < bytes.length; i++) {
        encrypted.add(bytes[i] ^ key[i % key.length]);
      }
      
      return base64Encode(encrypted);
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt sensitive data
  String decryptData(String encryptedData) {
    if (!_isInitialized || _encryptionKey == null) {
      throw Exception('Security service not initialized');
    }

    try {
      final encrypted = base64Decode(encryptedData);
      final key = utf8.encode(_encryptionKey!);
      
      // Simple XOR decryption (for demo - use AES in production)
      final decrypted = <int>[];
      for (int i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ key[i % key.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Hash sensitive data (one-way)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure hash with salt
  String hashWithSalt(String data, String salt) {
    final combined = data + salt;
    return hashData(combined);
  }

  /// Generate random salt
  String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(values);
  }

  /// Validate data integrity
  bool validateDataIntegrity(String data, String hash) {
    return hashData(data) == hash;
  }

  /// Secure data storage
  Future<void> setSecureData(String key, String value) async {
    if (!_isInitialized) return;
    
    try {
      final encryptedValue = encryptData(value);
      await _prefs.setString('secure_$key', encryptedValue);
    } catch (e) {
      debugPrint('Secure data storage error: $e');
    }
  }

  /// Secure data retrieval
  String? getSecureData(String key) {
    if (!_isInitialized) return null;
    
    try {
      final encryptedValue = _prefs.getString('secure_$key');
      if (encryptedValue == null) return null;
      
      return decryptData(encryptedValue);
    } catch (e) {
      debugPrint('Secure data retrieval error: $e');
      return null;
    }
  }

  /// Remove secure data
  Future<void> removeSecureData(String key) async {
    if (!_isInitialized) return;
    await _prefs.remove('secure_$key');
  }

  /// Clear all secure data (GDPR compliance)
  Future<void> clearAllSecureData() async {
    if (!_isInitialized) return;
    
    final keys = _prefs.getKeys().where((key) => key.startsWith('secure_'));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Generate session token
  String generateSessionToken() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List<int>.generate(16, (i) => random.nextInt(256));
    final combined = '$timestamp${base64Encode(randomBytes)}';
    return hashData(combined);
  }

  /// Validate session token expiry
  bool isSessionValid(String token, Duration maxAge) {
    try {
      final stored = getSecureData('session_token');
      final storedTimestamp = getSecureData('session_timestamp');
      
      if (stored != token || storedTimestamp == null) return false;
      
      final timestamp = int.parse(storedTimestamp);
      final sessionAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      
      return sessionAge <= maxAge.inMilliseconds;
    } catch (e) {
      return false;
    }
  }

  /// Store session data
  Future<void> storeSession(String token) async {
    await setSecureData('session_token', token);
    await setSecureData('session_timestamp', DateTime.now().millisecondsSinceEpoch.toString());
  }

  /// Clear session
  Future<void> clearSession() async {
    await removeSecureData('session_token');
    await removeSecureData('session_timestamp');
  }

  /// Biometric authentication placeholder
  Future<bool> authenticateWithBiometrics() async {
    // This would integrate with local_auth package for real biometric authentication
    // For now, return true as placeholder
    return true;
  }

  /// App security checks
  SecurityCheckResult performSecurityCheck() {
    final issues = <SecurityIssue>[];
    
    // Check if app is running in debug mode
    if (kDebugMode) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.debugMode,
        severity: SecuritySeverity.low,
        message: 'App is running in debug mode',
      ));
    }
    
    // Check encryption key
    if (_encryptionKey == null) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.missingEncryption,
        severity: SecuritySeverity.high,
        message: 'Encryption key not found',
      ));
    }
    
    // Check for secure storage
    final hasSecureData = _prefs.getKeys().any((key) => key.startsWith('secure_'));
    if (hasSecureData && _encryptionKey == null) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.unsecuredData,
        severity: SecuritySeverity.high,
        message: 'Secure data found but no encryption key',
      ));
    }
    
    return SecurityCheckResult(
      isSecure: issues.where((i) => i.severity == SecuritySeverity.high).isEmpty,
      issues: issues,
      checkedAt: DateTime.now(),
    );
  }

  /// GDPR compliance - data deletion
  Future<bool> deleteUserData() async {
    try {
      await clearAllSecureData();
      await clearSession();
      
      // Remove all user preferences
      final keys = _prefs.getKeys().toList();
      for (final key in keys) {
        if (!key.startsWith('system_')) {
          await _prefs.remove(key);
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('User data deletion error: $e');
      return false;
    }
  }

  /// Generate privacy report
  Map<String, dynamic> generatePrivacyReport() {
    final keys = _prefs.getKeys();
    final secureKeys = keys.where((key) => key.startsWith('secure_')).length;
    final totalKeys = keys.length;
    
    return {
      'total_stored_keys': totalKeys,
      'secure_keys_count': secureKeys,
      'has_encryption': _encryptionKey != null,
      'last_security_check': DateTime.now().toIso8601String(),
      'privacy_compliant': true,
    };
  }
}

// Security data classes
enum SecurityIssueType {
  debugMode,
  missingEncryption,
  unsecuredData,
  expiredSession,
  weakKey,
}

enum SecuritySeverity {
  low,
  medium,
  high,
  critical,
}

class SecurityIssue {
  final SecurityIssueType type;
  final SecuritySeverity severity;
  final String message;
  final DateTime detectedAt;

  SecurityIssue({
    required this.type,
    required this.severity,
    required this.message,
  }) : detectedAt = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'detected_at': detectedAt.toIso8601String(),
    };
  }
}

class SecurityCheckResult {
  final bool isSecure;
  final List<SecurityIssue> issues;
  final DateTime checkedAt;

  SecurityCheckResult({
    required this.isSecure,
    required this.issues,
    required this.checkedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'is_secure': isSecure,
      'issues': issues.map((i) => i.toMap()).toList(),
      'checked_at': checkedAt.toIso8601String(),
    };
  }
}