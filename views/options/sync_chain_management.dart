import 'package:depass/models/sync_chain.dart';
import 'package:depass/services/sync_chain_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SyncChainManagementScreen extends StatefulWidget {
  const SyncChainManagementScreen({super.key});

  @override
  State<SyncChainManagementScreen> createState() => _SyncChainManagementScreenState();
}

class _SyncChainManagementScreenState extends State<SyncChainManagementScreen> {
  final SyncChainService _syncChainService = SyncChainService();
  late Stream<SyncChainStatus> _statusStream;
  late Stream<List<PeerConnection>> _peersStream;

  @override
  void initState() {
    super.initState();
    _statusStream = _syncChainService.statusStream;
    _peersStream = _syncChainService.peersStream;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Sync Chain Management'),
        trailing: _buildActionButton(),
      ),
      child: SafeArea(
        child: StreamBuilder<SyncChainStatus>(
          stream: _statusStream,
          builder: (context, statusSnapshot) {
            final currentSyncChain = _syncChainService.currentSyncChain;
            
            if (currentSyncChain == null) {
              return _buildNoSyncChainView();
            }
            
            return _buildSyncChainView(currentSyncChain, statusSnapshot.data);
          },
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final currentSyncChain = _syncChainService.currentSyncChain;
    
    if (currentSyncChain == null) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Icon(LucideIcons.plus),
        onPressed: _showCreateOrJoinDialog,
      );
    }
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Icon(LucideIcons.menu),
      onPressed: _showOptionsDialog,
    );
  }

  Widget _buildNoSyncChainView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.link,
              size: 80,
              color: CupertinoColors.systemGrey3,
            ),
            SizedBox(height: 24),
            Text(
              'No Sync Chain',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Create a new sync chain or join an existing one to sync your passwords across devices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    child: Text('Create New'),
                    onPressed: _createNewSyncChain,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CupertinoButton(
                    child: Text('Join Existing'),
                    onPressed: _joinExistingSyncChain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncChainView(SyncChain syncChain, SyncChainStatus? status) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildStatusCard(syncChain, status),
        SizedBox(height: 16),
        _buildSyncChainInfo(syncChain),
        SizedBox(height: 16),
        _buildPeersSection(),
        SizedBox(height: 16),
        _buildActionsSection(syncChain),
      ],
    );
  }

  Widget _buildStatusCard(SyncChain syncChain, SyncChainStatus? status) {
    final currentStatus = status ?? syncChain.status;
    final statusColor = _getStatusColor(currentStatus);
    final statusText = _getStatusText(currentStatus);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  syncChain.isOwner ? 'Sync Chain Owner' : 'Sync Chain Member',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          if (currentStatus == SyncChainStatus.connecting || 
              currentStatus == SyncChainStatus.creating)
            CupertinoActivityIndicator(),
        ],
      ),
    );
  }

  Widget _buildSyncChainInfo(SyncChain syncChain) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Chain Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow('Chain ID', syncChain.id),
          _buildInfoRow('Created', _formatDate(syncChain.createdAt)),
          _buildInfoRow('Role', syncChain.isOwner ? 'Owner' : 'Member'),
          if (syncChain.isOwner) ...[
            SizedBox(height: 12),
            _buildSeedPhraseSection(syncChain.seedPhrase),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: label == 'Chain ID' ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedPhraseSection(String seedPhrase) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Seed Phrase',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.copy, size: 16),
                  SizedBox(width: 4),
                  Text('Copy'),
                ],
              ),
              onPressed: () => _copySeedPhrase(seedPhrase),
            ),
          ],
        ),
        SizedBox(height: 8),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeersSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connected Devices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          StreamBuilder<List<PeerConnection>>(
            stream: _peersStream,
            builder: (context, snapshot) {
              final peers = snapshot.data ?? [];
              
              if (peers.isEmpty) {
                return Text(
                  'No other devices connected',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel,
                  ),
                );
              }
              
              return Column(
                children: peers.map((peer) => _buildPeerItem(peer)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeerItem(PeerConnection peer) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: peer.isConnected 
                ? CupertinoColors.systemGreen 
                : CupertinoColors.systemGrey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.deviceName,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Last seen: ${_formatTime(peer.lastSeen)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          if (peer.isPendingVerification)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('Approve', style: TextStyle(color: CupertinoColors.systemGreen)),
                  onPressed: () => _verifyPeer(peer.peerId, true),
                ),
                CupertinoButton(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('Reject', style: TextStyle(color: CupertinoColors.systemRed)),
                  onPressed: () => _verifyPeer(peer.peerId, false),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(SyncChain syncChain) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          _buildSyncActionButton('Sync Now', LucideIcons.refreshCw, _syncNow),
          _buildSyncActionButton('Disconnect', LucideIcons.link, _disconnect),
          _buildSyncActionButton(
            'Leave Permanently', 
            LucideIcons.logOut, 
            _leavePermanently,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncActionButton(
    String title, 
    IconData icon, 
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: CupertinoListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? CupertinoColors.systemRed : null,
          ),
        ),
        leading: Icon(
          icon,
          color: isDestructive ? CupertinoColors.systemRed : null,
        ),
        trailing: Icon(LucideIcons.chevronRight),
        onTap: onPressed,
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(SyncChainStatus status) {
    switch (status) {
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
        return 'Connection Error';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Action methods
  void _showCreateOrJoinDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Sync Chain'),
        message: Text('Choose an option'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _createNewSyncChain();
            },
            child: Text('Create New Sync Chain'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _joinExistingSyncChain();
            },
            child: Text('Join Existing Sync Chain'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ),
    );
  }

  void _showOptionsDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Sync Chain Options'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _syncNow();
            },
            child: Text('Sync Now'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _disconnect();
            },
            child: Text('Disconnect'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _leavePermanently();
            },
            child: Text('Leave Permanently'),
            isDestructiveAction: true,
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ),
    );
  }

  void _createNewSyncChain() async {
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
        setState(() {}); // Refresh UI
        _showSeedPhraseDialog(syncChain.seedPhrase);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Failed to create sync chain: ${e.toString()}');
      }
    }
  }

  void _joinExistingSyncChain() {
    final TextEditingController seedController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Join Sync Chain'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Text('Enter the 16-word seed phrase:'),
            SizedBox(height: 16),
            CupertinoTextField(
              controller: seedController,
              placeholder: 'Enter seed phrase...',
              maxLines: 3,
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
              await _joinSyncChain(seedPhrase);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _joinSyncChain(String seedPhrase) async {
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
        setState(() {}); // Refresh UI
        _showSuccessDialog('Successfully joined the sync chain!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Failed to join sync chain: ${e.toString()}');
      }
    }
  }

  void _syncNow() async {
    try {
      await _syncChainService.syncAllPasswords();
      _showSuccessDialog('Sync completed successfully!');
    } catch (e) {
      _showErrorDialog('Sync failed: ${e.toString()}');
    }
  }

  void _disconnect() async {
    await _syncChainService.disconnectFromSyncChain();
    setState(() {});
  }

  void _leavePermanently() {
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

  void _verifyPeer(String peerId, bool approve) async {
    await _syncChainService.verifyPeerConnection(peerId, approve);
  }

  void _copySeedPhrase(String seedPhrase) {
    Clipboard.setData(ClipboardData(text: seedPhrase));
    _showSuccessDialog('Seed phrase copied to clipboard');
  }

  void _showSeedPhraseDialog(String seedPhrase) {
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
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                seedPhrase,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Save this seed phrase securely. You\'ll need it to connect other devices.',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Copy'),
            onPressed: () {
              _copySeedPhrase(seedPhrase);
            },
          ),
          CupertinoDialogAction(
            child: Text('Done'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Error'),
        content: Text(message),
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