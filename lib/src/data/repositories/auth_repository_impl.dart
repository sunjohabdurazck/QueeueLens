import '../../domain/entities/student.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_student_datasource.dart';
import '../models/student_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource authDataSource;
  final FirestoreStudentDataSource firestoreDataSource;

  AuthRepositoryImpl({
    required this.authDataSource,
    required this.firestoreDataSource,
  });

  bool _isValidStudentId(String id) => RegExp(r'^\d{9}$').hasMatch(id);

  // -------------------- SIGN IN --------------------
  @override
  Future<Student> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await authDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final studentModel = await firestoreDataSource.getStudent(user.uid);
      if (studentModel == null) {
        throw UserNotFoundException();
      }

      await firestoreDataSource.updateLastLogin(user.uid);
      await firestoreDataSource.updateEmailVerification(
        user.uid,
        user.emailVerified,
      );

      final updated = await firestoreDataSource.getStudent(user.uid);
      return updated!.toEntity();
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // -------------------- SIGN UP --------------------
  @override
  Future<Student> signUp({
    required Student student,
    required String password,
  }) async {
    try {
      if (!_isValidStudentId(student.studentId)) {
        throw AuthException('Student ID must be exactly 9 digits');
      }

      final exists =
          await firestoreDataSource.studentIdExists(student.studentId);
      if (exists) {
        throw AuthException('Student ID already registered');
      }

      final user = await authDataSource.createUserWithEmailAndPassword(
        email: student.email,
        password: password,
      );

      final studentModel = StudentModel.fromEntity(
        student.copyWith(
          uid: user.uid,
          emailVerified: user.emailVerified,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        ),
      );

      await firestoreDataSource.createStudent(studentModel);
      await authDataSource.sendEmailVerification();

      return studentModel.toEntity();
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // -------------------- SIGN OUT --------------------
  @override
  Future<void> signOut() async {
    try {
      await authDataSource.signOut();
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // -------------------- EMAIL VERIFICATION --------------------
  @override
  Future<void> sendVerificationEmail() async {
    try {
      await authDataSource.sendEmailVerification();
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<bool> checkEmailVerified() async {
    try {
      final user = authDataSource.getCurrentUser();
      if (user == null) throw AuthException('No user logged in');

      await authDataSource.reload();
      return authDataSource.getCurrentUser()?.emailVerified ?? false;
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // -------------------- PASSWORD RESET --------------------
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await authDataSource.sendPasswordResetEmail(email);
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // -------------------- CURRENT USER --------------------
  @override
  Future<Student?> getCurrentUser() async {
    try {
      final user = authDataSource.getCurrentUser();
      if (user == null) return null;

      final studentModel = await firestoreDataSource.getStudent(user.uid);
      return studentModel?.toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return authDataSource.isLoggedIn();
  }

  @override
  Future<Student> reloadUser() async {
    try {
      await authDataSource.reload();

      final user = authDataSource.getCurrentUser();
      if (user == null) throw AuthException('No user logged in');

      await firestoreDataSource.updateEmailVerification(
        user.uid,
        user.emailVerified,
      );

      final studentModel = await firestoreDataSource.getStudent(user.uid);
      if (studentModel == null) throw UserNotFoundException();

      return studentModel.toEntity();
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // -------------------- UPDATE PROFILE --------------------
  @override
  Future<Student> updateProfile({
    required String uid,
    String? name,
    String? country,
    String? department,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (country != null) updates['country'] = country;
      if (department != null) updates['department'] = department;

      await firestoreDataSource.updateStudent(uid, updates);

      final studentModel = await firestoreDataSource.getStudent(uid);
      if (studentModel == null) throw UserNotFoundException();

      return studentModel.toEntity();
    } catch (e) {
      throw AuthException('Failed to update profile');
    }
  }

  // -------------------- DELETE ACCOUNT --------------------
  @override
  Future<void> deleteAccount() async {
    try {
      final user = authDataSource.getCurrentUser();
      if (user == null) throw AuthException('No user logged in');

      await firestoreDataSource.deleteStudent(user.uid);
      await authDataSource.deleteUser();
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // ==================== FIXED MAPPER ====================
  AuthException _mapFirebaseException(Object e) {
    if (e is AuthException) return e;

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return InvalidCredentialsException();

        case 'user-not-found':
          return UserNotFoundException();

        case 'invalid-email':
          return InvalidEmailException();

        case 'email-already-in-use':
          return EmailAlreadyInUseException();

        case 'weak-password':
          return WeakPasswordException();

        case 'user-disabled':
          return UserDisabledException();

        case 'too-many-requests':
          return TooManyRequestsException();

        case 'network-request-failed':
          return NetworkException();

        default:
          return AuthException(
            e.message ?? 'Authentication failed',
            code: e.code,
          );
      }
    }

    return AuthException('An unexpected error occurred');
  }
}
