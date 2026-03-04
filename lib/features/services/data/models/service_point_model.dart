import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/service_point.dart';

class ServicePointModel extends ServicePoint {
  const ServicePointModel({
    required super.id,
    required super.name,
    required super.description,
    required super.status,
    required super.activeCount,
    required super.pendingCount,
    required super.avgMinsPerPerson,
    super.lastUpdatedAt,
  });

  factory ServicePointModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ServicePointModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown Service',
      description: data['description'] as String? ?? '',
      status: ServiceStatus.fromString(data['status'] as String? ?? 'CLOSED'),
      activeCount: (data['activeCount'] as num?)?.toInt() ?? 0,
      pendingCount: (data['pendingCount'] as num?)?.toInt() ?? 0,
      avgMinsPerPerson: (data['avgMinsPerPerson'] as num?)?.toInt() ?? 2,
      lastUpdatedAt: data['lastUpdatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'status': status.displayName,
      'activeCount': activeCount,
      'pendingCount': pendingCount,
      'avgMinsPerPerson': avgMinsPerPerson,
      'lastUpdatedAt': lastUpdatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}
