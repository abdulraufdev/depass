import 'package:depass/models/pass.dart';
import 'package:depass/models/vault.dart';
import 'package:depass/providers/password_provider.dart';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/vault/edit_vault.dart';
import 'package:depass/widgets/custom_list_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'password_screen.dart';

class PasswordsScreen extends StatefulWidget {
  const PasswordsScreen({super.key, required this.vault});

  final Vault vault;

  @override
  State<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends State<PasswordsScreen> {
  DBService db = DBService.instance;
  List<Pass> passes = [];

  @override
  void initState() {
    super.initState();
    _getPasses();
  }

  Future<void> _getPasses() async {
    final allPasses = await db.getPassesByVaultId(widget.vault.VaultId);
    setState(() {
      passes = allPasses;
    });
  }

  Future<void> _deleteVault() async {
    final vaultId = widget.vault.VaultId;

    setState(() {
      // _isDeleting = true;
    });

    try {
      // Delete from database
      final bool deleted = await db.deleteVault(vaultId);
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
                child: Text('Ok'),
                onPressed: () => Navigator.pop(context),
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
          Navigator.of(context).pop();
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

  String _getEmailFromData(List<Map<String, dynamic>>? data) {
    if (data == null || data.isEmpty) return '';
    for (var item in data) {
      if (item['Type'] == 'email') {
        return item['Description'] ?? '';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        trailing: passes.isEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showDeleteConfirmation,
                child: Icon(LucideIcons.trash2),
              )
            : SizedBox.shrink(),
      ),
      child: Consumer<PasswordProvider>(
        builder: (context, passwordProvider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                spacing: 24,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        spacing: 12,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  DepassConstants.profileColors[widget
                                      .vault
                                      .VaultColor] ??
                                  DepassConstants.slateGray,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              DepassConstants.profileIcons[widget
                                      .vault
                                      .VaultIcon] ??
                                  LucideIcons.lock,
                              color: CupertinoColors.white,
                              size: 20,
                            ),
                          ),
                          Text(
                            widget.vault.VaultTitle,
                            style: DepassTextTheme.heading1,
                          ),
                        ],
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(LucideIcons.pen),
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => EditVaultScreen(
                                id: widget.vault.VaultId.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  if (passes.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No passwords in this vault yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: CupertinoColors.systemGrey),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: DepassConstants.isDarkMode
                            ? DepassConstants.darkSeparator
                            : DepassConstants.lightSeparator,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        spacing: 2,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(passes.length, (index) {
                          final pass = passes[index];
                          final data = passwordProvider.getPasswordData(
                            pass.PassId,
                          );
                          final email = _getEmailFromData(data);

                          // Load data if not cached
                          if (data == null &&
                              !passwordProvider.isLoadingPassword(
                                pass.PassId,
                              )) {
                            passwordProvider.loadPasswordData(pass.PassId);
                          }

                          return CustomListTile(
                            title: pass.PassTitle,
                            subtitle: email,
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => PasswordScreen(
                                    id: pass.PassId.toString(),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
