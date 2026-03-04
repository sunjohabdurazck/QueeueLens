import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/queue_providers.dart';
import '../../../../core/geofencing/geofence_service.dart';
import '../../../../core/notifications/notification_manager.dart';
import '../../../services/presentation/providers/services_providers.dart';
import '../../domain/entities/queue_entry.dart';

class ScanQueueQrPage extends ConsumerStatefulWidget {
  const ScanQueueQrPage({super.key});

  @override
  ConsumerState<ScanQueueQrPage> createState() => _ScanQueueQrPageState();
}

class _ScanQueueQrPageState extends ConsumerState<ScanQueueQrPage> {
  // Updated coordinates from IUT campus
  static const _serviceCoords = <String, Map<String, double>>{
    // Second Academic Building (SAB) - CSE, EEE
    'svc_registrar': {'lat': 23.94917074398174, 'lng': 90.37953894638973},

    // Third Academic Building (TAB) - MCE, CEE
    'svc_library_print': {'lat': 23.949160938834662, 'lng': 90.37733953505189},

    // Medical Center
    'svc_medical': {'lat': 23.948847342350103, 'lng': 90.37738137384427},

    // Administrative Building / Admin Building (Registrar & student services)
    'svc_accounts': {'lat': 23.94806072165071, 'lng': 90.37928129865955},

    // Cafeteria
    'svc_cafeteria': {'lat': 23.948039068381526, 'lng': 90.3796841866017},

    // Library
    'svc_library': {'lat': 23.94814651513253, 'lng': 90.37968899664604},
  };

  bool _busy = false;
  String? _lastRaw;

  // Helper method to get service name
  String _getServiceName(String serviceId) {
    switch (serviceId) {
      case 'svc_registrar':
        return 'Second Academic Building (Registrar)';
      case 'svc_library_print':
        return 'Third Academic Building (Printing)';
      case 'svc_medical':
        return 'Medical Center';
      case 'svc_accounts':
        return 'Admin Building (Accounts)';
      case 'svc_cafeteria':
        return 'Cafeteria';
      case 'svc_library':
        return 'Library';
      default:
        return serviceId;
    }
  }

  // Parse QR code payload
  QueueQrPayload? _parseQueueQr(String raw) {
    try {
      final obj = jsonDecode(raw);
      if (obj is! Map) return null;

      if (obj["v"] != 1) return null;
      if (obj["type"] != "queue_checkin") return null;

      final serviceId = obj["serviceId"];
      final entryId = obj["entryId"];
      if (serviceId is! String || entryId is! String) return null;

      return QueueQrPayload(serviceId: serviceId, entryId: entryId);
    } catch (_) {
      return null;
    }
  }

  // Check if user can check in based on service state
  Future<bool> _canUserCheckIn(
    String serviceId,
    String entryId,
    DocumentSnapshot<Map<String, dynamic>> serviceDoc,
  ) async {
    final serviceData = serviceDoc.data();
    if (serviceData == null) return false;

    // Get the entry document to check its status
    final entryDoc = await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .collection('entries')
        .doc(entryId)
        .get();

    if (!entryDoc.exists) return false;

    final entryData = entryDoc.data();
    if (entryData == null) return false;

    final activeEntryId = serviceData['activeEntryId'] as String?;
    final headPendingEntryId = serviceData['headPendingEntryId'] as String?;
    final calledEntryId = serviceData['calledEntryId'] as String?;
    final callExpiresAtTs = serviceData['callExpiresAt'] as Timestamp?;
    final callExpiresAt = callExpiresAtTs?.toDate();
    final status = entryData['status'] as String?;

    // Must be pending (or called)
    final isPendingOrCalled = status == 'pending' || status == 'called';
    if (!isPendingOrCalled) return false;

    // Only if nobody is active
    if (activeEntryId != null) return false;

    // Only head pending can check in
    if (headPendingEntryId == null || headPendingEntryId != entryId) {
      return false;
    }

    // If staff called, enforce time window + identity
    if (calledEntryId != null) {
      if (calledEntryId != entryId) return false;
      if (callExpiresAt == null || !callExpiresAt.isAfter(DateTime.now())) {
        return false;
      }
    }

    return true;
  }

