import 'package:depass/providers/theme_provider.dart';
import 'package:depass/providers/password_provider.dart';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/theme/theme.dart';
import 'package:depass/views/auth/auth_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => PasswordProvider()),
        ChangeNotifierProvider(create: (context) => VaultProvider()),
      ],
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
          localizationsDelegates: [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
        );
      },
    );
  }
}
