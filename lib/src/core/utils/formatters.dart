import 'package:intl/intl.dart';

/// Text formatting utility class
class Formatters {
  Formatters._();

  // Format student ID with dashes (e.g., 190-041-123)
  static String formatStudentId(String studentId) {
    if (studentId.length != 9) return studentId;

    return '${studentId.substring(0, 3)}-${studentId.substring(3, 6)}-${studentId.substring(6, 9)}';
  }

  // Format email to lowercase and trim
  static String formatEmail(String email) {
    return email.trim().toLowerCase();
  }

  // Capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Capitalize first letter only
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Format date to readable string
  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    return DateFormat(format).format(date);
  }

  // Format date with time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  // Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  // Format phone number (if needed)
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 11) {
      // Format: 01712-345678
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    }

    return phoneNumber;
  }

  // Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Format currency (if needed)
  static String formatCurrency(double amount, {String symbol = '৳'}) {
    final formatter = NumberFormat('#,##0.00');
    return '$symbol${formatter.format(amount)}';
  }

  // Format percentage
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  // Remove special characters
  static String removeSpecialCharacters(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  // Convert to slug (URL-friendly string)
  static String toSlug(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  // Parse student ID from formatted string
  static String parseStudentId(String formattedId) {
    return formattedId.replaceAll('-', '');
  }

  // Format department code (e.g., CSE, EEE, etc.)
  static String formatDepartmentCode(String department) {
    // Extract initials from department name
    final words = department.split(' ');
    if (words.length == 1) {
      return department.substring(0, 3).toUpperCase();
    }

    return words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0])
        .join()
        .toUpperCase();
  }

  // Mask email (show only first 3 chars and domain)
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 3) {
      return email;
    }

    final masked = username.substring(0, 3) + '*' * (username.length - 3);
    return '$masked@$domain';
  }
}
