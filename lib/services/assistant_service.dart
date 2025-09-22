import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AssistantService {
  static Future<void> openAssistantSettings(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asistan Entegrasyonu'),
        content: const Text(
          'Bu uygulamayı Siri veya Google Assistant ile kullanabilirsiniz.\n\n'
          'Siri için: "Hey Siri, Ne Yesem? ile tarif ara"\n'
          'Google Assistant için: "Ok Google, Ne Yesem? ile konuş"'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () async {
              const url = 'https://support.google.com/assistant/answer/7393909';
              try {
                await launchUrl(Uri.parse(url));
              } catch (e) {
                print('URL açma hatası: $e');
              }
            },
            child: const Text('Nasıl Kurulur?'),
          ),
        ],
      ),
    );
  }

  static void showAssistantTip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💡 Siri veya Google Assistant\'a "Ne Yesem?" diye sorabilirsiniz!'),
        duration: Duration(seconds: 4),
      ),
    );
  }
}