import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service using SharedPreferences
class LocalStorage {
  static LocalStorage? _instance;
  static SharedPreferences? _preferences;

  LocalStorage._();

  /// Get singleton instance
  static Future<LocalStorage> getInstance() async {
    _instance ??= LocalStorage._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Storage keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyStudentId = 'student_id';
  static const String _keyDepartment = 'department';
  static const String _keyCountry = 'country';
  static const String _keyIsEmailVerified = 'is_email_verified';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyFirstLaunch = 'first_launch';

  // --- Authentication Methods ---

  /// Save login status
  Future<bool> setLoggedIn(bool value) async {
    return await _preferences!.setBool(_keyIsLoggedIn, value);
  }

  /// Get login status
  bool isLoggedIn() {
    return _preferences!.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Save user ID
  Future<bool> setUserId(String userId) async {
    return await _preferences!.setString(_keyUserId, userId);
  }

  /// Get user ID
  String? getUserId() {
    return _preferences!.getString(_keyUserId);
  }

  /// Save user email
  Future<bool> setUserEmail(String email) async {
    return await _preferences!.setString(_keyUserEmail, email);
  }

  /// Get user email
  String? getUserEmail() {
    return _preferences!.getString(_keyUserEmail);
  }

  /// Save user name
  Future<bool> setUserName(String name) async {
    return await _preferences!.setString(_keyUserName, name);
  }

  /// Get user name
  String? getUserName() {
    return _preferences!.getString(_keyUserName);
  }

  /// Save student ID
  Future<bool> setStudentId(String studentId) async {
    return await _preferences!.setString(_keyStudentId, studentId);
  }

  /// Get student ID
  String? getStudentId() {
    return _preferences!.getString(_keyStudentId);
  }

  /// Save department
  Future<bool> setDepartment(String department) async {
    return await _preferences!.setString(_keyDepartment, department);
  }

  /// Get department
  String? getDepartment() {
    return _preferences!.getString(_keyDepartment);
  }

  /// Save country
  Future<bool> setCountry(String country) async {
    return await _preferences!.setString(_keyCountry, country);
  }

  /// Get country
  String? getCountry() {
    return _preferences!.getString(_keyCountry);
  }

  /// Save email verification status
  Future<bool> setEmailVerified(bool verified) async {
    return await _preferences!.setBool(_keyIsEmailVerified, verified);
  }

  /// Get email verification status
  bool isEmailVerified() {
    return _preferences!.getBool(_keyIsEmailVerified) ?? false;
  }

  /// Save all user data at once
  Future<void> saveUserData({
    required String userId,
    required String email,
    required String name,
    required String studentId,
    required String department,
    required String country,
    bool emailVerified = false,
  }) async {
    await Future.wait([
      setLoggedIn(true),
      setUserId(userId),
      setUserEmail(email),
      setUserName(name),
      setStudentId(studentId),
      setDepartment(department),
      setCountry(country),
      setEmailVerified(emailVerified),
    ]);
  }

  /// Clear all user data (logout)
  Future<void> clearUserData() async {
    await Future.wait([
      _preferences!.remove(_keyIsLoggedIn),
      _preferences!.remove(_keyUserId),
      _preferences!.remove(_keyUserEmail),
      _preferences!.remove(_keyUserName),
      _preferences!.remove(_keyStudentId),
      _preferences!.remove(_keyDepartment),
      _preferences!.remove(_keyCountry),
      _preferences!.remove(_keyIsEmailVerified),
    ]);
  }

  // --- App Settings Methods ---

  /// Save theme mode (light/dark/system)
  Future<bool> setThemeMode(String mode) async {
    return await _preferences!.setString(_keyThemeMode, mode);
  }

  /// Get theme mode
  String getThemeMode() {
    return _preferences!.getString(_keyThemeMode) ?? 'system';
  }

  /// Save language preference
  Future<bool> setLanguage(String language) async {
    return await _preferences!.setString(_keyLanguage, language);
  }

  /// Get language preference
  String getLanguage() {
    return _preferences!.getString(_keyLanguage) ?? 'en';
  }

  /// Check if first launch
  bool isFirstLaunch() {
    return _preferences!.getBool(_keyFirstLaunch) ?? true;
  }

  /// Set first launch complete
  Future<bool> setFirstLaunchComplete() async {
    return await _preferences!.setBool(_keyFirstLaunch, false);
  }

  // --- Generic Methods ---

  /// Save string value
  Future<bool> setString(String key, String value) async {
    return await _preferences!.setString(key, value);
  }

  /// Get string value
  String? getString(String key) {
    return _preferences!.getString(key);
  }

  /// Save int value
  Future<bool> setInt(String key, int value) async {
    return await _preferences!.setInt(key, value);
  }

  /// Get int value
  int? getInt(String key) {
    return _preferences!.getInt(key);
  }

  /// Save double value
  Future<bool> setDouble(String key, double value) async {
    return await _preferences!.setDouble(key, value);
  }

  /// Get double value
  double? getDouble(String key) {
    return _preferences!.getDouble(key);
  }

  /// Save bool value
  Future<bool> setBool(String key, bool value) async {
    return await _preferences!.setBool(key, value);
  }

  /// Get bool value
  bool? getBool(String key) {
    return _preferences!.getBool(key);
  }

  /// Save string list
  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences!.setStringList(key, value);
  }

  /// Get string list
  List<String>? getStringList(String key) {
    return _preferences!.getStringList(key);
  }

  /// Remove value by key
  Future<bool> remove(String key) async {
    return await _preferences!.remove(key);
  }

  /// Check if key exists
  bool containsKey(String key) {
    return _preferences!.containsKey(key);
  }

  /// Clear all data
  Future<bool> clearAll() async {
    return await _preferences!.clear();
  }

  /// Get all keys
  Set<String> getKeys() {
    return _preferences!.getKeys();
  }

  /// Reload preferences
  Future<void> reload() async {
    await _preferences!.reload();
  }
}
