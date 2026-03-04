import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ServiceStatus {
  open,
  closed;

  static ServiceStatus fromString(String value) {
    return value.toUpperCase() == 'OPEN'
        ? ServiceStatus.open
        : ServiceStatus.closed;
  }

  String get displayName => name.toUpperCase();
}

class ServicePoint extends Equatable {
  final String id;
  final String name;
  final String description;
  final ServiceStatus status;
  final int activeCount;
  final int pendingCount;
  final int avgMinsPerPerson;
  final Timestamp? lastUpdatedAt;

  const ServicePoint({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.activeCount,
    required this.pendingCount,
    required this.avgMinsPerPerson,
    this.lastUpdatedAt,
  });

  // Updated to match AI prediction logic
  int estimatedWaitMinutesForPosition(int positionInQueue) {
    if (positionInQueue <= 0) return 0;

    // People ahead in queue (same as AI: position - 1)
    final peopleAhead = positionInQueue - 1;

    // If no one ahead, wait is 0
    if (peopleAhead <= 0) return 0;

    // Calculate wait time based on people ahead × average serve time
    return peopleAhead * avgMinsPerPerson;
  }

  // Convenience method for current user's position
  int get estimatedWaitMinutes => estimatedWaitMinutesForPosition(pendingCount);

  // Optional: Add range estimates like AI prediction
  (int low, int high) estimatedWaitRangeForPosition(int positionInQueue) {
    final baseWait = estimatedWaitMinutesForPosition(positionInQueue);
    final low = (baseWait * 0.85).round();
    final high = (baseWait * 1.15).round();
    return (low, high);
  }

  bool get isOpen => status == ServiceStatus.open;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    status,
    activeCount,
    pendingCount,
    avgMinsPerPerson,
    lastUpdatedAt,
  ];
}
