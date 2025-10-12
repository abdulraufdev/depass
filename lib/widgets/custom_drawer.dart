import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/options/about_screen.dart';
import 'package:depass/views/options/backup_sync.dart';
import 'package:depass/views/options/generate_password.dart';
import 'package:depass/views/options/report_screen.dart';
import 'package:depass/views/options/restore_screen.dart';
import 'package:depass/views/options/security_screen.dart';
import 'package:depass/views/options/theme_screen.dart';
import 'package:depass/views/vault/vault_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomPopup extends StatelessWidget {
  const CustomPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 20, 0, 0),
            width: 250,
            height: double.infinity,
            color: DepassConstants.isDarkMode
                ? DepassConstants.darkBackground
                : DepassConstants.lightBackground,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Options', style: DepassTextTheme.heading1),
                    CupertinoButton(
                      child: Icon(LucideIcons.chevronsRight, size: 24),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CupertinoListTile(
                      title: Text('Generator'),
                      padding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.rectangleEllipsis),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                const GeneratePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    CupertinoListTile(
                      title: Text('Theme'),
                      padding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.sunDim),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const ThemeScreen(),
                          ),
                        );
                      },
                    ),
                    CupertinoListTile(
                      title: Text('Security'),
                      padding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.lock),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const SecurityScreen(),
                          ),
                        );
                      },
                    ),
                    CupertinoListTile(
                      title: Text('Manage vaults'),
                      padding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.package),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const VaultScreen(),
                          ),
                        );
                      },
                    ),
                    CupertinoListTile(
                      title: Text('Backup & Sync'),
                      padding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.refreshCcw),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const BackupSyncScreen(),
                          ),
                        );
                      },
                    ),
                    CupertinoListTile(
                      title: Text('Restore'),
                      padding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.hardDriveDownload),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const RestoreScreen(),
                          ),
                        );
                      },
                    ),
                    CupertinoListTile(
                      title: Text('About'),
                      padding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.info),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    ColoredBox(
                      color: DepassConstants.isDarkMode
                          ? DepassConstants.darkSeparator
                          : DepassConstants.lightSeparator,
                      child: SizedBox(height: 1, width: double.infinity),
                    ),
                    SizedBox(height: 20),
                    CupertinoListTile(
                      title: Text('Report a bug'),
                      padding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.bug),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const ReportScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
