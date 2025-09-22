import 'package:flutter/material.dart';

class SpeechButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const SpeechButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isListening ? Icons.mic : Icons.mic_none,
        color: isListening ? Colors.red : null,
      ),
      onPressed: onPressed,
      tooltip: isListening ? 'Ses girişini durdur' : 'Sesli malzeme ekle',
    );
  }
}