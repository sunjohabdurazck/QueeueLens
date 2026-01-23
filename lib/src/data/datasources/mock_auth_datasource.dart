/// Mock data source simulating Firebase Authentication
/// Used for development and testing before Firebase integration
class MockAuthDataSource {
  // Simulated in-memory user storage
  final Map<String, MockUser> _users = {};
  MockUser? _currentUser;

  // Predefined test users
  MockAuthDataSource() {
    // Add some test users
    _users['test@iut-dhaka.edu'] = MockUser(
      uid: 'test-uid-001',
      email: 'test@iut-dhaka.edu',
      password: 'Test@123',
      emailVerified: true,
    );

    _users['student@iut-dhaka.edu'] = MockUser(
      uid: 'test-uid-002',
      email: 'student@iut-dhaka.edu',
      password: 'Student@123',
      emailVerified: false,
    );
  }

  /// Sign in with email and password
  Future<MockUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if user exists
    if (!_users.containsKey(email)) {
      throw MockAuthException('User not found', 'user-not-found');
    }

    final user = _users[email]!;

    // Check password
    if (user.password != password) {
      throw MockAuthException('Invalid password', 'wrong-password');
    }

    // Set as current user
    _currentUser = user.copyWith(lastLoginAt: DateTime.now());

    return _currentUser!;
  }

  /// Create new user with email and password
  Future<MockUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Check if user already exists
    if (_users.containsKey(email)) {
      throw MockAuthException('Email already in use', 'email-already-in-use');
    }

    // Create new user
    final newUser = MockUser(
      uid: 'uid-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      password: password,
      emailVerified: false,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    // Store user
    _users[email] = newUser;
    _currentUser = newUser;

    return newUser;
  }

  /// Sign out current user
  Future<void> signOut() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  /// Send verification email
  Future<void> sendEmailVerification() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentUser == null) {
      throw MockAuthException('No user logged in', 'no-current-user');
    }

    // In real implementation, this would trigger an email
    print('📧 Verification email sent to ${_currentUser!.email}');
  }

  /// Reload user data
  Future<void> reload() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (_currentUser == null) {
      throw MockAuthException('No user logged in', 'no-current-user');
    }

    // In mock, we can simulate verification after some time
    // For testing purposes, auto-verify after reload
    final user = _users[_currentUser!.email];
    if (user != null && !user.emailVerified) {
      // Simulate email verification
      _users[_currentUser!.email] = user.copyWith(emailVerified: true);
      _currentUser = _users[_currentUser!.email];
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if user exists
    if (!_users.containsKey(email)) {
      throw MockAuthException('User not found', 'user-not-found');
    }

    // In real implementation, this would send an email
    print('📧 Password reset email sent to $email');
  }

  /// Get current user
  MockUser? getCurrentUser() {
    return _currentUser;
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _currentUser != null;
  }

  /// Delete current user
  Future<void> deleteUser() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentUser == null) {
      throw MockAuthException('No user logged in', 'no-current-user');
    }

    // Remove from storage
    _users.remove(_currentUser!.email);
    _currentUser = null;
  }
}

/// Mock user class representing authenticated user
class MockUser {
  final String uid;
  final String email;
  final String password; // In real Firebase, password is never stored/returned
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  MockUser({
    required this.uid,
    required this.email,
    required this.password,
    this.emailVerified = false,
    this.createdAt,
    this.lastLoginAt,
  });

  MockUser copyWith({
    String? uid,
    String? email,
    String? password,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return MockUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      password: password ?? this.password,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// Mock authentication exception
class MockAuthException implements Exception {
  final String message;
  final String code;

  MockAuthException(this.message, this.code);

  @override
  String toString() => 'MockAuthException: $message (code: $code)';
}
