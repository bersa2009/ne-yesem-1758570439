import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceSearchScreen extends StatefulWidget {
  const VoiceSearchScreen({super.key});

  @override
  State<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends State<VoiceSearchScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Mikrofonu dinliyorum...';
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onSoundLevelChange: (level) {
          print('Sound level: $level');
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _text = 'Dinliyorum...';
        });

        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              if (result.finalResult) {
                _lastWords = result.recognizedWords;
              }
            });
          },
          localeId: 'tr_TR', // Türkçe için
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
      _speech.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesli Arama'),
        actions: [
          IconButton(
            onPressed: _isListening ? _stopListening : null,
            icon: const Icon(Icons.stop),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _text,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_lastWords.isNotEmpty) ...[
              Text(
                'Son sözler: $_lastWords',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ],
            FloatingActionButton.large(
              onPressed: _listen,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isListening ? 'Dinliyorum...' : 'Konuşmak için dokun',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}