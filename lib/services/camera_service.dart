import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  Future<bool> initialize() async {
    final hasPermission = await Permission.camera.request().isGranted;
    if (!hasPermission) return false;

    _cameras = await availableCameras();
    if (_cameras!.isEmpty) return false;

    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    _isInitialized = true;
    return true;
  }

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<void> dispose() async {
    await _controller?.dispose();
    _isInitialized = false;
  }

  // Take picture and analyze for ingredients
  Future<List<String>> analyzeImage() async {
    if (!_isInitialized || _controller == null) return [];

    try {
      final image = await _controller!.takePicture();
      // TODO: Implement ML Kit or external API for ingredient recognition
      // For now, return mock data
      return _mockIngredientRecognition(image.path);
    } catch (e) {
      print('Error taking picture: $e');
      return [];
    }
  }

  // Pick image from gallery
  Future<List<String>> pickImageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // TODO: Implement image analysis
      return _mockIngredientRecognition(image.path);
    }

    return [];
  }

  // Mock ingredient recognition - replace with actual ML
  List<String> _mockIngredientRecognition(String imagePath) {
    // Simple mock based on common ingredients
    final mockIngredients = [
      'domates', 'sogan', 'patates', 'havuc', 'brokoli',
      'tavuk', 'et', 'balik', 'yumurta', 'sut'
    ];

    // Return 1-3 random ingredients
    mockIngredients.shuffle();
    return mockIngredients.take(2 + DateTime.now().millisecond % 2).toList();
  }

  // Barcode scanning (placeholder)
  Future<String?> scanBarcode() async {
    if (!_isInitialized || _controller == null) return null;

    try {
      // TODO: Implement barcode scanning with google_ml_kit or similar
      return 'barcode_placeholder';
    } catch (e) {
      print('Error scanning barcode: $e');
      return null;
    }
  }
}