import 'package:depass/utils/constants.dart';
import 'package:depass/views/options/about_screen.dart';
import 'package:depass/views/options/backup_sync.dart';
import 'package:depass/views/options/generate_password.dart';
import 'package:depass/views/options/report_screen.dart';
import 'package:depass/views/options/restore_screen.dart';
import 'package:depass/views/options/security_screen.dart';
import 'package:depass/views/options/theme_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomPopup extends StatelessWidget {
  const CustomPopup({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        leading: Text('Depass', style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(LucideIcons.chevronsLeft),
          onPressed: () {
            onMenu!();
          },
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        height: double.infinity,
        color: DepassConstants.isDarkMode
            ? DepassConstants.darkBackground
            : DepassConstants.lightBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoListTile(
              title: Text(
                'Generator',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              padding: EdgeInsets.zero,
              leading: Icon(LucideIcons.rectangleEllipsis),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const GeneratePasswordScreen(),
                  ),
                );
              },
            ),
            CupertinoListTile(
              title: Text(
                'Theme',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              padding: EdgeInsets.zero,
              leading: Icon(LucideIcons.sunDim),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(builder: (context) => const ThemeScreen()),
                );
              },
            ),
            CupertinoListTile(
              title: Text(
                'Security',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
              title: Text(
                'Backup & Sync',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
              title: Text(
                'Restore',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
              title: Text(
                'About',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              padding: EdgeInsets.zero,
              leading: Icon(LucideIcons.info),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(builder: (context) => const AboutScreen()),
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
              title: Text(
                'Report a bug',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
      ),
    );
  }
}
