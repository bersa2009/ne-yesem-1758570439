import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _voiceEnabled = true;
  bool _cameraEnabled = true;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _assistantEnabled = true;
  String _selectedLanguage = 'Türkçe';
  String _selectedDiet = 'Hepsi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildSectionHeader('Genel'),
              _buildSettingsCard([
                _buildSwitchTile(
                  'Koyu Tema',
                  'Gece modunu etkinleştir',
                  Icons.dark_mode,
                  _darkModeEnabled,
                  (value) => setState(() => _darkModeEnabled = value),
                ),
                _buildListTile(
                  'Dil',
                  _selectedLanguage,
                  Icons.language,
                  () => _showLanguageDialog(),
                ),
                _buildListTile(
                  'Beslenme Tercihi',
                  _selectedDiet,
                  Icons.restaurant_menu,
                  () => _showDietDialog(),
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionHeader('Özellikler'),
              _buildSettingsCard([
                _buildSwitchTile(
                  'Sesli Giriş',
                  'Mikrofon ile malzeme ekleme',
                  Icons.mic,
                  _voiceEnabled,
                  (value) => setState(() => _voiceEnabled = value),
                ),
                _buildSwitchTile(
                  'Kamera',
                  'Fotoğraf ile malzeme tanıma',
                  Icons.camera_alt,
                  _cameraEnabled,
                  (value) => setState(() => _cameraEnabled = value),
                ),
                _buildSwitchTile(
                  'Akıllı Asistan',
                  'AI destekli öneriler',
                  Icons.smart_toy,
                  _assistantEnabled,
                  (value) => setState(() => _assistantEnabled = value),
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionHeader('Bildirimler'),
              _buildSettingsCard([
                _buildSwitchTile(
                  'Bildirimler',
                  'Uygulama bildirimleri',
                  Icons.notifications,
                  _notificationsEnabled,
                  (value) => setState(() => _notificationsEnabled = value),
                ),
                _buildListTile(
                  'Bildirim Ayarları',
                  'Detaylı ayarlar',
                  Icons.tune,
                  () => _showNotificationSettings(),
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionHeader('Veri ve Gizlilik'),
              _buildSettingsCard([
                _buildListTile(
                  'Veri Kullanımı',
                  'Kullanım istatistikleri',
                  Icons.data_usage,
                  () => _showDataUsage(),
                ),
                _buildListTile(
                  'Gizlilik Politikası',
                  'Veri koruma bilgileri',
                  Icons.privacy_tip,
                  () => _showPrivacyPolicy(),
                ),
                _buildListTile(
                  'Verileri Temizle',
                  'Önbellek ve geçmişi sil',
                  Icons.delete_sweep,
                  () => _showClearDataDialog(),
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionHeader('Destek'),
              _buildSettingsCard([
                _buildListTile(
                  'Yardım ve SSS',
                  'Sık sorulan sorular',
                  Icons.help,
                  () => _showHelp(),
                ),
                _buildListTile(
                  'Geri Bildirim',
                  'Önerilerinizi paylaşın',
                  Icons.feedback,
                  () => _showFeedback(),
                ),
                _buildListTile(
                  'Hakkında',
                  'Uygulama bilgileri',
                  Icons.info,
                  () => _showAbout(),
                ),
              ]),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dil Seçimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Türkçe'),
              value: 'Türkçe',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDietDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beslenme Tercihi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Hepsi',
            'Vejeteryan',
            'Vegan',
            'Glutensiz',
            'Laktozsuz',
          ].map((diet) => RadioListTile<String>(
            title: Text(diet),
            value: diet,
            groupValue: _selectedDiet,
            onChanged: (value) {
              setState(() => _selectedDiet = value!);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildirim ayarları açılıyor...')),
    );
  }

  void _showDataUsage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veri Kullanımı'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Önbellek: 12.3 MB'),
            Text('Fotoğraflar: 45.7 MB'),
            Text('Ses kayıtları: 8.2 MB'),
            Text('Toplam: 66.2 MB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gizlilik politikası açılıyor...')),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verileri Temizle'),
        content: const Text('Tüm önbellek ve geçmiş verileri silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veriler temizlendi')),
              );
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yardım sayfası açılıyor...')),
    );
  }

  void _showFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geri bildirim formu açılıyor...')),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Ne Yesem?',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.restaurant,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: const [
        Text('Dolapta ne varsa, sofrada lezzet olsun!'),
        SizedBox(height: 16),
        Text('Bu uygulama, mevcut malzemelerinizle yapabileceğiniz tarifleri bulmanıza yardımcı olur.'),
      ],
    );
  }
}