import 'package:flutter/material.dart';
import '../../services/assistant_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _voiceSearchEnabled = true;
  String _language = 'Türkçe';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Gerçek uygulamada SharedPreferences'dan ayarlar yüklenecek
  }

  void _saveSettings() {
    // Gerçek uygulamada SharedPreferences'a ayarlar kaydedilecek
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Bildirimler'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveSettings();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Koyu Tema'),
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
                _saveSettings();
                // Burada tema değişikliği yapılacak
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Dil'),
            subtitle: Text(_language),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Dil Seçin'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Türkçe'),
                        onTap: () {
                          setState(() {
                            _language = 'Türkçe';
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        title: const Text('English'),
                        onTap: () {
                          setState(() {
                            _language = 'English';
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('Sesli Arama'),
            trailing: Switch(
              value: _voiceSearchEnabled,
              onChanged: (value) {
                setState(() {
                  _voiceSearchEnabled = value;
                });
                _saveSettings();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.assistant, color: Colors.blue),
            title: const Text('Asistan Entegrasyonu'),
            subtitle: const Text('Siri ve Google Assistant ile kullan'),
            onTap: () {
              AssistantService.openAssistantSettings(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Hakkında'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Ne Yesem?',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.restaurant_menu),
                children: [
                  const Text('Dolapta ne varsa, sofrada lezzet olsun!'),
                  const SizedBox(height: 16),
                  const Text('Bu uygulama ile malzemelerinizle yapabileceğiniz tarifleri keşfedin.'),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Yardım'),
            onTap: () {
              // Yardım ekranı henüz implementasyonsuz
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yardım özelliği henüz implementasyonsuz'))
              );
            },
          ),
        ],
      ),
    );
  }
}