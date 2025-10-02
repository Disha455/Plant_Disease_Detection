import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import '../models/detection_result.dart';


class MLService {
  tfl.Interpreter? _classifierInterpreter;
  tfl.Interpreter? _segmentationInterpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;

  // Load both models - RENAMED METHOD
  Future<void> loadModels() async {
    try {
      print("🔄 Starting to load models...");

      // Load classifier model
      print("📱 Loading classifier model...");
      _classifierInterpreter = await tfl.Interpreter.fromAsset(
        'assets/models/plant_disease_classifier.tflite',
        options: tfl.InterpreterOptions()..threads = 2,
      );
      print("✅ Classifier model loaded successfully");

      // Load segmentation model
      print("🎯 Loading segmentation model...");
      _segmentationInterpreter = await tfl.Interpreter.fromAsset(
        'assets/models/plant_disease_segmentation.tflite',
        options: tfl.InterpreterOptions()..threads = 2,
      );
      print("✅ Segmentation model loaded successfully");

      _labels = [
        'Healthy',
        'Bacterial Spot',
        'Early Blight',
        'Late Blight',
        'Leaf Mold',
      ];

      _isModelLoaded = true;
      print("🎉 All models loaded successfully");
    } catch (e) {
      print("❌ Error loading models: $e");
      throw Exception('Failed to load ML models: $e');
    }
  }

  // For backward compatibility
  Future<void> loadModel() async {
    await loadModels();
  }

  // Update processCameraImage method
  Future<DetectionResult> processCameraImage(CameraImage image) async {
    if (!_isModelLoaded) {
      throw Exception('Models not loaded. Call loadModels() first.');
    }

    try {
      final bytes = _convertCameraImageToBytes(image);
      final input = _bytesToInputTensor(bytes, 224);

      final classificationResult = await _runClassification(input);
      final segmentationResult = await _runSegmentation(input);

      final severity = _calculateSeverity(segmentationResult);

      return DetectionResult(
        disease: _getDiseaseName(classificationResult),
        confidence: _getConfidence(classificationResult),
        severity: severity,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw Exception('Camera image processing failed: $e');
    }
  }

// Update analyzeImage method
  Future<DetectionResult> analyzeImage(String imagePath) async {
    if (!_isModelLoaded) {
      throw Exception('Models not loaded. Call loadModels() first.');
    }

    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Could not decode image');
      }

      final resized = img.copyResize(image, width: 224, height: 224);
      final input = _imageToByteListFloat32(resized, 224);

      final classificationResult = await _runClassification(input);
      final segmentationResult = await _runSegmentation(input);

      final severity = _calculateSeverity(segmentationResult);

      return DetectionResult(
        disease: _getDiseaseName(classificationResult),
        confidence: _getConfidence(classificationResult),
        severity: severity,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw Exception('Image analysis failed: $e');
    }
  }


  // Convert CameraImage to bytes
  Uint8List _convertCameraImageToBytes(CameraImage image) {
    try {
      // This is a simplified conversion - you may need to adjust based on your camera format
      final allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      return allBytes.done().buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to convert camera image: $e');
    }
  }

  // Convert bytes to input tensor
  Uint8List _bytesToInputTensor(Uint8List bytes, int inputSize) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Could not decode image');

    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    return _imageToByteListFloat32(resized, inputSize);
  }

  // Run classification inference
  Future<List<double>> _runClassification(Uint8List input) async {
    if (_classifierInterpreter == null) {
      throw Exception('Classification model not loaded');
    }

    try {
      final inputTensor = [input.buffer.asFloat32List().reshape([1, 224, 224, 3])];
      final outputTensor = [List.filled(_labels.length, 0.0)];

      _classifierInterpreter!.run(inputTensor, outputTensor);
      return outputTensor[0].cast<double>();
    } catch (e) {
      throw Exception('Classification inference failed: $e');
    }
  }

  // Run segmentation inference
  Future<List<double>> _runSegmentation(Uint8List input) async {
    if (_segmentationInterpreter == null) {
      throw Exception('Segmentation model not loaded');
    }

    try {
      final inputTensor = [input.buffer.asFloat32List().reshape([1, 224, 224, 3])];
      const outputSize = 224 * 224;
      final outputTensor = [List.filled(outputSize, 0.0)];

      _segmentationInterpreter!.run(inputTensor, outputTensor);
      return outputTensor[0].cast<double>();
    } catch (e) {
      throw Exception('Segmentation inference failed: $e');
    }
  }

  // Convert image to byte list for model input
  Uint8List _imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  String _getDiseaseName(List<double> classificationOutput) {
    int maxIndex = 0;
    double maxValue = classificationOutput[0];

    for (int i = 1; i < classificationOutput.length; i++) {
      if (classificationOutput[i] > maxValue) {
        maxValue = classificationOutput[i];
        maxIndex = i;
      }
    }

    return maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';
  }

  double _getConfidence(List<double> classificationOutput) {
    double maxValue = classificationOutput[0];
    for (int i = 1; i < classificationOutput.length; i++) {
      if (classificationOutput[i] > maxValue) {
        maxValue = classificationOutput[i];
      }
    }
    return maxValue;
  }

  double _calculateSeverity(List<double> segmentationOutput) {
    int diseasePixels = 0;
    int totalPixels = segmentationOutput.length;

    for (double pixel in segmentationOutput) {
      if (pixel > 0.5) {
        diseasePixels++;
      }
    }

    return totalPixels > 0 ? (diseasePixels / totalPixels) * 100 : 0.0;
  }

  void dispose() {
    _classifierInterpreter?.close();
    _segmentationInterpreter?.close();
  }
}

extension on Float32List {
  List<List<List<List<double>>>> reshape(List<int> shape) {
    if (shape.length != 4) throw ArgumentError('Expected 4D shape');

    final result = <List<List<List<double>>>>[];
    final b = shape[0], h = shape[1], w = shape[2], c = shape[3];

    for (int bi = 0; bi < b; bi++) {
      final batch = <List<List<double>>>[];
      for (int hi = 0; hi < h; hi++) {
        final row = <List<double>>[];
        for (int wi = 0; wi < w; wi++) {
          final pixel = <double>[];
          for (int ci = 0; ci < c; ci++) {
            final index = bi * h * w * c + hi * w * c + wi * c + ci;
            pixel.add(this[index]);
          }
          row.add(pixel);
        }
        batch.add(row);
      }
      result.add(batch);
    }
    return result;
  }
}
