import 'package:depass/providers/theme_provider.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  DepassThemeMode _selectedTheme = DepassThemeMode.system;
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(transitionBetweenRoutes: false),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: DepassTextTheme.heading1),
            CupertinoSegmentedControl<DepassThemeMode>(
              children: const <DepassThemeMode, Widget>{
                DepassThemeMode.light: Text('Light'),
                DepassThemeMode.dark: Text('Dark'),
                DepassThemeMode.system: Text('System'),
              },
              groupValue: _selectedTheme,
              onValueChanged: (DepassThemeMode value) {
                setState(() {
                  _selectedTheme = value;
                  themeProvider.setTheme(value == DepassThemeMode.dark);
                });
              },
            ),
          ],
        ),
      ),
      );
  }
}