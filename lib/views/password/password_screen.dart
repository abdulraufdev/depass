import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key, required this.id});

  final String id;

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: (){
              Navigator.pop(context);
            },
            child: Icon(
              LucideIcons.chevronLeft,
              size: 22, // Icon visual size
          ),
        ),
        previousPageTitle: 'Back',
        middle: Text('Password ${widget.id}'),
      ),
      child: Center(child: Text('Password Screen')),
    );
  }
}
