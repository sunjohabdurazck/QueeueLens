import 'dart:convert';
import '/src/features/shared/qr_scanner/domain/entities/qr_data.dart';

class QRDataModel extends QRData {
  const QRDataModel({
    required super.name,
    required super.studentID,
    required super.country,
    required super.department,
  });

  factory QRDataModel.fromJson(Map<String, dynamic> json) {
    return QRDataModel(
      name: json['name'] as String,
      studentID: json['studentID'] as String,
      country: json['country'] as String,
      department: json['department'] as String,
    );
  }

  factory QRDataModel.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return QRDataModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'studentID': studentID,
      'country': country,
      'department': department,
    };
  }

  QRData toEntity() {
    return QRData(
      name: name,
      studentID: studentID,
      country: country,
      department: department,
    );
  }
}
