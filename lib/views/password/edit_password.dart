import 'package:depass/models/note.dart';
import 'package:depass/models/vault.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key, required this.password});

  final List<Map<String,dynamic>> password;
  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final DBService _databaseService = DBService.instance;
  int _selectedIndex = 0;
  late final List<Vault> _vaults;
  late final TextEditingController _titleController = TextEditingController(text: widget.password[0]['PassTitle']);

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

  List<TextEditingController> _addControllers(String type){
    return List.generate(widget.password.where(
            (item) => item['Type'] == type
    ).length, (i){
      return TextEditingController(text: widget.password.where(
              (item) => item['Type'] == type
      ).toList()[i]['Description']);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadVaults();
    _emailControllers = _addControllers('email');
    _passwordControllers = _addControllers('password');
    _textControllers = _addControllers('text');
    _websiteControllers = _addControllers('website');
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

  void _save() {
    setState(() {
      _isLoading = true;
    });
    try {
      // Prepare data to save
      Map<String,List<TextEditingController>> updatedFields = {
        'email': _emailControllers,
        'password': _passwordControllers,
        'text': _textControllers,
        'website': _websiteControllers,
      };
      
      List<Note> passwordNotes = widget.password.where(
          (item) => item['Type'] == 'password'
      ).toList().map((item) => Note(
          NoteId: item['NoteId'], Description: item['Description'], Type: 'password', CreatedAt: item['CreatedAt'], UpdatedAt: item['UpdatedAt'], PassId: item['PassId'])
      ).toList();

      List<Note> emailNotes = widget.password.where(
          (item) => item['Type'] == 'email'
      ).toList().map((item) => Note(
          NoteId: item['NoteId'], Description: item['Description'], Type: 'email', CreatedAt: item['CreatedAt'], UpdatedAt: item['UpdatedAt'], PassId: item['PassId'])
      ).toList();

      List<Note> textNotes = widget.password.where(
          (item) => item['Type'] == 'text'
      ).toList().map((item) => Note(
          NoteId: item['NoteId'], Description: item['Description'], Type: 'text', CreatedAt: item['CreatedAt'], UpdatedAt: item['UpdatedAt'], PassId: item['PassId'])
      ).toList();

      List<Note> websiteNotes = widget.password.where(
          (item) => item['Type'] == 'website'
      ).toList().map((item) => Note(
          NoteId: item['NoteId'], Description: item['Description'], Type: 'website', CreatedAt: item['CreatedAt'], UpdatedAt: item['UpdatedAt'], PassId: item['PassId'])
      ).toList();

      // Call the database service to update the password entry
      Future<void> saveChanges(List<Note> notes, String type) async {
        try{
          for(int i=0; i < updatedFields[type]!.length; i++){
            if( i >= notes.length){
              await _databaseService.createNote(description: updatedFields[type]![i].text, type: type , passId: widget.password[0]['PassId']);
            } else if(notes[i].Description == updatedFields[type]![i].text){
              print('no change');
            } else {
              await _databaseService.updateNote(notes[i].NoteId, updatedFields[type]![i].text, type);
            }
          }
        } catch(e){
          print("Error updating $type notes: $e");
        }
      }

      saveChanges(passwordNotes, 'password');
      saveChanges(emailNotes, 'email');
      saveChanges(textNotes, 'text');
      saveChanges(websiteNotes, 'website');

      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context); // Go back after saving
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error updating password entry: $e");
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        trailing: CupertinoButton(onPressed: () {
              _save();
        },
        padding: EdgeInsets.zero,
          child: Text('Save'),),
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
    );
  }
}
