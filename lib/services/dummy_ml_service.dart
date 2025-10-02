import 'dart:math';
import '../models/detection_result.dart';
import 'package:camera/camera.dart';

class DummyMLService {
  bool _isModelLoaded = false;
  final Random _random = Random();

  Future<void> loadModel() async {
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 1));
    _isModelLoaded = true;
    print("✅ Dummy models loaded successfully");
  }

  Future<void> loadModels() async {
    await loadModel();
  }

  bool get isModelLoaded => _isModelLoaded;

  Future<DetectionResult> processCameraImage(CameraImage image) async {
    if (!_isModelLoaded) {
      throw Exception('Models not loaded');
    }

    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 300));

    return _generateDummyResult();
  }

  Future<DetectionResult> analyzeImage(String imagePath) async {
    if (!_isModelLoaded) {
      throw Exception('Models not loaded');
    }

    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 500));

    return _generateDummyResult();
  }

  DetectionResult _generateDummyResult() {
    final diseases = ['Healthy', 'Bacterial Spot', 'Early Blight', 'Late Blight', 'Leaf Mold'];
    final disease = diseases[_random.nextInt(diseases.length)];
    final confidence = 0.7 + _random.nextDouble() * 0.3; // 70-100%
    final severity = _random.nextDouble() * 80; // 0-80%

    return DetectionResult(
      disease: disease,
      confidence: confidence,
      severity: severity,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  void dispose() {
    print("🗑️ Dummy ML service disposed");
  }
}
