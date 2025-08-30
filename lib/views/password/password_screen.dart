import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/password/edit_password.dart';
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
        middle: Text('Password ${widget.id}'),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          spacing: 32,
          children: [
            SizedBox(
              height: 40,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Title ${widget.id}", style: DepassTextTheme.heading1),
                CupertinoButton(child: Icon(LucideIcons.pen,), onPressed: (){
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => EditPasswordScreen()
                    )
                  );
                },),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: DepassConstants.separator,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                spacing: 2,
                children: [
                  CupertinoListTile(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            backgroundColor: DepassConstants.fadedBackground,
                    title: Text("email@email.com"),
                    trailing: Icon(LucideIcons.copy),
                  ),
                  CupertinoListTile(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            backgroundColor: DepassConstants.fadedBackground,
                    title: Text("***************"),
                    trailing: Icon(LucideIcons.copy),
                  ),
                  CupertinoListTile(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            backgroundColor: DepassConstants.fadedBackground,
                    title: Text("foijfor8n4s"),
                    trailing: Icon(LucideIcons.copy),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
