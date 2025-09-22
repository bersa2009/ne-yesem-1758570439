import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/screens/welcome_screen.dart';
import 'providers/app_providers.dart';
import 'ui/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

class NeYesemApp extends ConsumerWidget {
  const NeYesemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);
    
    return MaterialApp(
      title: 'Ne Yesem?',
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appSettings.theme,
      
      // Localization configuration
      locale: Locale(appSettings.language),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Turkish
        Locale('en', 'US'), // English
      ],
      
      // Navigation configuration
      home: const WelcomeScreen(),
      
      // Error handling
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            // Listen to error stream and show error dialogs
            ref.listen(errorStreamProvider, (previous, next) {
              next.whenData((error) {
                if (ErrorService.instance.shouldShowToUser(error)) {
                  _showErrorDialog(context, error);
                }
              });
            });
            
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
  
  void _showErrorDialog(BuildContext context, AppError error) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(ErrorService.instance.getUserFriendlyMessage(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

