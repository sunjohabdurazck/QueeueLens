import '../../domain/entities/student.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/mock_auth_datasource.dart';
import '../datasources/mock_firestore_datasource.dart';
import '../models/student_model.dart';

/// Mock implementation of AuthRepository
/// Uses mock data sources instead of real Firebase
/// This allows development and testing without Firebase setup
class MockAuthRepositoryImpl implements AuthRepository {
  final MockAuthDataSource authDataSource;
  final MockFirestoreDataSource firestoreDataSource;

  MockAuthRepositoryImpl({
    required this.authDataSource,
    required this.firestoreDataSource,
  });

  @override
  Future<Student> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with auth data source
      final mockUser = await authDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get student data from Firestore
      final studentModel = await firestoreDataSource.getStudent(mockUser.uid);

      if (studentModel == null) {
        throw UserNotFoundException();
      }

      // Update last login
      await firestoreDataSource.updateLastLogin(mockUser.uid);

      // Update email verification status from auth
      await firestoreDataSource.updateEmailVerification(
        mockUser.uid,
        mockUser.emailVerified,
      );

      // Return updated student entity
      final updatedModel = await firestoreDataSource.getStudent(mockUser.uid);
      return updatedModel!.toEntity();
    } on MockAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<Student> signUp({
    required Student student,
    required String password,
  }) async {
    try {
      // Check if student ID already exists
      final exists = await firestoreDataSource.studentIdExists(
        student.studentId,
      );
      if (exists) {
        throw AuthException('Student ID already registered');
      }

      // Create auth account
      final mockUser = await authDataSource.createUserWithEmailAndPassword(
        email: student.email,
        password: password,
      );

      // Create student document in Firestore
      final studentModel = StudentModel.fromEntity(
        student.copyWith(
          uid: mockUser.uid,
          emailVerified: mockUser.emailVerified,
          createdAt: mockUser.createdAt,
          lastLoginAt: mockUser.lastLoginAt,
        ),
      );

      await firestoreDataSource.createStudent(studentModel);

      // Send verification email
      await authDataSource.sendEmailVerification();

      return studentModel.toEntity();
    } on MockAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await authDataSource.signOut();
    } on MockAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> sendVerificationEmail() async {
    try {
      await authDataSource.sendEmailVerification();
    } on MockAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<bool> checkEmailVerified() async {
    try {
      final currentUser = authDataSource.getCurrentUser();
      if (currentUser == null) {
        throw AuthException('No user logged in');
      }
      return currentUser.emailVerified;
    } catch (e) {
      throw AuthException(
        'Failed to check email verification: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await authDataSource.sendPasswordResetEmail(email);
    } on MockAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<Student?> getCurrentUser() async {
    try {
      final mockUser = authDataSource.getCurrentUser();
      if (mockUser == null) {
        return null;
      }

      final studentModel = await firestoreDataSource.getStudent(mockUser.uid);
      return studentModel?.toEntity();
    } catch (e) {
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

      final mockUser = authDataSource.getCurrentUser();
      if (mockUser == null) {
        throw AuthException('No user logged in');
      }

      // Update verification status in Firestore
      await firestoreDataSource.updateEmailVerification(
        mockUser.uid,
        mockUser.emailVerified,
      );

      final studentModel = await firestoreDataSource.getStudent(mockUser.uid);
      if (studentModel == null) {
        throw UserNotFoundException();
      }

      return studentModel.toEntity();
    } on MockAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

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
      if (studentModel == null) {
        throw UserNotFoundException();
      }

      return studentModel.toEntity();
    } catch (e) {
      throw AuthException('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final mockUser = authDataSource.getCurrentUser();
      if (mockUser == null) {
        throw AuthException('No user logged in');
      }

      // Delete Firestore document
      await firestoreDataSource.deleteStudent(mockUser.uid);

      // Delete auth account
      await authDataSource.deleteUser();
    } on MockAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Maps MockAuthException to AuthException
  AuthException _mapAuthException(MockAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return UserNotFoundException();
      case 'wrong-password':
        return InvalidCredentialsException();
      case 'email-already-in-use':
        return EmailAlreadyInUseException();
      case 'weak-password':
        return WeakPasswordException();
      case 'invalid-email':
        return InvalidEmailException();
      case 'network-error':
        return NetworkException();
      case 'too-many-requests':
        return TooManyRequestsException();
      case 'user-disabled':
        return UserDisabledException();
      default:
        return AuthException(e.message, code: e.code);
    }
  }
}
