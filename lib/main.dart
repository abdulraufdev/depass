import 'package:depass/providers/sync_chain_provider.dart';
import 'package:depass/providers/theme_provider.dart';
import 'package:depass/providers/password_provider.dart';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/services/notification_service.dart';
import 'package:depass/theme/theme.dart';
import 'package:depass/views/auth/auth_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service and request permission once at app launch
  await NotiService.instance.initNotification();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => PasswordProvider()),
        ChangeNotifierProvider(create: (context) => VaultProvider()),
        ChangeNotifierProxyProvider2<
          PasswordProvider,
          VaultProvider,
          SyncChainProvider
        >(
          create: (context) => SyncChainProvider(),
          update:
              (context, passwordProvider, vaultProvider, syncChainProvider) {
                syncChainProvider?.setPasswordProvider(passwordProvider);
                syncChainProvider?.setVaultProvider(vaultProvider);
                return syncChainProvider ?? SyncChainProvider();
              },
        ),
      ],
      child: const MainApp(),
    ),
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
