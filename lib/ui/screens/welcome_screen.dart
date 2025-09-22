import 'package:flutter/material.dart';
import 'ingredients_screen.dart';
import 'results_screen.dart';
import 'camera_scan_screen.dart';
import 'voice_search_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'reset_screen.dart';
import '../../services/matching_service.dart';
import '../../models/models.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NE YESEM', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2F80ED),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _MenuCard(
              icon: Icons.home,
              title: 'Ana Sayfa',
              color: const Color(0xFF2F80ED),
              onTap: () {
                // Ana sayfa - mevcut sayfa zaten
              },
            ),
            _MenuCard(
              icon: Icons.search,
              title: 'Tarif Bul',
              color: const Color(0xFF2F80ED),
              onTap: () async {
                final service = await MatchingService.loadFromAssets();
                final results = service.match(userIngredientIds: const {}, filters: const MatchFilters(maxTimeMinutes: 30));
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ResultsScreen(results: results, ingredientById: service.ingredientById)
                ));
              },
            ),
            _MenuCard(
              icon: Icons.qr_code_scanner,
              title: 'Malzeme Tara',
              color: const Color(0xFF2F80ED),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CameraScanScreen())
                );
              },
            ),
            _MenuCard(
              icon: Icons.favorite,
              title: 'Favoriler',
              color: const Color(0xFF2F80ED),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen())
                );
              },
            ),
            _MenuCard(
              icon: Icons.mic,
              title: 'Sesli Arama',
              color: const Color(0xFF2F80ED),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VoiceSearchScreen())
                );
              },
            ),
            _MenuCard(
              icon: Icons.camera_alt,
              title: 'Kamera ile Ara',
              color: const Color(0xFF2F80ED),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CameraScanScreen())
                );
              },
            ),
            _MenuCard(
              icon: Icons.settings,
              title: 'Ayarlar',
              color: const Color(0xFF2F80ED),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen())
                );
              },
            ),
            _MenuCard(
              icon: Icons.refresh,
              title: 'Asetlem',
              color: const Color(0xFF2F80ED),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResetScreen())
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

