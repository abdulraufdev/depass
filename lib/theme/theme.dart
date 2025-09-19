import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';

class DepassTheme {
  DepassTheme._();
  
  static CupertinoThemeData themeData = CupertinoThemeData(
    scaffoldBackgroundColor: DepassConstants.background,
    primaryColor: DepassConstants.primary,
    barBackgroundColor: DepassConstants.barBackground,
    textTheme: DepassTextTheme.regular,
    brightness: Brightness.light,

  );

  // Dark theme
  static CupertinoThemeData get darkTheme => const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: CupertinoColors.systemBlue,
    scaffoldBackgroundColor: CupertinoColors.black,
    barBackgroundColor: CupertinoColors.systemGrey6,
    textTheme: CupertinoTextThemeData(
      primaryColor: CupertinoColors.white,
    ),
  );
}