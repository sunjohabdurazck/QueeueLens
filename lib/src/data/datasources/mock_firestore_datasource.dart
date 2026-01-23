import '../models/student_model.dart';

/// Mock data source simulating Cloud Firestore
/// Used for development and testing before Firebase integration
class MockFirestoreDataSource {
  // Simulated in-memory Firestore collection
  final Map<String, Map<String, dynamic>> _students = {};

  // Predefined test students
  MockFirestoreDataSource() {
    // Add test student data
    _students['test-uid-001'] = {
      'uid': 'test-uid-001',
      'name': 'Ahmed Rahman',
      'studentId': '190041123',
      'email': 'test@iut-dhaka.edu',
      'country': 'Bangladesh',
      'department': 'Computer Science & Engineering',
      'emailVerified': true,
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
      'lastLoginAt': DateTime.now().toIso8601String(),
    };

    _students['test-uid-002'] = {
      'uid': 'test-uid-002',
      'name': 'Fatima Khan',
      'studentId': '190041456',
      'email': 'student@iut-dhaka.edu',
      'country': 'Bangladesh',
      'department': 'Electrical & Electronic Engineering',
      'emailVerified': false,
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(),
      'lastLoginAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create new student document
  Future<void> createStudent(StudentModel student) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if student already exists
    if (_students.containsKey(student.uid)) {
      throw MockFirestoreException('Student already exists', 'already-exists');
    }

    // Store student
    _students[student.uid] = student.toJson();
    print('✅ Student document created: ${student.name} (${student.uid})');
  }

  /// Get student by UID
  Future<StudentModel?> getStudent(String uid) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_students.containsKey(uid)) {
      return null;
    }

    final data = _students[uid]!;
    return StudentModel.fromJson(data);
  }

  /// Update student document
  Future<void> updateStudent(String uid, Map<String, dynamic> updates) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    if (!_students.containsKey(uid)) {
      throw MockFirestoreException('Student not found', 'not-found');
    }

    // Merge updates with existing data
    _students[uid] = {..._students[uid]!, ...updates};
    print('✅ Student document updated: $uid');
  }

  /// Delete student document
  Future<void> deleteStudent(String uid) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    if (!_students.containsKey(uid)) {
      throw MockFirestoreException('Student not found', 'not-found');
    }

    _students.remove(uid);
    print('✅ Student document deleted: $uid');
  }

  /// Check if student with student ID exists
  Future<bool> studentIdExists(String studentId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return _students.values.any((data) => data['studentId'] == studentId);
  }

  /// Get student by student ID
  Future<StudentModel?> getStudentByStudentId(String studentId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final data = _students.values.firstWhere(
      (data) => data['studentId'] == studentId,
      orElse: () => {},
    );

    if (data.isEmpty) {
      return null;
    }

    return StudentModel.fromJson(data);
  }

  /// Get all students (for admin purposes)
  Future<List<StudentModel>> getAllStudents() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return _students.values.map((data) => StudentModel.fromJson(data)).toList();
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String uid) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    if (_students.containsKey(uid)) {
      _students[uid]!['lastLoginAt'] = DateTime.now().toIso8601String();
    }
  }

  /// Update email verification status
  Future<void> updateEmailVerification(String uid, bool verified) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    if (_students.containsKey(uid)) {
      _students[uid]!['emailVerified'] = verified;
    }
  }
}

/// Mock Firestore exception
class MockFirestoreException implements Exception {
  final String message;
  final String code;

  MockFirestoreException(this.message, this.code);

  @override
  String toString() => 'MockFirestoreException: $message (code: $code)';
}
