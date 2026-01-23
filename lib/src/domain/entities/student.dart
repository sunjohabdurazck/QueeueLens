import 'package:equatable/equatable.dart';

/// Pure domain entity representing a student
/// This is framework-agnostic and contains only business logic
class Student extends Equatable {
  final String uid;
  final String name;
  final String studentId;
  final String email;
  final String country;
  final String department;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const Student({
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

  /// Creates a copy of this student with updated fields
  Student copyWith({
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
    return Student(
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

  /// Validates if the student ID is in correct format (9 digits)
  bool get isValidStudentId {
    return RegExp(r'^\d{9}$').hasMatch(studentId);
  }

  /// Validates if the email is a valid IUT email
  bool get isValidIUTEmail {
    return email.endsWith('@iut-dhaka.edu');
  }

  /// Gets display name (first name only for UI)
  String get displayName {
    return name.split(' ').first;
  }

  /// Gets full name
  String get fullName {
    return name;
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    studentId,
    email,
    country,
    department,
    emailVerified,
    createdAt,
    lastLoginAt,
  ];

  @override
  String toString() {
    return 'Student(uid: $uid, name: $name, studentId: $studentId, email: $email, emailVerified: $emailVerified)';
  }
}
