import 'package:flutter/cupertino.dart';

class DepassConstants {
  DepassConstants._();

  // Global theme state
  static bool _isDarkMode = false;

  // Method to update theme state (called by ThemeProvider)
  static void updateTheme(bool isDark) {
    _isDarkMode = isDark;
  }

  // Light mode colors
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightFadedBackground = Color(0xFFF5F5F5);
  static const Color _lightSeparator = Color(0xFFE0E0E0);
  static const Color _lightPrimary = Color(0xFF111111);
  static const Color _lightBarBackground = Color(0xFFF5F5F5);
  static const Color _lightDropdownButton = Color(0xFFEDF6F4);
  static const Color _lightText = Color(0xFF111111);
  static const Color _lightToast = Color(0xFF333333);

  // Dark mode colors
  static const Color _darkBackground = Color(0xFF000000);
  static const Color _darkFadedBackground = Color(0xFF1C1C1E);
  static const Color _darkSeparator = Color(0xFF444444);
  static const Color _darkPrimary = Color(0xFFFFFFFF);
  static const Color _darkBarBackground = Color(0xFF1C1C1E);
  static const Color _darkDropdownButton = Color.fromARGB(255, 35, 52, 63);
  static const Color _darkText = Color(0xFFFFFFFF);
  static const Color _darkToast = Color(0xFFE5E5E7);

  // Simple getter methods
  static Color get background => _isDarkMode ? _darkBackground : _lightBackground;
  static Color get fadedBackground => _isDarkMode ? _darkFadedBackground : _lightFadedBackground;
  static Color get separator => _isDarkMode ? _darkSeparator : _lightSeparator;
  static Color get primary => _isDarkMode ? _darkPrimary : _lightPrimary;
  static Color get barBackground => _isDarkMode ? _darkBarBackground : _lightBarBackground;
  static Color get dropdownButton => _isDarkMode ? _darkDropdownButton : _lightDropdownButton;
  static Color get text => _isDarkMode ? _darkText : _lightText;
  static Color get buttonText => _isDarkMode ? _lightPrimary : _darkPrimary;
  static Color get toast => _isDarkMode ? _darkToast : _lightToast;

  static List noteTypes = ["email", "password", "text", "website"];
}

enum DepassThemeMode { light, dark, system }