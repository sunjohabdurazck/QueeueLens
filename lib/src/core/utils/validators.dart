/// Validation utility class for form inputs
class Validators {
  Validators._();

  // Email validation - must end with @iut-dhaka.edu
  static bool isValidIUTEmail(String email) {
    if (email.isEmpty) return false;
    return email.trim().toLowerCase().endsWith('@iut-dhaka.edu');
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    if (!isValidIUTEmail(value)) {
      return 'Please use your IUT email (@iut-dhaka.edu)';
    }
    
    return null;
  }

  // Password validation - min 8 chars, 1 upper, 1 lower, 1 number
  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    
    return hasUpperCase && hasLowerCase && hasDigit;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  // Password strength calculator (0-4)
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int strength = 0;
    
    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    
    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'\d').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    
    // Normalize to 0-4 scale
    return (strength / 1.5).ceil().clamp(0, 4);
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Student ID validation - exactly 9 digits
  static bool isValidStudentId(String id) {
    return RegExp(r'^\d{9}$').hasMatch(id.trim());
  }

  static String? validateStudentId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Student ID is required';
    }
    
    if (!isValidStudentId(value)) {
      return 'Student ID must be exactly 9 digits';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  // Department validation
  static String? validateDepartment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Department is required';
    }
    
    return null;
  }

  // Country validation
  static String? validateCountry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Country is required';
    }
    
    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }

  // Phone number validation (optional - if needed later)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    // Basic phone number validation (can be customized)
    if (!RegExp(r'^\+?[\d\s-()]+$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // URL validation (optional - if needed later)
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}