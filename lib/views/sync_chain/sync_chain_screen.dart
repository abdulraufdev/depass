import 'package:depass/models/sync_chain.dart';
import 'package:depass/providers/sync_chain_provider.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class SyncChainScreen extends StatefulWidget {
  const SyncChainScreen({super.key});

  @override
  State<SyncChainScreen> createState() => _SyncChainScreenState();
}

class _SyncChainScreenState extends State<SyncChainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SyncChainProvider>(context, listen: false);
      if (!provider.isInitialized) {
        provider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Sync Chain'),
        transitionBetweenRoutes: false,
        trailing: Consumer<SyncChainProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && !provider.isInitialized) {
              return CupertinoActivityIndicator(radius: 5);
            }
            if (!provider.isInitialized || !provider.isChainActive) {
              return SizedBox.shrink();
            }
            return CupertinoButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _showLeaveConfirmation(context, provider),
              child: Icon(LucideIcons.logOut, color: CupertinoColors.systemRed),
            );
          },
        ),
      ),
      child: Consumer<SyncChainProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.isInitialized) {
            return Center(child: CupertinoActivityIndicator());
          }

          if (provider.isChainActive) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DepassConstants.isDarkMode
                          ? const Color.fromARGB(255, 6, 18, 29)
                          : Colors.blue[50]!,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DepassConstants.isDarkMode
                            ? DepassConstants.darkDropdownButton
                            : Colors.blue[200]!,
                      ),
                    ),
                    child: Column(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.link,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Decentralized Sync',
                              style: DepassTextTheme.heading2.copyWith(
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Sync Chain lets you securely sync passwords across multiple devices without any server or account. All devices share the same data using peer-to-peer connection via Bluetooth/WiFi Direct.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status section
                  SizedBox(height: 24),
                  Center(child: _buildStatusSection(context, provider)),
                  SizedBox(height: 24),
                  _buildSeedPhraseSection(context, provider),
                  SizedBox(height: 24),
                  _buildConnectedDevicesSection(context, provider),
                  SizedBox(height: 24),
                  _buildControlsSection(context, provider),

                  // Error message
                  if (provider.errorMessage != null) ...[
                    SizedBox(height: 16),
                    _buildErrorMessage(context, provider.errorMessage!),
                  ],
                ],
              ),
            );
          } else {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: _buildSetupContent(context, provider),
                  ),
                ),
                // Error message
                if (provider.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _buildErrorMessage(context, provider.errorMessage!),
                  ),
                _buildSetupButtons(context, provider),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, SyncChainProvider provider) {
    Color statusColor;
    IconData statusIcon;

    switch (provider.status) {
      case SyncChainStatus.connected:
        statusColor = CupertinoColors.systemGreen;
        statusIcon = LucideIcons.wifi;
        break;
      case SyncChainStatus.discovering:
      case SyncChainStatus.connecting:
      case SyncChainStatus.syncing:
        statusColor = CupertinoColors.systemOrange;
        statusIcon = LucideIcons.loader;
        break;
      case SyncChainStatus.error:
        statusColor = CupertinoColors.systemRed;
        statusIcon = LucideIcons.circleAlert;
        break;
      default:
        statusColor = CupertinoColors.systemGrey;
        statusIcon = LucideIcons.wifiOff;
    }
    return Column(
      spacing: 8,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DepassConstants.isDarkMode
                ? DepassConstants.darkFadedBackground
                : DepassConstants.lightFadedBackground,
            borderRadius: BorderRadius.circular(40),
          ),
          child: (provider.isLoading)
              ? CupertinoActivityIndicator()
              : Icon(statusIcon, color: statusColor, size: 28),
        ),
        Text(
          provider.getStatusText(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSeedPhraseSection(
    BuildContext context,
    SyncChainProvider provider,
  ) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 12,
      children: [
        CupertinoButton.tinted(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Icon(LucideIcons.copy, size: 20),
                Text('Recovery Phrase', style: DepassTextTheme.label),
              ],
            ),
          ),
          onPressed: () {
            if (provider.seedPhrase != null) {
              Clipboard.setData(ClipboardData(text: provider.seedPhrase!));
            }
          },
        ),
        if (provider.status == SyncChainStatus.disconnected)
          CupertinoButton.filled(
            padding: EdgeInsets.zero,
            onPressed: provider.isLoading
                ? null
                : () => provider.startSyncChain(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Icon(
                    LucideIcons.play,
                    size: 20,
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkButtonText
                        : DepassConstants.lightButtonText,
                  ),
                  Text('Start Sync Chain', style: DepassTextTheme.button),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectedDevicesSection(
    BuildContext context,
    SyncChainProvider provider,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DepassConstants.isDarkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.smartphone, size: 20),
              SizedBox(width: 8),
              Text('Connected Devices', style: DepassTextTheme.heading3),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.connectedDevices.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (provider.connectedDevices.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DepassConstants.isDarkMode
                    ? CupertinoColors.black
                    : CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Devices will show up here',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
            )
          else
            ...provider.connectedDevices.map(
              (device) => _buildDeviceItem(device),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(SyncChainDevice device) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DepassConstants.isDarkMode
            ? CupertinoColors.black
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.smartphone,
              color: CupertinoColors.systemGreen,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Connected ${_formatTime(device.connectedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Widget _buildControlsSection(
    BuildContext context,
    SyncChainProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (provider.status == SyncChainStatus.disconnected)
          SizedBox(height: 8)
        else
          CupertinoButton.filled(
            onPressed: provider.isLoading
                ? null
                : () => provider.stopSyncChain(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.pause,
                  size: 20,
                  color: DepassConstants.isDarkMode
                      ? DepassConstants.darkButtonText
                      : DepassConstants.lightButtonText,
                ),
                SizedBox(width: 8),
                Text('Stop Sync Chain', style: DepassTextTheme.button),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSetupContent(BuildContext context, SyncChainProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Text('Get Started with Sync Chain', style: DepassTextTheme.heading1),
        Text(
          'Sync your passwords securely across multiple devices using peer-to-peer connection.',
          style: DepassTextTheme.bodyMedium,
        ),
        Row(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DepassConstants.isDarkMode
                    ? DepassConstants.darkFadedBackground
                    : DepassConstants.lightFadedBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.shield, size: 40),
            ),
            Flexible(
              child: Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('End-to-End Encrypted', style: DepassTextTheme.heading3),
                  Text(
                    'Your passwords are encrypted before sync. Only devices with the recovery phrase can decrypt them.',
                    style: DepassTextTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DepassConstants.isDarkMode
                    ? DepassConstants.darkFadedBackground
                    : DepassConstants.lightFadedBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.cloudOff, size: 40),
            ),
            Flexible(
              child: Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Servers', style: DepassTextTheme.heading3),
                  Text(
                    'Direct device-to-device connection. Your data stays with you and your devices only.',
                    style: DepassTextTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DepassConstants.isDarkMode
                    ? DepassConstants.darkFadedBackground
                    : DepassConstants.lightFadedBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.users, size: 40),
            ),
            Flexible(
              child: Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Multiple Devices', style: DepassTextTheme.heading3),
                  Text(
                    'Sync multiple devices using Bluetooth/WiFi Direct for seamless password management.',
                    style: DepassTextTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSetupButtons(BuildContext context, SyncChainProvider provider) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CupertinoButton.filled(
              child: Text('Create Sync Chain', style: DepassTextTheme.button),
              onPressed: () => _showCreateDialog(context, provider),
            ),
            CupertinoButton(
              child: Text('Join Sync Chain'),
              onPressed: () => _showJoinDialog(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.circleAlert,
            color: CupertinoColors.systemRed,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: CupertinoColors.systemRed, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, SyncChainProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Create Sync Chain'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'This will generate a unique 8-word recovery phrase. Share this phrase with other devices to connect them to your sync chain.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final chain = await provider.createSyncChain();
              if (chain != null && context.mounted) {
                _showSeedPhraseDialog(context, chain.seedPhrase);
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSeedPhraseDialog(BuildContext context, String seedPhrase) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.key, color: CupertinoColors.systemBlue),
            SizedBox(width: 8),
            Text('Recovery Phrase'),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Text(
                'Save this phrase securely. You\'ll need it to connect other devices.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  seedPhrase,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: seedPhrase));
              Navigator.pop(context);
            },
            child: Text('Copy & Close'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, SyncChainProvider provider) {
    final controller = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (builder) {
        return CupertinoAlertDialog(
          title: Text('Data Replacement Warning'),
          content: Padding(
            padding: EdgeInsets.only(top: 12),
            child: Column(
              spacing: 12,
              children: [
                Text(
                  'Joining a sync chain will completely replace all the existing passwords and vaults from this device with those from the sync chain. Your current data will be permanently lost and will not be recovered.',
                ),
                Text(
                  'Do you want to proceed?',
                  style: TextStyle(color: CupertinoColors.systemRed),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) => SizedBox(
                    height: 300,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DepassConstants.isDarkMode
                            ? DepassConstants.darkBackground
                            : DepassConstants.lightBackground,
                      ),
                      child: Column(
                        children: [
                          Text('Join Sync Chain'),
                          Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Enter the 8-word recovery phrase from another device in your sync chain.',
                                  style: TextStyle(fontSize: 13),
                                ),
                                SizedBox(height: 16),
                                CupertinoTextField(
                                  controller: controller,
                                  placeholder: 'Enter seed phrase...',
                                  maxLines: 2,
                                  style: TextStyle(fontSize: 14),
                                  textInputAction: TextInputAction.done,
                                ),
                                SizedBox(height: 24),
                                CupertinoButton.filled(
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    final phrase = controller.text.trim();
                                    if (!provider.validateSeedPhrase(phrase)) {
                                      _showToast(
                                        context,
                                        'Invalid seed phrase. Must be 8 words.',
                                      );
                                      return;
                                    }
                                    Navigator.pop(context);
                                    final success = await provider
                                        .joinSyncChain(phrase);
                                    if (success && context.mounted) {
                                      _showToast(
                                        context,
                                        'Successfully joined sync chain!',
                                      );
                                    }
                                  },
                                  child: Text(
                                    'Join',
                                    style: DepassTextTheme.button,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Text('Replace My Data'),
            ),
          ],
        );
      },
    );
  }

  void _showLeaveConfirmation(
    BuildContext context,
    SyncChainProvider provider,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Leave Sync Chain?'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Your passwords will remain on this device, but you\'ll stop syncing with other devices. You\'ll need the recovery phrase to rejoin.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await provider.leaveSyncChain();
              if (context.mounted) {
                _showToast(context, 'Left sync chain');
              }
            },
            child: Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        Future.delayed(Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(bottom: 100),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              message,
              style: TextStyle(color: CupertinoColors.white),
            ),
          ),
        );
      },
    );
  }
}
