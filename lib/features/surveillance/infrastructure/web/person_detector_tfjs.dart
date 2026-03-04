// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:web/web.dart' as web;
import '../../domain/person_detection.dart';
import '../../domain/person_detector.dart';
import 'tfjs_bridge.dart';

class PersonDetectorTfjs implements PersonDetector {
  Object? _model;
  bool _isInitialized = false;
  web.HTMLVideoElement? _videoElement;
  web.HTMLCanvasElement? _canvasElement;
  web.CanvasRenderingContext2D? _context;
  web.MediaStream? _mediaStream;

  @override
  int get inputWidth => 300;
  @override
  int get inputHeight => 300;

  @override
  Future<void> init() async {
    try {
      // Initialize TFJS and load COCO-SSD model
      await TfjsBridge.ready();
      _model = await TfjsBridge.loadCocoSsd();
      _isInitialized = true;

      // Setup video capture
      await _setupVideoCapture();
    } catch (e) {
      throw Exception('Failed to initialize TFJS detector: $e');
    }
  }

  Future<void> _setupVideoCapture() async {
    _videoElement = web.HTMLVideoElement()
      ..width = 640
      ..height = 480
      ..autoplay = true;

    _canvasElement = web.HTMLCanvasElement()
      ..width = 640
      ..height = 480;

    _context =
        _canvasElement!.getContext('2d') as web.CanvasRenderingContext2D?;
  }

  @override
  Future<List<PersonDetection>> detect(ImageFrame frame) async {
    if (!_isInitialized || _model == null) {
      throw StateError('Detector not initialized');
    }

    try {
      // For web, we use the video frame directly
      if (_videoElement != null &&
          _context != null &&
          _videoElement!.readyState >= 2) {
        _context!.drawImage(_videoElement!, 0, 0);

        final predictions = await TfjsBridge.detect(_model!, _videoElement!);
        return _processPredictions(predictions);
      }

      return [];
    } catch (e) {
      throw Exception('Detection failed: $e');
    }
  }

  List<PersonDetection> _processPredictions(List<dynamic> predictions) {
    final detections = <PersonDetection>[];

    for (final pred in predictions) {
      final bbox = pred['bbox'] as List<dynamic>;
      final score = pred['score'] as num;
      final className = pred['class'] as String;

      if (className.toLowerCase() == 'person' && score >= 0.4) {
        detections.add(
          PersonDetection(
            label: className,
            confidence: score.toDouble(),
            boundingBox: Rect(
              left: bbox[0].toDouble(),
              top: bbox[1].toDouble(),
              right: bbox[0].toDouble() + bbox[2].toDouble(),
              bottom: bbox[1].toDouble() + bbox[3].toDouble(),
            ),
          ),
        );
      }
    }

    return detections;
  }

  @override
  Future<void> dispose() async {
    // Cleanup video stream
    if (_mediaStream != null) {
      final tracks = _mediaStream!.getTracks();
      for (int i = 0; i < tracks.length; i++) {
        tracks[i].stop();
      }
    }
    _isInitialized = false;
  }
}
