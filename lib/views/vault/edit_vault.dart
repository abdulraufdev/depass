import 'package:depass/theme/text_theme.dart';
import 'package:flutter/cupertino.dart';

class EditVaultScreen extends StatefulWidget {
  const EditVaultScreen({super.key, required this.id});

  final String id;

  @override
  State<EditVaultScreen> createState() => _EditVaultScreenState();
}

class _EditVaultScreenState extends State<EditVaultScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.id);
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
              child: Text('Save'),
              onPressed: () {
                // Save the edited vault
              },
            )
          ],
        ),
      )
    );
  }
}