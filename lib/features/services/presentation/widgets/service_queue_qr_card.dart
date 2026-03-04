import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ServiceQueueQrCard extends StatelessWidget {
  final String serviceId;
  final String entryId;

  const ServiceQueueQrCard({
    super.key,
    required this.serviceId,
    required this.entryId,
  });

  @override
  Widget build(BuildContext context) {
    final payload = jsonEncode({
      "v": 1,
      "type": "queue_checkin",
      "serviceId": serviceId,
      "entryId": entryId,
    });

    return Card(
      margin: const EdgeInsets.only(top: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Text(
              "Queue QR (Test Mode)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            QrImageView(
              data: payload,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              payload,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
