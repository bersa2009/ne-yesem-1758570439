import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../screens/ingredients_screen.dart';
import '../screens/recipe_detail_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';
import '../../services/voice/voice_service.dart';
import '../../services/camera/camera_service.dart';
import '../../services/assistant/assistant_service.dart';

class AppNavigationDrawer extends StatefulWidget {
  const AppNavigationDrawer({super.key});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  final VoiceService _voiceService = VoiceService();
  final CameraService _cameraService = CameraService();
  final AssistantService _assistantService = AssistantService();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildDrawerHeader(context),
              
              // Menu Items
              Expanded(
                child: AnimationLimiter(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 375),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildMenuItem(
                          context,
                          Icons.restaurant_menu,
                          'Malzemeler',
                          'Mevcut malzemelerini ekle',
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const IngredientsScreen()),
                          ),
                        ),
                        _buildMenuItem(
                          context,
                          Icons.camera_alt,
                          'Fotoğraf Çek',
                          'Malzeme fotoğrafı çek',
                          () => _handleCameraAction(context),
                        ),
                        _buildMenuItem(
                          context,
                          Icons.mic,
                          'Sesli Giriş',
                          'Sesle malzeme ekle',
                          () => _handleVoiceAction(context),
                        ),
                        _buildMenuItem(
                          context,
                          Icons.favorite,
                          'Favoriler',
                          'Favori tariflerim',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                          ),
                        ),
                        _buildMenuItem(
                          context,
                          Icons.history,
                          'Geçmiş',
                          'Son aranan tarifler',
                          () => _showHistoryScreen(context),
                        ),
                        _buildMenuItem(
                          context,
                          Icons.local_grocery_store,
                          'Alışveriş Listesi',
                          'Eksik malzemeler',
                          () => _showShoppingList(context),
                        ),
                        const Divider(height: 24),
                        _buildMenuItem(
                          context,
                          Icons.smart_toy,
                          'Asistan',
                          'Akıllı öneriler al',
                          () => _showAssistantDialog(context),
                        ),
                        _buildMenuItem(
                          context,
                          Icons.settings,
                          'Ayarlar',
                          'Uygulama ayarları',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                        _buildMenuItem(
                          context,
                          Icons.help,
                          'Yardım',
                          'Nasıl kullanılır?',
                          () => _showHelpDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer
              _buildDrawerFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ne Yesem?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dolapta ne varsa, sofrada lezzet olsun!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
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
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickActionButton(
                context,
                Icons.camera_alt,
                'Kamera',
                () => _handleCameraAction(context),
              ),
              _buildQuickActionButton(
                context,
                Icons.mic,
                'Ses',
                () => _handleVoiceAction(context),
              ),
              _buildQuickActionButton(
                context,
                Icons.search,
                'Ara',
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const IngredientsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
              onTap();
            },
            icon: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _handleCameraAction(BuildContext context) async {
    final file = await _cameraService.showImageSourceDialog(context);
    if (file != null) {
      final ingredients = await _cameraService.recognizeIngredients(file);
      if (ingredients.isNotEmpty && context.mounted) {
        _showRecognizedIngredientsDialog(context, ingredients);
      }
    }
  }

  void _handleVoiceAction(BuildContext context) async {
    if (await _voiceService.initialize()) {
      _showVoiceInputDialog(context);
    } else {
      _showErrorSnackBar(context, 'Mikrofon izni gerekli');
    }
  }

  void _showRecognizedIngredientsDialog(BuildContext context, List<String> ingredients) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tanınan Malzemeler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ingredients.map((ingredient) => 
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(ingredient),
            ),
          ).toList(),
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

  void _showVoiceInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => VoiceInputDialog(voiceService: _voiceService),
    );
  }

  void _showAssistantDialog(BuildContext context) {
    final suggestions = _assistantService.getCookingSuggestions(
      availableIngredients: [], // This would come from user's ingredients
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akıllı Öneriler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions.map((suggestion) => 
            ListTile(
              leading: const Icon(Icons.lightbulb, color: Colors.orange),
              title: Text(suggestion),
            ),
          ).toList(),
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

  void _showHistoryScreen(BuildContext context) {
    // This would show recent searches
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geçmiş özelliği yakında!')),
    );
  }

  void _showShoppingList(BuildContext context) {
    // This would show missing ingredients
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alışveriş listesi özelliği yakında!')),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yardım'),
        content: const Text(
          'Ne Yesem uygulaması ile:\n\n'
          '• Malzemelerinizi ekleyin\n'
          '• Fotoğraf çekerek malzeme tanıma\n'
          '• Sesli komutlar kullanın\n'
          '• Akıllı asistan önerileri alın\n'
          '• Size uygun tarifleri bulun'
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

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class VoiceInputDialog extends StatefulWidget {
  final VoiceService voiceService;

  const VoiceInputDialog({super.key, required this.voiceService});

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String _recognizedText = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    widget.voiceService.onSpeechResult = (text) {
      setState(() => _recognizedText = text);
    };

    widget.voiceService.onListeningStateChanged = (isListening) {
      setState(() => _isListening = isListening);
      if (isListening) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    };
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sesli Giriş'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _isListening ? 'Dinliyorum...' : 'Konuşmaya başlayın',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_recognizedText),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isListening 
            ? () => widget.voiceService.stopListening()
            : () => widget.voiceService.startListening(),
          child: Text(_isListening ? 'Durdur' : 'Başlat'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}