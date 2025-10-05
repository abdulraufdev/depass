import 'dart:developer';

import 'package:depass/providers/password_provider.dart';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/password/edit_password.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key, required this.id});

  final String id;

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final DBService _databaseService = DBService.instance;
  bool _isDeleting = false;
  bool _isExporting = false;
  @override
  void initState() {
    super.initState();
    // Load password data when screen initializes

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PasswordProvider>();
      final passId = int.parse(widget.id);

      // Load data if not already cached
      if (provider.getPasswordData(passId) == null) {
        provider.loadPasswordData(passId);
      }
    });
  }

  Widget _customTitle(Map<String, dynamic> note) {
    final type = note['Type'] as String?;
    final description = note['Description'] as String? ?? '';

    return type == "password"
        ? Text("***********")
        : Text(description.isEmpty ? 'No content' : description);
  }

  Future<void> _deletePassword() async {
    final passId = int.parse(widget.id);

    setState(() {
      _isDeleting = true;
    });

    try {
      // Delete from database
      await _databaseService.deletePass(passId);

      // Update provider
      final passwordProvider = context.read<PasswordProvider>();
      passwordProvider.clearPasswordCache(passId);
      await passwordProvider.loadAllPasses();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      _showErrorDialog('Error deleting password: $e');
    }
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete Password'),
        content: Text(
          'Are you sure you want to delete this password? This action cannot be undone.',
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
              _deletePassword();
            },
          ),
        ],
      ),
    );
  }

  void _movePassword() async {
    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
    final allVaults = vaultProvider.allVaults ?? [];
    final password = await _databaseService.getPassById(int.parse(widget.id));

    if (allVaults.isEmpty) {
      _showErrorDialog("No vaults available. Please create a vault first.");
      return;
    }

    if (allVaults.length <= 1) {
      _showErrorDialog("No other vaults available to move to.");
      return;
    }

    // Find current vault index
    int _selectedIndex = 0;
    final currentVaultId = password.VaultId;
    _selectedIndex = allVaults.indexWhere(
      (vault) => vault.VaultId == currentVaultId,
    );
    if (_selectedIndex == -1) _selectedIndex = 0;

    // Store the selected index in a variable that can be updated
    int tempSelectedIndex = _selectedIndex;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: Text('Move password'),
          content: SizedBox(
            height: 200,
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: _selectedIndex,
              ),
              backgroundColor: DepassConstants.isDarkMode ? DepassConstants.darkBackground : DepassConstants.lightBackground,
              itemExtent: 42.0,
              onSelectedItemChanged: (int index) {
                tempSelectedIndex = index;
              },
              children: allVaults
                  .map(
                    (vault) => Center(
                      child: Text(
                        vault.VaultTitle,
                        style: TextStyle(
                          color: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: Text('Confirm'),
              onPressed: () async {
                Navigator.pop(context);

                // Check if the selected vault is different from current vault
                final currentVaultId = password.VaultId;
                final newVaultId = allVaults[tempSelectedIndex].VaultId;

                if (currentVaultId == newVaultId) {
                  // Show message that password is already in this vault
                  log("Password is already in this vault");
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text('Info'),
                      content: Text('Password is already in this vault.'),
                      actions: [
                        CupertinoDialogAction(
                          child: Text('OK'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                try {
                  // Move the password to the new vault
                  final passwordProvider = context.read<PasswordProvider>();
                  await passwordProvider.movePassword(
                    int.parse(widget.id),
                    newVaultId,
                  );

                  // Show success message
                  if (mounted) {
                    log("Moved");
                    showCupertinoDialog(
                      builder: (context) => CupertinoAlertDialog(
                        title: Text('Success'),
                        content: Text('Password moved successfully.'),
                        actions: [
                          CupertinoDialogAction(
                            child: Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      context: context,
                    );
                  }
                } catch (e) {
                  // Show error message
                  if (mounted) {
                    _showErrorDialog('Error moving password: $e');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportToJSON() {
    final passId = int.parse(widget.id);
    setState(() {
      _isExporting = true;
    });

    try {
      final passwordProvider = context.read<PasswordProvider>();
      passwordProvider
          .exportPasswordToFile(passId)
          .then((filePath) {
            log("Exported to $filePath");
            setState(() {
              _isExporting = false;
            });
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: Text('Export Successful'),
                content: Text('Password exported to $filePath'),
                actions: [
                  CupertinoDialogAction(
                    child: Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          })
          .catchError((e) {
            setState(() {
              _isExporting = false;
            });
            _showErrorDialog('Error exporting password: $e');
          });
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      _showErrorDialog('Error exporting password: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    final passId = int.parse(widget.id);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text('Password', style: TextStyle(fontFamily: 'Inter'),),
        trailing: _isDeleting
            ? CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  showCupertinoSheet(
                    context: context,
                    builder: (context) {
                      return CupertinoPageScaffold(
                        backgroundColor: DepassConstants.isDarkMode ? DepassConstants.darkFadedBackground : DepassConstants.lightFadedBackground,
                        navigationBar: CupertinoNavigationBar(
                          middle: Text('Options'),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 1,
                              child: Container(
                                color: DepassConstants.isDarkMode ? DepassConstants.darkSeparator : DepassConstants.lightSeparator,
                              ),
                            ),
                            CupertinoButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _movePassword();
                              },
                              child: Row(
                                spacing: 8,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.cornerUpRight),
                                  Text('Move to another vault'),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 2,
                              child: Container(
                                color: DepassConstants.isDarkMode ? DepassConstants.darkSeparator : DepassConstants.lightSeparator,
                              ),
                            ),
                            CupertinoButton(
                              onPressed: _isExporting
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _exportToJSON();
                                    },
                              child: _isExporting
                                  ? CupertinoActivityIndicator()
                                  : Row(
                                      spacing: 8,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(LucideIcons.braces),
                                        Text('Export to JSON'),
                                      ],
                                    ),
                            ),
                            SizedBox(
                              height: 2,
                              child: Container(
                                color: DepassConstants.isDarkMode ? DepassConstants.darkSeparator : DepassConstants.lightSeparator,
                              ),
                            ),
                            CupertinoButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeleteConfirmation();
                              },
                              child: Row(
                                spacing: 8,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.trash2, color: Colors.red),
                                  Text(
                                    'Delete Password',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Icon(LucideIcons.ellipsis),
              ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Consumer<PasswordProvider>(
            builder: (context, passwordProvider, child) {
              final isLoading = passwordProvider.isLoadingPassword(passId);
              final data = passwordProvider.getPasswordData(passId);

              if (isLoading) {
                return Center(child: CupertinoActivityIndicator());
              }

              if (data == null || data.isEmpty) {
                return Center(child: Text('No data found'));
              }

              final passTitle = data.isNotEmpty
                  ? data[0]['PassTitle'] as String? ?? 'Untitled'
                  : 'Untitled';

              return Column(
                spacing: 32,
                children: [
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          passTitle,
                          style: DepassTextTheme.heading1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CupertinoButton(
                        child: Icon(LucideIcons.pen),
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) =>
                                  EditPasswordScreen(passwordId: passId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Column(
                    spacing: 24,
                    children: List.generate(4, (index) {
                      final notesOfType = data
                          .where(
                            (note) =>
                                note['Type'] ==
                                DepassConstants.noteTypes[index],
                          )
                          .toList();

                      return notesOfType.isNotEmpty
                          ? Column(
                              spacing: 12,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DepassConstants.noteTypes[index]),
                                Container(
                                  decoration: BoxDecoration(
                                    color: DepassConstants.isDarkMode ? DepassConstants.darkSeparator : DepassConstants.lightSeparator,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    children: List.generate(
                                      notesOfType.length,
                                      (index2) {
                                        final note = notesOfType[index2];
                                        return CupertinoListTile(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          backgroundColor:
                                              DepassConstants.isDarkMode ? DepassConstants.darkFadedBackground : DepassConstants.lightFadedBackground,
                                          title: _customTitle(note),
                                          trailing: CupertinoButton(
                                            child: Icon(LucideIcons.copy),
                                            onPressed: () {
                                              final description =
                                                  note['Description']
                                                      as String? ??
                                                  '';
                                              if (description.isNotEmpty) {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: description,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : SizedBox.shrink();
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
