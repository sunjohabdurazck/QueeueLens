import '../entities/student.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing up a new user
/// Validates all input fields and delegates to repository
class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  /// Execute sign up
  ///
  /// Validates:
  /// - All required fields are present
  /// - Email is valid IUT email
  /// - Password meets strength requirements
  /// - Student ID is 9 digits
  /// - Name is not empty
  /// - Country is not empty
  /// - Department is not empty
  ///
  /// Returns Student entity on success
  /// Throws AuthException on failure
  Future<Student> call(SignUpParams params) async {
    // Validate student data
    _validateStudent(params.student);

    // Validate password
    _validatePassword(params.password);

    // Delegate to repository
    return await repository.signUp(
      student: params.student,
      password: params.password,
    );
  }

  /// Validates student entity fields
  void _validateStudent(Student student) {
    // Validate name
    if (student.name.trim().isEmpty) {
      throw AuthException('Name cannot be empty');
    }

    if (student.name.trim().length < 3) {
      throw AuthException('Name must be at least 3 characters');
    }

    // Validate email
    if (student.email.isEmpty) {
      throw AuthException('Email cannot be empty');
    }

    if (!_isValidIUTEmail(student.email)) {
      throw InvalidEmailException();
    }

    // Validate student ID
    if (student.studentId.isEmpty) {
      throw AuthException('Student ID cannot be empty');
    }

    if (!_isValidStudentId(student.studentId)) {
      throw AuthException('Student ID must be exactly 9 digits');
    }

    // Validate country
    if (student.country.trim().isEmpty) {
      throw AuthException('Country cannot be empty');
    }

    // Validate department
    if (student.department.trim().isEmpty) {
      throw AuthException('Department cannot be empty');
    }
  }

  /// Validates password
  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw AuthException('Password cannot be empty');
    }

    if (!_isPasswordStrong(password)) {
      throw WeakPasswordException();
    }
  }

  /// Validates IUT email format
  bool _isValidIUTEmail(String email) {
    return email.trim().toLowerCase().endsWith('@iut-dhaka.edu');
  }

  /// Validates student ID format (exactly 9 digits)
  bool _isValidStudentId(String studentId) {
    return RegExp(r'^\d{9}$').hasMatch(studentId);
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

/// Parameters for SignUpUseCase
class SignUpParams {
  final Student student;
  final String password;

  SignUpParams({required this.student, required this.password});
}
