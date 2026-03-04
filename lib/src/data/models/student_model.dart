import '../../domain/entities/student.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Student - handles serialization/deserialization
/// This is the data layer representation that interfaces with Firestore
class StudentModel {
  final String uid;
  final String name;
  final String studentId;
  final String email;
  final String country;
  final String department;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const StudentModel({
    required this.uid,
    required this.name,
    required this.studentId,
    required this.email,
    required this.country,
    required this.department,
    this.emailVerified = false,
    this.createdAt,
    this.lastLoginAt,
  });

  /// Helper method to parse dates from Firestore
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    // sometimes Firestore web returns DateTime directly
    if (value is DateTime) {
      return value;
    }

    return null;
  }

  /// Creates StudentModel from JSON (Firestore document)
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      studentId: (json['studentID'] ?? json['studentId']) as String? ?? '',
      email: json['email'] as String? ?? '',
      country: json['country'] as String? ?? '',
      department: json['department'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      lastLoginAt: _parseDate(json['lastLoginAt']),
    );
  }

  /// Converts StudentModel to JSON (for Firestore)
  /// Currently stores timestamps as ISO strings
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'studentID': studentId,
      'email': email,
      'country': country,
      'department': department,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  /// Alternative: Store timestamps as Firestore Timestamp objects
  /// Uncomment if you want to use Firestore timestamps instead of strings
  Map<String, dynamic> toJsonWithTimestamp() {
    return {
      'uid': uid,
      'name': name,
      'studentID': studentId,
      'email': email,
      'country': country,
      'department': department,
      'emailVerified': emailVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  /// Creates StudentModel from domain entity
  factory StudentModel.fromEntity(Student student) {
    return StudentModel(
      uid: student.uid,
      name: student.name,
      studentId: student.studentId,
      email: student.email,
      country: student.country,
      department: student.department,
      emailVerified: student.emailVerified,
      createdAt: student.createdAt,
      lastLoginAt: student.lastLoginAt,
    );
  }

  /// Converts StudentModel to domain entity
  Student toEntity() {
    return Student(
      uid: uid,
      name: name,
      studentId: studentId,
      email: email,
      country: country,
      department: department,
      emailVerified: emailVerified,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  /// Creates a copy with updated fields
  StudentModel copyWith({
    String? uid,
    String? name,
    String? studentId,
    String? email,
    String? country,
    String? department,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return StudentModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      country: country ?? this.country,
      department: department ?? this.department,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
