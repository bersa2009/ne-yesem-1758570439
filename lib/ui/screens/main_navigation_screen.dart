import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/navigation_provider.dart';
import 'ingredients_screen.dart';
import 'recipe_results_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {

  final List<Widget> _screens = const [
    IngredientsScreen(),
    RecipeResultsScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedIngredients = ref.watch(selectedIngredientsProvider);
    final recipeResults = ref.watch(recipeResultsProvider);
    final currentIndex = ref.watch(navigationProvider);
    
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationProvider.notifier).setIndex(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.mediumGray,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.kitchen),
                if (selectedIngredients.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        selectedIngredients.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: l10n.ingredients,
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.restaurant_menu),
                recipeResults.when(
                  data: (results) => results.isNotEmpty
                      ? Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              results.length > 99 ? '99+' : results.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            label: l10n.recipes,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: l10n.favorites,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
      floatingActionButton: currentIndex == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Voice Input FAB
                FloatingActionButton(
                  heroTag: 'voice',
                  onPressed: () => _showVoiceInput(context),
                  backgroundColor: AppTheme.secondaryColor,
                  child: const Icon(Icons.mic),
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                // Camera Input FAB
                FloatingActionButton(
                  heroTag: 'camera',
                  onPressed: () => _showCameraInput(context),
                  backgroundColor: AppTheme.accentColor,
                  child: const Icon(Icons.camera_alt),
                ),
              ],
            )
          : null,
    );
  }

  void _showVoiceInput(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceInputBottomSheet(),
    );
  }

  void _showCameraInput(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CameraInputBottomSheet(),
    );
  }
}

// Voice Input Bottom Sheet
class VoiceInputBottomSheet extends ConsumerStatefulWidget {
  const VoiceInputBottomSheet({super.key});

  @override
  ConsumerState<VoiceInputBottomSheet> createState() => _VoiceInputBottomSheetState();
}

class _VoiceInputBottomSheetState extends ConsumerState<VoiceInputBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final voiceState = ref.watch(voiceRecognitionProvider);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Text(
              l10n.voiceInput,
              style: theme.textTheme.headlineMedium,
            ),
          ),
          
          // Voice Animation
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: voiceState.status == VoiceRecognitionStatus.listening
                            ? _pulseAnimation.value
                            : 1.0,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: voiceState.status == VoiceRecognitionStatus.listening
                                ? AppTheme.secondaryColor.withOpacity(0.3)
                                : AppTheme.lightGray.withOpacity(0.3),
                          ),
                          child: Icon(
                            Icons.mic,
                            size: 60,
                            color: voiceState.status == VoiceRecognitionStatus.listening
                                ? AppTheme.secondaryColor
                                : AppTheme.mediumGray,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLarge),
                  
                  // Status Text
                  Text(
                    _getStatusText(voiceState.status, l10n),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  if (voiceState.result != null) ...[
                    const SizedBox(height: AppTheme.spacingMedium),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                      decoration: BoxDecoration(
                        color: AppTheme.veryLightGray,
                        borderRadius: AppTheme.smallRadius,
                      ),
                      child: Text(
                        voiceState.result!.recognizedText,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  
                  if (voiceState.error != null) ...[
                    const SizedBox(height: AppTheme.spacingMedium),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: AppTheme.smallRadius,
                      ),
                      child: Text(
                        voiceState.error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Control Buttons
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: voiceState.status == VoiceRecognitionStatus.listening
                        ? () => ref.read(voiceRecognitionProvider.notifier).stopListening()
                        : () => ref.read(voiceRecognitionProvider.notifier).startListening(),
                    child: Text(
                      voiceState.status == VoiceRecognitionStatus.listening
                          ? l10n.stopListening
                          : l10n.startListening,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(VoiceRecognitionStatus status, AppLocalizations l10n) {
    switch (status) {
      case VoiceRecognitionStatus.idle:
        return l10n.voiceHint;
      case VoiceRecognitionStatus.listening:
        return l10n.listening;
      case VoiceRecognitionStatus.recognized:
        return 'Malzemeler tanındı!';
      case VoiceRecognitionStatus.error:
        return 'Ses tanıma hatası';
    }
  }
}

// Camera Input Bottom Sheet
class CameraInputBottomSheet extends ConsumerWidget {
  const CameraInputBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cameraState = ref.watch(cameraStateProvider);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Text(
              l10n.cameraInput,
              style: theme.textTheme.headlineMedium,
            ),
          ),
          
          // Camera Preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spacingLarge),
              decoration: BoxDecoration(
                color: AppTheme.veryLightGray,
                borderRadius: AppTheme.mediumRadius,
              ),
              child: _buildCameraContent(cameraState, l10n, theme),
            ),
          ),
          
          // Control Buttons
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: cameraState.status == CameraStatus.ready
                        ? () => ref.read(cameraStateProvider.notifier).takePicture()
                        : cameraState.status == CameraStatus.idle
                            ? () => ref.read(cameraStateProvider.notifier).initializeCamera()
                            : null,
                    child: Text(_getCameraButtonText(cameraState.status, l10n)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraContent(CameraState cameraState, AppLocalizations l10n, ThemeData theme) {
    switch (cameraState.status) {
      case CameraStatus.idle:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 80,
                color: AppTheme.mediumGray,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                'Kamerayı başlatmak için butona basın',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      case CameraStatus.initializing:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppTheme.spacingMedium),
              Text('Kamera başlatılıyor...'),
            ],
          ),
        );
      case CameraStatus.ready:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 80,
                color: AppTheme.successColor,
              ),
              SizedBox(height: AppTheme.spacingMedium),
              Text('Kamera hazır! Fotoğraf çekebilirsiniz.'),
            ],
          ),
        );
      case CameraStatus.capturing:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppTheme.spacingMedium),
              Text('Fotoğraf çekiliyor...'),
            ],
          ),
        );
      case CameraStatus.analyzed:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                'Analiz tamamlandı!',
                style: theme.textTheme.titleMedium,
              ),
              if (cameraState.result != null && cameraState.result!.detectedIngredients.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  'Bulunan malzemeler:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                ...cameraState.result!.detectedIngredients.map(
                  (ingredient) => Chip(
                    label: Text(ingredient.name),
                    backgroundColor: AppTheme.successColor.withOpacity(0.1),
                  ),
                ),
              ],
            ],
          ),
        );
      case CameraStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 80,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                cameraState.error ?? 'Bilinmeyen hata',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }

  String _getCameraButtonText(CameraStatus status, AppLocalizations l10n) {
    switch (status) {
      case CameraStatus.idle:
        return 'Kamerayı Başlat';
      case CameraStatus.initializing:
        return 'Başlatılıyor...';
      case CameraStatus.ready:
        return l10n.takePicture;
      case CameraStatus.capturing:
        return 'Çekiliyor...';
      case CameraStatus.analyzed:
        return 'Tekrar Çek';
      case CameraStatus.error:
        return 'Tekrar Dene';
    }
  }
}