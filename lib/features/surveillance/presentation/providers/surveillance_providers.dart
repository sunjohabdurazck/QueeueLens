import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/surveillance_camera.dart';
import '../../domain/repositories/surveillance_repository.dart';
import '../../data/repositories/surveillance_repository_impl.dart';

// Repository provider
final surveillanceRepositoryProvider = Provider<SurveillanceRepository>((ref) {
  return SurveillanceRepositoryImpl();
});

// Watch all cameras
final allCamerasProvider = StreamProvider<List<SurveillanceCamera>>((ref) {
  final repo = ref.watch(surveillanceRepositoryProvider);
  return repo.watchAllCameras();
});

// Watch cameras for a specific service
final serviceCamerasProvider =
    StreamProvider.family<List<SurveillanceCamera>, String>((ref, serviceId) {
  final repo = ref.watch(surveillanceRepositoryProvider);
  return repo.watchCamerasForService(serviceId);
});

// Get single camera
final cameraProvider =
    FutureProvider.family<SurveillanceCamera?, String>((ref, cameraId) async {
  final repo = ref.watch(surveillanceRepositoryProvider);
  return await repo.getCamera(cameraId);
});

// Camera actions provider
final cameraActionsProvider = Provider<CameraActions>((ref) {
  final repo = ref.watch(surveillanceRepositoryProvider);
  return CameraActions(repo);
});

// Camera actions class
class CameraActions {
  final SurveillanceRepository _repository;

  CameraActions(this._repository);

  Future<void> addCamera(SurveillanceCamera camera) async {
    await _repository.addCamera(camera);
  }

  Future<void> updateCamera(SurveillanceCamera camera) async {
    await _repository.updateCamera(camera);
  }

  Future<void> toggleCameraStatus(String cameraId, bool isActive) async {
    await _repository.updateCameraStatus(cameraId, isActive);
  }

  Future<void> deleteCamera(String cameraId) async {
    await _repository.deleteCamera(cameraId);
  }

  Future<void> updateLastActive(String cameraId) async {
    await _repository.updateLastActive(cameraId);
  }
}
