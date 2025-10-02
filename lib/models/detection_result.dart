class DetectionResult {
  final String disease;
  final double confidence;
  final double severity;
  final String timestamp;

  DetectionResult({
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.timestamp,
  });

  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      disease: map['disease'] ?? 'Unknown',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      severity: (map['severity'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'timestamp': timestamp,
    };
  }
}
