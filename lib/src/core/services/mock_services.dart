/// Mock Local Storage for testing
class MockLocalStorage {
  final Map<String, dynamic> _storage = {};

  // Authentication keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyStudentId = 'student_id';
  static const String _keyDepartment = 'department';
  static const String _keyCountry = 'country';
  static const String _keyIsEmailVerified = 'is_email_verified';
  static const String _keyThemeMode = 'theme_mode';

  // --- Authentication Methods ---

  Future<bool> setLoggedIn(bool value) async {
    _storage[_keyIsLoggedIn] = value;
    return true;
  }

  bool isLoggedIn() {
    return _storage[_keyIsLoggedIn] ?? false;
  }

  Future<bool> setUserId(String userId) async {
    _storage[_keyUserId] = userId;
    return true;
  }

  String? getUserId() {
    return _storage[_keyUserId];
  }

  Future<bool> setUserEmail(String email) async {
    _storage[_keyUserEmail] = email;
    return true;
  }

  String? getUserEmail() {
    return _storage[_keyUserEmail];
  }

  Future<bool> setUserName(String name) async {
    _storage[_keyUserName] = name;
    return true;
  }

  String? getUserName() {
    return _storage[_keyUserName];
  }

  Future<bool> setStudentId(String studentId) async {
    _storage[_keyStudentId] = studentId;
    return true;
  }

  String? getStudentId() {
    return _storage[_keyStudentId];
  }

  Future<bool> setDepartment(String department) async {
    _storage[_keyDepartment] = department;
    return true;
  }

  String? getDepartment() {
    return _storage[_keyDepartment];
  }

  Future<bool> setCountry(String country) async {
    _storage[_keyCountry] = country;
    return true;
  }

  String? getCountry() {
    return _storage[_keyCountry];
  }

  Future<bool> setEmailVerified(bool verified) async {
    _storage[_keyIsEmailVerified] = verified;
    return true;
  }

  bool isEmailVerified() {
    return _storage[_keyIsEmailVerified] ?? false;
  }

  Future<void> saveUserData({
    required String userId,
    required String email,
    required String name,
    required String studentId,
    required String department,
    required String country,
    bool emailVerified = false,
  }) async {
    await setLoggedIn(true);
    await setUserId(userId);
    await setUserEmail(email);
    await setUserName(name);
    await setStudentId(studentId);
    await setDepartment(department);
    await setCountry(country);
    await setEmailVerified(emailVerified);
  }

  Future<void> clearUserData() async {
    _storage.remove(_keyIsLoggedIn);
    _storage.remove(_keyUserId);
    _storage.remove(_keyUserEmail);
    _storage.remove(_keyUserName);
    _storage.remove(_keyStudentId);
    _storage.remove(_keyDepartment);
    _storage.remove(_keyCountry);
    _storage.remove(_keyIsEmailVerified);
  }

  // --- Generic Methods ---

  Future<bool> setString(String key, String value) async {
    _storage[key] = value;
    return true;
  }

  String? getString(String key) {
    return _storage[key];
  }

  Future<bool> setBool(String key, bool value) async {
    _storage[key] = value;
    return true;
  }

  bool? getBool(String key) {
    return _storage[key];
  }

  Future<bool> remove(String key) async {
    _storage.remove(key);
    return true;
  }

  bool containsKey(String key) {
    return _storage.containsKey(key);
  }

  Future<bool> clearAll() async {
    _storage.clear();
    return true;
  }

  Set<String> getKeys() {
    return _storage.keys.toSet();
  }

  // Theme
  Future<bool> setThemeMode(String mode) async {
    _storage[_keyThemeMode] = mode;
    return true;
  }

  String getThemeMode() {
    return _storage[_keyThemeMode] ?? 'system';
  }
}

/// Mock Analytics Service for testing
class MockAnalyticsService {
  final List<Map<String, dynamic>> _events = [];

  /// Log event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    _events.add({
      'name': name,
      'parameters': parameters ?? {},
      'timestamp': DateTime.now(),
    });
    print('Analytics Event: $name ${parameters ?? ""}');
  }

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', parameters: {'screen_name': screenName});
  }

  /// Log login
  Future<void> logLogin(String method) async {
    await logEvent('login', parameters: {'method': method});
  }

  /// Log sign up
  Future<void> logSignUp(String method) async {
    await logEvent('sign_up', parameters: {'method': method});
  }

  /// Log logout
  Future<void> logLogout() async {
    await logEvent('logout');
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    print('Analytics: Set User ID: $userId');
  }

  /// Set user property
  Future<void> setUserProperty(String name, String value) async {
    print('Analytics: Set User Property: $name = $value');
  }

  /// Get logged events (for testing)
  List<Map<String, dynamic>> getEvents() {
    return _events;
  }

  /// Clear events
  void clearEvents() {
    _events.clear();
  }
}

/// Mock Notification Service for testing
class MockNotificationService {
  final List<Map<String, dynamic>> _notifications = [];
  bool _permissionGranted = false;

  /// Request notification permission
  Future<bool> requestPermission() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _permissionGranted = true;
    print('Notification: Permission requested');
    return true;
  }

  /// Check if permission is granted
  bool isPermissionGranted() {
    return _permissionGranted;
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    _notifications.add({
      'title': title,
      'body': body,
      'data': data ?? {},
      'timestamp': DateTime.now(),
    });
    print('Notification: $title - $body');
  }

  /// Schedule notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
  }) async {
    print('Notification Scheduled: $title at $scheduledDate');
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    print('Notification Cancelled: $id');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    print('All Notifications Cancelled');
  }

  /// Get notifications (for testing)
  List<Map<String, dynamic>> getNotifications() {
    return _notifications;
  }

  /// Clear notifications
  void clearNotifications() {
    _notifications.clear();
  }
}

/// Mock Crash Analytics Service
class MockCrashAnalyticsService {
  final List<Map<String, dynamic>> _errors = [];

  /// Log error
  Future<void> logError(dynamic error, StackTrace? stackTrace) async {
    _errors.add({
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'timestamp': DateTime.now(),
    });
    print('Crash Analytics: Error logged - $error');
  }

  /// Log custom exception
  Future<void> logException(
    String message, {
    Map<String, dynamic>? parameters,
  }) async {
    _errors.add({
      'message': message,
      'parameters': parameters ?? {},
      'timestamp': DateTime.now(),
    });
    print('Crash Analytics: Exception - $message');
  }

  /// Get logged errors (for testing)
  List<Map<String, dynamic>> getErrors() {
    return _errors;
  }

  /// Clear errors
  void clearErrors() {
    _errors.clear();
  }
}

/// Mock Remote Config Service
class MockRemoteConfigService {
  final Map<String, dynamic> _config = {
    'maintenance_mode': false,
    'force_update_version': '1.0.0',
    'feature_flags': {
      'enable_dark_mode': true,
      'enable_qr_scanner': true,
      'enable_notifications': true,
    },
  };

  /// Fetch remote config
  Future<void> fetchConfig() async {
    await Future.delayed(const Duration(milliseconds: 100));
    print('Remote Config: Fetched');
  }

  /// Get bool value
  bool getBool(String key) {
    return _config[key] ?? false;
  }

  /// Get string value
  String getString(String key) {
    return _config[key] ?? '';
  }

  /// Get int value
  int getInt(String key) {
    return _config[key] ?? 0;
  }

  /// Get double value
  double getDouble(String key) {
    return _config[key] ?? 0.0;
  }

  /// Set value (for testing)
  void setValue(String key, dynamic value) {
    _config[key] = value;
  }
}
