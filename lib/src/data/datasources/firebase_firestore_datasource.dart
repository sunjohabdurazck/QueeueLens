import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class FirebaseFirestoreDataSource {
  final FirebaseFirestore _db;

  FirebaseFirestoreDataSource(this._db);

  CollectionReference<Map<String, dynamic>> get _students =>
      _db.collection('students');

  // -------------------------
  // GET STUDENT
  // -------------------------
  Future<StudentModel?> getStudent(String uid) async {
    try {
      final doc = await _students.doc(uid).get();
      final data = doc.data();
      if (data == null) return null;
      return StudentModel.fromJson({...data, 'uid': uid});
    } on FirebaseException {
      rethrow;
    }
  }

  // -------------------------
  // CREATE STUDENT
  // -------------------------
  Future<void> createStudent(StudentModel model) async {
    try {
      await _students.doc(model.uid).set(
            model.toJson(),
            SetOptions(merge: false),
          );
    } on FirebaseException {
      rethrow;
    }
  }

  // -------------------------
  // UPDATE STUDENT
  // -------------------------
  Future<void> updateStudent(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      final docRef = _students.doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Student document does not exist',
        );
      }

      await docRef.update(updates);
    } on FirebaseException {
      rethrow;
    }
  }

  // -------------------------
  // DELETE STUDENT
  // -------------------------
  Future<void> deleteStudent(String uid) async {
    try {
      await _students.doc(uid).delete();
    } on FirebaseException {
      rethrow;
    }
  }

  // -------------------------
  // UPDATE LAST LOGIN
  // -------------------------
  Future<void> updateLastLogin(String uid) async {
    try {
      await _students.doc(uid).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      rethrow;
    }
  }

  // -------------------------
  // EMAIL VERIFICATION FLAG
  // -------------------------
  Future<void> updateEmailVerification(
    String uid,
    bool verified,
  ) async {
    try {
      await _students.doc(uid).set({
        'emailVerified': verified,
      }, SetOptions(merge: true));
    } on FirebaseException {
      rethrow;
    }
  }

  // -------------------------
  // STUDENT ID DUPLICATE CHECK
  // -------------------------
  Future<bool> studentIdExists(String studentId) async {
    try {
      final snap = await _students
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } on FirebaseException {
      rethrow;
    }
  }
}
