import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  // Card and border colors
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color darkCardBackground = Color(0xFF1C1C1E);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color darkBorder = Color(0xFF444444);

  static const Color slateGray = Color(0xFF475569);
  static const Color deepTeal = Color(0xFF0F766E);
  static const Color burntOrange = Color(0xFFD9730B);
  static const Color dustyRose = Color(0xFFE03D3E);
  static const Color deepBrown = Color(0xFF64473A);
  static const Color indigoPlum = Color(0xFF693FA5);
  static const Color charcoalBlue = Color(0xFF0C6E99);
  static const Color warmYellow = Color(0xFFDFAB00);

  static List noteTypes = ["email", "password", "text", "website"];

  static const Map<String, IconData> profileIcons = {
    'vault': LucideIcons.vault,
    // Security & Access
    'lock': LucideIcons.lock,
    'key': LucideIcons.key,
    'key-round': LucideIcons.keyRound,
    'shield': LucideIcons.shield,
    'shield-check': LucideIcons.shieldCheck,
    'fingerprint': LucideIcons.fingerprint,
    'scan-face': LucideIcons.scanFace,

    // Storage & Organization
    'folder': LucideIcons.folder,
    'folder-lock': LucideIcons.folderLock,
    'archive': LucideIcons.archive,
    'box': LucideIcons.box,
    'package': LucideIcons.package,
    'database': LucideIcons.database,
    'hard-drive': LucideIcons.hardDrive,
    'server': LucideIcons.server,

    // Finance & Payment
    'wallet': LucideIcons.wallet,
    'credit-card': LucideIcons.creditCard,
    'banknote': LucideIcons.banknote,
    'piggy-bank': LucideIcons.piggyBank,
    'landmark': LucideIcons.landmark,

    // Work & Personal
    'briefcase': LucideIcons.briefcase,
    'building': LucideIcons.building,
    'home': LucideIcons.house,
    'heart': LucideIcons.heart,
    'user': LucideIcons.user,
    'users': LucideIcons.users,
    'contact': LucideIcons.contact,

    // Web & Social
    'globe': LucideIcons.globe,
    'at-sign': LucideIcons.atSign,
    'mail': LucideIcons.mail,
    'message-circle': LucideIcons.messageCircle,
    'share-2': LucideIcons.share2,

    // Entertainment & Media
    'gamepad': LucideIcons.gamepad2,
    'music': LucideIcons.music,
    'film': LucideIcons.film,
    'tv': LucideIcons.tv,
    'camera': LucideIcons.camera,

    // Utilities
    'star': LucideIcons.star,
    'bookmark': LucideIcons.bookmark,
    'settings': LucideIcons.settings,
    'smartphone': LucideIcons.smartphone,
    'laptop': LucideIcons.laptop,
    'cloud': LucideIcons.cloud,
    'wifi': LucideIcons.wifi,
  };

  static const Map<String, Color> profileColors = {
    'slateGray': slateGray,
    'deepTeal': deepTeal,
    'burntOrange': burntOrange,
    'dustyRose': dustyRose,
    'deepBrown': deepBrown,
    'indigoPlum': indigoPlum,
    'charcoalBlue': charcoalBlue,
    'warmYellow': warmYellow,
  };
}

enum DepassThemeMode { light, dark, system }
