import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            width: 300,
            height: double.infinity,
            color: DepassConstants.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Options', style: DepassTextTheme.heading1,),
                    CupertinoButton(child: 
                    Icon(LucideIcons.chevronsRight), onPressed: (){
                      Navigator.of(context).pop();
                    })
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CupertinoListTile(title: Text('Generator'),
                    leading: Icon(LucideIcons.rectangleEllipsis), onTap: (){
                      Navigator.of(context).pop();
                    }),
                    CupertinoListTile(title: Text('Theme'),
                    leading: Icon(LucideIcons.sunDim), onTap: (){
                      Navigator.of(context).pop();
                    }),
                    CupertinoListTile(title: Text('Security'),
                    leading: Icon(LucideIcons.rectangleEllipsis), onTap: (){
                      Navigator.of(context).pop();
                    }),
                    CupertinoListTile(title: Text('Manage'),
                    leading: Icon(LucideIcons.package), onTap: (){
                      Navigator.of(context).pop();
                    }),
                    CupertinoListTile(title: Text('Backup'),
                    leading: Icon(LucideIcons.rectangleEllipsis), onTap: (){
                      Navigator.of(context).pop();
                    }),
                    CupertinoListTile(title: Text('Restore'),
                    leading: Icon(LucideIcons.rectangleEllipsis), onTap: (){
                      Navigator.of(context).pop();
                    }),
                    CupertinoListTile(title: Text('About'),
                    leading: Icon(LucideIcons.info), onTap: (){
                      Navigator.of(context).pop();
                    }),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}