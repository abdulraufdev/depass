import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';

class DepassTextTheme {
  DepassTextTheme._();

  static CupertinoTextThemeData regular = CupertinoTextThemeData(
    textStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: DepassConstants.text,
      // fontFamily: 'Inter',
    ),
  );

  static const heading1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter');
  static const heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter');
  static const subtitle1 = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter');
  static const paragraph = TextStyle(fontSize: 16, fontFamily: 'Inter');

  static const caption = TextStyle(fontSize: 12, color: DepassConstants.text, fontFamily: 'Inter');
  static const button = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter');
  static const label = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Inter');
  static const dropdown = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter');
  static const boldLabel = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter');
}