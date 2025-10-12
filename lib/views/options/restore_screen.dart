import 'dart:developer';

import 'package:depass/providers/password_provider.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class RestoreScreen extends StatefulWidget {
  const RestoreScreen({super.key});

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {

  void _importData() async {
    // Implement your import logic here
    showCupertinoDialog(context: context, builder: (context){
      return CupertinoAlertDialog(
        title: Text('Import data'),
        content: Text('This will erase all existing data and import from CSV. Proceed?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Proceed'),
            onPressed: () async {
              Navigator.of(context).pop();
                    final passwordProvider = Provider.of<PasswordProvider>(context, listen: false);
                    await passwordProvider.importFromCSVFile();
                    log('Imported passwords from CSV');
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
      ),
      child:  Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restore', style: DepassTextTheme.heading1),
            SizedBox(height: 12,),
            CupertinoListTile(
              title: Text('Import data from CSV'),
              leading: Icon(LucideIcons.import),
              padding: EdgeInsets.symmetric(vertical: 20),
              onTap: () {
                _importData();
              },
            ),
          ],
        ),
      ),
    );
  }
}