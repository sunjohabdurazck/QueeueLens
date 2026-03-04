// @dart=2.19
import 'dart:async';
import 'package:web/web.dart' as web;
import 'web_camera.dart';

class WebCameraImpl {
  Future<void> initialize(WebCameraController controller) async {
    try {
      // Create video element
      final videoElement = _createVideoElement();
      final canvasElement = _createCanvasElement();

      // Get user media
      final stream = await _getUserMedia();
      videoElement.srcObject = stream;

      // Set properties on controller
      controller.setVideoElement(videoElement);
      controller.setCanvasElement(canvasElement);
      controller.setStream(stream);
    } catch (e) {
      throw Exception('Failed to access camera: $e');
    }
  }

  web.HTMLVideoElement _createVideoElement() {
    final video = web.document.createElement('video') as web.HTMLVideoElement;
    video
      ..width = 640
      ..height = 480
      ..autoplay = true
      ..setAttribute('playsinline', 'true');
    return video;
  }

  web.HTMLCanvasElement _createCanvasElement() {
    final canvas =
        web.document.createElement('canvas') as web.HTMLCanvasElement;
    canvas
      ..width = 640
      ..height = 480;
    return canvas;
  }

  Future<web.MediaStream> _getUserMedia() async {
    final mediaDevices = web.window.navigator.mediaDevices;

    // This null check is needed - ignore the warning
    if (mediaDevices == null) {
      throw Exception('MediaDevices not supported in this browser');
    }

    try {
      // Create a completer for the result
      final completer = Completer<web.MediaStream>();

      // Use a simple object literal approach
      final options = <String, dynamic>{
        'video': true,
        'audio': false,
      };

      // Call getUserMedia - it accepts Map directly in practice

      // Wait for the result with timeout
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (!completer.isCompleted) {
            throw Exception('Camera access timeout');
          }
          return completer.future;
        },
      );
    } catch (e) {
      throw Exception('Failed to get user media: $e');
    }
  }

  // Helper to handle promises without type issues
  void _handlePromise(
    dynamic promise, {
    required void Function(dynamic) onSuccess,
    required void Function(dynamic) onError,
  }) {
    // Use setTimeout to avoid immediate execution issues
    Future.microtask(() {
      try {
        // Check if promise has then/catch methods
        if (promise != null) {
          // Use bracket notation to access methods
          final thenMethod = promise['then'];
          final catchMethod = promise['catch'];

          if (thenMethod != null) {
            thenMethod((dynamic value) {
              onSuccess(value);
            });
          } else {
            onError('Promise has no then method');
          }

          if (catchMethod != null) {
            catchMethod((dynamic error) {
              onError(error);
            });
          }
        } else {
          onError('Promise is null');
        }
      } catch (e) {
        onError(e);
      }
    });
  }
}
