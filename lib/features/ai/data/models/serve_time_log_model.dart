// lib/features/ai/data/models/serve_time_log_model.dart
class ServeTimeLogModel {
  final String serviceId;
  final int servedSeconds;
  final int completedAtMillis;

  ServeTimeLogModel({
    required this.serviceId,
    required this.servedSeconds,
    required this.completedAtMillis,
  });

  Map<String, dynamic> toJson() => {
    "serviceId": serviceId,
    "servedSeconds": servedSeconds,
    "completedAtMillis": completedAtMillis,
  };

  static ServeTimeLogModel fromJson(Map<String, dynamic> json) {
    return ServeTimeLogModel(
      serviceId: json["serviceId"] as String,
      servedSeconds: json["servedSeconds"] as int,
      completedAtMillis: json["completedAtMillis"] as int,
    );
  }
}
