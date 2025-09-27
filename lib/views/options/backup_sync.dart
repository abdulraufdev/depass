import 'package:flutter/cupertino.dart';

class BackupSyncScreen extends StatelessWidget {
  const BackupSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text('Backup & Sync'),
      ),
      child: Center(
        child: Text('Backup & Sync Screen'),
      ),
    );
  }
}