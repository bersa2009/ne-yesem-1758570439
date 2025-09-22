import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _encryptionKey = 'ne_yesem_encryption_key_2024';
  static const String _userIdKey = 'user_id';

  // Simple encryption using SHA256 (for demo - use proper encryption in production)
  String encrypt(String data) {
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Generate user ID
  Future<String> generateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);

    if (userId == null) {
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_userIdKey, userId);
    }

    return userId;
  }

  // Data deletion (KVKK compliance)
  Future<void> deleteUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // TODO: Clear SQLite database
    // TODO: Send deletion request to backend if exists
  }

  // Anonymize data for analytics
  Map<String, dynamic> anonymizeData(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    if (userId != null) {
      data = Map.from(data);
      data['user_id'] = encrypt(userId);
    }
    return data;
  }

  // Check if user has consented to data collection
  Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('data_consent') ?? false;
  }

  Future<void> setConsent(bool consented) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('data_consent', consented);
  }

  // Rate limiting for API calls
  static const int _maxRequestsPerMinute = 10;
  final Map<String, List<DateTime>> _requestHistory = {};

  bool canMakeRequest(String endpoint) {
    final now = DateTime.now();
    final history = _requestHistory[endpoint] ?? [];

    // Remove requests older than 1 minute
    final recentRequests = history.where((time) => now.difference(time).inMinutes < 1).toList();

    if (recentRequests.length >= _maxRequestsPerMinute) {
      return false;
    }

    recentRequests.add(now);
    _requestHistory[endpoint] = recentRequests;
    return true;
  }
}