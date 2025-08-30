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
}