import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'ingredients_screen.dart';
import '../widgets/app_navigation.dart';
import '../../services/voice/voice_service.dart';
import '../../services/camera/camera_service.dart';
import '../../services/assistant/assistant_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final VoiceService _voiceService = VoiceService();
  final CameraService _cameraService = CameraService();
  final AssistantService _assistantService = AssistantService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    
    _animationController.forward();
    _initializeServices();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeServices() async {
    await Future.wait([
      _voiceService.initialize(),
      _cameraService.initialize(),
      _assistantService.initialize(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showQuickActions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        
                        // App Icon and Title
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Ne Yesem?',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Dolapta ne varsa, sofrada lezzet olsun!',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Quick Action Buttons
                        AnimationLimiter(
                          child: Column(
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(child: widget),
                              ),
                              children: [
                                _buildQuickActionButton(
                                  context,
                                  'Malzemelerimi Ekle',
                                  'Manuel olarak malzeme seç',
                                  Icons.edit,
                                  Theme.of(context).colorScheme.primary,
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const IngredientsScreen()),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildQuickActionButton(
                                        context,
                                        'Fotoğraf Çek',
                                        'Kamera ile tanı',
                                        Icons.camera_alt,
                                        Colors.green,
                                        () => _handleCameraAction(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildQuickActionButton(
                                        context,
                                        'Sesli Giriş',
                                        'Konuşarak ekle',
                                        Icons.mic,
                                        Colors.orange,
                                        () => _handleVoiceAction(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                _buildQuickActionButton(
                                  context,
                                  'Akıllı Öneriler',
                                  'AI destekli tarif önerileri',
                                  Icons.smart_toy,
                                  Colors.purple,
                                  () => _showSmartSuggestions(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCameraAction() async {
    final file = await _cameraService.showImageSourceDialog(context);
    if (file != null) {
      final ingredients = await _cameraService.recognizeIngredients(file);
      if (ingredients.isNotEmpty && mounted) {
        _showRecognizedIngredientsDialog(ingredients);
      }
    }
  }

  void _handleVoiceAction() async {
    if (await _voiceService.initialize()) {
      _showVoiceInputDialog();
    } else {
      _showErrorSnackBar('Mikrofon izni gerekli');
    }
  }

  void _showSmartSuggestions() {
    final suggestions = _assistantService.getCookingSuggestions(
      availableIngredients: [],
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

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favoriler'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to favorites
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Geçmiş'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to history
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRecognizedIngredientsDialog(List<String> ingredients) {
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

  void _showVoiceInputDialog() {
    showDialog(
      context: context,
      builder: (context) => VoiceInputDialog(voiceService: _voiceService),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

