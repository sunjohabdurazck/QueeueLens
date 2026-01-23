import '../repositories/auth_repository.dart';

/// Use case for sending email verification
/// Sends verification email to the current user's email address
class SendVerificationEmailUseCase {
  final AuthRepository repository;

  SendVerificationEmailUseCase(this.repository);

  /// Execute send verification email
  ///
  /// Performs:
  /// - Checks if user is logged in
  /// - Sends verification email to user's email address
  ///
  /// Throws AuthException if:
  /// - User is not logged in
  /// - Email has already been verified
  /// - Network error occurs
  /// - Too many requests (rate limited)
  Future<void> call() async {
    // Check if user is logged in
    final isLoggedIn = await repository.isLoggedIn();
    if (!isLoggedIn) {
      throw AuthException('No user is currently logged in');
    }

    // Check if email is already verified
    final isVerified = await repository.checkEmailVerified();
    if (isVerified) {
      throw AuthException('Email is already verified');
    }

    // Send verification email
    await repository.sendVerificationEmail();
  }
}
