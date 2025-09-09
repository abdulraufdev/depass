import 'package:depass/models/note.dart';
import 'package:depass/models/vault.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  DBService _databaseService = DBService.instance;
  int _selectedIndex = 0;
  late final List<Vault> _vaults;
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

  @override
  void initState() {
    super.initState();
    _loadVaults();
  }

  Future<void> _loadVaults() async {
    setState(() => _isLoading = true);

    try {
      final vaults = await _databaseService.getAllVaults();
      setState(() {
        _vaults = vaults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Failed to load vaults: $e');
    }
  }
  
  Future<void> _createPass() async {
    try{
      final int passId = await _databaseService.createPass(title: _titleController.text);
      List<TextEditingController> controllers = [
        ..._emailControllers,
        ..._passwordControllers,
        ..._textControllers,
        ..._websiteControllers
    ];
      late List<Map<String, dynamic>> allNotes;
      if(controllers.isNotEmpty){
        allNotes = controllers.map((controller) => {
          'Description': controller.text,
          'Type': _emailControllers.contains(controller) ? 'Email' :
                      _passwordControllers.contains(controller) ? 'Password' :
                      _textControllers.contains(controller) ? 'Text' : 'Website',
        }).toList();
      }

      await _databaseService.createBulkNotes(allNotes, passId);
    } catch(e){
      print("Error while inserting: $e");
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

  Widget _buildFieldSection(String title, List<TextEditingController> controllers, bool canRemove) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: controllers[index],
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    placeholder: "Your ${title.toLowerCase()}...",
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
            onPressed: () {
              _createPass();
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (context) => const App(),
                ),
              );
            },
            padding: EdgeInsets.zero,
            child: Text('Save'),
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
                    CupertinoButton(
                      sizeStyle: CupertinoButtonSize.small,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: CupertinoColors.systemGrey4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_vaults[_selectedIndex].VaultTitle), 
                            Icon(LucideIcons.chevronDown)
                          ],
                        ),
                      ),
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return SizedBox(
                              height: 200.0,
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(initialItem: _selectedIndex),
                                backgroundColor: DepassConstants.background,
                                itemExtent: 42.0,
                                onSelectedItemChanged: (int index) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                children: _vaults.map((vault) => Center(
                                  child: Text(
                                    vault.VaultTitle,
                                    style: TextStyle(
                                      color: DepassConstants.text,
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                                )).toList()
                              ),
                            );
                          },
                        );
                      },
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
                          Text('Add'),
                          SizedBox(width: 4),
                          Icon(LucideIcons.plus),
                        ],
                      ), 
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context, 
                          builder: (context) {
                            return CupertinoActionSheet(
                              title: Text('Add New Item'),
                              actions: [
                                CupertinoActionSheetAction(
                                  child: Text('Text'),
                                  onPressed: () {
                                    _addField('Text');
                                    Navigator.pop(context);
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: Text('Password'),
                                  onPressed: () {
                                    _addField('Password');
                                    Navigator.pop(context);
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: Text('Email'),
                                  onPressed: () {
                                    _addField('Email');
                                    Navigator.pop(context);
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: Text('Website'),
                                  onPressed: () {
                                    _addField('Website');
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                child: Text('Cancel'),
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