import '../entities/student.dart';

/// Repository interface for authentication operations
/// This defines the contract that the data layer must implement
abstract class AuthRepository {
  /// Sign in with email and password
  /// Returns Student entity on success
  /// Throws AuthException on failure
  Future<Student> signIn({required String email, required String password});

  /// Sign up new student account
  /// Returns Student entity on success
  /// Throws AuthException on failure
  Future<Student> signUp({required Student student, required String password});

  /// Sign out current user
  /// Throws AuthException on failure
  Future<void> signOut();

  /// Send email verification to current user
  /// Throws AuthException on failure
  Future<void> sendVerificationEmail();

  /// Check if current user's email is verified
  /// Returns true if verified, false otherwise
  Future<bool> checkEmailVerified();

  /// Send password reset email
  /// Throws AuthException on failure
  Future<void> sendPasswordResetEmail(String email);

  /// Get currently logged in user
  /// Returns Student entity if logged in
  /// Returns null if no user is logged in
  Future<Student?> getCurrentUser();

  /// Check if user is currently logged in
  /// Returns true if user is logged in
  Future<bool> isLoggedIn();

  /// Reload current user data from server
  /// Returns updated Student entity
  /// Throws AuthException on failure
  Future<Student> reloadUser();

  /// Update student profile data
  /// Returns updated Student entity
  /// Throws AuthException on failure
  Future<Student> updateProfile({
    required String uid,
    String? name,
    String? country,
    String? department,
  });

  /// Delete user account
  /// Throws AuthException on failure
  Future<void> deleteAccount();
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() =>
      'AuthException: $message ${code != null ? '(code: $code)' : ''}';
}

/// Specific authentication error types
class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException()
    : super('Invalid email or password', code: 'invalid-credentials');
}

class UserNotFoundException extends AuthException {
  UserNotFoundException() : super('User not found', code: 'user-not-found');
}

class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException()
    : super('Email already in use', code: 'email-already-in-use');
}

class WeakPasswordException extends AuthException {
  WeakPasswordException()
    : super('Password is too weak', code: 'weak-password');
}

class InvalidEmailException extends AuthException {
  InvalidEmailException()
    : super('Invalid email format', code: 'invalid-email');
}

class NetworkException extends AuthException {
  NetworkException()
    : super(
        'Network error. Please check your connection',
        code: 'network-error',
      );
}

class TooManyRequestsException extends AuthException {
  TooManyRequestsException()
    : super(
        'Too many attempts. Please try again later',
        code: 'too-many-requests',
      );
}

class UserDisabledException extends AuthException {
  UserDisabledException()
    : super('User account has been disabled', code: 'user-disabled');
}
