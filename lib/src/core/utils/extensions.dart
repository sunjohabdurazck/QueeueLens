import 'package:flutter/material.dart';

/// String extensions
extension StringExtensions on String {
  // Check if string is empty or null
  bool get isNullOrEmpty => isEmpty;

  // Check if string is not empty
  bool get isNotNullOrEmpty => isNotEmpty;

  // Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize)
        .join(' ');
  }

  // Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  // Check if string is numeric
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);

  // Check if string is alphabetic
  bool get isAlphabetic => RegExp(r'^[a-zA-Z]+$').hasMatch(this);

  // Check if string is alphanumeric
  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);

  // Check if valid email format
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  // Check if valid IUT email
  bool get isValidIUTEmail {
    return toLowerCase().endsWith('@iut-dhaka.edu');
  }

  // Check if valid student ID (9 digits)
  bool get isValidStudentId => RegExp(r'^\d{9}$').hasMatch(this);

  // Convert to int safely
  int? get toIntOrNull => int.tryParse(this);

  // Convert to double safely
  double? get toDoubleOrNull => double.tryParse(this);

  // Truncate with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  // Reverse string
  String get reversed => split('').reversed.join('');

  // Count occurrences of substring
  int countOccurrences(String substring) {
    return substring.allMatches(this).length;
  }

  // Format as student ID (XXX-XXX-XXX)
  String get formatAsStudentId {
    if (length != 9) return this;
    return '${substring(0, 3)}-${substring(3, 6)}-${substring(6, 9)}';
  }
}

/// BuildContext extensions
extension ContextExtensions on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // MediaQuery
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  EdgeInsets get viewPadding => mediaQuery.viewPadding;

  // Device type checks
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  // Orientation
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;

  // Dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isLightMode => theme.brightness == Brightness.light;

  // Navigation
  NavigatorState get navigator => Navigator.of(this);

  void pop<T>([T? result]) => navigator.pop(result);

  Future<T?> push<T>(Route<T> route) => navigator.push(route);

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigator.pushNamed(routeName, arguments: arguments);
  }

  Future<T?> pushReplacementNamed<T, TO>(String routeName,
      {Object? arguments}) {
    return navigator.pushReplacementNamed(routeName, arguments: arguments);
  }

  Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) {
    return navigator.pushNamedAndRemoveUntil(
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  // Show snackbar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }

  // Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  // Request focus
  void requestFocus(FocusNode focusNode) {
    FocusScope.of(this).requestFocus(focusNode);
  }
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  // Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  // Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  // Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  // Check if date is in current week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek) && isBefore(endOfWeek);
  }

  // Check if date is in current month
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  // Check if date is in current year
  bool get isThisYear {
    final now = DateTime.now();
    return year == now.year;
  }

  // Get start of day
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  // Get end of day
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  // Add days
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  // Subtract days
  DateTime subtractDays(int days) {
    return subtract(Duration(days: days));
  }

  // Get difference in days
  int differenceInDays(DateTime other) {
    return difference(other).inDays;
  }

  // Format as relative time
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

/// List extensions
extension ListExtensions<T> on List<T> {
  // Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  // Check if list is not empty
  bool get isNotNullOrEmpty => isNotEmpty;

  // Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  // Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  // Get element at index or null
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  // Separate list into chunks
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size < length) ? i + size : length));
    }
    return chunks;
  }
}

/// Color extensions
extension ColorExtensions on Color {
  // Convert to hex string
  String get toHex {
    return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  // Lighten color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Darken color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

/// num extensions
extension NumExtensions on num {
  // Check if number is positive
  bool get isPositive => this > 0;

  // Check if number is negative
  bool get isNegative => this < 0;

  // Check if number is zero
  bool get isZero => this == 0;

  // Clamp between min and max
  num clampTo(num min, num max) => clamp(min, max);
}
