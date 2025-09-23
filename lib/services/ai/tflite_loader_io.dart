import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

Future<Object?> tfliteLoadFromAsset(String assetPath) async {
  try {
    return tfl.Interpreter.fromAsset(assetPath);
  } catch (_) {
    return null;
  }
}

