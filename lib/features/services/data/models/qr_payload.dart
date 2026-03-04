// lib/features/queue/data/models/qr_payload.dart
import 'dart:convert';
import '../../domain/entities/qr_data.dart';

class QRPayload {
  /// Parse QR code string to QRData
  /// Expected format: {"serviceId":"registrar","serviceName":"Registrar"}
  /// Or simple format: registrar (just service ID)
  static QRData? parse(String qrString) {
    try {
      // Try JSON format first
      final json = jsonDecode(qrString) as Map<String, dynamic>;
      return QRData(
        serviceId: json['serviceId'] as String,
        serviceName:
            json['serviceName'] as String? ?? json['serviceId'] as String,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
      );
    } catch (e) {
      // Fallback to simple format (just service ID)
      if (qrString.isNotEmpty && !qrString.contains(' ')) {
        return QRData(serviceId: qrString, serviceName: qrString);
      }
      return null;
    }
  }

  /// Generate QR string from service data
  static String generate(
    String serviceId,
    String serviceName, {
    DateTime? expiresAt,
  }) {
    return jsonEncode({
      'serviceId': serviceId,
      'serviceName': serviceName,
      if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
    });
  }
}
