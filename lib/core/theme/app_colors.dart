import 'package:flutter/material.dart';

class AppColors {
  // Base Palette
  static const Color deepNavy = Color(0xFF091540);
  static const Color royalBlue = Color(0xFF182CC1);
  static const Color periwinkle = Color(0xFF7692FF);
  static const Color sky = Color(0xFFABD2FA);

  // Light Mode
  static const Color lightPrimary = royalBlue;
  static const Color lightOnPrimary = Colors.white;
  static const Color lightPrimaryContainer = sky;
  static const Color lightOnPrimaryContainer = deepNavy;
  static const Color lightSecondary = periwinkle;
  static const Color lightBackground = Color(0xFFF5F8FF);
  static const Color lightSurface = Colors.white;
  static const Color lightOutline = sky;
  static const Color lightTextPrimary = deepNavy;
  static const Color lightTextSecondary = Color(0xFF4B5678);
  static const Color lightError = Color(0xFFC62828);

  // Dark Mode
  static const Color darkPrimary = periwinkle;
  static const Color darkOnPrimary = deepNavy;
  static const Color darkPrimaryContainer = royalBlue;
  static const Color darkOnPrimaryContainer = sky;
  static const Color darkSecondary = sky;
  static const Color darkBackground = deepNavy;
  static const Color darkSurface = Color(0xFF0F1E5A);
  static const Color darkOutline = royalBlue;
  static const Color darkTextPrimary = Color(0xFFF2F6FF);
  static const Color darkTextSecondary = sky;
  static const Color darkError = Color(0xFFFF8A80);

  // Semantic Status Colors - Light
  static const Color statusAvailableLight = Color(0xFF1E8E5A);
  static const Color statusReservedLight = Color(0xFFB7791F);
  static const Color statusOnTripLight = Color(0xFF182CC1);
  static const Color statusMaintenanceLight = Color(0xFF6B7280);

  // Semantic Status Colors - Dark
  static const Color statusAvailableDark = Color(0xFF4CC38A);
  static const Color statusReservedDark = Color(0xFFF2B84B);
  static const Color statusOnTripDark = Color(0xFF7692FF);
  static const Color statusMaintenanceDark = Color(0xFF9AA3B5);

  static Color getStatusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'available':
        return isDark ? statusAvailableDark : statusAvailableLight;
      case 'reserved':
        return isDark ? statusReservedDark : statusReservedLight;
      case 'on trip':
      case 'ontrip':
      case 'ongoing':
        return isDark ? statusOnTripDark : statusOnTripLight;
      case 'maintenance':
      case 'cancelled':
        return isDark ? statusMaintenanceDark : statusMaintenanceLight;
      case 'completed':
      case 'paid':
        return isDark ? statusAvailableDark : statusAvailableLight;
      case 'partial':
        return isDark ? statusReservedDark : statusReservedLight;
      case 'unpaid':
        return isDark ? darkError : lightError;
      default:
        return isDark ? darkTextSecondary : lightTextSecondary;
    }
  }
}
