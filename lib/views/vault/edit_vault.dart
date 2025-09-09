import 'package:depass/models/vault.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:flutter/cupertino.dart';

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
  
  Future<void> _loadVaultData() async{
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

  Future<void> _saveChanges()async {
    setState(() {
      _isLoading =true;
    });
    try{
      await _databaseService.updateVault(int.parse(widget.id), _controller.text);
      setState(() {
        _isLoading = false;
      });
    } catch(e){
      setState(() {
        _isLoading= false;
      });
      print("Error updating vault: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(),
      child: Padding(
        padding:  const EdgeInsets.all(12.0),
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
                  child: _isLoading ? CupertinoActivityIndicator() : Text('Save'),
                  onPressed: () {
                    // Save the edited vault
                    _saveChanges();
                    Navigator.pop(context);
                  },
                )
              ],
            ),
        ),
      );
  }
}