import 'dart:async'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Common helper functions
class Helpers {
  Helpers._();

  // Hide keyboard
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous
                ? ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Show info dialog
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // Vibrate device (short)
  static Future<void> vibrateShort() async {
    await HapticFeedback.lightImpact();
  }

  // Vibrate device (medium)
  static Future<void> vibrateMedium() async {
    await HapticFeedback.mediumImpact();
  }

  // Vibrate device (heavy)
  static Future<void> vibrateHeavy() async {
    await HapticFeedback.heavyImpact();
  }

  // Copy to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  // Get clipboard data
  static Future<String?> getClipboardData() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  // Delay execution
  static Future<void> delay(Duration duration) async {
    await Future.delayed(duration);
  }

  // Safe execute (with error handling)
  static Future<T?> safeExecute<T>(Future<T> Function() function) async {
    try {
      return await function();
    } catch (e) {
      debugPrint('Error in safeExecute: $e');
      return null;
    }
  }

  // Retry with exponential backoff
  static Future<T?> retryWithBackoff<T>(
    Future<T> Function() function, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await function();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          debugPrint('Max retry attempts reached: $e');
          rethrow;
        }

        debugPrint('Retry attempt $attempt failed: $e');
        await Future.delayed(currentDelay);
        currentDelay *= 2; // Exponential backoff
      }
    }

    return null;
  }

  // Debounce function calls
  static void Function() debounce(
    void Function() function, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    Timer? timer; // This now refers to dart:async Timer

    return () {
      timer?.cancel();
      timer = Timer(delay, function);
    };
  }

  // Throttle function calls
  static void Function() throttle(
    void Function() function, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    bool throttling = false;
    Timer? timer; // This now refers to dart:async Timer

    return () {
      if (throttling) return;

      throttling = true;
      function();

      timer?.cancel(); // Cancel any existing timer
      timer = Timer(delay, () {
        throttling = false;
      });
    };
  }

  // Generate random string
  static String generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;

    return List.generate(
      length,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }

  // Check if email is valid format (basic check)
  static bool isValidEmailFormat(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Get initials from name
  static String getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();

    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  // Get color from string (for avatars)
  static Color getColorFromString(String text) {
    final hash = text.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;

    return Color.fromARGB(255, r, g, b);
  }

  // Check if dark mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Get screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  // Check if mobile
  static bool isMobile(BuildContext context) {
    return getScreenSize(context).width < 600;
  }

  // Check if tablet
  static bool isTablet(BuildContext context) {
    final width = getScreenSize(context).width;
    return width >= 600 && width < 1024;
  }

  // Check if desktop
  static bool isDesktop(BuildContext context) {
    return getScreenSize(context).width >= 1024;
  }

  // Safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
}
