import 'package:flutter/material.dart';

/// Utility class untuk akses warna tema yang konsisten di semua role
/// Gunakan BuildContext untuk mendapatkan warna yang sesuai dengan tema aktif
class ThemeColors {
  // Primary Colors
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF1B7A3E);
  }

  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2196F3)
        : const Color(0xFF1976D2);
  }

  static Color getTertiaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFD32F2F);
  }

  // Surface Colors
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFFFFFFF);
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);
  }

  // Text Colors
  static Color getPrimaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1B1B1B);
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFCCCCCC)
        : const Color(0xFF333333);
  }

  static Color getTertiaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF999999)
        : const Color(0xFF666666);
  }

  static Color getHintTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF888888)
        : const Color(0xFF999999);
  }

  // Role-specific Status Colors
  static Color getStatusPendingColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFA726) // Orange
        : const Color(0xFFFF9800);
  }

  static Color getStatusInProgressColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF42A5F5) // Blue
        : const Color(0xFF1976D2);
  }

  static Color getStatusArrivedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFAB47BC) // Purple
        : const Color(0xFF7B1FA2);
  }

  static Color getStatusCompletedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF66BB6A) // Green
        : const Color(0xFF4CAF50);
  }

  static Color getStatusRejectedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEF5350) // Red
        : const Color(0xFFD32F2F);
  }

  // Border & Divider Colors
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF404040)
        : const Color(0xFFE0E0E0);
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF0F0F0);
  }

  // Success/Error/Warning Colors
  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF66BB6A)
        : const Color(0xFF4CAF50);
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEF5350)
        : const Color(0xFFD32F2F);
  }

  static Color getWarningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFA726)
        : const Color(0xFFFF9800);
  }

  static Color getInfoColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF42A5F5)
        : const Color(0xFF1976D2);
  }

  // Shadow Colors (for cards, elevated buttons, etc)
  static Color getShadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0x00000000).withValues(alpha: 0.3)
        : const Color(0x00000000).withValues(alpha: 0.15);
  }

  // Icon Colors
  static Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF666666);
  }

  static Color getPrimaryIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF1B7A3E);
  }

  // Disabled States
  static Color getDisabledColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF404040)
        : const Color(0xFFE0E0E0);
  }

  static Color getDisabledTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF606060)
        : const Color(0xFF999999);
  }

  // Input Field Colors
  static Color getInputFillColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF9F9F9);
  }

  static Color getInputBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF404040)
        : const Color(0xFFE0E0E0);
  }

  static Color getInputFocusedBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF1B7A3E);
  }

  // Gradient Colors (for role-specific cards or sections)
  /// Gradient untuk User role
  static List<Color> getUserGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
        : [const Color(0xFF1B7A3E), const Color(0xFF0D47A1)];
  }

  /// Gradient untuk Petugas role
  static List<Color> getPetugasGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? [const Color(0xFF42A5F5), const Color(0xFF1565C0)]
        : [const Color(0xFF1976D2), const Color(0xFF0D47A1)];
  }

  /// Gradient untuk Admin role
  static List<Color> getAdminGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? [const Color(0xFFFFA726), const Color(0xFFE65100)]
        : [const Color(0xFFFF9800), const Color(0xFFE65100)];
  }

  // Overlay/Scrim Colors
  static Color getOverlayColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.32);
  }

  // Card Background Color
  static Color getCardBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFFFFFFF);
  }

  // Selection/Highlight Colors
  static Color getSelectionColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4CAF5033)
        : const Color(0xFF1B7A3E33);
  }
}
