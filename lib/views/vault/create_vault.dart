import 'package:depass/services/database_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/app.dart';
import 'package:flutter/cupertino.dart';

class CreateVaultScreen extends StatefulWidget {
  const CreateVaultScreen({super.key});

  @override
  State<CreateVaultScreen> createState() => _CreateVaultScreenState();
}

class _CreateVaultScreenState extends State<CreateVaultScreen> {
  DBService db = DBService.instance;
  late final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _createVault() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await db.createVault(_controller.text);
    } catch (e) {
      print('Error: $e :)');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            Text('Create Vault', style: DepassTextTheme.heading1),
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
              child: (_isLoading ?
              CupertinoActivityIndicator(color: DepassConstants.background,) : Text('Save')),
              onPressed: () {
                // Save the edited vault
                _createVault();
                Navigator.of(context).pushReplacement(CupertinoPageRoute(
                  builder: (context) => App(),
                ));
              },
            )
          ],
        ),
      )
    );
  }
}