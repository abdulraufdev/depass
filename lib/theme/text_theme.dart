import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';

class DepassTextTheme {
  DepassTextTheme._();

  static CupertinoTextThemeData get regular {
    return CupertinoTextThemeData(
      textStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
      ),
    );
  }

  static TextStyle get heading1 => TextStyle(
    fontSize: 24, 
    fontWeight: FontWeight.bold, 
    fontFamily: 'Inter',
    color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
  );

  static TextStyle get heading2 => TextStyle(
    fontSize: 20, 
    fontWeight: FontWeight.bold, 
    fontFamily: 'Inter',
    color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
  );

  static TextStyle get subtitle1 => TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.bold, 
    fontFamily: 'Inter',
    color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
  );

  static TextStyle get paragraph => TextStyle(
    fontSize: 16, 
    fontFamily: 'Inter',
    color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
  );

  static TextStyle get caption => TextStyle(
    fontSize: 12, 
    color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
    fontFamily: 'Inter',
  );

  static TextStyle get button => TextStyle(
    fontSize: 14, 
    fontWeight: FontWeight.bold, 
    fontFamily: 'Inter',
    color: DepassConstants.isDarkMode ? DepassConstants.darkButtonText : DepassConstants.lightButtonText,
  );

  static TextStyle get label => TextStyle(
    fontSize: 16, 
    fontWeight: FontWeight.w500, 
    fontFamily: 'Inter',
    color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
  );

  static TextStyle get dropdown => TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.bold, 
    fontFamily: 'Inter',
    color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
  );

  static TextStyle get boldLabel => TextStyle(
    fontSize: 16, 
    fontWeight: FontWeight.bold, 
    fontFamily: 'Inter',
    color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
  );
}