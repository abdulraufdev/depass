import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';

class DepassTheme {
  DepassTheme._();
  
  static CupertinoThemeData get lightTheme => CupertinoThemeData(
    scaffoldBackgroundColor: DepassConstants.background,
    primaryColor: DepassConstants.primary,
    barBackgroundColor: DepassConstants.barBackground,
    textTheme: DepassTextTheme.regular,
    brightness: Brightness.light,
  );

  static CupertinoThemeData get darkTheme => CupertinoThemeData(
    scaffoldBackgroundColor: DepassConstants.background,
    primaryColor: DepassConstants.primary,
    barBackgroundColor: DepassConstants.barBackground,
    textTheme: DepassTextTheme.regular,
    brightness: Brightness.dark,
  );

  // Get current theme based on the global state
  static CupertinoThemeData get currentTheme => darkTheme; // Always return darkTheme as it will have the right colors based on the global state
}