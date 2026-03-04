import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../../services/presentation/providers/services_providers.dart';
import '../../../surveillance/presentation/providers/surveillance_providers.dart';
import '../../../surveillance/domain/entities/surveillance_camera.dart';
import '../../../services/domain/entities/service_point.dart';
import '../../../surveillance/presentation/pages/camera_view_page.dart';
import '../../../surveillance/presentation/widgets/campus_3d_painter.dart';

class VirtualCampusViewPage extends ConsumerStatefulWidget {
  const VirtualCampusViewPage({super.key});

  @override
  ConsumerState<VirtualCampusViewPage> createState() =>
      _VirtualCampusViewPageState();
}

class _VirtualCampusViewPageState extends ConsumerState<VirtualCampusViewPage> {
  double _yaw = 0.0;
  double _pitch = 0.0;
  double _compassHeading = 0.0;
  String? _hoveredBuildingId;
  Offset? _lastTapPosition;

  @override
  void initState() {
    super.initState();
    _listenToCompass();
  }

  void _listenToCompass() {
    FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() {
          _compassHeading = event.heading!;
        });
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _yaw += details.delta.dx * 0.005;
      _pitch = (_pitch - details.delta.dy * 0.005).clamp(-0.5, 0.5);
    });
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _lastTapPosition = details.localPosition;
    });
  }

  void _onTapUp(TapUpDetails details) {
    final tapPosition = _lastTapPosition;
    if (tapPosition == null) return;

    // Check if a building was tapped
    final services = ref.read(servicesStreamProvider).valueOrNull ?? [];
    final buildings = _getBuildingPositions(services);

    for (final building in buildings) {
      final distance = (building.position - tapPosition).distance;
      if (distance < 50) {
        _showCameraOptions(building.serviceId, context);
        return;
      }
    }
  }

  List<BuildingInfo> _getBuildingPositions(List<ServicePoint> services) {
    final List<BuildingInfo> buildings = [];

    for (int i = 0; i < services.length; i++) {
      final service = services[i];
      final angle = (i / services.length) * 2 * pi;
      final radius = 200.0;
      final x = cos(angle - _yaw) * radius;
      final z = sin(angle - _yaw) * radius;
      final scale = 300 / (300 + z);

      buildings.add(
        BuildingInfo(
          serviceId: service.id,
          serviceName: service.name,
          position: Offset(
            MediaQuery.of(context).size.width / 2 + x * scale,
            MediaQuery.of(context).size.height / 2 -
                (_pitch * 100) -
                50 * scale,
          ),
          scale: scale,
        ),
      );
    }

    return buildings;
  }

  void _showCameraOptions(String serviceId, BuildContext context) {
    final camerasAsync = ref.read(serviceCamerasProvider(serviceId));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: camerasAsync.when(
            data: (cameras) {
              if (cameras.isEmpty) {
                return _buildNoCamerasView();
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetHandle(),
                  const SizedBox(height: 8),
                  const Text(
                    'Available Cameras',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...cameras.map(
                    (camera) => _buildCameraListTile(camera, context),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SizedBox(
              height: 200,
              child: Center(child: Text('Error: $error')),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildNoCamerasView() {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSheetHandle(),
          const SizedBox(height: 20),
          Icon(Icons.videocam_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No cameras available',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'No surveillance cameras configured for this location',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraListTile(SurveillanceCamera camera, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: camera.isActive
                ? Colors.green.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.videocam,
            color: camera.isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          camera.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getCameraTypeLabel(camera.type)),
            if (camera.description != null) ...[
              const SizedBox(height: 4),
              Text(
                camera.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (camera.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Offline',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          _openCameraView(camera);
        },
      ),
    );
  }

  String _getCameraTypeLabel(CameraType type) {
    switch (type) {
      case CameraType.ipWebcam:
        return 'IP Webcam';
      case CameraType.rtsp:
        return 'RTSP Stream';
      case CameraType.mjpeg:
        return 'MJPEG Stream';
      case CameraType.http:
        return 'HTTP Stream';
    }
  }

  void _openCameraView(SurveillanceCamera camera) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraViewPage(camera: camera)),
    );
  }

  void _showAllCameras(BuildContext context) {
    final camerasAsync = ref.read(allCamerasProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: camerasAsync.when(
            data: (cameras) {
              return Column(
                children: [
                  _buildSheetHandle(),
                  const SizedBox(height: 8),
                  const Text(
                    'All Campus Cameras',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                      itemCount: cameras.length,
                      itemBuilder: (context, index) {
                        final camera = cameras[index];
                        return _buildCameraGridTile(camera);
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        );
      },
    );
  }

  Widget _buildCameraGridTile(SurveillanceCamera camera) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _openCameraView(camera);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: camera.isActive
                ? [Colors.blue.shade50, Colors.blue.shade100]
                : [Colors.grey.shade100, Colors.grey.shade200],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: camera.isActive
                ? Colors.blue.shade200
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 48,
              color: camera.isActive ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                camera.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            if (camera.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const Text(
                'Offline',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);
    final camerasAsync = ref.watch(allCamerasProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Virtual Campus View'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            onPressed: () {
              setState(() {
                _yaw = _compassHeading * pi / 180;
              });
            },
            tooltip: 'Align with compass',
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _showAllCameras(context),
            tooltip: 'View all cameras',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _yaw = 0;
                _pitch = 0;
              });
            },
            tooltip: 'Reset view',
          ),
        ],
      ),
      body: servicesAsync.when(
        data: (services) => GestureDetector(
          onPanUpdate: _onPanUpdate,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          child: CustomPaint(
            painter: Campus3DPainter(
              services: services,
              yaw: _yaw,
              pitch: _pitch,
              hoveredBuildingId: _hoveredBuildingId,
              cameras: camerasAsync.valueOrNull ?? [],
            ),
            child: Container(),
          ),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Text(
            'Error loading campus view: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(camerasAsync),
    );
  }

  Widget _buildBottomBar(AsyncValue<List<SurveillanceCamera>> camerasAsync) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '👆 Tap on buildings to view cameras • Drag to look around',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                Icons.explore,
                'Heading: ${_compassHeading.round()}°',
              ),
              _buildInfoChip(
                Icons.threed_rotation,
                'Yaw: ${(_yaw * 180 / pi).round()}°',
              ),
              _buildInfoChip(
                Icons.videocam,
                'Cameras: ${camerasAsync.valueOrNull?.length ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class BuildingInfo {
  final String serviceId;
  final String serviceName;
  final Offset position;
  final double scale;

  BuildingInfo({
    required this.serviceId,
    required this.serviceName,
    required this.position,
    required this.scale,
  });
}
