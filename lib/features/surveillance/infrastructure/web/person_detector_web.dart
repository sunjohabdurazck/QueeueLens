import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/person_detector.dart';
import '../../domain/person_detection.dart';

class PersonDetectorWeb implements PersonDetector {
  bool _isInitialized = false;

  @override
  int get inputWidth => 300;

  @override
  int get inputHeight => 300;

  @override
  Future<void> init() async {
    _isInitialized = true;
  }

  @override
  Future<List<PersonDetection>> detect(ImageFrame frame) async {
    if (!_isInitialized) {
      throw StateError('Detector not initialized');
    }

    try {
      // For web, you need to send the image to a backend API
      // or use TensorFlow.js in the browser

      // Option 1: Send to backend API
      String base64Image = base64Encode(frame.bytes);

      final response = await http.post(
        Uri.parse('https://your-api.com/detect'),
        body: jsonEncode({
          'image': base64Image,
          'width': frame.width,
          'height': frame.height,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final detections = <PersonDetection>[];

        for (var d in data['detections']) {
          if (d['label'] == 'person' && d['confidence'] > 0.4) {
            detections.add(
              PersonDetection(
                label: d['label'],
                confidence: d['confidence'],
                boundingBox: Rect(
                  left: d['x'].toDouble(),
                  top: d['y'].toDouble(),
                  right: (d['x'] + d['width']).toDouble(),
                  bottom: (d['y'] + d['height']).toDouble(),
                ),
              ),
            );
          }
        }

        return detections;
      }

      return [];

      // Option 2: For testing, return mock detections
      // return _getMockDetections();
    } catch (e) {
      throw Exception('Detection failed: $e');
    }
  }

  // For testing without backend
  List<PersonDetection> _getMockDetections() {
    return [
      PersonDetection(
        label: 'person',
        confidence: 0.95,
        boundingBox: Rect(left: 0.2, top: 0.3, right: 0.4, bottom: 0.8),
      ),
      PersonDetection(
        label: 'person',
        confidence: 0.87,
        boundingBox: Rect(left: 0.6, top: 0.25, right: 0.8, bottom: 0.75),
      ),
    ];
  }

  @override
  Future<void> dispose() async {}
}
