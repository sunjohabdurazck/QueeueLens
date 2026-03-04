// lib/features/services/data/models/queue_entry_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/queue_entry.dart';

class QueueEntryModel extends QueueEntry {
  const QueueEntryModel({
    required super.id,
    required super.serviceId,
    required super.tempUserKey,
    required super.status,
    required super.joinedAt,
    required super.checkInBy,
    super.lastSeenAt,
    super.position,
  });

  factory QueueEntryModel.fromFirestore(
    DocumentSnapshot doc,
    String serviceId,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    return QueueEntryModel(
      id: doc.id,
      serviceId: serviceId,
      tempUserKey: data['tempUserKey'] as String,
      status: QueueEntryStatus.fromString(
        data['status'] as String? ?? 'pending',
      ),
      joinedAt: data['joinedAt'] as Timestamp,
      checkInBy: data['checkInBy'] as Timestamp?,
      lastSeenAt: data['lastSeenAt'] as Timestamp?,
      position: (data['position'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceId': serviceId,
      'tempUserKey': tempUserKey,
      'userId': tempUserKey, // ← ADD THIS
      'status': status.name.toLowerCase(), // normalize
      'joinedAt': joinedAt,
      if (checkInBy != null) 'checkInBy': checkInBy,
      'lastSeenAt': lastSeenAt ?? FieldValue.serverTimestamp(),
    };
  }
}
