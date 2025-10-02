import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import '../models/detection_result.dart';
import 'package:camera/camera.dart';

class MLServiceDebug {
  tfl.Interpreter? _classifierInterpreter;
  tfl.Interpreter? _segmentationInterpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    await loadModels();
  }

  Future<void> loadModels() async {
    try {
      print("🔍 Starting model diagnostics...");

      // Check if assets exist
      try {
        final manifestContent = await rootBundle.loadString('AssetManifest.json');
        print("📋 AssetManifest loaded successfully");

        // Check for our specific files
        if (manifestContent.contains('plant_disease_classifier.tflite')) {
          print("✅ Classifier asset found in manifest");
        } else {
          print("❌ Classifier asset NOT found in manifest");
        }

        if (manifestContent.contains('plant_disease_segmentation.tflite')) {
          print("✅ Segmentation asset found in manifest");
        } else {
          print("❌ Segmentation asset NOT found in manifest");
        }
      } catch (e) {
        print("❌ Cannot load AssetManifest: $e");
      }

      // Try to load classifier with detailed error info
      print("🔄 Attempting to load classifier model...");
      try {
        _classifierInterpreter = await tfl.Interpreter.fromAsset(
          'assets/models/plant_disease_classifier.tflite',
          options: tfl.InterpreterOptions()..threads = 1,
        );
        print("✅ Classifier model loaded successfully");

        // Get model info
        final inputTensors = _classifierInterpreter!.getInputTensors();
        final outputTensors = _classifierInterpreter!.getOutputTensors();
        print("📊 Classifier Input shape: ${inputTensors[0].shape}");
        print("📊 Classifier Output shape: ${outputTensors.shape}");
      } catch (e) {
        print("❌ Classifier failed to load: $e");
        throw Exception('Classifier loading failed: $e');
      }

      // Try to load segmentation with detailed error info
      print("🔄 Attempting to load segmentation model...");
      try {
        _segmentationInterpreter = await tfl.Interpreter.fromAsset(
          'assets/models/plant_disease_segmentation.tflite',
          options: tfl.InterpreterOptions()..threads = 1,
        );
        print("✅ Segmentation model loaded successfully");

        // Get model info
        final inputTensors = _segmentationInterpreter!.getInputTensors();
        final outputTensors = _segmentationInterpreter!.getOutputTensors();
        print("📊 Segmentation Input shape: ${inputTensors[0].shape}");
        print("📊 Segmentation Output shape: ${outputTensors.shape}");
      } catch (e) {
        print("❌ Segmentation failed to load: $e");
        throw Exception('Segmentation loading failed: $e');
      }

      _labels = [
        'Healthy',
        'Bacterial Spot',
        'Early Blight',
        'Late Blight',
        'Leaf Mold',
      ];

      _isModelLoaded = true;
      print("🎉 All models loaded successfully with debug info");
    } catch (e) {
      print("❌ Model loading failed with error: $e");
      rethrow;
    }
  }

  Future<DetectionResult> processCameraImage(CameraImage image) async {
    if (!_isModelLoaded) {
      throw Exception('Models not loaded. Call loadModels() first.');
    }

    // For now, return dummy result to test the flow
    await Future.delayed(const Duration(milliseconds: 300));
    return DetectionResult(
      disease: "Debug Mode - Real models loaded!",
      confidence: 0.95,
      severity: 25.0,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  Future<DetectionResult> analyzeImage(String imagePath) async {
    if (!_isModelLoaded) {
      throw Exception('Models not loaded. Call loadModels() first.');
    }

    print("🔄 Debug: Analyzing image at $imagePath");

    // For now, return dummy result but with real model validation
    await Future.delayed(const Duration(milliseconds: 500));
    return DetectionResult(
      disease: "Debug: Real Models Working!",
      confidence: 0.88,
      severity: 35.0,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  void dispose() {
    try {
      _classifierInterpreter?.close();
      _segmentationInterpreter?.close();
    } catch (_) {}
  }
}
