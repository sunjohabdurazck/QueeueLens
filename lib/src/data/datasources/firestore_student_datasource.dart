import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class FirestoreStudentDataSource {
  final FirebaseFirestore _firestore;

  // Single, clear constructor (DI-friendly)
  FirestoreStudentDataSource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection('students');

  // -------------------------
  // READ
  // -------------------------
  Future<StudentModel?> getStudent(String uid) async {
    final doc = await _students.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return StudentModel.fromJson(doc.data()!);
  }

  // -------------------------
  // CREATE
  // -------------------------
  Future<void> createStudent(StudentModel student) async {
    await _students.doc(student.uid).set(student.toJson());
  }

  // -------------------------
  // UPDATE
  // -------------------------
  Future<void> updateStudent(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await _students.doc(uid).update(updates);
  }

  Future<void> updateLastLogin(String uid) async {
    await _students.doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEmailVerification(
    String uid,
    bool verified,
  ) async {
    await _students.doc(uid).update({
      'emailVerified': verified,
    });
  }

  // -------------------------
  // DELETE
  // -------------------------
  Future<void> deleteStudent(String uid) async {
    await _students.doc(uid).delete();
  }

  // -------------------------
  // VALIDATION
  // -------------------------
  Future<bool> studentIdExists(String studentId) async {
    final query =
        await _students.where('studentId', isEqualTo: studentId).limit(1).get();

    return query.docs.isNotEmpty;
  }
}
