import 'package:depass/providers/password_provider.dart';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final DBService _databaseService = DBService.instance;
  int _selectedIndex = 0;
  late final TextEditingController _titleController = TextEditingController();
  List<TextEditingController> _emailControllers = [
    TextEditingController(),
  ];
  List<TextEditingController> _passwordControllers = [
    TextEditingController(),
  ];
  List<TextEditingController> _textControllers = [
    TextEditingController(),
  ];
  List<TextEditingController> _websiteControllers = [];
  bool _isLoading = false;
  
  // Validation error messages
  Map<String, String> _validationErrors = {};

  // Validation methods
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _isValidWebsite(String website) {
    // Allow domains with or without protocol
    final domainRegex = RegExp(r'^(?:https?:\/\/)?(?:www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\/[^\s]*)?$');
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
        vaultProvider.loadAllVaults();
      }
    });
  }
  
  Future<void> _createPass() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate all fields first
      if (!_validateAllFields()) {
        setState(() {
          _isLoading = false;
        });
        _showValidationDialog();
        return;
      }

      final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
      final vaults = vaultProvider.allVaults;
      
      if (vaults == null || vaults.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('No vaults available');
        return;
      }
      
      List<TextEditingController> controllers = [
        ..._emailControllers,
        ..._passwordControllers,
        ..._textControllers,
        ..._websiteControllers
    ];
      late List<Map<String, dynamic>> allNotes;
      if(controllers.isNotEmpty){
        allNotes = controllers.map((controller) => {
          'Description': controller.text.trim(),
          'Type': _emailControllers.contains(controller) ? 'email' :
                      _passwordControllers.contains(controller) ? 'password' :
                      _textControllers.contains(controller) ? 'text' : 'website',
        }).toList();
      } else {
        allNotes = [];
      }

      // Use direct database service and then refresh provider
      await _databaseService.createBulkNotes(
        notes: allNotes,
        title: _titleController.text.trim(),
        vaultId: vaults[_selectedIndex].VaultId
      );
      
      // Refresh provider data after successful creation
      final passwordProvider = context.read<PasswordProvider>();
      await passwordProvider.loadAllPasses();
      
      setState(() {
        _isLoading = false;
      });
    } catch(e){
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error while creating password: $e');
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

  Widget _buildFieldSection(String title, List<TextEditingController> controllers, bool canRemove) {
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
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        placeholder: title == 'Email' 
                          ? "example@domain.com"
                          : title == 'Website'
                            ? "example.com"
                            : "Your ${title.toLowerCase()}...",
                        decoration: BoxDecoration(
                          border: hasError 
                            ? Border.all(color: CupertinoColors.systemRed, width: 1)
                            : Border.all(color: DepassConstants.isDarkMode ? DepassConstants.darkFadedBackground : DepassConstants.lightFadedBackground),
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
    return PopScope(
      canPop: false,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          transitionBetweenRoutes: false,
          padding: EdgeInsetsDirectional.symmetric(vertical: 8.0, horizontal: 12.0),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(LucideIcons.x),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (context) => const App(),
                ),
              );
            },
          ),
          trailing: CupertinoButton(
            onPressed: () async {
              await _createPass();
              if (_validationErrors.isEmpty) {
                Navigator.of(context).pushReplacement(
                  CupertinoPageRoute(
                    builder: (context) => const App(),
                  ),
                );
              }
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
                        
                        // Ensure selected index is within bounds
                        if (_selectedIndex >= vaults.length) {
                          _selectedIndex = vaults.isNotEmpty ? 0 : 0;
                        }
                        
                        return CupertinoButton(
                          sizeStyle: CupertinoButtonSize.small,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: CupertinoColors.systemGrey4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 2,
                              children: [
                                Text(vaults.isNotEmpty ? vaults[_selectedIndex].VaultTitle : "No Vaults", style: DepassTextTheme.label), 
                                Icon(LucideIcons.chevronDown)
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
                                    scrollController: FixedExtentScrollController(initialItem: _selectedIndex),
                                    backgroundColor: DepassConstants.isDarkMode ? DepassConstants.darkBackground : DepassConstants.lightBackground,
                                    itemExtent: 42.0,
                                    onSelectedItemChanged: (int index) {
                                      setState(() {
                                        _selectedIndex = index;
                                      });
                                    },
                                    children: vaults.map((vault) => Center(
                                      child: Text(
                                        vault.VaultTitle,
                                        style: DepassTextTheme.boldLabel,
                                      ),
                                    )).toList()
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }
                    ),
                    
                    // Title field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        CupertinoTextField(
                          controller: _titleController,
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          placeholder: "Your title...",
                          decoration: BoxDecoration(
                            border: _validationErrors.containsKey('title') 
                              ? Border.all(color: CupertinoColors.systemRed, width: 1)
                              : Border.all(color: DepassConstants.isDarkMode ? DepassConstants.darkFadedBackground : DepassConstants.lightFadedBackground),
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
                          Text('Add', style: DepassTextTheme.button.copyWith(
                            fontSize: 16
                          ),),
                          SizedBox(width: 4),
                          Icon(LucideIcons.plus, color: DepassConstants.isDarkMode ? DepassConstants.darkButtonText : DepassConstants.lightButtonText,),
                        ],
                      ), 
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context, 
                          builder: (context) {
                            return CupertinoActionSheet(
                              title: Text('Add New Item', style: TextStyle(fontFamily: 'Inter'),),
                              actions: [
                                CupertinoActionSheetAction(
                                  child: Text('Text', style: DepassTextTheme.dropdown),
                                  onPressed: () {
                                    _addField('Text');
                                    Navigator.pop(context);
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: Text('Password', style: DepassTextTheme.dropdown),
                                  onPressed: () {
                                    _addField('Password');
                                    Navigator.pop(context);
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: Text('Email', style: DepassTextTheme.dropdown),
                                  onPressed: () {
                                    _addField('Email');
                                    Navigator.pop(context);
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: Text('Website', style: DepassTextTheme.dropdown),
                                  onPressed: () {
                                    _addField('Website');
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                
                                child: Text('Cancel', style: TextStyle(fontFamily: 'Inter'),),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          }
                        );
                      }
                    ),
                    SizedBox(
                      height: 32,
                    )
                  ],
                ),
              ),
        ),
      ),
    );
  }
}