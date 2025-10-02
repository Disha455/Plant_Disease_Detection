import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/real_hybrid_ml_service.dart';  // ← Changed back to real MLService
import '../services/image_picker_service.dart';
import '../models/detection_result.dart';

class GalleryAnalysisScreen extends StatefulWidget {
  const GalleryAnalysisScreen({super.key});

  @override
  State<GalleryAnalysisScreen> createState() => _GalleryAnalysisScreenState();
}

class _GalleryAnalysisScreenState extends State<GalleryAnalysisScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  DetectionResult? _analysisResult;
  late RealHybridMLService _mlService;  // ← Changed back to real MLService
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      print("🔄 Initializing real ML models...");
      _mlService = RealHybridMLService();  // ← Real service
      await _mlService.loadModel();
      if (mounted) {
        setState(() {
          _isModelLoaded = true;
        });
        print("✅ Real models loaded successfully");
      }
    } catch (e) {
      print("❌ Failed to load real AI model: $e");
      if (mounted) {
        _showErrorDialog('Failed to load AI model: $e');
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await ImagePickerService.pickImageFromGallery();

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _analysisResult = null;
        });
        print("📸 Image selected from gallery: ${pickedFile.path}");
      }
    } catch (e) {
      print("❌ Failed to pick image: $e");
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await ImagePickerService.pickImageFromCamera();

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _analysisResult = null;
        });
        print("📸 Image captured from camera: ${pickedFile.path}");
      }
    } catch (e) {
      print("❌ Failed to capture image: $e");
      _showErrorDialog('Failed to capture image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || !_isModelLoaded) {
      print("❌ Cannot analyze: image=${_selectedImage != null}, modelLoaded=$_isModelLoaded");
      return;
    }

    print("🔄 Starting real image analysis...");
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _mlService.analyzeImage(_selectedImage!.path);
      if (mounted) {
        setState(() {
          _analysisResult = result;
        });
        print("✅ Real analysis complete: ${result.disease} (${(result.confidence * 100).toStringAsFixed(1)}%)");
      }
    } catch (e) {
      print("❌ Real analysis failed: $e");
      if (mounted) {
        _showErrorDialog('Analysis failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
    });
    print("🔄 Analysis reset");
  }

  @override
  void dispose() {
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image Analysis'),
        actions: [
          if (_selectedImage != null || _analysisResult != null)
            IconButton(
              onPressed: _resetAnalysis,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Model loading status
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isModelLoaded ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isModelLoaded ? '✅ Real AI Model Ready' : '⏳ Loading Real AI Model...',
                style: TextStyle(
                  color: _isModelLoaded ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedImage == null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No image selected'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isAnalyzing || !_isModelLoaded) ? null : _analyzeImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isModelLoaded ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: _isAnalyzing
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Analyzing...'),
                    ],
                  )
                      : Text(_isModelLoaded ? 'Analyze Image' : 'Loading Real AI Model...'),
                ),
              ),
            ],

            if (_analysisResult != null) ...[
              const SizedBox(height: 30),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Real AI Analysis Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildResultRow(
                        'Disease Type',
                        _analysisResult!.disease,
                        Icons.bug_report,
                      ),
                      const SizedBox(height: 10),
                      _buildResultRow(
                        'Confidence',
                        '${(_analysisResult!.confidence * 100).toStringAsFixed(1)}%',
                        Icons.bar_chart,
                      ),
                      const SizedBox(height: 10),
                      _buildResultRow(
                        'Severity',
                        '${_analysisResult!.severity.toStringAsFixed(1)}%',
                        Icons.warning,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
