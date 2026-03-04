import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/surveillance_camera.dart';
import '../../domain/repositories/surveillance_repository.dart';
import '../models/surveillance_camera_model.dart';

class SurveillanceRepositoryImpl implements SurveillanceRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'surveillance_cameras';

  SurveillanceRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<SurveillanceCamera>> watchAllCameras() {
    return _firestore.collection(_collection).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => SurveillanceCameraModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Stream<List<SurveillanceCamera>> watchCamerasForService(String serviceId) {
    return _firestore
        .collection(_collection)
        .where('serviceId', isEqualTo: serviceId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SurveillanceCameraModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<SurveillanceCamera?> getCamera(String cameraId) async {
    final doc = await _firestore.collection(_collection).doc(cameraId).get();
    if (!doc.exists) return null;
    return SurveillanceCameraModel.fromFirestore(doc);
  }

  @override
  Future<void> addCamera(SurveillanceCamera camera) async {
    final model = SurveillanceCameraModel.fromEntity(camera);
    await _firestore
        .collection(_collection)
        .doc(camera.id)
        .set(model.toFirestore());
  }

  @override
  Future<void> updateCamera(SurveillanceCamera camera) async {
    final model = SurveillanceCameraModel.fromEntity(camera);
    await _firestore
        .collection(_collection)
        .doc(camera.id)
        .update(model.toFirestore());
  }

  @override
  Future<void> updateCameraStatus(String cameraId, bool isActive) async {
    await _firestore.collection(_collection).doc(cameraId).update({
      'isActive': isActive,
      'lastActive': isActive ? Timestamp.now() : null,
    });
  }

  @override
  Future<void> deleteCamera(String cameraId) async {
    await _firestore.collection(_collection).doc(cameraId).delete();
  }

  @override
  Future<void> updateLastActive(String cameraId) async {
    await _firestore.collection(_collection).doc(cameraId).update({
      'lastActive': Timestamp.now(),
    });
  }
}
