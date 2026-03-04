import 'package:flutter/material.dart';
import 'package:camera/camera.dart'
    hide ImageFormat; // Fix 1: Hide ImageFormat from camera
import 'package:flutter/foundation.dart' show kIsWeb;
import '../application/surveillance_controller.dart';
import '../domain/person_detector.dart';
import 'widgets/people_counter_badge.dart';
import 'widgets/detection_boxes_painter.dart';

class SurveillanceScreen extends StatefulWidget {
  final String cameraId;
  final String cameraName;

  const SurveillanceScreen({
    super.key,
    required this.cameraId,
    required this.cameraName,
  });

  @override
  State<SurveillanceScreen> createState() => _SurveillanceScreenState();
}

class _SurveillanceScreenState extends State<SurveillanceScreen> {
  late SurveillanceController _controller;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = SurveillanceController(cameraId: widget.cameraId);
    _controller.initialize();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!kIsWeb) {
      // Mobile camera initialization
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }

        // Start processing camera frames
        _cameraController!.startImageStream(_processCameraImage);
      }
    }
  }

  void _processCameraImage(CameraImage image) {
    // Convert CameraImage to ImageFrame and pass to controller
    final frame = ImageFrame(
      bytes: image.planes[0].bytes,
      width: image.width,
      height: image.height,
      format: ImageFormat.yuv420, // This now refers to domain's ImageFormat
    );

    _controller.processCameraFrame(frame);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.cameraName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera preview
          _buildCameraPreview(),

          // People counter overlay
          Positioned(
            top: 16,
            left: 16,
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return PeopleCounterBadge(
                  count: _controller.currentCount,
                  isActive: _controller.isInitialized,
                );
              },
            ),
          ),

          // Detection boxes overlay
          if (_controller.currentDetections.isNotEmpty)
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: DetectionBoxesPainter(
                      detections: _controller.currentDetections,
                      imageSize: const Size(640, 480),
                    ),
                  );
                },
              ),
            ),

          // Error overlay
          if (_controller.error != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(
                    alpha: 0.8,
                  ), // Fix 2: Use withValues
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _controller.error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (kIsWeb) {
      // Web camera view - handled by TFJS
      return Container(color: Colors.black);
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return CameraPreview(_cameraController!);
  }
}
