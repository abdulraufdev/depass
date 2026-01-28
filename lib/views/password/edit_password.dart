import 'dart:developer';

import 'package:depass/models/pass.dart';
import 'package:depass/providers/password_provider.dart';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key, required this.passwordId});

  final int passwordId;
  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final DBService _databaseService = DBService.instance;
  int _selectedIndex = 0;
  int _initialVault = 1;
  late final TextEditingController _titleController = TextEditingController();

  // Store provider reference to avoid read-only context issues
  PasswordProvider? _passwordProvider;
  VaultProvider? _vaultProvider;

  // Password data fetched from provider
  List<Map<String, dynamic>>? _passwordData;
  bool _vaultIndexInitialized = false;

  List<TextEditingController> _emailControllers = [TextEditingController()];
  List<TextEditingController> _passwordControllers = [TextEditingController()];
  List<TextEditingController> _textControllers = [TextEditingController()];

  List<TextEditingController> _websiteControllers = [];
  bool _isLoading = false;

  // Validation error messages
  Map<String, String> _validationErrors = {};

  // Validation methods
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool _isValidWebsite(String website) {
    // Allow domains with or without protocol
    final domainRegex = RegExp(
      r'^(?:https?:\/\/)?(?:www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\/[^\s]*)?$',
    );
    return domainRegex.hasMatch(website);
  }

  bool _validateAllFields() {
    _validationErrors.clear();
    bool isValid = true;

    // Validate title
    if (_titleController.text.trim().isEmpty) {
      _validationErrors['title'] = 'Title is required';
      isValid = false;
    }

    // Validate email fields
    for (int i = 0; i < _emailControllers.length; i++) {
      final email = _emailControllers[i].text.trim();
      if (email.isEmpty) {
        _validationErrors['email_$i'] = 'Email is required';
        isValid = false;
      } else if (!_isValidEmail(email)) {
        _validationErrors['email_$i'] = 'Invalid email format';
        isValid = false;
      }
    }

    // Validate password fields
    for (int i = 0; i < _passwordControllers.length; i++) {
      final password = _passwordControllers[i].text.trim();
      if (password.isEmpty) {
        _validationErrors['password_$i'] = 'Password is required';
        isValid = false;
      }
    }

    // Validate text fields
    for (int i = 0; i < _textControllers.length; i++) {
      final text = _textControllers[i].text.trim();
      if (text.isEmpty) {
        _validationErrors['text_$i'] = 'Text is required';
        isValid = false;
      }
    }

    // Validate website fields
    for (int i = 0; i < _websiteControllers.length; i++) {
      final website = _websiteControllers[i].text.trim();
      if (website.isEmpty) {
        _validationErrors['website_$i'] = 'Website is required';
        isValid = false;
      } else if (!_isValidWebsite(website)) {
        _validationErrors['website_$i'] = 'Invalid website format';
        isValid = false;
      }
    }

    return isValid;
  }

  List<TextEditingController> _addControllers(String type) {
    if (_passwordData == null) return [TextEditingController()];

    return List.generate(
      _passwordData!.where((item) => item['Type'] == type).length,
      (i) {
        return TextEditingController(
          text: _passwordData!
              .where((item) => item['Type'] == type)
              .toList()[i]['Description'],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vaultProvider = Provider.of<VaultProvider>(
          context,
          listen: false,
        );
        final passwordProvider = Provider.of<PasswordProvider>(
          context,
          listen: false,
        );

        // Load vaults
        vaultProvider.loadAllVaults();

        // Load password data
        _loadPasswordData(passwordProvider);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    for (var controller in _passwordControllers) {
      controller.dispose();
    }
    for (var controller in _textControllers) {
      controller.dispose();
    }
    for (var controller in _websiteControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPasswordData(PasswordProvider passwordProvider) async {
    await passwordProvider.loadPasswordData(widget.passwordId);
    final data = passwordProvider.getPasswordData(widget.passwordId);

    if (data != null && data.isNotEmpty && mounted) {
      final Pass pass = await _databaseService.getPassById(widget.passwordId);
      setState(() {
        _passwordData = data;
        log("Loaded password data: $_passwordData");
        // Initialize title controller with the password title
        _titleController.text = data[0]['PassTitle'] ?? '';
        // Initialize field controllers
        _emailControllers = _addControllers('email');
        _passwordControllers = _addControllers('password');
        _textControllers = _addControllers('text');
        _websiteControllers = _addControllers('website');
        _initialVault = pass.VaultId;
      });
      log("Initial vault ID: $_initialVault");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store provider reference when context is available
    _passwordProvider ??= context.read<PasswordProvider>();
    _vaultProvider ??= context.read<VaultProvider>();
  }

  void _save() async {
    if (!mounted) {
      print("not mounted!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate all fields first
      if (!_validateAllFields()) {
        log("Not vaild");
        setState(() {
          _isLoading = false;
        });
        _showValidationDialog();
        return;
      }

      // 1. Update PassTitle or VaultId if changed
      final currentTitle = _passwordData != null && _passwordData!.isNotEmpty
          ? _passwordData![0]['PassTitle'] as String? ?? ''
          : '';
      final newTitle = _titleController.text.trim();

      // Get the selected vault ID from the vaults list
      final vaults = _vaultProvider?.allVaults ?? [];
      final selectedVaultId =
          vaults.isNotEmpty &&
              _selectedIndex >= 0 &&
              _selectedIndex < vaults.length
          ? vaults[_selectedIndex].VaultId
          : _initialVault;
      log("Initial vault: $_initialVault");
      log("Selected vault: $selectedVaultId");
      if (_passwordData != null && _passwordData!.isNotEmpty) {
        final passId = _passwordData![0]['PassId'];
        // Update if title changed or vault changed
        if (currentTitle != newTitle || _initialVault != selectedVaultId) {
          await _databaseService.updatePass(
            passId,
            newTitle,
            selectedVaultId.toString(),
          );

          // Update provider after successful database update
          if (_passwordProvider != null) {
            _passwordProvider!.clearPasswordCache(passId);
            await _passwordProvider!.loadPasswordData(passId);
            await _passwordProvider!.loadAllPasses();
          }
        }
      }
      // 2. Update/Create notes for each type
      await _saveNotesOfType('email', _emailControllers);
      await _saveNotesOfType('password', _passwordControllers);
      await _saveNotesOfType('text', _textControllers);
      await _saveNotesOfType('website', _websiteControllers);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);
    } catch (e) {
      print("Error saving changes: $e");
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error saving changes: $e');
    }
  }

  void _showValidationDialog() {
    final errors = _validationErrors.values.take(3).join('\n');
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Validation Error'),
        content: Text(errors),
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

  Future<void> _saveNotesOfType(
    String type,
    List<TextEditingController> controllers,
  ) async {
    // Get existing notes of this type
    final existingNotes =
        _passwordData?.where((item) => item['Type'] == type).toList() ?? [];

    final passId = _passwordData != null && _passwordData!.isNotEmpty
        ? _passwordData![0]['PassId']
        : null;
    if (passId == null) return;

    // Process each controller
    for (int i = 0; i < controllers.length; i++) {
      final newDescription = controllers[i].text.trim();

      if (i < existingNotes.length) {
        // Update existing note if description changed
        final existingNote = existingNotes[i];
        final currentDescription = existingNote['Description'] as String? ?? '';

        if (currentDescription != newDescription) {
          final noteId = existingNote['NoteId'];
          await _databaseService.updateNote(noteId, newDescription, type);
        }
      } else {
        // Create new note if we have more controllers than existing notes
        if (newDescription.isNotEmpty) {
          await _databaseService.createNote(
            description: newDescription,
            type: type,
            passId: passId,
          );
        }
      }
    }

    // Refresh provider data after note updates
    if (_passwordProvider != null) {
      _passwordProvider!.clearPasswordCache(passId);
      await _passwordProvider!.loadPasswordData(passId);
    }
  }

  void _addField(String fieldType) {
    setState(() {
      switch (fieldType) {
        case 'Email':
          _emailControllers.add(TextEditingController());
          break;
        case 'Password':
          _passwordControllers.add(TextEditingController());
          break;
        case 'Text':
          _textControllers.add(TextEditingController());
          break;
        case 'Website':
          _websiteControllers.add(TextEditingController());
          break;
      }
    });
  }

  void _removeField(String fieldType, int index) {
    setState(() {
      switch (fieldType) {
        case 'Email':
          if (_emailControllers.length > 1) {
            _emailControllers.removeAt(index);
          }
          break;
        case 'Password':
          if (_passwordControllers.length > 1) {
            _passwordControllers.removeAt(index);
          }
          break;
        case 'Text':
          if (_textControllers.length > 1) {
            _textControllers.removeAt(index);
          }
          break;
        case 'Website':
          _websiteControllers.removeAt(index);
          break;
      }
    });
  }

  Widget _buildFieldSection(
    String title,
    List<TextEditingController> controllers,
    bool canRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ...List.generate(controllers.length, (index) {
          final fieldKey = '${title.toLowerCase()}_$index';
          final hasError = _validationErrors.containsKey(fieldKey);

          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: controllers[index],
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        placeholder: title == 'Email'
                            ? "example@domain.com"
                            : title == 'Website'
                            ? "example.com"
                            : "Your ${title.toLowerCase()}...",
                        decoration: BoxDecoration(
                          border: hasError
                              ? Border.all(
                                  color: CupertinoColors.systemRed,
                                  width: 1,
                                )
                              : Border.all(
                                  color: DepassConstants.isDarkMode
                                      ? DepassConstants.darkFadedBackground
                                      : DepassConstants.lightFadedBackground,
                                ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onChanged: (_) {
                          if (hasError) {
                            setState(() {
                              _validationErrors.remove(fieldKey);
                            });
                          }
                        },
                      ),
                    ),
                    if (canRemove && controllers.length > 1)
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        onPressed: () => _removeField(title, index),
                        child: Icon(LucideIcons.x, size: 18),
                      ),
                  ],
                ),
                if (hasError)
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 14),
                    child: Text(
                      _validationErrors[fieldKey]!,
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if password data is not loaded yet
    if (_passwordData == null) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          transitionBetweenRoutes: false,
          trailing: CupertinoActivityIndicator(),
        ),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        trailing: CupertinoButton(
          onPressed: () {
            _save();
          },
          padding: EdgeInsets.zero,
          child: _isLoading ? CupertinoActivityIndicator() : Text('Save'),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: _isLoading
            ? Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                child: Column(
                  spacing: 24,
                  children: [
                    Consumer<VaultProvider>(
                      builder: (context, vaultProvider, child) {
                        final vaults = vaultProvider.allVaults ?? [];

                        // Initialize vault index when vaults are loaded and not yet initialized
                        // if (vaults.isNotEmpty && !_vaultIndexInitialized && _passwordData != null && _passwordData!.isNotEmpty) {
                        //   setState(() {
                        //     _selectedIndex = vaults.indexWhere((vault) => vault.VaultId == _initialVault);
                        //     if (_selectedIndex == -1) {
                        //       _selectedIndex = 0; // Default to first vault if not found
                        //     }
                        //     _vaultIndexInitialized = true;
                        //   });
                        // }
                        if (!_vaultIndexInitialized) {
                          _selectedIndex = vaults.indexWhere(
                            (vault) => vault.VaultId == _initialVault,
                          ); // Reset to first vault if out of bounds
                          _vaultIndexInitialized = true;
                        }

                        // Ensure selected index is within bounds
                        if (vaults.isNotEmpty &&
                            (_selectedIndex < 0 ||
                                _selectedIndex >= vaults.length)) {
                          _selectedIndex = vaults.indexWhere(
                            (vault) => vault.VaultId == _initialVault,
                          ); // Reset to first vault if out of bounds
                        }

                        return CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: DepassConstants
                                  .profileColors[vaults[_selectedIndex]
                                      .VaultColor]!
                                  .withValues(alpha: 0.15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  spacing: 8,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color:
                                            DepassConstants
                                                .profileColors[vaults[_selectedIndex]
                                                .VaultColor] ??
                                            DepassConstants.deepTeal,
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          DepassConstants
                                                  .profileIcons[vaults[_selectedIndex]
                                                  .VaultIcon] ??
                                              LucideIcons.vault,
                                          color: CupertinoColors.white
                                              .withValues(alpha: 0.9),
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      vaults.isNotEmpty
                                          ? vaults[_selectedIndex].VaultTitle
                                          : "No Vaults",
                                      style: DepassTextTheme.dropdown,
                                    ),
                                  ],
                                ),
                                Icon(LucideIcons.chevronDown),
                              ],
                            ),
                          ),
                          onPressed: () {
                            if (vaults.isEmpty) return;

                            showCupertinoModalPopup(
                              context: context,
                              builder: (context) {
                                return SizedBox(
                                  height: 200.0,
                                  child: CupertinoPicker(
                                    scrollController:
                                        FixedExtentScrollController(
                                          initialItem: _selectedIndex,
                                        ),
                                    backgroundColor: DepassConstants.isDarkMode
                                        ? DepassConstants.darkBackground
                                        : DepassConstants.lightBackground,
                                    itemExtent: 42.0,
                                    onSelectedItemChanged: (int index) {
                                      setState(() {
                                        _selectedIndex = index;
                                      });
                                    },
                                    children: vaults
                                        .map(
                                          (vault) => Center(
                                            child: Text(
                                              vault.VaultTitle,
                                              style: DepassTextTheme.boldLabel,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),

                    // Title field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Title',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        CupertinoTextField(
                          controller: _titleController,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          placeholder: "Your title...",
                          decoration: BoxDecoration(
                            border: _validationErrors.containsKey('title')
                                ? Border.all(
                                    color: CupertinoColors.systemRed,
                                    width: 1,
                                  )
                                : Border.all(
                                    color: DepassConstants.isDarkMode
                                        ? DepassConstants.darkFadedBackground
                                        : DepassConstants.lightFadedBackground,
                                  ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (_) {
                            if (_validationErrors.containsKey('title')) {
                              setState(() {
                                _validationErrors.remove('title');
                              });
                            }
                          },
                        ),
                        if (_validationErrors.containsKey('title'))
                          Padding(
                            padding: EdgeInsets.only(top: 4, left: 14),
                            child: Text(
                              _validationErrors['title']!,
                              style: TextStyle(
                                color: CupertinoColors.systemRed,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Email fields
                    _buildFieldSection('Email', _emailControllers, true),

                    // Password fields
                    _buildFieldSection('Password', _passwordControllers, true),

                    // Text fields
                    _buildFieldSection('Text', _textControllers, true),

                    // Website fields (if any)
                    if (_websiteControllers.isNotEmpty) ...[
                      _buildFieldSection('Website', _websiteControllers, true),
                    ],

                    // Add button
                    CupertinoButton.filled(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Add',
                            style: DepassTextTheme.button.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            LucideIcons.plus,
                            color: DepassConstants.isDarkMode
                                ? DepassConstants.darkButtonText
                                : DepassConstants.lightButtonText,
                          ),
                        ],
                      ),
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return CupertinoActionSheet(
                              title: Text(
                                'Add New Item',
                                style: TextStyle(fontFamily: 'Inter'),
                              ),
                              actions: [
                                CupertinoActionSheetAction(
                                  child: Text(
                                    'Text',
                                    style: DepassTextTheme.dropdown,
                                  ),
                                  onPressed: () {
                                    _addField('Text');
                                    Navigator.pop(context);
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: Text(
                                    'Password',
                                    style: DepassTextTheme.dropdown,
                                  ),
                                  onPressed: () {
                                    _addField('Password');
                                    Navigator.pop(context);
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: Text(
                                    'Email',
                                    style: DepassTextTheme.dropdown,
                                  ),
                                  onPressed: () {
                                    _addField('Email');
                                    Navigator.pop(context);
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: Text(
                                    'Website',
                                    style: DepassTextTheme.dropdown,
                                  ),
                                  onPressed: () {
                                    _addField('Website');
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(fontFamily: 'Inter'),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}
