import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        trailing: CupertinoButton(onPressed: () {},
        padding: EdgeInsets.zero,
          child: Text('Save'),),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
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
                  children: [Text('Vault'), Icon(LucideIcons.chevronDown)],
                ),
              ),
              onPressed: () {},
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
                CupertinoTextField(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  placeholder: "Your title...",
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold)),
                CupertinoTextField(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  placeholder: "Your email address...",
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                CupertinoTextField(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  placeholder: "Your password...",
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 0,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Text', style: TextStyle(fontWeight: FontWeight.bold)),
                    CupertinoButton(padding: EdgeInsets.zero, onPressed: () {},
                    child: Icon(LucideIcons.x), )
                  ],
                ),
                CupertinoTextField(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  placeholder: "Your text...",
                ),
              ],
            ),
            CupertinoButton.filled(child: 
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                Text('Add'),
                Icon(LucideIcons.plus),
              ],
            ), onPressed: (){
              showCupertinoModalPopup(context: context, builder: (context) {
                return CupertinoActionSheet(
                  title: Text('Add New Item'),
                  actions: [
                    CupertinoActionSheetAction(
                      child: Text('Text'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoActionSheetAction(
                      child: Text('Password'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoActionSheetAction(
                      child: Text('Email Address'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoActionSheetAction(
                      child: Text('Website'),
                      onPressed: () {
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
              });
            })
          ],
        ),
      ),
    );
  }
}
