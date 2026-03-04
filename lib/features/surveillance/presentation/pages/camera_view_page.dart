// features/surveillance/presentation/pages/camera_view_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/surveillance_camera.dart';
import '../../domain/person_detector.dart';
import '../providers/surveillance_providers.dart';
import '../widgets/mjpeg_stream_view.dart';
import '../widgets/people_counter_badge.dart';
import '../widgets/detection_boxes_painter.dart';
import '../../application/surveillance_controller.dart';

class CameraViewPage extends ConsumerStatefulWidget {
  final SurveillanceCamera camera;

  const CameraViewPage({super.key, required this.camera});

  @override
  ConsumerState<CameraViewPage> createState() => _CameraViewPageState();
}

class _CameraViewPageState extends ConsumerState<CameraViewPage> {
  bool _isLoading = true;
  bool _isFullscreen = false;
  bool _hasError = false;
  String? _errorMessage;
  Timer? _connectionTimer;
  final _frameStreamController = StreamController<Uint8List>.broadcast();

  late SurveillanceController _surveillanceController;

  @override
  void initState() {
    super.initState();
    _surveillanceController = SurveillanceController(
      cameraId: widget.camera.id,
    );
    _surveillanceController.initialize();
    _connectToCamera();

    // Listen to frames and process them
    _frameStreamController.stream.listen((frameBytes) {
      if (_surveillanceController.isInitialized) {
        final imageFrame = ImageFrame(
          bytes: frameBytes,
          width: 640, // Default width, can be adjusted
          height: 480, // Default height, can be adjusted
          format: ImageFormat.rgb, // MJPEG streams are typically RGB
        );
        _surveillanceController.processCameraFrame(imageFrame);
      }
    });
  }

  Future<void> _connectToCamera() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Update last active timestamp
      await ref.read(cameraActionsProvider).updateLastActive(widget.camera.id);

      // Simulate connection delay (remove in production)
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Start periodic heartbeat
      _startHeartbeat();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _startHeartbeat() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (widget.camera.isActive) {
        ref.read(cameraActionsProvider).updateLastActive(widget.camera.id);
      }
    });
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _frameStreamController.close();
    _surveillanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen
          ? null
          : AppBar(
              title: Text(widget.camera.name),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {
                    setState(() => _isFullscreen = true);
                  },
                ),
                IconButton(
                  icon: Icon(
                    widget.camera.isActive
                        ? Icons.videocam
                        : Icons.videocam_off,
                  ),
                  onPressed: () => _toggleCameraStatus(),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'refresh') {
                      _connectToCamera();
                    } else if (value == 'info') {
                      _showCameraInfo();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Refresh Stream'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Text('Camera Info'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: Stack(
        children: [
          // Camera feed
          _buildBody(),

          // People counter overlay
          Positioned(
            top: 16,
            left: 16,
            child: ListenableBuilder(
              listenable: _surveillanceController,
              builder: (context, _) {
                return PeopleCounterBadge(
                  count: _surveillanceController.currentCount,
                  isActive: _surveillanceController.isInitialized && !_hasError,
                );
              },
            ),
          ),

          // Detection boxes overlay
          if (_surveillanceController.currentDetections.isNotEmpty)
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _surveillanceController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: DetectionBoxesPainter(
                      detections: _surveillanceController.currentDetections,
                      imageSize: const Size(640, 480),
                    ),
                  );
                },
              ),
            ),

          // Error overlay
          if (_surveillanceController.error != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _surveillanceController.error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_hasError) {
      return _buildErrorView();
    }

    return _buildCameraView();
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Connecting to ${widget.camera.name}...',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Connection Failed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Could not connect to camera',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _connectToCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    final cameraView = Stack(
      children: [
        // MJPEG STREAM with frame callback
        MjpegStreamView(
          streamUrl: widget.camera.streamUrl,
          onFrame: (frameBytes) {
            if (_surveillanceController.isInitialized) {
              final imageFrame = ImageFrame(
                bytes: frameBytes,
                width: 640, // You might want to detect actual dimensions
                height: 480,
                format: ImageFormat.rgb,
              );
              _surveillanceController.processCameraFrame(imageFrame);
            }
          },
        ),

        // Fullscreen controls
        if (_isFullscreen)
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.fullscreen_exit,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                setState(() => _isFullscreen = false);
              },
            ),
          ),

        // Camera info overlay at bottom
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _buildCameraOverlay(),
        ),
      ],
    );

    return GestureDetector(
      onDoubleTap: () {
        setState(() => _isFullscreen = !_isFullscreen);
      },
      child: cameraView,
    );
  }

  Widget _buildCameraOverlay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.camera.isActive
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.camera.isActive ? Icons.circle : Icons.circle_outlined,
                color: widget.camera.isActive ? Colors.green : Colors.red,
                size: 12,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.camera.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.camera.isActive
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.camera.isActive ? 'LIVE' : 'OFFLINE',
                  style: TextStyle(
                    color: widget.camera.isActive ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey.shade400, size: 14),
              const SizedBox(width: 4),
              Text(
                _getCameraTypeLabel(widget.camera.type),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          if (widget.camera.description != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.camera.description!,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ],
          if (widget.camera.lastActive != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last active: ${_formatLastActive(widget.camera.lastActive!)}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  String _getCameraTypeLabel(CameraType type) {
    switch (type) {
      case CameraType.ipWebcam:
        return 'IP Webcam Stream';
      case CameraType.rtsp:
        return 'RTSP Stream';
      case CameraType.mjpeg:
        return 'MJPEG Stream';
      case CameraType.http:
        return 'HTTP Stream';
    }
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _toggleCameraStatus() async {
    final newStatus = !widget.camera.isActive;

    try {
      await ref
          .read(cameraActionsProvider)
          .toggleCameraStatus(widget.camera.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Camera activated' : 'Camera deactivated',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update camera status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCameraInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name:', widget.camera.name),
            _buildInfoRow('Type:', _getCameraTypeLabel(widget.camera.type)),
            _buildInfoRow('Stream URL:', widget.camera.streamUrl),
            _buildInfoRow(
              'Status:',
              widget.camera.isActive ? 'Active' : 'Inactive',
            ),
            if (widget.camera.description != null)
              _buildInfoRow('Description:', widget.camera.description!),
            if (widget.camera.lastActive != null)
              _buildInfoRow(
                'Last Active:',
                _formatLastActive(widget.camera.lastActive!),
              ),
            _buildInfoRow(
              'Position:',
              'X: ${widget.camera.position.x.toStringAsFixed(1)}, '
                  'Y: ${widget.camera.position.y.toStringAsFixed(1)}, '
                  'Z: ${widget.camera.position.z.toStringAsFixed(1)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}
