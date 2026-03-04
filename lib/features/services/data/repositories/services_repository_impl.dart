import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/service_point.dart';
import '../../domain/repositories/services_repository.dart';
import '../models/service_point_model.dart';
import '../../../../core/constants/firestore_paths.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final FirebaseFirestore _firestore;

  ServicesRepositoryImpl(this._firestore);

  @override
  Stream<List<ServicePoint>> watchServices() {
    return _firestore.collection(FirestorePaths.services).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => ServicePointModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<ServicePoint?> watchServiceById(String id) {
    return _firestore
        .collection(FirestorePaths.services)
        .doc(id)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return ServicePointModel.fromFirestore(doc);
        });
  }
}
