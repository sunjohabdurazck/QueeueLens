// lib/features/queue/domain/entities/qr_data.dart
import 'package:equatable/equatable.dart';

class QRData extends Equatable {
  final String serviceId;
  final String serviceName;
  final DateTime? expiresAt;

  const QRData({
    required this.serviceId,
    required this.serviceName,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  @override
  List<Object?> get props => [serviceId, serviceName, expiresAt];
}
