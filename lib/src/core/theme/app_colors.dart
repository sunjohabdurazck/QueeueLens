import 'package:flutter/material.dart';

/// IUT color scheme and theme colors
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);

  // Status Colors
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Neutral Colors - Light Theme
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5);
  static const Color lightOnBackground = Color(0xFF1F2937);
  static const Color lightOnSurface = Color(0xFF374151);
  static const Color lightOnSurfaceVariant = Color(0xFF6B7280);

  // Neutral Colors - Dark Theme
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkSurfaceVariant = Color(0xFF374151);
  static const Color darkOnBackground = Color(0xFFF9FAFB);
  static const Color darkOnSurface = Color(0xFFE5E7EB);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);

  // Border Colors
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color darkBorder = Color(0xFF374151);

  // Disabled Colors
  static const Color lightDisabled = Color(0xFFD1D5DB);
  static const Color darkDisabled = Color(0xFF4B5563);

  // Shadow Colors
  static const Color lightShadow = Color(0x1A000000);
  static const Color darkShadow = Color(0x3A000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, Color(0xFF1E40AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [secondaryGreen, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Opacity variations
  static Color primaryBlueLight = primaryBlue.withOpacity(0.1);
  static Color secondaryGreenLight = secondaryGreen.withOpacity(0.1);
  static Color accentAmberLight = accentAmber.withOpacity(0.1);
  static Color errorRedLight = errorRed.withOpacity(0.1);
}
