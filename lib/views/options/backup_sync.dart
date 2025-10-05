import 'package:depass/providers/password_provider.dart';
import 'package:depass/services/sync_chain_service.dart';
import 'package:depass/models/sync_chain.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  final SyncChainService _syncChainService = SyncChainService();

  @override
  void initState() {
    super.initState();
    _syncChainService.initialize();
  }

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

  void _navigateToSyncChain(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text('Sync Chain'),
          message: Text('Choose an option for sync chain management'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _createNewSyncChain(context);
              },
              child: Text('Create New Sync Chain'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _joinExistingSyncChain(context);
              },
              child: Text('Join Existing Sync Chain'),
            ),
            if (_syncChainService.currentSyncChain != null)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _viewCurrentSyncChain(context);
                },
                child: Text('View Current Sync Chain'),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        );
      },
    );
  }

  void _createNewSyncChain(BuildContext context) async {
    try {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Creating Sync Chain'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              CupertinoActivityIndicator(),
              SizedBox(height: 10),
              Text('Generating secure sync chain...'),
            ],
          ),
        ),
      );

      final syncChain = await _syncChainService.createSyncChain();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSeedPhraseDialog(syncChain.seedPhrase, context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error'),
            content: Text('Failed to create sync chain: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSeedPhraseDialog(String seedPhrase, BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Sync Chain Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your sync chain has been created successfully!'),
            SizedBox(height: 16),
            Text('Seed Phrase:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DepassConstants.isDarkMode ? DepassConstants.darkFadedBackground : DepassConstants.lightFadedBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                seedPhrase,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Save this seed phrase securely. You\'ll need it to connect other devices to this sync chain.',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('I\'ve Saved It'),
            onPressed: () {
              Navigator.pop(context);
              
              setState(() {}); // Refresh to show updated status
            },
          ),
        ],
      ),
    );
  }

  void _joinExistingSyncChain(BuildContext context) {
    final TextEditingController seedController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Join Sync Chain'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Text('Enter the 16-word seed phrase to join an existing sync chain:'),
            SizedBox(height: 16),
            CupertinoTextField(
              controller: seedController,
              placeholder: 'Enter seed phrase...',
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text('Join'),
            onPressed: () async {
              final seedPhrase = seedController.text.trim();
              if (seedPhrase.isEmpty) return;
              
              Navigator.pop(context);
              
              try {
                showCupertinoDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text('Joining Sync Chain'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 10),
                        CupertinoActivityIndicator(),
                        SizedBox(height: 10),
                        Text('Connecting to sync chain...'),
                      ],
                    ),
                  ),
                );

                await _syncChainService.joinSyncChain(seedPhrase);
                
                if (mounted) {
                  Navigator.pop(context); // Close loading dialog
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text('Success'),
                      content: Text('Successfully joined the sync chain! Waiting for verification from the owner.'),
                      actions: [
                        CupertinoDialogAction(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading dialog
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text('Error'),
                      content: Text('Failed to join sync chain: ${e.toString()}'),
                      actions: [
                        CupertinoDialogAction(
                          child: Text('OK'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _viewCurrentSyncChain(BuildContext context) {
    final syncChain = _syncChainService.currentSyncChain;
    if (syncChain == null) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Current Sync Chain'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_getStatusText(syncChain.status)}'),
            SizedBox(height: 8),
            Text('Role: ${syncChain.isOwner ? "Owner" : "Member"}'),
            SizedBox(height: 8),
            Text('Connected Peers: ${_syncChainService.connectedPeers.length}'),
            SizedBox(height: 8),
            Text('Created: ${_formatDate(syncChain.createdAt)}'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Disconnect'),
            onPressed: () async {
              Navigator.pop(context);
              await _syncChainService.disconnectFromSyncChain();
              setState(() {});
            },
          ),
          CupertinoDialogAction(
            child: Text('Leave Permanently'),
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              _confirmLeaveSyncChain(context);
            },
          ),
          CupertinoDialogAction(
            child: Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveSyncChain(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Leave Sync Chain'),
        content: Text('Are you sure you want to leave this sync chain permanently? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text('Leave'),
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _syncChainService.leaveSyncChain();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  String _getStatusText(SyncChainStatus status) {
    switch (status) {
      case SyncChainStatus.connected:
        return 'Connected';
      case SyncChainStatus.connecting:
        return 'Connecting...';
      case SyncChainStatus.waiting:
        return 'Waiting for peers';
      case SyncChainStatus.creating:
        return 'Creating...';
      case SyncChainStatus.disconnected:
        return 'Disconnected';
      case SyncChainStatus.error:
        return 'Error';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget syncChainSubtitle() {
    final syncChain = _syncChainService.currentSyncChain;
    if (syncChain == null) {
      return Text('Not connected to any sync chain');
    }
    
    switch (syncChain.status) {
      case SyncChainStatus.connected:
        return Text('Connected • ${_syncChainService.connectedPeers.length} peer(s)');
      case SyncChainStatus.connecting:
        return Text('Connecting...');
      case SyncChainStatus.waiting:
        return Text('Waiting for peers');
      case SyncChainStatus.creating:
        return Text('Creating sync chain...');
      case SyncChainStatus.disconnected:
        return Text('Disconnected');
      case SyncChainStatus.error:
        return Text('Connection error');
    }
  }

  Color _getSyncChainStatusColor() {
    final syncChain = _syncChainService.currentSyncChain;
    if (syncChain == null) {
      return CupertinoColors.systemGrey;
    }
    
    switch (syncChain.status) {
      case SyncChainStatus.connected:
        return CupertinoColors.systemGreen;
      case SyncChainStatus.connecting:
      case SyncChainStatus.creating:
        return CupertinoColors.systemBlue;
      case SyncChainStatus.waiting:
        return CupertinoColors.systemOrange;
      case SyncChainStatus.disconnected:
        return CupertinoColors.systemGrey;
      case SyncChainStatus.error:
        return CupertinoColors.systemRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backup & Sync', style: DepassTextTheme.heading1),
            SizedBox(height: 12,),
            CupertinoListTile(
              title: Text('Sync Chain'),
              subtitle: syncChainSubtitle(),
              leading: Icon(
                LucideIcons.link2,
                color: _getSyncChainStatusColor(),
              ),
              trailing: Icon(LucideIcons.chevronRight),
              padding: EdgeInsets.symmetric(vertical: 20),
              onTap: () => _navigateToSyncChain(context),
            ),
            SizedBox(
              height: 2,
              child: Container(
                color: DepassConstants.isDarkMode ? DepassConstants.darkBarBackground : DepassConstants.lightBarBackground,
              ),
            ),
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
                          child: Text('Export'),
                        ),
                        CupertinoDialogAction(
                          child: Text('Cancel'),
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
          ],
        ),
      ),
    );
  }
}