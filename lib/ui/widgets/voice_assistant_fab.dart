import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../screens/voice_assistant_screen.dart';

class VoiceAssistantFAB extends ConsumerStatefulWidget {
  final VoidCallback? onPressed;

  const VoiceAssistantFAB({
    super.key,
    this.onPressed,
  });

  @override
  ConsumerState<VoiceAssistantFAB> createState() => _VoiceAssistantFABState();
}

class _VoiceAssistantFABState extends ConsumerState<VoiceAssistantFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isActive ? _pulseAnimation.value : 1.0,
          child: FloatingActionButton(
            heroTag: 'voice_assistant',
            onPressed: _handlePress,
            backgroundColor: AppTheme.primaryColor,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.assistant, color: Colors.white),
                if (_isActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePress() {
    setState(() {
      _isActive = !_isActive;
    });
    
    if (_isActive) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
    }
    
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const VoiceAssistantScreen(),
          fullscreenDialog: true,
        ),
      );
    }
  }
}

// Quick Voice Commands Widget
class QuickVoiceCommands extends StatelessWidget {
  final Function(String) onCommandSelected;

  const QuickVoiceCommands({
    super.key,
    required this.onCommandSelected,
  });

  @override
  Widget build(BuildContext context) {
    final commands = [
      VoiceCommandSuggestion(
        text: 'Malzemeler: domates, yumurta, peynir',
        icon: Icons.kitchen,
        description: 'Malzemelerinizi söyleyin',
      ),
      VoiceCommandSuggestion(
        text: 'Hızlı yemek istiyorum',
        icon: Icons.flash_on,
        description: '15 dakikada tarif',
      ),
      VoiceCommandSuggestion(
        text: 'Vejetaryen tarif öner',
        icon: Icons.eco,
        description: 'Sebze yemekleri',
      ),
      VoiceCommandSuggestion(
        text: 'Tarif öner',
        icon: Icons.restaurant,
        description: 'Genel tarif önerisi',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı Komutlar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ...commands.map((command) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    command.icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  command.text,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(command.description),
                trailing: const Icon(Icons.mic),
                onTap: () => onCommandSelected(command.text),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class VoiceCommandSuggestion {
  final String text;
  final IconData icon;
  final String description;

  const VoiceCommandSuggestion({
    required this.text,
    required this.icon,
    required this.description,
  });
}