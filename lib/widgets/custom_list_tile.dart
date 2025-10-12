import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';

class CustomListTile extends StatelessWidget {
  const CustomListTile({super.key, required this.title, this.subtitle, this.onTap});

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            backgroundColor: DepassConstants.isDarkMode ? DepassConstants.darkFadedBackground : DepassConstants.lightFadedBackground,
            subtitle: subtitle != null ? Text(subtitle!) : null,
            title: Text(title, style: DepassTextTheme.paragraph),
            onTap: onTap ?? (){
              print('clicked');
            },
          );
  }
}