import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siri_wave/siri_wave.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/voice_service.dart';
import '../../services/assistant_service.dart';

class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  
  bool _isListening = false;
  String _assistantMessage = '';
  List<String> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _assistantMessage = 'Merhaba! Size nasıl yardımcı olabilirim?';
    _speakWelcome();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _speakWelcome() async {
    final voiceService = ref.read(voiceServiceProvider);
    if (!voiceService.isInitialized) {
      await voiceService.initialize();
    }
    await voiceService.speak(_assistantMessage);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    // Listen to voice recognition
    ref.listen(voiceRecognitionStreamProvider, (previous, next) {
      next.whenData((result) {
        if (result.isFinal && result.recognizedText.isNotEmpty) {
          _processVoiceCommand(result.recognizedText);
        }
      });
    });

    // Listen to assistant responses
    ref.listen(assistantResponseStreamProvider, (previous, next) {
      next.whenData((response) {
        _handleAssistantResponse(response);
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ne Yesem Asistanı'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearConversation,
            icon: const Icon(Icons.refresh),
            tooltip: 'Konuşmayı yenile',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Conversation History
              Expanded(
                child: _buildConversationHistory(),
              ),
              
              // Voice Visualization
              Container(
                height: 200,
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: _buildVoiceVisualization(),
              ),
              
              // Assistant Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                  vertical: AppTheme.spacingMedium,
                ),
                child: Text(
                  _assistantMessage,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Control Buttons
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: _buildControlButtons(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationHistory() {
    if (_conversationHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assistant,
              size: 80,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              'Ne Yesem Asistanı',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Sesli komutlarınızı bekliyorum...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      itemCount: _conversationHistory.length,
      itemBuilder: (context, index) {
        final message = _conversationHistory[index];
        final isUser = index % 2 == 0;
        
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: isUser 
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceVisualization() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening 
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Siri-like wave visualization
                  if (_isListening)
                    SizedBox(
                      width: 80,
                      height: 40,
                      child: SiriWaveform.ios9(
                        controller: SiriWaveformController(),
                        options: const IOS9SiriWaveformOptions(
                          height: 40,
                          showSupportBar: true,
                          waveColor: Colors.white,
                          supportBarColor: Colors.white54,
                        ),
                      ),
                    ),
                  
                  // Microphone Icon
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 40,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlButtons(AppLocalizations l10n) {
    return Column(
      children: [
        // Main Voice Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isListening ? _stopListening : _startListening,
            icon: Icon(_isListening ? Icons.stop : Icons.mic),
            label: Text(_isListening ? l10n.stopListening : l10n.startListening),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.mediumRadius,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        // Quick Commands
        Row(
          children: [
            Expanded(
              child: _buildQuickCommandButton(
                'Malzeme Ekle',
                Icons.add,
                () => _executeQuickCommand('Malzemeler: domates, yumurta'),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _buildQuickCommandButton(
                'Tarif Öner',
                Icons.restaurant,
                () => _executeQuickCommand('Tarif öner'),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _buildQuickCommandButton(
                'Hızlı Yemek',
                Icons.flash_on,
                () => _executeQuickCommand('Hızlı yemek istiyorum'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCommandButton(String text, IconData icon, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _startListening() async {
    try {
      setState(() {
        _isListening = true;
        _assistantMessage = 'Dinliyorum... Komutunuzu söyleyebilirsiniz.';
      });
      
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
      
      final voiceService = ref.read(voiceServiceProvider);
      if (!voiceService.isInitialized) {
        await voiceService.initialize();
      }
      
      await voiceService.startListening();
      
    } catch (e) {
      setState(() {
        _isListening = false;
        _assistantMessage = 'Ses tanıma başlatılamadı: $e';
      });
      _pulseController.stop();
      _waveController.stop();
    }
  }

  Future<void> _stopListening() async {
    try {
      setState(() {
        _isListening = false;
        _assistantMessage = 'Dinleme durduruldu.';
      });
      
      _pulseController.stop();
      _waveController.stop();
      
      final voiceService = ref.read(voiceServiceProvider);
      await voiceService.stopListening();
      
    } catch (e) {
      setState(() {
        _assistantMessage = 'Dinleme durdurulamadı: $e';
      });
    }
  }

  Future<void> _processVoiceCommand(String command) async {
    setState(() {
      _isListening = false;
      _assistantMessage = 'Komutunuz işleniyor...';
    });
    
    _pulseController.stop();
    _waveController.stop();
    
    // Add user message to history
    _conversationHistory.add('Siz: $command');
    
    try {
      final assistantService = ref.read(assistantServiceProvider);
      final response = await assistantService.processVoiceCommand(command);
      
      // Add assistant response to history
      _conversationHistory.add('Asistan: ${response.message}');
      
      setState(() {
        _assistantMessage = response.message;
      });
      
      // Speak the response
      final voiceService = ref.read(voiceServiceProvider);
      await voiceService.speak(response.message);
      
      // Handle specific response types
      _handleAssistantResponse(response);
      
    } catch (e) {
      setState(() {
        _assistantMessage = 'Komut işlenirken hata oluştu: $e';
      });
      
      _conversationHistory.add('Hata: $e');
    }
  }

  void _handleAssistantResponse(AssistantResponse response) {
    switch (response.type) {
      case AssistantResponseType.success:
        if (response.data['action'] == 'ingredients_added') {
          final ingredients = response.data['ingredients'] as List<String>? ?? [];
          if (ingredients.isNotEmpty) {
            // Navigate to ingredients screen and add ingredients
            Navigator.of(context).pop();
            // The ingredients will be added via the provider
          }
        }
        break;
      case AssistantResponseType.recipeFound:
        final recipe = response.data['recipe'];
        if (recipe != null) {
          // Show recipe suggestions
          _showRecipeSuggestions(response.data);
        }
        break;
      case AssistantResponseType.clarification:
        // Assistant needs more information
        _showClarificationDialog(response.message);
        break;
      case AssistantResponseType.noResults:
        // No recipes found
        _showNoResultsDialog(response.message);
        break;
      default:
        break;
    }
  }

  void _executeQuickCommand(String command) {
    _conversationHistory.add('Hızlı Komut: $command');
    _processVoiceCommand(command);
  }

  void _showRecipeSuggestions(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Text(
                'Önerilen Tarifler',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                children: [
                  Card(
                    child: ListTile(
                      title: Text(data['recipe']?.name ?? 'Tarif'),
                      subtitle: Text('${data['score']} puan eşleşme'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.of(context).pop();
                        // Navigate to recipe detail
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClarificationDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daha Fazla Bilgi Gerekli'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startListening();
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  void _showNoResultsDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sonuç Bulunamadı'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executeQuickCommand('Malzeme ekle');
            },
            child: const Text('Malzeme Ekle'),
          ),
        ],
      ),
    );
  }

  void _clearConversation() {
    setState(() {
      _conversationHistory.clear();
      _assistantMessage = 'Konuşma temizlendi. Yeni bir komut verebilirsiniz.';
    });
    
    final voiceService = ref.read(voiceServiceProvider);
    voiceService.speak(_assistantMessage);
  }
}

// Voice Assistant Widget for Integration
class VoiceAssistantWidget extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const VoiceAssistantWidget({
    super.key,
    this.onClose,
  });

  @override
  ConsumerState<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends ConsumerState<VoiceAssistantWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Assistant Avatar
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? 1.1 : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.assistant,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Status Text
          Text(
            _isListening ? 'Dinliyorum...' : 'Ne Yesem Asistanı',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _isListening ? _stopListening : _startListening,
                icon: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const VoiceAssistantScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startListening() async {
    setState(() => _isListening = true);
    _animationController.repeat(reverse: true);
    
    final voiceService = ref.read(voiceServiceProvider);
    if (!voiceService.isInitialized) {
      await voiceService.initialize();
    }
    await voiceService.startListening();
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    _animationController.stop();
    
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.stopListening();
  }
}