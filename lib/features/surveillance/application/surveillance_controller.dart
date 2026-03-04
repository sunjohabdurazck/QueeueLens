import 'dart:async';
import 'dart:typed_data'; // Add this import for Uint8List
import 'package:flutter/material.dart';
import '../domain/person_detection.dart';
import '../domain/person_detector.dart';
import '../infrastructure/person_detector_factory.dart';

class SurveillanceController extends ChangeNotifier {
  final String cameraId;
  PersonDetector? _detector;
  Timer? _detectionTimer;
  final List<int> _recentCounts = [];
  int _currentCount = 0;
  List<PersonDetection> _currentDetections = [];
  bool _isInitialized = false;
  String? _error;

  SurveillanceController({required this.cameraId});

  int get currentCount => _currentCount;
  List<PersonDetection> get currentDetections => _currentDetections;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      _detector = await PersonDetectorFactory.create();
      await _detector!.init();
      _isInitialized = true;
      _startDetectionLoop();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize detector: $e';
      notifyListeners();
    }
  }

  void _startDetectionLoop() {}

  Future<void> _runDetection() async {
    if (_detector == null || !_isInitialized) return;

    try {
      // This will be called with actual camera frames
      // For now, we'll update with test data
      // In real implementation, you'd pass the camera frame here

      // Simulate detection
      final mockFrame = ImageFrame(
        bytes: Uint8List(0),
        width: 640,
        height: 480,
        format: ImageFormat.rgb,
      );

      final detections = await _detector!.detect(mockFrame);
      _processDetections(detections);
    } catch (e) {
      _error = 'Detection error: $e';
      notifyListeners();
    }
  }

  void _processDetections(List<PersonDetection> detections) {
    // Filter persons (already done in detector)
    final personCount = detections.length;

    // Smooth the count using median of last 10 values
    _recentCounts.add(personCount);
    if (_recentCounts.length > 10) {
      _recentCounts.removeAt(0);
    }

    // Calculate median
    final sorted = List<int>.from(_recentCounts)..sort();
    final median = sorted[sorted.length ~/ 2];

    _currentCount = median;
    _currentDetections = detections;
    notifyListeners();
  }

  void processCameraFrame(ImageFrame frame) async {
    if (_detector == null || !_isInitialized) return;

    try {
      final detections = await _detector!.detect(frame);
      _processDetections(detections);
    } catch (e) {
      _error = 'Frame processing error: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _detector?.dispose();
    super.dispose();
  }
}
