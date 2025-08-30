import 'package:depass/theme/theme.dart';
import 'package:depass/views/app.dart';
import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: DepassTheme.themeData,
      home: App(),
    );
  }
}
