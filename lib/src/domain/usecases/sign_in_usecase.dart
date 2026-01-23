import '../entities/student.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in a user
/// Validates input and delegates to repository
class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  /// Execute sign in
  ///
  /// Validates:
  /// - Email is not empty
  /// - Email ends with @iut-dhaka.edu
  /// - Password is not empty
  /// - Password meets strength requirements
  ///
  /// Returns Student entity on success
  /// Throws AuthException on failure
  Future<Student> call(SignInParams params) async {
    // Validate email
    if (params.email.isEmpty) {
      throw AuthException('Email cannot be empty');
    }

    if (!_isValidIUTEmail(params.email)) {
      throw InvalidEmailException();
    }

    // Validate password
    if (params.password.isEmpty) {
      throw AuthException('Password cannot be empty');
    }

    if (!_isPasswordStrong(params.password)) {
      throw WeakPasswordException();
    }

    // Delegate to repository
    return await repository.signIn(
      email: params.email,
      password: params.password,
    );
  }

  /// Validates IUT email format
  bool _isValidIUTEmail(String email) {
    return email.trim().toLowerCase().endsWith('@iut-dhaka.edu');
  }

  /// Validates password strength
  /// Must contain:
  /// - At least 8 characters
  /// - At least 1 uppercase letter
  /// - At least 1 lowercase letter
  /// - At least 1 number
  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'\d'));

    return hasUppercase && hasLowercase && hasDigits;
  }
}

/// Parameters for SignInUseCase
class SignInParams {
  final String email;
  final String password;

  SignInParams({required this.email, required this.password});
}
