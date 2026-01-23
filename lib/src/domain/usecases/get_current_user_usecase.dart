import '../entities/student.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting the currently logged in user
/// Returns the current user's Student entity or null if not logged in
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  /// Execute get current user
  ///
  /// Performs:
  /// - Retrieves current user from authentication state
  /// - Returns Student entity if logged in
  /// - Returns null if no user is logged in
  ///
  /// Does not throw exceptions - returns null for "not logged in" state
  Future<Student?> call() async {
    return await repository.getCurrentUser();
  }
}
