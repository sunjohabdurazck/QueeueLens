import '../entities/surveillance_camera.dart';

abstract class SurveillanceRepository {
  /// Get all cameras
  Stream<List<SurveillanceCamera>> watchAllCameras();

  /// Get cameras for a specific service
  Stream<List<SurveillanceCamera>> watchCamerasForService(String serviceId);

  /// Get a single camera
  Future<SurveillanceCamera?> getCamera(String cameraId);

  /// Add a new camera
  Future<void> addCamera(SurveillanceCamera camera);

  /// Update camera details
  Future<void> updateCamera(SurveillanceCamera camera);

  /// Update camera status (active/inactive)
  Future<void> updateCameraStatus(String cameraId, bool isActive);

  /// Delete a camera
  Future<void> deleteCamera(String cameraId);

  /// Update last active timestamp
  Future<void> updateLastActive(String cameraId);
}
