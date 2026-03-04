// lib/features/queue/presentation/providers/queue_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/queue_repository_impl.dart';
import '../../domain/repositories/queue_repository.dart';
import '../../domain/entities/queue_entry.dart';
import '../../../../core/utils/device_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Repository provider
final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  return QueueRepositoryImpl(FirebaseFirestore.instance);
});

// Temp user key provider

final tempUserKeyProvider = FutureProvider<String>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("User not logged in");
  return user.uid;
});

// Watch user's active entry
final myActiveEntryProvider = StreamProvider<QueueEntry?>((ref) {
  final tempUserKeyAsync = ref.watch(tempUserKeyProvider);
  final repository = ref.watch(queueRepositoryProvider);

  return tempUserKeyAsync.when(
    data: (tempUserKey) => repository.watchMyActiveEntry(tempUserKey),
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

// Watch specific entry with position
final entryWithPositionProvider = StreamProvider.family<QueueEntry?, String>((
  ref,
  params,
) {
  // params format: "serviceId:entryId"
  final parts = params.split(':');
  if (parts.length != 2) return Stream.value(null);

  final serviceId = parts[0];
  final entryId = parts[1];
  final repository = ref.watch(queueRepositoryProvider);

  return repository.watchEntry(serviceId, entryId).asyncMap((entry) async {
    if (entry == null) return null;

    final position = await repository.calculatePosition(serviceId, entryId);

    // Return a new QueueEntry with the position added
    // Assuming QueueEntry has a copyWith method or we create a new instance
    return QueueEntry(
      id: entry.id,
      serviceId: entry.serviceId,
      tempUserKey: entry.tempUserKey,
      status: entry.status,
      joinedAt: entry.joinedAt,
      checkInBy: entry.checkInBy,
      lastSeenAt: entry.lastSeenAt,
      position: position, // Add the calculated position
    );
  });
});
// Watch service doc (needed to know headPendingEntryId / activeEntryId / calledEntryId / callExpiresAt)
final serviceDocProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>, String>((ref, serviceId) {
      return FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .snapshots();
    });
