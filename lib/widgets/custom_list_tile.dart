import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/password/password_screen.dart';
import 'package:flutter/cupertino.dart';

class CustomListTile extends StatelessWidget {
  const CustomListTile({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            backgroundColor: DepassConstants.fadedBackground,
            subtitle: Text(subtitle),
            title: Text(title, style: DepassTextTheme.paragraph),
            onTap: (){
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => PasswordScreen(id: title)),
              );
            },
          );
  }
}