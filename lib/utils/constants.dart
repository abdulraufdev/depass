import 'package:flutter/cupertino.dart';

class DepassConstants {
  DepassConstants._();

  // Global theme state
  static bool _isDarkMode = false;

  static bool get isDarkMode => _isDarkMode;

  // Method to update theme state (called by ThemeProvider)
  static void updateTheme(bool isDark) {
    _isDarkMode = isDark;
  }

  // Light mode colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightFadedBackground = Color(0xFFF5F5F5);
  static const Color lightSeparator = Color(0xFFE0E0E0);
  static const Color lightPrimary = Color(0xFF111111);
  static const Color lightBarBackground = Color(0xFFF5F5F5);
  static const Color lightDropdownButton = Color(0xFFEDF6F4);
  static const Color lightText = Color(0xFF111111);
  static const Color lightToast = Color(0xFF333333);
  static const Color lightButtonText = Color(0xFFFFFFFF);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkFadedBackground = Color(0xFF1C1C1E);
  static const Color darkSeparator = Color(0xFF444444);
  static const Color darkPrimary = Color(0xFFFFFFFF);
  static const Color darkBarBackground = Color(0xFF1C1C1E);
  static const Color darkDropdownButton = Color.fromARGB(255, 35, 52, 63);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkToast = Color(0xFFE5E5E7);
  static const Color darkButtonText = Color(0xFF000000);

  static List noteTypes = ["email", "password", "text", "website"];
}

enum DepassThemeMode { light, dark, system }