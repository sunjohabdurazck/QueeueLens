import '../repositories/auth_repository.dart';

/// Use case for checking if user's email is verified
/// Reloads user data from server and checks verification status
class CheckEmailVerifiedUseCase {
  final AuthRepository repository;

  CheckEmailVerifiedUseCase(this.repository);

  /// Execute check email verified
  ///
  /// Performs:
  /// - Checks if user is logged in
  /// - Reloads user data from server (to get fresh verification status)
  /// - Returns verification status
  ///
  /// Returns true if email is verified, false otherwise
  ///
  /// Throws AuthException if:
  /// - User is not logged in
  /// - Network error occurs
  Future<bool> call() async {
    // Check if user is logged in
    final isLoggedIn = await repository.isLoggedIn();
    if (!isLoggedIn) {
      throw AuthException('No user is currently logged in');
    }

    // Reload user to get fresh data from server
    await repository.reloadUser();

    // Check verification status
    return await repository.checkEmailVerified();
  }
}
