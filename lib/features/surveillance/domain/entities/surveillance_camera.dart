import 'package:equatable/equatable.dart';

class SurveillanceCamera extends Equatable {
  final String id;
  final String serviceId;
  final String name;
  final String streamUrl;
  final CameraType type;
  final bool isActive;
  final CameraPosition position;
  final DateTime? lastActive;
  final String? description;

  const SurveillanceCamera({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.streamUrl,
    required this.type,
    required this.isActive,
    required this.position,
    this.lastActive,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        serviceId,
        name,
        streamUrl,
        type,
        isActive,
        position,
        lastActive,
        description,
      ];

  SurveillanceCamera copyWith({
    String? id,
    String? serviceId,
    String? name,
    String? streamUrl,
    CameraType? type,
    bool? isActive,
    CameraPosition? position,
    DateTime? lastActive,
    String? description,
  }) {
    return SurveillanceCamera(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      position: position ?? this.position,
      lastActive: lastActive ?? this.lastActive,
      description: description ?? this.description,
    );
  }
}

enum CameraType {
  ipWebcam, // For iPhone XR IP Webcam
  rtsp, // For Raspberry Pi RTSP streams
  mjpeg, // For MJPEG streams
  http, // For simple HTTP image streams
}

class CameraPosition extends Equatable {
  final double x;
  final double y;
  final double z;

  const CameraPosition({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  List<Object?> get props => [x, y, z];

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
      };

  factory CameraPosition.fromJson(Map<String, dynamic> json) {
    return CameraPosition(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }
}
