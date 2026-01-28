import 'package:depass/models/sync_chain.dart';
import 'package:depass/providers/password_provider.dart';
import 'package:depass/providers/sync_chain_provider.dart';
import 'package:depass/services/notification_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/sync_chain/sync_chain_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  void _exportToCSV(BuildContext context) async {
    try {
      final passwordProvider = Provider.of<PasswordProvider>(
        context,
        listen: false,
      );
      final filePath = await passwordProvider.exportAllPasswordsToCSV();

      if (context.mounted) {
        NotiService.instance.showNotification(
          id: 2,
          title: 'Export Successful',
          body: 'Passwords exported to CSV file!',
        );
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text('Export Successful'),
              content: Text('Passwords exported to CSV file.'),
              actions: [
                CupertinoDialogAction(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) {
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
          },
        );
      }
    }
  }

  void _exportToJSON(BuildContext context) async {
    try {
      final passwordProvider = Provider.of<PasswordProvider>(
        context,
        listen: false,
      );
      await passwordProvider.exportToJSON();

      if (context.mounted) {
        NotiService.instance.showNotification(
          id: 4,
          title: 'Export Successful',
          body: 'Passwords exported to JSON file!',
        );
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text('Export Successful'),
              content: Text('Passwords exported to JSON file.'),
              actions: [
                CupertinoDialogAction(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) {
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
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(transitionBetweenRoutes: false),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backup & Sync', style: DepassTextTheme.heading1),
            SizedBox(height: 12),
            // Sync Chain - Decentralized P2P Sync
            Consumer<SyncChainProvider>(
              builder: (context, syncChainProvider, child) {
                final isActive = syncChainProvider.isChainActive;
                final status = syncChainProvider.status;

                String subtitle = 'Decentralized peer-to-peer sync';
                Color statusColor = CupertinoColors.systemGrey;

                if (isActive) {
                  switch (status) {
                    case SyncChainStatus.connected:
                      subtitle =
                          'Connected (${syncChainProvider.connectedDevices.length} devices)';
                      statusColor = CupertinoColors.systemGreen;
                      break;
                    case SyncChainStatus.discovering:
                    case SyncChainStatus.connecting:
                      subtitle = 'Connecting...';
                      statusColor = CupertinoColors.systemOrange;
                      break;
                    case SyncChainStatus.syncing:
                      subtitle = 'Syncing...';
                      statusColor = CupertinoColors.systemOrange;
                      break;
                    case SyncChainStatus.disconnected:
                      subtitle = 'Chain active - Tap to start';
                      statusColor = CupertinoColors.systemBlue;
                      break;
                    case SyncChainStatus.error:
                      subtitle = 'Error - Tap to retry';
                      statusColor = CupertinoColors.systemRed;
                      break;
                  }
                }

                return CupertinoListTile(
                  title: Text('Sync Chain'),
                  subtitle: Text(
                    subtitle,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                  leading: Stack(
                    children: [
                      Icon(LucideIcons.link),
                      if (isActive && status == SyncChainStatus.connected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: DepassConstants.isDarkMode
                                    ? CupertinoColors.black
                                    : CupertinoColors.white,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Icon(LucideIcons.chevronRight),
                  padding: EdgeInsetsGeometry.symmetric(vertical: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => SyncChainScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(
              height: 2,
              child: Container(
                color: DepassConstants.isDarkMode
                    ? DepassConstants.darkBarBackground
                    : DepassConstants.lightBarBackground,
              ),
            ),
            CupertinoListTile(
              title: Text('Export data to CSV'),
              leading: Icon(LucideIcons.fileSpreadsheet),
              padding: EdgeInsets.symmetric(vertical: 20),
              onTap: () {
                final parentContext = context;
                showCupertinoDialog(
                  context: context,
                  builder: (dialogContext) {
                    return CupertinoAlertDialog(
                      title: Text('Security warning!'),
                      content: Text(
                        'Storing unencrypted data may compromise your security. It is recommended to use Sync chain for backups. Do you want to proceed?',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _exportToCSV(parentContext);
                          },
                          child: Text('Export'),
                        ),
                        CupertinoDialogAction(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            CupertinoListTile(
              title: Text('Export data to JSON'),
              leading: Icon(LucideIcons.fileJson),
              padding: EdgeInsets.symmetric(vertical: 20),
              onTap: () {
                final parentContext = context;
                showCupertinoDialog(
                  context: context,
                  builder: (dialogContext) {
                    return CupertinoAlertDialog(
                      title: Text('Security warning!'),
                      content: Text(
                        'Storing unencrypted data may compromise your security. It is recommended to use Sync chain for backups. Do you want to proceed?',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _exportToJSON(parentContext);
                          },
                          child: Text('Export'),
                        ),
                        CupertinoDialogAction(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
