import '../repositories/auth_repository.dart';

/// Use case for password reset (forgot password)
/// Sends password reset email to the provided email address
class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  /// Execute forgot password
  ///
  /// Validates:
  /// - Email is not empty
  /// - Email is valid IUT email format
  ///
  /// Performs:
  /// - Sends password reset email to the provided address
  ///
  /// Throws AuthException if:
  /// - Email is invalid
  /// - User with email doesn't exist
  /// - Network error occurs
  /// - Too many requests (rate limited)
  Future<void> call(ForgotPasswordParams params) async {
    // Validate email
    if (params.email.isEmpty) {
      throw AuthException('Email cannot be empty');
    }

    if (!_isValidIUTEmail(params.email)) {
      throw InvalidEmailException();
    }

    // Send password reset email
    await repository.sendPasswordResetEmail(params.email);
  }

  /// Validates IUT email format
  bool _isValidIUTEmail(String email) {
    return email.trim().toLowerCase().endsWith('@iut-dhaka.edu');
  }
}

/// Parameters for ForgotPasswordUseCase
class ForgotPasswordParams {
  final String email;

  ForgotPasswordParams({required this.email});
}
