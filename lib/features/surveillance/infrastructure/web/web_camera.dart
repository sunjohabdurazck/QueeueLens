import 'package:flutter/foundation.dart' show kIsWeb;
// We need to import web types for type checking
import 'package:web/web.dart' as web;

abstract class WebCameraControllerInterface {
  Future<void> initialize();
  void captureFrame(dynamic context);
  Future<void> dispose();
  dynamic get videoElement;

  // Add setters for web implementation
  void setVideoElement(dynamic element);
  void setCanvasElement(dynamic element);
  void setStream(dynamic stream);
}

class WebCameraController implements WebCameraControllerInterface {
  dynamic _videoElement;
  dynamic _canvasElement;
  dynamic _stream;
  final bool _isWeb = kIsWeb;

  @override
  dynamic get videoElement => _videoElement;

  @override
  void setVideoElement(dynamic element) {
    _videoElement = element;
  }

  @override
  void setCanvasElement(dynamic element) {
    _canvasElement = element;
  }

  @override
  void setStream(dynamic stream) {
    _stream = stream;
  }

  @override
  Future<void> initialize() async {
    if (!_isWeb) {
      throw UnsupportedError('WebCameraController is only supported on web');
    }

    await _initializeWeb();
  }

  Future<void> _initializeWeb() async {
    try {
      final webImpl = WebCameraImpl();
      await webImpl.initialize(this);
    } catch (e) {
      throw Exception('Failed to initialize web camera: $e');
    }
  }

  @override
  void captureFrame(dynamic context) {
    if (!_isWeb || _videoElement == null || _canvasElement == null) return;

    // Direct method call without type checking
    try {
      // Try to cast to expected types and call methods directly
      if (context is web.CanvasRenderingContext2D &&
          _videoElement is web.HTMLVideoElement) {
        context.drawImage(_videoElement as web.HTMLVideoElement, 0, 0);
      }
    } catch (e) {
      // Silently fail - better than crashing
    }
  }

  @override
  Future<void> dispose() async {
    if (!_isWeb || _stream == null) return;

    try {
      // Direct approach - cast and call methods
      if (_stream is web.MediaStream) {
        final stream = _stream as web.MediaStream;
        final tracks = stream.getTracks();

        // Convert JSArray to List using a simple loop
        final int trackCount = tracks.length;
        for (int i = 0; i < trackCount; i++) {
          final track = tracks[i];
          track.stop();
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
}

// Forward declaration
class WebCameraImpl {
  Future<void> initialize(WebCameraController controller) async {
    throw UnimplementedError(
      'WebCameraImpl must be implemented in web-only file',
    );
  }
}
