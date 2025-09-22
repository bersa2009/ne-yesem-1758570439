import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class AssistantService {
  static const String _googleAssistantUrl = 'https://assistant.google.com/';
  static const String _siriUrl = 'https://www.apple.com/siri/';

  static Future<bool> isGoogleAssistantAvailable() async {
    if (Platform.isAndroid) {
      try {
        // Android için Google Assistant kontrolü
        return await canLaunchUrl(Uri.parse('com.google.android.googlequicksearchbox'));
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  static Future<bool> isSiriAvailable() async {
    if (Platform.isIOS) {
      try {
        // iOS için Siri kontrolü
        return await canLaunchUrl(Uri.parse('com.apple.assistant'));
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  static Future<void> openGoogleAssistant() async {
    final bool available = await isGoogleAssistantAvailable();
    if (available) {
      try {
        await launchUrl(Uri.parse('com.google.android.googlequicksearchbox'));
      } catch (e) {
        // Fallback: web versiyonu aç
        await launchUrl(Uri.parse(_googleAssistantUrl));
      }
    } else {
      await launchUrl(Uri.parse(_googleAssistantUrl));
    }
  }

  static Future<void> openSiri() async {
    final bool available = await isSiriAvailable();
    if (available) {
      try {
        await launchUrl(Uri.parse('com.apple.assistant'));
      } catch (e) {
        // Fallback: web versiyonu aç
        await launchUrl(Uri.parse(_siriUrl));
      }
    } else {
      await launchUrl(Uri.parse(_siriUrl));
    }
  }

  static Future<void> openVoiceAssistant() async {
    if (Platform.isAndroid) {
      await openGoogleAssistant();
    } else if (Platform.isIOS) {
      await openSiri();
    } else {
      // Desktop veya diğer platformlar için Google Assistant web
      await launchUrl(Uri.parse(_googleAssistantUrl));
    }
  }

  static String getAssistantName() {
    if (Platform.isAndroid) {
      return 'Google Assistant';
    } else if (Platform.isIOS) {
      return 'Siri';
    } else {
      return 'Sesli Asistan';
    }
  }
}