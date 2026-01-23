import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Show success snackbar
void showSuccessSnackbar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.successGreen,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: action,
    ),
  );
}

/// Show error snackbar
void showErrorSnackbar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.errorRed,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: action,
    ),
  );
}

/// Show warning snackbar
void showWarningSnackbar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.warning_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.warningOrange,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: action,
    ),
  );
}

/// Show info snackbar
void showInfoSnackbar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.info_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.infoBlue,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: action,
    ),
  );
}

/// Custom snackbar widget
class CustomSnackbar extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final SnackBarAction? action;

  const CustomSnackbar({
    super.key,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: action!.onPressed,
              child: Text(
                action!.label,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Show this snackbar
  void show(BuildContext context, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: this,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Utility class for snackbar management
class SnackbarService {
  SnackbarService._();

  static void success(BuildContext context, String message) {
    showSuccessSnackbar(context, message);
  }

  static void error(BuildContext context, String message) {
    showErrorSnackbar(context, message);
  }

  static void warning(BuildContext context, String message) {
    showWarningSnackbar(context, message);
  }

  static void info(BuildContext context, String message) {
    showInfoSnackbar(context, message);
  }

  static void custom(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Color? iconColor,
    Color? textColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    CustomSnackbar(
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      textColor: textColor,
      action: action,
    ).show(context, duration: duration);
  }
}
