import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isInitialized = false;

  // Initialize cameras
  Future<bool> initialize() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        return false;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) return false;

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller?.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      return false;
    }
  }

  // Take photo from camera
  Future<File?> takePhoto() async {
    if (!_isInitialized || _controller == null) {
      await initialize();
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Take photo error: $e');
      return null;
    }
  }

  // Pick image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Pick from gallery error: $e');
      return null;
    }
  }

  // Recognize ingredients from image using ML Kit
  Future<List<String>> recognizeIngredients(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      // Extract potential ingredient names from recognized text
      List<String> potentialIngredients = [];
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String text = line.text.toLowerCase().trim();
          if (text.isNotEmpty && text.length > 2) {
            potentialIngredients.add(text);
          }
        }
      }
      
      textRecognizer.close();
      
      // Filter and match with known ingredients
      return _filterKnownIngredients(potentialIngredients);
    } catch (e) {
      debugPrint('Ingredient recognition error: $e');
      return [];
    }
  }

  // Filter recognized text against known ingredients
  List<String> _filterKnownIngredients(List<String> recognizedText) {
    // Common Turkish ingredients that might be recognized
    final commonIngredients = [
      'domates', 'soğan', 'sarımsak', 'biber', 'patates', 'havuç', 'kabak',
      'patlıcan', 'salatalık', 'marul', 'maydanoz', 'dereotu', 'nane',
      'et', 'tavuk', 'balık', 'yumurta', 'peynir', 'süt', 'yoğurt',
      'pirinç', 'makarna', 'bulgur', 'un', 'şeker', 'tuz', 'karabiber',
      'zeytinyağı', 'tereyağı', 'limon', 'elma', 'muz', 'portakal'
    ];

    List<String> matchedIngredients = [];
    
    for (String recognized in recognizedText) {
      for (String ingredient in commonIngredients) {
        if (recognized.contains(ingredient) || ingredient.contains(recognized)) {
          if (!matchedIngredients.contains(ingredient)) {
            matchedIngredients.add(ingredient);
          }
        }
      }
    }
    
    return matchedIngredients;
  }

  // Show image source selection dialog
  Future<File?> showImageSourceDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğraf Seç'),
        content: const Text('Malzeme fotoğrafını nereden eklemek istiyorsunuz?'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final file = await takePhoto();
              if (context.mounted) Navigator.pop(context, file);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Kamera'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final file = await pickFromGallery();
              if (context.mounted) Navigator.pop(context, file);
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeri'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  // Dispose resources
  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}