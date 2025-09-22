import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/assistant_service.dart';
import 'ingredients_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final ImagePicker _picker = ImagePicker();
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _speechText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onSoundLevelChange: (level) {},
    );
    if (!available) {
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ses tanıma kullanılamıyor')),
        );
      }
    }
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _speechText = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("tr-TR");
    await _flutterTts.speak(text);
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        // Kamera ile çekilen fotoğrafı işle (görsel tanıma için)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fotoğraf çekildi: ${photo.name}')),
          );
          // Burada görsel tanıma servisi çağrılabilir
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera hatası: $e')),
        );
      }
    }
  }

  Future<void> _openAssistant() async {
    try {
      final assistantName = AssistantService.getAssistantName();
      await AssistantService.openVoiceAssistant();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$assistantName açılıyor...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asistan açılamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ne Yesem?'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'camera':
                  _takePhoto();
                  break;
                case 'voice':
                  _startListening();
                  break;
                case 'help':
                  _speak('Ne Yesem uygulamasına hoş geldiniz! Malzemelerinizi ekleyip size uygun tarifler bulabilirsiniz.');
                  break;
                case 'assistant':
                  _openAssistant();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'camera',
                child: ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Kamera ile Ekle'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'voice',
                child: ListTile(
                  leading: Icon(Icons.mic),
                  title: Text('Sesli Ekle'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Yardım'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'assistant',
                child: ListTile(
                  leading: Icon(Icons.assistant),
                  title: Text('Sesli Asistan'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text('Ne Yesem?', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Dolapta ne varsa, sofrada lezzet olsun!', style: TextStyle(fontSize: 16)),
              if (_speechText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Söylediğiniz: $_speechText',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IngredientsScreen()));
                      },
                      icon: const Icon(Icons.kitchen),
                      label: const Text('Malzemelerini Ekle'),
                    ),
                  ),
                  if (_speechText.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Sesli metni işle ve malzemeleri çıkar
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IngredientsScreen()));
                      },
                      icon: const Icon(Icons.mic),
                      label: const Text('Sesli Ara'),
                    ),
                  ],
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

