import 'package:depass/theme/theme.dart';
import 'package:depass/views/auth/auth_screen.dart';
import 'package:flutter/cupertino.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MainApp(),
    )
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return CupertinoApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.isDarkMode 
              ? DepassTheme.darkTheme 
              : DepassTheme.lightTheme,
          title: 'Depass',
          home: AuthScreen(),
        );
      },
    );
  }
}
