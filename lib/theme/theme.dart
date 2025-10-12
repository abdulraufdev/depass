import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';

class DepassTheme {
  DepassTheme._();
  
  static CupertinoThemeData get lightTheme => CupertinoThemeData(
    scaffoldBackgroundColor: DepassConstants.lightBackground,
    primaryColor: DepassConstants.lightPrimary,
    barBackgroundColor: DepassConstants.lightBarBackground,
    textTheme: DepassTextTheme.regular,
    brightness: Brightness.light,
  );

  static CupertinoThemeData get darkTheme => CupertinoThemeData(
    scaffoldBackgroundColor: DepassConstants.darkBackground,
    primaryColor: DepassConstants.darkPrimary,
    barBackgroundColor: DepassConstants.darkBarBackground,
    textTheme: DepassTextTheme.regular,
    brightness: Brightness.dark,
  );

  // Get current theme based on the global state
  static CupertinoThemeData get currentTheme => darkTheme;
}