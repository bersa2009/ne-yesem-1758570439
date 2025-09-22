import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';

class CameraService {
  static CameraService? _instance;
  static CameraService get instance => _instance ??= CameraService._();
  CameraService._();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isInitialized = false;

  List<CameraDescription> get cameras => _cameras;
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  /// Initialize camera service
  Future<bool> initialize() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        return false;
      }

      // Initialize camera controller with back camera
      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      return false;
    }
  }

  /// Take a picture and analyze for ingredients
  Future<CameraAnalysisResult> takePictureAndAnalyze() async {
    if (!_isInitialized || _controller == null) {
      return CameraAnalysisResult(
        success: false,
        error: 'Kamera başlatılamadı',
        detectedIngredients: [],
      );
    }

    try {
      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();
      
      // Analyze the image for ingredients
      final ingredients = await _analyzeImageForIngredients(imageBytes);
      
      return CameraAnalysisResult(
        success: true,
        imagePath: image.path,
        detectedIngredients: ingredients,
      );
    } catch (e) {
      return CameraAnalysisResult(
        success: false,
        error: 'Fotoğraf çekilemedi: $e',
        detectedIngredients: [],
      );
    }
  }

  /// Analyze image for ingredients using basic pattern matching
  Future<List<DetectedIngredient>> _analyzeImageForIngredients(Uint8List imageBytes) async {
    // This is a simplified version - in a real app, you'd use ML/AI services
    // like Google Vision API, AWS Rekognition, or a custom trained model
    
    // For demo purposes, return some common ingredients
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing time
    
    return [
      DetectedIngredient(
        ingredientId: 'domates',
        name: 'Domates',
        confidence: 0.85,
        boundingBox: const Rect.fromLTWH(100, 150, 200, 180),
      ),
      DetectedIngredient(
        ingredientId: 'sogan',
        name: 'Soğan',
        confidence: 0.72,
        boundingBox: const Rect.fromLTWH(320, 200, 150, 160),
      ),
    ];
  }

  /// Dispose camera resources
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}

class BarcodeService {
  static BarcodeService? _instance;
  static BarcodeService get instance => _instance ??= BarcodeService._();
  BarcodeService._();

  MobileScannerController? _scannerController;

  /// Initialize barcode scanner
  Future<bool> initialize() async {
    try {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        return false;
      }

      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      return true;
    } catch (e) {
      debugPrint('Barcode scanner initialization error: $e');
      return false;
    }
  }

  /// Scan barcode and get product information
  Stream<BarcodeDetectionResult> scanBarcode() async* {
    if (_scannerController == null) {
      yield BarcodeDetectionResult(
        success: false,
        error: 'Barkod tarayıcı başlatılamadı',
      );
      return;
    }

    yield* _scannerController!.barcodes.map((capture) {
      if (capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        return BarcodeDetectionResult(
          success: true,
          barcode: barcode.rawValue ?? '',
          productInfo: _getProductInfoFromBarcode(barcode.rawValue ?? ''),
        );
      }
      return BarcodeDetectionResult(success: false);
    });
  }

  /// Get product information from barcode (simplified version)
  ProductInfo? _getProductInfoFromBarcode(String barcode) {
    // In a real app, you'd query a product database like OpenFoodFacts API
    // This is a simplified demo version
    
    final Map<String, ProductInfo> mockDatabase = {
      '8690504004011': ProductInfo(
        barcode: '8690504004011',
        name: 'Domates Salçası',
        brand: 'Tat',
        ingredients: ['domates', 'tuz'],
        category: 'Konserve',
      ),
      '8690637008016': ProductInfo(
        barcode: '8690637008016',
        name: 'Makarna',
        brand: 'Barilla',
        ingredients: ['bugday_unu', 'su'],
        category: 'Tahıl',
      ),
    };

    return mockDatabase[barcode];
  }

  /// Dispose scanner resources
  void dispose() {
    _scannerController?.dispose();
    _scannerController = null;
  }

  MobileScannerController? get controller => _scannerController;
}

// Data classes for camera analysis results
class CameraAnalysisResult {
  final bool success;
  final String? error;
  final String? imagePath;
  final List<DetectedIngredient> detectedIngredients;

  CameraAnalysisResult({
    required this.success,
    this.error,
    this.imagePath,
    required this.detectedIngredients,
  });
}

class DetectedIngredient {
  final String ingredientId;
  final String name;
  final double confidence;
  final Rect boundingBox;

  DetectedIngredient({
    required this.ingredientId,
    required this.name,
    required this.confidence,
    required this.boundingBox,
  });
}

class BarcodeDetectionResult {
  final bool success;
  final String? error;
  final String? barcode;
  final ProductInfo? productInfo;

  BarcodeDetectionResult({
    required this.success,
    this.error,
    this.barcode,
    this.productInfo,
  });
}

class ProductInfo {
  final String barcode;
  final String name;
  final String brand;
  final List<String> ingredients;
  final String category;

  ProductInfo({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.ingredients,
    required this.category,
  });
}