  // Show loading snackbar
  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Queue QR")),
      body: MobileScanner(
        onDetect: (capture) async {
          if (_busy) return;

          final raw = capture.barcodes.firstOrNull?.rawValue;
          if (raw == null || raw.isEmpty) return;

          // Avoid repeated scans of same code firing quickly
          if (raw == _lastRaw) return;
          _lastRaw = raw;

          final payload = _parseQueueQr(raw);
          if (payload == null) {
            _showErrorSnackBar("Invalid QR (not a queue check-in QR).");
            return;
          }

          setState(() => _busy = true);

          // ✅ DEBUG: print what was scanned + who is scanning
          debugPrint("========== QR SCAN ==========");
          debugPrint("RAW: $raw");
          debugPrint("serviceId: ${payload.serviceId}");
          debugPrint("entryId: ${payload.entryId}");
          debugPrint("scanner uid: ${FirebaseAuth.instance.currentUser?.uid}");
          debugPrint("=============================");

          // Show loading indicator
          _showLoadingSnackBar('Processing check-in...');

          try {
            // ✅ DEBUG: check if entry doc exists BEFORE updating
            final entryRef = FirebaseFirestore.instance
                .collection("services")
                .doc(payload.serviceId)
                .collection("entries")
                .doc(payload.entryId);

            final snap = await entryRef.get();
            debugPrint("ENTRY PATH: ${entryRef.path}");
            debugPrint("ENTRY EXISTS?: ${snap.exists}");

            if (!snap.exists) {
              _showErrorSnackBar(
                "Entry not found (QR is test/expired). Create this entry in Firestore first.",
              );
              setState(() => _busy = false);
              return;
            }

            // Get service document to check check-in eligibility
            final serviceDoc = await FirebaseFirestore.instance
                .collection('services')
                .doc(payload.serviceId)
                .get();

            if (!serviceDoc.exists) {
              _showErrorSnackBar("Service not found");
              setState(() => _busy = false);
              return;
            }

            // Check if user can check in based on service state
            final canCheckIn = await _canUserCheckIn(
              payload.serviceId,
              payload.entryId,
              serviceDoc,
            );

            if (!canCheckIn) {
              _showErrorSnackBar(
                "Cannot check in at this time. You may not be at the front of the queue or someone else is already being served.",
              );
              setState(() => _busy = false);
              return;
            }

            // Location check: if scanning far from service area, require confirmation.
            final coords = _serviceCoords[payload.serviceId];
            if (coords != null) {
              try {
                final pos = await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.low,
                  ),
                );

                final dist = GeofenceService.haversine(
                  pos.latitude,
                  pos.longitude,
                  coords['lat']!,
                  coords['lng']!,
                );

                debugPrint(
                  "Distance from service: ${dist.toStringAsFixed(1)}m",
                );

                // Changed from 100m to 10m as requested
                if (dist > 10) {
                  final confirmBy = Timestamp.fromDate(
                    DateTime.now().add(const Duration(minutes: 2)),
                  );

                  await entryRef.update({
                    'needsActiveConfirm': true,
                    'confirmBy': confirmBy,
                    'confirmReason': 'scan_outside',
                  });

                  await NotificationManager.instance.showActiveConfirmRequired(
                    serviceId: payload.serviceId,
                    entryId: payload.entryId,
                    serviceName: _getServiceName(payload.serviceId),
                    reason: 'scan_outside',
                    minutesToRespond: 2,
                  );

                  _showSuccessSnackBar(
                    "You appear outside the service area. Tap “I’m here” in the notification within 2 minutes to stay in queue.",
                  );
                  setState(() => _busy = false);
                  return;
                }
              } catch (e) {
                debugPrint("Location check failed: $e");
                // If location fails, you can either allow check-in or block it.
                // For now: allow check-in to proceed.
              }
            }

            debugPrint("➡️ Calling repo.checkIn(...)");
            final repo = ref.read(queueRepositoryProvider);
            await repo.checkIn(payload.serviceId, payload.entryId);
            debugPrint("✅ checkIn success");

            if (!mounted) return;

            // Hide loading and show success
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _showSuccessSnackBar("Checked in successfully! ✅");

            // Navigate back after a short delay
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) Navigator.pop(context);
            });
          } on FirebaseException catch (e, st) {
            // ✅ EXACT Firebase reason
            debugPrint("🔥 FirebaseException during check-in");
            debugPrint("code: ${e.code}");
            debugPrint("message: ${e.message}");
            debugPrint("plugin: ${e.plugin}");
            debugPrint("stack: $st");

            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _showErrorSnackBar("Firestore error: ${e.code} — ${e.message}");
            setState(() => _busy = false);
          } catch (e, st) {
            debugPrint("🔥 Unknown error: $e");
            debugPrint("stack: $st");

            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _showErrorSnackBar("Check-in failed: $e");
            setState(() => _busy = false);
          }
        },
      ),
    );
  }
}

class QueueQrPayload {
  final String serviceId;
  final String entryId;
  const QueueQrPayload({required this.serviceId, required this.entryId});
}

extension _FirstOrNullX<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
