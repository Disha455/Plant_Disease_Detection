import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../services/real_hybrid_ml_service.dart';  // ← Changed back to real MLService
import '../models/detection_result.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late RealHybridMLService _mlService;  // ← Changed back to real MLService
  bool _isMLLoaded = false;
  bool _isProcessing = false;
  DetectionResult? _latestResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeML();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> _initializeML() async {
    try {
      print("🔄 Initializing real ML models in camera...");
      _mlService = RealHybridMLService();  // ← Real service
      await _mlService.loadModels();
      if (mounted) {
        setState(() {
          _isMLLoaded = true;
        });
        print("✅ Real ML Service loaded in camera");
      }
    } catch (e) {
      print("❌ Real ML initialization failed: $e");
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (!_controller.value.isInitialized || !_isMLLoaded || _isProcessing) {
      print("❌ Cannot capture: camera=${_controller.value.isInitialized}, ml=$_isMLLoaded, processing=$_isProcessing");
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print("📸 Taking picture...");
      final image = await _controller.takePicture();

      print("🔄 Starting real analysis...");
      final result = await _mlService.analyzeImage(image.path);

      if (mounted) {
        setState(() {
          _latestResult = result;
        });
        print("✅ Real analysis complete: ${result.disease}");
      }
    } catch (e) {
      print("❌ Real capture/analysis failed: $e");
      if (mounted) {
        _showErrorSnackBar('Analysis failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _severityColor(double severity) {
    if (severity < 25) return Colors.green;
    if (severity < 50) return Colors.orange;
    if (severity < 75) return Colors.red;
    return Colors.red[900]!;
  }

  Widget _buildResultOverlay(DetectionResult result) {
    final color = _severityColor(result.severity);

    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disease: ${result.disease}  (${(result.confidence * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: result.severity / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${result.severity.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isMLLoaded ? Colors.green.withOpacity(0.8) : Colors.orange.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _isMLLoaded ? '✅ Real AI Ready' : '⏳ Loading Real AI...',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned(
      bottom: 200,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 16),
            Text(
              'Real AI Analyzing...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real AI Camera Analysis'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera Preview
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),

          // Status overlay
          _buildStatusOverlay(),

          // Result overlay
          if (_latestResult != null) _buildResultOverlay(_latestResult!),

          // Processing overlay
          if (_isProcessing) _buildProcessingOverlay(),

          // Capture button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: (_isMLLoaded && !_isProcessing) ? _captureAndAnalyze : null,
                backgroundColor: (_isMLLoaded && !_isProcessing) ? Colors.green : Colors.grey,
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),

          // Clear results button
          if (_latestResult != null)
            Positioned(
              bottom: 30,
              right: 30,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  setState(() {
                    _latestResult = null;
                  });
                },
                backgroundColor: Colors.red,
                child: const Icon(Icons.clear, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
