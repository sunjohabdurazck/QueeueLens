// lib/features/queue/data/repositories/queue_repository_impl.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/queue_entry.dart';
import '../../domain/repositories/queue_repository.dart';
import '../models/queue_entry_model.dart';
import '../../../../core/constants/firestore_paths.dart';

class QueueRepositoryImpl implements QueueRepository {
  final FirebaseFirestore _firestore;

  QueueRepositoryImpl(this._firestore);

  // ✅ SINGLE source of truth: Call head and update BOTH service AND entry
  Future<void> callHeadIfNeeded(String serviceId) async {
    final serviceRef = _firestore.collection('services').doc(serviceId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(serviceRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final activeEntryId = data['activeEntryId'] as String?;
      final headPendingEntryId = data['headPendingEntryId'] as String?;
      final calledEntryId = data['calledEntryId'] as String?;
      final callExpiresAt = data['callExpiresAt'] as Timestamp?;

      // Only call head when:
      // - nobody is active
      // - there is a head
      if (activeEntryId != null) return;
      if (headPendingEntryId == null) return;

      // If already called and still valid, do nothing
      if (calledEntryId == headPendingEntryId &&
          callExpiresAt != null &&
          callExpiresAt.toDate().isAfter(DateTime.now())) {
        return;
      }

      // If called is set but expired, clear it (so we can re-call cleanly)
      if (calledEntryId != null &&
          callExpiresAt != null &&
          callExpiresAt.toDate().isBefore(DateTime.now())) {
        tx.update(serviceRef, {
          'calledEntryId': null,
          'callExpiresAt': null,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
        // continue to call again below
      }

      final expires = Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 1)),
      );

      // ✅ Update service with call info
      tx.update(serviceRef, {
        'calledEntryId': headPendingEntryId,
        'callExpiresAt': expires,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Update entry with called status and checkInBy (for timer)
      final entryRef = serviceRef.collection('entries').doc(headPendingEntryId);
      tx.update(entryRef, {'status': 'called', 'checkInBy': expires});

      debugPrint(
        "✅ callHeadIfNeeded: Called head $headPendingEntryId until $expires",
      );
    });
    try {
      await callHeadIfNeeded(serviceId);
    } catch (e) {
      debugPrint("callHeadIfNeeded FAILED: $e");
    }
  }

  // ✅ Expire and delete a called entry (used by UI when timer expires)
  Future<void> expireCalledEntryDelete({
    required String serviceId,
    required String reason,
  }) async {
    final serviceRef = _firestore.collection('services').doc(serviceId);

    await _firestore.runTransaction((tx) async {
      final serviceSnap = await tx.get(serviceRef);
      if (!serviceSnap.exists) return;

      final s = serviceSnap.data() as Map<String, dynamic>;
      final String? activeEntryId = s['activeEntryId'] as String?;
      final String? headPendingEntryId = s['headPendingEntryId'] as String?;
      final String? calledEntryId = s['calledEntryId'] as String?;
      final Timestamp? callExpiresAt = s['callExpiresAt'] as Timestamp?;
      final int pendingCount = (s['pendingCount'] as num?)?.toInt() ?? 0;

      // Must be in "called head" state
      if (activeEntryId != null) return;
      if (headPendingEntryId == null) return;
      if (calledEntryId == null || calledEntryId != headPendingEntryId) return;
      if (callExpiresAt == null) return;
      if (callExpiresAt.toDate().isAfter(DateTime.now()))
        return; // not expired yet

      final entryRef = serviceRef.collection('entries').doc(calledEntryId);

      // Delete the head entry
      tx.delete(entryRef);

      // Find next pending head AFTER delete is committed (can't query inside tx safely),
      // so we set head to null now. We'll fix head right after transaction in a normal read.
      final int newPending = pendingCount > 0 ? pendingCount - 1 : 0;

      tx.update(serviceRef, {
        'pendingCount': newPending,
        'headPendingEntryId': null,
        'calledEntryId': null,
        'callExpiresAt': null,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    });

    // After commit: set new head (committed state query)
    final serviceRef2 = _firestore.collection('services').doc(serviceId);
    final nextPendingSnapshot = await serviceRef2
        .collection('entries')
        .where('status', isEqualTo: 'pending')
        .orderBy('joinedAt')
        .limit(1)
        .get();

    if (nextPendingSnapshot.docs.isNotEmpty) {
      final nextId = nextPendingSnapshot.docs.first.id;
      await serviceRef2.update({'headPendingEntryId': nextId});

      // ✅ Immediately start timer for the new head (updates both service and entry)
      await callHeadIfNeeded(serviceId);
    } else {
      await serviceRef2.update({'headPendingEntryId': null});
    }
  }

  @override
  Future<QueueEntry> joinQueuePending(
    String serviceId,
    String tempUserKey,
  ) async {
    // Enforce: a user can only be in ONE queue at a time (pending/active).
    final existing = await _firestore
        .collectionGroup('entries')
        .where('tempUserKey', isEqualTo: tempUserKey)
        .where('status', whereIn: ['pending', 'active'])
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception(
        'You are already in a queue. Leave your current queue before joining another.',
      );
    }

    final created = await _firestore.runTransaction((transaction) async {
      final serviceRef = _firestore
          .collection(FirestorePaths.services)
          .doc(serviceId);
      final serviceSnap = await transaction.get(serviceRef);
      if (!serviceSnap.exists) throw Exception('Service not found');

      final serviceData = serviceSnap.data() as Map<String, dynamic>;
      final String? headPendingEntryId =
          serviceData['headPendingEntryId'] as String?;
      final int pendingCount =
          (serviceData['pendingCount'] as num?)?.toInt() ?? 0;

      final entryRef = _firestore
          .collection(FirestorePaths.entries(serviceId))
          .doc();
      final now = Timestamp.now();
      final entry = QueueEntryModel(
        id: entryRef.id,
        serviceId: serviceId,
        tempUserKey: tempUserKey,
        status: QueueEntryStatus.pending,
        joinedAt: now,
        checkInBy: null, // Only called entries have checkInBy
        lastSeenAt: now,
      );

      transaction.set(entryRef, entry.toFirestore());

      // Increment pendingCount
      final updates = <String, dynamic>{
        'pendingCount': FieldValue.increment(1),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      // If queue is empty pending-wise AND no head set, make this new entry the head
      if (headPendingEntryId == null && pendingCount == 0) {
        updates['headPendingEntryId'] = entryRef.id;
      }

      transaction.update(serviceRef, updates);

      return entry;
    });

    // ✅ Call head if needed after joining
    await callHeadIfNeeded(serviceId);
    return created;
  }

  @override
  Future<void> checkIn(String serviceId, String entryId) async {
    final serviceRef = _firestore.collection('services').doc(serviceId);
    final entryRef = serviceRef.collection('entries').doc(entryId);

    bool wasHeadPending = false;

    // STEP 1: Transaction - activate entry and update counters
    await _firestore.runTransaction((tx) async {
      final serviceSnap = await tx.get(serviceRef);
      if (!serviceSnap.exists) throw Exception('Service not found');

      final s = serviceSnap.data() as Map<String, dynamic>;
      final String? activeEntryId = s['activeEntryId'] as String?;
      final String? headPendingEntryId = s['headPendingEntryId'] as String?;
      final String? calledEntryId = s['calledEntryId'] as String?;
      final Timestamp? callExpiresAt = s['callExpiresAt'] as Timestamp?;

      // Only one active at a time
      if (activeEntryId != null) {
        throw Exception('Another user is currently being served. Please wait.');
      }

      // Only first pending can check in
      if (headPendingEntryId == null || headPendingEntryId != entryId) {
        throw Exception('Only the first user in queue can check in.');
      }

      wasHeadPending = (headPendingEntryId == entryId);

      // If staff called someone, enforce time window
      if (calledEntryId != null) {
        if (calledEntryId != entryId) {
          throw Exception('You are not the called user.');
        }
        if (callExpiresAt == null ||
            callExpiresAt.toDate().isBefore(DateTime.now())) {
          throw Exception('Check-in window expired.');
        }
      }

      final entrySnap = await tx.get(entryRef);
      if (!entrySnap.exists) throw Exception('Entry not found');

      final e = entrySnap.data() as Map<String, dynamic>;
      final status = (e['status'] as String?) ?? 'pending';

      // Only allow pending/called -> active
      if (!(status == 'pending' || status == 'called')) {
        throw Exception('Cannot check in from status=$status');
      }

      // Honor entry-level checkInBy (only for called entries)
      final Timestamp? checkInBy = e['checkInBy'] as Timestamp?;
      if (checkInBy != null && checkInBy.toDate().isBefore(DateTime.now())) {
        throw Exception('Check-in window expired.');
      }

      // Activate
      final updates = <String, dynamic>{
        'activeEntryId': entryId,
        'activeCount': FieldValue.increment(1),
        'pendingCount': FieldValue.increment(-1),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        // Clear call state
        'calledEntryId': null,
        'callExpiresAt': null,
        // Clear head temporarily (will be set after transaction)
        'headPendingEntryId': null,
      };

      tx.update(serviceRef, updates);

      tx.update(entryRef, {
        'status': 'active',
        'checkedInAt': FieldValue.serverTimestamp(),
        'needsActiveConfirm': true,
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
    });

    // STEP 2: AFTER transaction, recalculate head if needed
    if (wasHeadPending) {
      debugPrint("checkIn: Recalculating head pending after activation...");

      // Find next oldest pending entry (query runs on committed state)
      final nextPendingSnapshot = await serviceRef
          .collection('entries')
          .where('status', isEqualTo: 'pending')
          .orderBy('joinedAt')
          .limit(1)
          .get();

      if (nextPendingSnapshot.docs.isNotEmpty) {
        final nextId = nextPendingSnapshot.docs.first.id;
        await serviceRef.update({'headPendingEntryId': nextId});
        debugPrint("checkIn: New head pending set to: $nextId");
      } else {
        await serviceRef.update({'headPendingEntryId': null});
        debugPrint("checkIn: No pending entries left, head set to null");
      }
    }

    // ✅ Call head if needed after check-in (updates both service and entry)
    await callHeadIfNeeded(serviceId);
  }

  @override
  Future<void> leaveQueue(
    String serviceId,
    String entryId,
    QueueEntryStatus currentStatus,
  ) async {
    debugPrint("=== LEAVE QUEUE DEBUG START ===");
    debugPrint("serviceId: $serviceId");
    debugPrint("entryId: $entryId");
    debugPrint("currentStatus: $currentStatus");

    final serviceRef = _firestore.collection('services').doc(serviceId);
    final entryRef = serviceRef.collection('entries').doc(entryId);

    try {
      // STEP 1: Transaction - delete entry and update counters atomically
      debugPrint("1. Running transaction to delete entry...");
      bool wasHeadPending = false;
      String? status;

      await _firestore.runTransaction((tx) async {
        // Read both service and entry INSIDE transaction
        final serviceSnap = await tx.get(serviceRef);
        if (!serviceSnap.exists) return;

        final entrySnap = await tx.get(entryRef);
        if (!entrySnap.exists) {
          throw Exception('Cannot leave: You\'re not in the queue.');
        }

        final data = serviceSnap.data() as Map<String, dynamic>;
        final entryData = entrySnap.data() as Map<String, dynamic>;

        status = (entryData['status'] ?? 'pending').toString();
        final activeEntryId = data['activeEntryId'] as String?;
        final headPendingEntryId = data['headPendingEntryId'] as String?;
        final int currentPending = (data['pendingCount'] as num?)?.toInt() ?? 0;
        final int currentActive = (data['activeCount'] as num?)?.toInt() ?? 0;

        // Check if this entry was the head pending
        wasHeadPending = (headPendingEntryId == entryId);

        // Clear active lock if this was the active entry
        if (activeEntryId == entryId) {
          tx.update(serviceRef, {'activeEntryId': null});
        }

        // Delete the entry
        tx.delete(entryRef);

        // Update counters safely based on status
        if (status == 'active') {
          final int newActive = currentActive > 0 ? currentActive - 1 : 0;
          tx.update(serviceRef, {
            'activeCount': newActive,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final int newPending = currentPending > 0 ? currentPending - 1 : 0;
          tx.update(serviceRef, {
            'pendingCount': newPending,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        }

        // If this was the head pending, clear it temporarily
        if (wasHeadPending) {
          tx.update(serviceRef, {'headPendingEntryId': null});
          // ❌ DO NOT call head here - it's inside a transaction!
        }
      });

      debugPrint(
        "  ✓ Transaction completed. wasHeadPending: $wasHeadPending, status: $status",
      );

      // STEP 2: AFTER transaction, recalculate head if needed
      if (wasHeadPending) {
        debugPrint("2. Recalculating head pending after deletion...");

        // Find next oldest pending entry (query runs on committed state)
        final nextPendingSnapshot = await serviceRef
            .collection('entries')
            .where('status', isEqualTo: 'pending')
            .orderBy('joinedAt')
            .limit(1)
            .get();

        if (nextPendingSnapshot.docs.isNotEmpty) {
          final nextId = nextPendingSnapshot.docs.first.id;
          await serviceRef.update({'headPendingEntryId': nextId});
          debugPrint("  ✓ New head pending set to: $nextId");
        } else {
          await serviceRef.update({'headPendingEntryId': null});
          debugPrint("  ✓ No pending entries left, head set to null");
        }
      }

      // ✅ Call head if needed after leaving (updates both service and entry)
      await callHeadIfNeeded(serviceId);

      debugPrint("=== LEAVE QUEUE DEBUG END (SUCCESS) ===");
    } catch (e, stack) {
      debugPrint("=== LEAVE QUEUE DEBUG END (ERROR) ===");
      debugPrint("Error: $e");
      debugPrint("Stack trace: $stack");
      rethrow;
    }
  }

  Future<void> _debugDirectEntryRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('DEBUG DIRECT READ uid=$uid');

    // ✅ Put real IDs here from Firestore console (same project)
    const serviceId = 'svc_library_print';
    const entryId = 'PASTE_REAL_ENTRY_DOC_ID_HERE';

    try {
      final doc = await _firestore
          .collection('services')
          .doc(serviceId)
          .collection('entries')
          .doc(entryId)
          .get();

      debugPrint(
        'DEBUG DIRECT READ success exists=${doc.exists} path=${doc.reference.path}',
      );
      debugPrint('DEBUG DIRECT READ data=${doc.data()}');
    } catch (e, st) {
      debugPrint('DEBUG DIRECT READ error: $e');
      debugPrint('$st');
    }
  }

  @override
  Stream<QueueEntry?> watchMyActiveEntry(String tempUserKey) {
    debugPrint('========== WATCH ACTIVE ENTRY ==========');
    debugPrint('AUTH UID: ${FirebaseAuth.instance.currentUser?.uid}');
    debugPrint('tempUserKey arg: $tempUserKey');
    debugPrint('=========================================');
    _debugDirectEntryRead();

    // ✅ IMPORTANT: Include 'called' status so UI shows timer correctly
    final query = _firestore
        .collectionGroup('entries')
        .where('tempUserKey', isEqualTo: tempUserKey)
        .where('status', whereIn: ['pending', 'called', 'active'])
        .limit(1);

    return query
        .snapshots()
        .map((snapshot) {
          debugPrint('SNAPSHOT DOC COUNT: ${snapshot.docs.length}');
          for (final doc in snapshot.docs) {
            debugPrint('DOC PATH: ${doc.reference.path}');
          }

          if (snapshot.docs.isEmpty) return null;

          final doc = snapshot.docs.first;
          final serviceDocRef = doc.reference.parent.parent;
          if (serviceDocRef == null) return null;

          return QueueEntryModel.fromFirestore(doc, serviceDocRef.id);
        })
        .handleError((e, st) {
          debugPrint('watchMyActiveEntry error: $e');
          debugPrint('$st');
        });
  }

  @override
  Stream<QueueEntry?> watchEntry(String serviceId, String entryId) {
    return _firestore
        .collection(FirestorePaths.entries(serviceId))
        .doc(entryId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return QueueEntryModel.fromFirestore(doc, serviceId);
        });
  }

  @override
  Future<QueueEntry?> getUserEntryInService(
    String serviceId,
    String tempUserKey,
  ) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.entries(serviceId))
        .where('tempUserKey', isEqualTo: tempUserKey)
        .where('status', whereIn: ['pending', 'called', 'active'])
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return QueueEntryModel.fromFirestore(snapshot.docs.first, serviceId);
  }

  @override
  Future<void> updateHeartbeat(String serviceId, String entryId) async {
    await _firestore
        .collection(FirestorePaths.entries(serviceId))
        .doc(entryId)
        .update({'lastSeenAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> cleanupExpiredEntries(String serviceId) async {
    final serviceRef = _firestore
        .collection(FirestorePaths.services)
        .doc(serviceId);

    // Only expire CALLED entries, not pending
    final snapshot = await _firestore
        .collection(FirestorePaths.entries(serviceId))
        .where('status', isEqualTo: 'called')
        .where('checkInBy', isLessThan: Timestamp.now())
        .get();

    final batch = _firestore.batch();
    int expiredCount = 0;
    Set<String> expiredIds = {};

    for (final doc in snapshot.docs) {
      expiredIds.add(doc.id);
      batch.update(doc.reference, {
        'status': QueueEntryStatus.expired.name,
        'expiredReason': 'check_in_timeout',
        'expiredAt': FieldValue.serverTimestamp(),
      });
      expiredCount++;
    }

    if (expiredCount > 0) {
      // Get current service data to safely update counters
      final serviceSnap = await serviceRef.get();
      if (serviceSnap.exists) {
        final data = serviceSnap.data() as Map<String, dynamic>;
        final int currentPending = (data['pendingCount'] as num?)?.toInt() ?? 0;
        final int newPending = currentPending > expiredCount
            ? currentPending - expiredCount
            : 0;

        final updates = <String, dynamic>{
          'pendingCount': newPending,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        };

        // If head pending was among expired, clear it (will be recalculated)
        if (data['headPendingEntryId'] != null &&
            expiredIds.contains(data['headPendingEntryId'])) {
          updates['headPendingEntryId'] = null;
        }

        batch.update(serviceRef, updates);
      }
    }

    await batch.commit();

    if (expiredCount > 0) {
      debugPrint("cleanupExpiredEntries: Expired $expiredCount called entries");

      // Recalculate head and call if needed after expiration
      final nextPendingSnapshot = await serviceRef
          .collection('entries')
          .where('status', isEqualTo: 'pending')
          .orderBy('joinedAt')
          .limit(1)
          .get();

      if (nextPendingSnapshot.docs.isNotEmpty) {
        final nextId = nextPendingSnapshot.docs.first.id;
        await _firestore
            .collection(FirestorePaths.services)
            .doc(serviceId)
            .update({'headPendingEntryId': nextId});

        // ✅ Call the new head (updates both service and entry)
        await callHeadIfNeeded(serviceId);
      }
    }
  }

  @override
  Future<int> calculatePosition(String serviceId, String entryId) async {
    final entryDoc = await _firestore
        .collection(FirestorePaths.entries(serviceId))
        .doc(entryId)
        .get();

    if (!entryDoc.exists) return 0;

    final entryData = entryDoc.data() as Map<String, dynamic>;
    final joinedAt = entryData['joinedAt'] as Timestamp;
    final status = QueueEntryStatus.fromString(entryData['status'] as String);

    if (status == QueueEntryStatus.pending) {
      // Count active entries (they're ahead)
      final activeCount = await _firestore
          .collection(FirestorePaths.entries(serviceId))
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      // Count pending entries before this one
      final pendingBefore = await _firestore
          .collection(FirestorePaths.entries(serviceId))
          .where('status', isEqualTo: 'pending')
          .where('joinedAt', isLessThan: joinedAt)
          .count()
          .get();

      return (activeCount.count ?? 0).toInt() +
          (pendingBefore.count ?? 0).toInt() +
          1;
    } else if (status == QueueEntryStatus.active) {
      // Count only active entries before this one
      final activeBefore = await _firestore
          .collection(FirestorePaths.entries(serviceId))
          .where('status', isEqualTo: 'active')
          .where('joinedAt', isLessThan: joinedAt)
          .count()
          .get();

      return (activeBefore.count ?? 0).toInt() + 1;
    }

    return 0;
  }

  @override
  Future<void> markWarned(String serviceId, String entryId) async {
    await _firestore
        .collection('services')
        .doc(serviceId)
        .collection('entries')
        .doc(entryId)
        .update({'warnedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> expireEntry({
    required String serviceId,
    required String entryId,
    required String reason,
  }) async {
    final serviceRef = _firestore.collection('services').doc(serviceId);
    final entryRef = serviceRef.collection('entries').doc(entryId);

    bool wasHeadPending = false;
    String? prevStatus;

    // STEP 1: Transaction - update entry and counters atomically
    await _firestore.runTransaction((tx) async {
      final serviceSnap = await tx.get(serviceRef);
      if (!serviceSnap.exists) return;

      final data = serviceSnap.data() as Map<String, dynamic>;
      final activeEntryId = data['activeEntryId'] as String?;
      final headPendingEntryId = data['headPendingEntryId'] as String?;
      final int currentPending = (data['pendingCount'] as num?)?.toInt() ?? 0;
      final int currentActive = (data['activeCount'] as num?)?.toInt() ?? 0;

      final entrySnap = await tx.get(entryRef);
      if (!entrySnap.exists) return;

      final entryData = entrySnap.data() as Map<String, dynamic>;
      prevStatus = (entryData['status'] as String?) ?? 'pending';

      // Check if this entry was the head pending
      wasHeadPending = (headPendingEntryId == entryId);

      // Clear active lock if this was the active entry
      if (activeEntryId == entryId) {
        tx.update(serviceRef, {'activeEntryId': null});
      }

      // Mark entry expired
      tx.update(entryRef, {
        'status': 'expired',
        'expiredReason': reason,
        'expiredAt': FieldValue.serverTimestamp(),
      });

      // Update counters safely based on previous status
      if (prevStatus == 'pending') {
        final int newPending = currentPending > 0 ? currentPending - 1 : 0;
        tx.update(serviceRef, {
          'pendingCount': newPending,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      } else if (prevStatus == 'active') {
        final int newActive = currentActive > 0 ? currentActive - 1 : 0;
        tx.update(serviceRef, {
          'activeCount': newActive,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      // If this was the head pending, clear it temporarily
      if (wasHeadPending) {
        tx.update(serviceRef, {'headPendingEntryId': null});
      }
    });

    // STEP 2: AFTER transaction, recalculate head if needed
    if (wasHeadPending && prevStatus == 'pending') {
      debugPrint("expireEntry: Recalculating head pending after expiration...");

      // Find next oldest pending entry (query runs on committed state)
      final nextPendingSnapshot = await serviceRef
          .collection('entries')
          .where('status', isEqualTo: 'pending')
          .orderBy('joinedAt')
          .limit(1)
          .get();

      if (nextPendingSnapshot.docs.isNotEmpty) {
        final nextId = nextPendingSnapshot.docs.first.id;
        await serviceRef.update({'headPendingEntryId': nextId});
        debugPrint("expireEntry: New head pending set to: $nextId");

        // ✅ Call the new head (updates both service and entry)
        await callHeadIfNeeded(serviceId);
      }
      // If no pending entries left, head is already null from transaction
    }
  }
}
