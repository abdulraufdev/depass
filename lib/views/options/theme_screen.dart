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
  void initState() {
    super.initState();
    // Initialize the selected theme based on current theme provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _selectedTheme = themeProvider.isDarkMode ? DepassThemeMode.dark : DepassThemeMode.light;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return CupertinoPageScaffold(
      backgroundColor: DepassConstants.isDarkMode ? DepassConstants.darkBackground : DepassConstants.lightBackground,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: DepassConstants.isDarkMode ? DepassConstants.darkBarBackground : DepassConstants.lightBarBackground,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: DepassTextTheme.heading1),
            SizedBox(
              width: double.infinity,
              child: CupertinoSegmentedControl<DepassThemeMode>(
                borderColor: DepassConstants.isDarkMode ?  DepassConstants.darkSeparator : DepassConstants.lightSeparator,
                selectedColor: DepassConstants.isDarkMode ? DepassConstants.darkPrimary : DepassConstants.lightPrimary,
                unselectedColor: DepassConstants.isDarkMode ? DepassConstants.darkFadedBackground : DepassConstants.lightFadedBackground,
              children: <DepassThemeMode, Widget>{
                DepassThemeMode.light: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Light'),
                ),
                DepassThemeMode.dark: Padding(
                  padding: EdgeInsets.all(12.0), 
                  child: Text('Dark'),
                ),
                DepassThemeMode.system: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('System'),
                ),
              },
              groupValue: _selectedTheme,
              onValueChanged: (DepassThemeMode value) {
                setState(() {
                  _selectedTheme = value;
                  if (value == DepassThemeMode.dark) {
                    themeProvider.setTheme(true);
                  } else if (value == DepassThemeMode.light) {
                    themeProvider.setTheme(false);
                  }
                  // For system mode, you might want to implement system theme detection
                });
              },
            ),
            )
          ],
        ),
      ),
      );
  }
}