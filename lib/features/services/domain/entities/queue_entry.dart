// lib/features/services/domain/entities/queue_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum QueueEntryStatus {
  pending,
  active,
  expired,
  left,
  served;

  static QueueEntryStatus fromString(String value) {
    return QueueEntryStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => QueueEntryStatus.pending,
    );
  }

  String get displayName => name.toUpperCase();
}

class QueueEntry extends Equatable {
  final String id;
  final String serviceId;
  final String tempUserKey;
  final QueueEntryStatus status;
  final Timestamp joinedAt;
  final Timestamp? checkInBy;
  final Timestamp? lastSeenAt;
  final int? position;

  const QueueEntry({
    required this.id,
    required this.serviceId,
    required this.tempUserKey,
    required this.status,
    required this.joinedAt,
    this.checkInBy,
    this.lastSeenAt,
    this.position,
  });

  bool get isPending => status == QueueEntryStatus.pending;
  bool get isActive => status == QueueEntryStatus.active;
  bool get isExpired => status == QueueEntryStatus.expired;

  bool get isCheckInExpired {
    if (checkInBy == null) return false; // only called entries expire
    return DateTime.now().isAfter(checkInBy!.toDate());
  }

  Duration get timeUntilCheckInExpiry {
    if (checkInBy == null) return Duration.zero; // no timer
    final diff = checkInBy!.toDate().difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get canCheckIn {
    // user can check in only when a deadline exists and it's not expired
    return isPending && checkInBy != null && !isCheckInExpired;
  }

  @override
  List<Object?> get props => [
    id,
    serviceId,
    tempUserKey,
    status,
    joinedAt,
    checkInBy,
    lastSeenAt,
    position,
  ];
}
