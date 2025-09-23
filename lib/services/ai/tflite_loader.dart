import 'tflite_bridge.dart' show TfliteInterpreterStub; // keep analyzer happy on web
import 'tflite_bridge_io.dart' show TfliteInterpreterIO; // only used on io

Future<Object?> tfliteLoadFromAsset(String assetPath) async {
  try {
    // On IO platforms, use real loader
    // ignore: unnecessary_cast
    final loader = TfliteInterpreterIO as Type?; // exists on IO builds
    if (loader != null) {
      return TfliteInterpreterIO.fromAsset(assetPath);
    }
  } catch (_) {}
  return null; // For web/unsupported
}

