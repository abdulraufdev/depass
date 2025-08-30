import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';

class DepassTextTheme {
  DepassTextTheme._();

  static CupertinoTextThemeData regular = CupertinoTextThemeData(
    textStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: DepassConstants.text,
      // fontFamily: 'Inter',
    ),
  );

  static const heading1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const paragraph = TextStyle(fontSize: 16);
  static const caption = TextStyle(fontSize: 12, color: DepassConstants.text);

}