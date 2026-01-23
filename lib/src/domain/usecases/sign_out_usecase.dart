import '../repositories/auth_repository.dart';

/// Use case for signing out the current user
/// Clears authentication session and local data
class SignOutUseCase {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  /// Execute sign out
  ///
  /// Performs:
  /// - Signs out from Firebase Auth
  /// - Clears local session data
  /// - Clears cached user data
  ///
  /// Throws AuthException on failure
  Future<void> call() async {
    await repository.signOut();
  }
}
