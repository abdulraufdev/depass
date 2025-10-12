import 'package:depass/models/vault.dart';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class EditVaultScreen extends StatefulWidget {
  const EditVaultScreen({super.key, required this.id});

  final String id;

  @override
  State<EditVaultScreen> createState() => _EditVaultScreenState();
}

class _EditVaultScreenState extends State<EditVaultScreen> {
  final DBService _databaseService = DBService.instance;
  late final Vault _vault;
  TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVaultData();
  }

  Future<void> _loadVaultData() async {
    setState(() => _isLoading = true);

    try {
      final vault = await _databaseService.getVaultById(int.parse(widget.id));
      setState(() {
        _vault = vault!;
        _controller = TextEditingController(text: _vault.VaultTitle);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Failed to load vaults: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use VaultProvider to update the title (this will refresh all vault UI automatically)
      final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
      await vaultProvider.updateVaultTitle(
        int.parse(widget.id),
        _controller.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error updating vault: $e");
    }
  }

  Future<void> _deleteVault() async {
    final vaultId = int.parse(widget.id);

    setState(() {
      // _isDeleting = true;
    });

    try {
      // Delete from database
      final bool deleted = await _databaseService.deleteVault(vaultId);
      if (!deleted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text("Can't delete vault"),
            content: Text(
              'You need to remove all the passwords from this vault in order to delete it.',
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text('Delete'),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteVault();
                },
              ),
            ],
          ),
        );
      } else {
        // Update provider
        final vaultProvider = context.read<VaultProvider>();
        vaultProvider.clearAllCaches();
        await vaultProvider.loadAllVaults();

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        //_isDeleting = false;
      });
      // _showErrorDialog('Error deleting password: $e');
    }
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete Vault'),
        content: Text(
          'Are you sure you want to delete this vault? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              _deleteVault();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showDeleteConfirmation,
          child: Icon(LucideIcons.trash2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Text('Edit Vault', style: DepassTextTheme.heading1),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
                CupertinoTextField(
                  controller: _controller,
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  placeholder: "Your title...",
                ),
              ],
            ),
            CupertinoButton.filled(
              minimumSize: Size(double.infinity, 44),
              borderRadius: BorderRadius.circular(8),
              child: _isLoading ? CupertinoActivityIndicator() : Text('Save', style: TextStyle(color: DepassConstants.isDarkMode ? DepassConstants.darkButtonText : DepassConstants.lightButtonText),),
              onPressed: () {
                // Save the edited vault
                _saveChanges();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
