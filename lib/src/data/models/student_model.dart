import '../../domain/entities/student.dart';

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

  /// Creates StudentModel from JSON (Firestore document)
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      country: json['country'] as String? ?? '',
      department: json['department'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }

  /// Converts StudentModel to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'studentId': studentId,
      'email': email,
      'country': country,
      'department': department,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
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
