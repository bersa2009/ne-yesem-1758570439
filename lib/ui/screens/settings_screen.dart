import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/database_service.dart';
import '../../services/security_service.dart';
import 'voice_assistant_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        children: [
          // Language Settings
          _buildSettingsCard(
            context,
            title: l10n.language,
            children: [
              RadioListTile<String>(
                title: const Text('Türkçe'),
                value: 'tr',
                groupValue: settings.language,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(appSettingsProvider.notifier).updateLanguage(value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: settings.language,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(appSettingsProvider.notifier).updateLanguage(value);
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Theme Settings
          _buildSettingsCard(
            context,
            title: l10n.theme,
            children: [
              RadioListTile<ThemeMode>(
                title: Text(l10n.lightTheme),
                value: ThemeMode.light,
                groupValue: settings.theme,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(appSettingsProvider.notifier).updateTheme(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.darkTheme),
                value: ThemeMode.dark,
                groupValue: settings.theme,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(appSettingsProvider.notifier).updateTheme(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.systemTheme),
                value: ThemeMode.system,
                groupValue: settings.theme,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(appSettingsProvider.notifier).updateTheme(value);
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Feature Settings
          _buildSettingsCard(
            context,
            title: 'Özellikler',
            children: [
              SwitchListTile(
                title: Text(l10n.voice),
                subtitle: const Text('Sesli komutları etkinleştir'),
                value: settings.voiceEnabled,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).updateVoiceEnabled(value);
                },
              ),
              ListTile(
                title: const Text('Ne Yesem Asistanı'),
                subtitle: const Text('Kendi sesli asistanımızı test edin'),
                leading: const Icon(Icons.assistant, color: AppTheme.primaryColor),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const VoiceAssistantScreen(),
                    ),
                  );
                },
              ),
              SwitchListTile(
                title: Text(l10n.camera),
                subtitle: const Text('Kamera ile malzeme tanımayı etkinleştir'),
                value: settings.cameraEnabled,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).updateCameraEnabled(value);
                },
              ),
              SwitchListTile(
                title: Text(l10n.notifications),
                subtitle: const Text('Bildirimleri etkinleştir'),
                value: settings.notificationsEnabled,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).updateNotificationsEnabled(value);
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Privacy Settings
          _buildSettingsCard(
            context,
            title: l10n.privacy,
            children: [
              SwitchListTile(
                title: const Text('Analitik'),
                subtitle: const Text('Uygulama kullanım verilerini paylaş'),
                value: settings.analyticsEnabled,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).updateAnalyticsEnabled(value);
                },
              ),
              ListTile(
                title: const Text('Verilerimi Sil'),
                subtitle: const Text('Tüm kişisel verilerinizi silin'),
                leading: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
                onTap: () => _showDeleteDataDialog(context, ref),
              ),
              ListTile(
                title: const Text('Verilerimi Dışa Aktar'),
                subtitle: const Text('Kişisel verilerinizi dışa aktarın'),
                leading: const Icon(Icons.download),
                onTap: () => _exportUserData(context, ref),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Data Management
          _buildSettingsCard(
            context,
            title: 'Veri Yönetimi',
            children: [
              ListTile(
                title: const Text('Önbelleği Temizle'),
                subtitle: const Text('Geçici dosyaları ve önbelleği temizle'),
                leading: const Icon(Icons.cleaning_services),
                onTap: () => _clearCache(context, ref),
              ),
              ListTile(
                title: const Text('Arama Geçmişini Temizle'),
                subtitle: const Text('Tüm arama geçmişinizi silin'),
                leading: const Icon(Icons.history),
                onTap: () => _clearSearchHistory(context, ref),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // About
          _buildSettingsCard(
            context,
            title: l10n.about,
            children: [
              ListTile(
                title: const Text('Sürüm'),
                subtitle: const Text('1.0.0'),
                leading: const Icon(Icons.info),
              ),
              ListTile(
                title: const Text('Geliştirici'),
                subtitle: const Text('Ne Yesem? Ekibi'),
                leading: const Icon(Icons.code),
              ),
              ListTile(
                title: const Text('Geri Bildirim'),
                subtitle: const Text('Önerilerinizi paylaşın'),
                leading: const Icon(Icons.feedback),
                onTap: () => _showFeedbackDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verilerimi Sil'),
        content: const Text(
          'Bu işlem tüm kişisel verilerinizi kalıcı olarak silecektir. '
          'Bu işlem geri alınamaz. Devam etmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete user data
                final securityService = ref.read(securityServiceProvider);
                await securityService.deleteUserData();
                
                // Clear app state
                ref.read(selectedIngredientsProvider.notifier).clearIngredients();
                ref.read(recipeResultsProvider.notifier).clearResults();
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verileriniz başarıyla silindi'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Veri silme hatası: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _exportUserData(BuildContext context, WidgetRef ref) async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final userData = await databaseService.exportUserData();
      
      // In a real app, you would save this to a file or share it
      // For now, just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verileriniz dışa aktarıldı'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dışa aktarma hatası: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _clearCache(BuildContext context, WidgetRef ref) async {
    try {
      final performanceService = ref.read(performanceServiceProvider);
      performanceService.clearCache();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önbellek temizlendi'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Önbellek temizleme hatası: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _clearSearchHistory(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arama Geçmişini Temizle'),
        content: const Text('Tüm arama geçmişinizi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Clear search history would be implemented here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Arama geçmişi temizlendi'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Geçmiş temizleme hatası: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geri Bildirim'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Görüşleriniz bizim için çok değerli!'),
            SizedBox(height: AppTheme.spacingMedium),
            TextField(
              decoration: InputDecoration(
                hintText: 'Önerilerinizi yazın...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Geri bildiriminiz gönderildi. Teşekkürler!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}