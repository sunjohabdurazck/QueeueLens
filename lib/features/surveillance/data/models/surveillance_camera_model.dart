import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/surveillance_camera.dart';

class SurveillanceCameraModel extends SurveillanceCamera {
  const SurveillanceCameraModel({
    required super.id,
    required super.serviceId,
    required super.name,
    required super.streamUrl,
    required super.type,
    required super.isActive,
    required super.position,
    super.lastActive,
    super.description,
  });

  factory SurveillanceCameraModel.fromEntity(SurveillanceCamera camera) {
    return SurveillanceCameraModel(
      id: camera.id,
      serviceId: camera.serviceId,
      name: camera.name,
      streamUrl: camera.streamUrl,
      type: camera.type,
      isActive: camera.isActive,
      position: camera.position,
      lastActive: camera.lastActive,
      description: camera.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'name': name,
      'streamUrl': streamUrl,
      'type': type.index,
      'isActive': isActive,
      'position': position.toJson(),
      'lastActive': lastActive?.toIso8601String(),
      'description': description,
    };
  }

  factory SurveillanceCameraModel.fromJson(Map<String, dynamic> json) {
    return SurveillanceCameraModel(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      name: json['name'] as String,
      streamUrl: json['streamUrl'] as String,
      type: CameraType.values[json['type'] as int],
      isActive: json['isActive'] as bool,
      position: CameraPosition.fromJson(json['position'] as Map<String, dynamic>),
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : null,
      description: json['description'] as String?,
    );
  }

  factory SurveillanceCameraModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SurveillanceCameraModel(
      id: doc.id,
      serviceId: data['serviceId'] as String,
      name: data['name'] as String,
      streamUrl: data['streamUrl'] as String,
      type: CameraType.values[data['type'] as int],
      isActive: data['isActive'] as bool,
      position: CameraPosition.fromJson(data['position'] as Map<String, dynamic>),
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceId': serviceId,
      'name': name,
      'streamUrl': streamUrl,
      'type': type.index,
      'isActive': isActive,
      'position': position.toJson(),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'description': description,
    };
  }
}
