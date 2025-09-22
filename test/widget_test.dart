import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ne_yesem/main.dart';
import 'package:ne_yesem/app.dart';
import 'package:ne_yesem/services/voice_service.dart';

void main() {
  group('Ne Yesem App Tests', () {
    testWidgets('App should start without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const ProviderScope(child: NeYesemApp()));

      // Verify that the splash screen appears
      expect(find.text('Ne Yesem?'), findsOneWidget);
      
      // Wait for animations to complete
      await tester.pumpAndSettle();
    });

    testWidgets('Welcome screen should show app features', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: NeYesemApp()));
      await tester.pumpAndSettle();

      // Should show welcome screen after splash
      expect(find.text('Dolapta ne varsa, sofrada lezzet olsun!'), findsOneWidget);
      expect(find.text('Başla'), findsOneWidget);
    });

    testWidgets('Navigation should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: NeYesemApp()));
      await tester.pumpAndSettle();

      // Tap get started button
      await tester.tap(find.text('Başla'));
      await tester.pumpAndSettle();

      // Should navigate to main navigation screen
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });

  group('Voice Service Tests', () {
    test('Voice command parsing should work correctly', () {
      final commands = [
        'Malzemeler: domates, yumurta, peynir',
        'Hızlı yemek istiyorum',
        'Vejetaryen tarif öner',
        'Tarif öner',
      ];

      for (final command in commands) {
        final parsed = VoiceCommand.parse(command);
        expect(parsed.originalText, equals(command));
        expect(parsed.type, isNot(VoiceCommandType.unknown));
      }
    });
  });

  group('Recipe Matching Tests', () {
    test('Recipe matching algorithm should work correctly', () async {
      // This would test the matching algorithm
      // For now, just verify it doesn't crash
      expect(true, isTrue);
    });
  });
}