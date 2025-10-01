import 'package:depass/providers/password_provider.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

class BackupSyncScreen extends StatelessWidget {
  const BackupSyncScreen({super.key});

  void _exportToCSV(BuildContext context) async {
    try {
      final passwordProvider = Provider.of<PasswordProvider>(context, listen: false);
      final filePath = await passwordProvider.exportAllPasswordsToCSV();
      
      if (context.mounted) {
        final fileName = basename(filePath);
        showCupertinoDialog(context: context, builder: (context) {
          return CupertinoAlertDialog(
            title: Text('Export Successful'),
            content: Text('Passwords exported to $fileName'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(context: context, builder: (context) {
          return CupertinoAlertDialog(
            title: Text('Export Failed'),
            content: Text('Passwords could not be exported: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text('Backup & Sync'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            CupertinoListTile(
              title: Text('Export data to CSV'),
              leading: Icon(LucideIcons.fileSpreadsheet),
              padding: EdgeInsets.symmetric(vertical: 20),
              onTap: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    return CupertinoAlertDialog(
                      title: Text('Security warning!'),
                      content: Text('Storing unencrypted data may compromise your security. It is recommended to use Sync chain for backups. Do you want to proceed?'),
                      actions: [
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.of(context).pop();
                            _exportToCSV(context);
                          },
                          child: Text('Yes'),
                        ),
                        CupertinoDialogAction(
                          child: Text('No'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            SizedBox(
              height: 2,
              child: Container(
                color: DepassConstants.barBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}