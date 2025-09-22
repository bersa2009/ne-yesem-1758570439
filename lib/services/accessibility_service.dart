import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Check if accessibility services are enabled
  static bool get isAccessibilityEnabled {
    return WidgetsBinding.instance.window.accessibilityFeatures.accessibleNavigation;
  }

  // Check if screen reader is enabled
  static bool get isScreenReaderEnabled {
    return WidgetsBinding.instance.window.accessibilityFeatures.accessibleNavigation;
  }

  // Check if high contrast is enabled
  static bool get isHighContrastEnabled {
    return WidgetsBinding.instance.window.accessibilityFeatures.highContrast;
  }

  // Check if large text is enabled
  static bool get isLargeTextEnabled {
    return WidgetsBinding.instance.window.accessibilityFeatures.boldText;
  }

  // Announce message to screen reader
  static void announce(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  // Create accessible button
  static Widget createAccessibleButton({
    required String label,
    required VoidCallback onPressed,
    String? semanticLabel,
    String? tooltip,
    IconData? icon,
    bool enabled = true,
  }) {
    return Semantics(
      label: semanticLabel ?? label,
      hint: tooltip,
      enabled: enabled,
      button: true,
      child: Tooltip(
        message: tooltip ?? label,
        child: ElevatedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
          label: Text(label),
        ),
      ),
    );
  }

  // Create accessible text field
  static Widget createAccessibleTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? semanticLabel,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
      ),
    );
  }

  // Create accessible list item
  static Widget createAccessibleListItem({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel ?? title,
      hint: subtitle,
      button: onTap != null,
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  // Create accessible image with description
  static Widget createAccessibleImage({
    required String imagePath,
    required String semanticLabel,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
      ),
    );
  }

  // Create accessible navigation
  static Widget createAccessibleNavigation({
    required List<NavigationItem> items,
    required int currentIndex,
    required Function(int) onTap,
  }) {
    return Semantics(
      container: true,
      label: 'Ana navigasyon',
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        items: items.map((item) => BottomNavigationBarItem(
          icon: Semantics(
            label: item.semanticLabel ?? item.label,
            child: Icon(item.icon),
          ),
          label: item.label,
        )).toList(),
      ),
    );
  }

  // Focus management helpers
  static void requestFocus(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  static void clearFocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // Color contrast helpers
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  static bool hasGoodContrast(Color foreground, Color background) {
    final ratio = _calculateContrastRatio(foreground, background);
    return ratio >= 4.5; // WCAG AA standard
  }

  static double _calculateContrastRatio(Color color1, Color color2) {
    final lum1 = color1.computeLuminance();
    final lum2 = color2.computeLuminance();
    final brightest = lum1 > lum2 ? lum1 : lum2;
    final darkest = lum1 > lum2 ? lum2 : lum1;
    return (brightest + 0.05) / (darkest + 0.05);
  }

  // Text scaling helpers
  static double getAccessibleTextScale(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.textScaleFactor.clamp(0.8, 2.0);
  }

  static TextStyle getAccessibleTextStyle(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    final textScale = getAccessibleTextScale(context);
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * textScale,
    );
  }

  // Haptic feedback helpers
  static void provideFeedback(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }

  // Voice guidance helpers
  static void provideVoiceGuidance(String text) {
    announce(text);
  }

  static String getVoiceGuidanceForAction(String action) {
    switch (action.toLowerCase()) {
      case 'camera':
        return 'Kamera açılıyor, malzeme fotoğrafı çekebilirsiniz';
      case 'voice':
        return 'Sesli giriş başlatılıyor, konuşmaya başlayabilirsiniz';
      case 'search':
        return 'Tarif arama başlatılıyor';
      case 'favorite':
        return 'Favorilere eklendi';
      case 'remove_favorite':
        return 'Favorilerden çıkarıldı';
      default:
        return '$action işlemi gerçekleştiriliyor';
    }
  }

  // Keyboard navigation helpers
  static Widget createKeyboardNavigable({
    required Widget child,
    required VoidCallback onActivate,
    String? semanticLabel,
  }) {
    return Focus(
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.enter) ||
            event.isKeyPressed(LogicalKeyboardKey.space)) {
          onActivate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        label: semanticLabel,
        focusable: true,
        child: child,
      ),
    );
  }

  // Screen reader helpers
  static Widget createScreenReaderOnly({
    required String text,
  }) {
    return Semantics(
      label: text,
      child: const SizedBox.shrink(),
    );
  }

  // High contrast theme helper
  static ThemeData getHighContrastTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.white,
        onSecondary: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
        background: Colors.white,
        onBackground: Colors.black,
      ),
    );
  }

  // Accessibility testing helpers
  static void testAccessibility(BuildContext context) {
    if (!kReleaseMode) {
      // Only run in debug mode
      final mediaQuery = MediaQuery.of(context);
      debugPrint('Accessibility Features:');
      debugPrint('- Text Scale: ${mediaQuery.textScaleFactor}');
      debugPrint('- High Contrast: ${mediaQuery.highContrast}');
      debugPrint('- Bold Text: ${mediaQuery.boldText}');
      debugPrint('- Accessible Navigation: ${mediaQuery.accessibleNavigation}');
    }
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final String? semanticLabel;

  NavigationItem({
    required this.label,
    required this.icon,
    this.semanticLabel,
  });
}

// Accessibility widget wrapper
class AccessibilityWrapper extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final String? hint;
  final bool excludeSemantics;

  const AccessibilityWrapper({
    super.key,
    required this.child,
    this.semanticLabel,
    this.hint,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    if (excludeSemantics) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      label: semanticLabel,
      hint: hint,
      child: child,
    );
  }
}

// Focus management widget
class FocusManager extends StatefulWidget {
  final Widget child;
  final List<FocusNode> focusNodes;

  const FocusManager({
    super.key,
    required this.child,
    required this.focusNodes,
  });

  @override
  State<FocusManager> createState() => _FocusManagerState();
}

class _FocusManagerState extends State<FocusManager> {
  int _currentFocusIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
          _moveFocus(event.isShiftPressed ? -1 : 1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }

  void _moveFocus(int direction) {
    _currentFocusIndex += direction;
    if (_currentFocusIndex < 0) {
      _currentFocusIndex = widget.focusNodes.length - 1;
    } else if (_currentFocusIndex >= widget.focusNodes.length) {
      _currentFocusIndex = 0;
    }
    
    widget.focusNodes[_currentFocusIndex].requestFocus();
  }
}

enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}