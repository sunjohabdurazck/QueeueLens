import 'dart:typed_data';
import 'person_detection.dart';

abstract class PersonDetector {
  /// Initialize the detector (load model, warm up)
  Future<void> init();

  /// Detect persons in the given image frame
  /// Returns list of person detections
  Future<List<PersonDetection>> detect(ImageFrame frame);

  /// Clean up resources
  Future<void> dispose();

  /// Get recommended input size for the model
  int get inputWidth => 300;
  int get inputHeight => 300;
}

class ImageFrame {
  final Uint8List bytes;
  final int width;
  final int height;
  final ImageFormat format;

  const ImageFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
  });
}

enum ImageFormat { yuv420, rgb, bgra }
