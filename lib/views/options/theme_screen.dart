import 'package:depass/providers/theme_provider.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          spacing: 24,
          children: [
            Text('Theme', style: DepassTextTheme.heading1),
            RadioGroup<DepassThemeMode>(
      groupValue: _character,
      onChanged: (DepassThemeMode? value) {
        setState(() {
          _character = value;
          themeProvider.setTheme(true);
        });
      },
      child: CupertinoListSection(
        children: const <Widget>[
          CupertinoListTile(
            title: Text('Light Theme'),
            leading: CupertinoRadio<SingingCharacter>(value: DepassThemeMode.light),
          ),
          CupertinoListTile(
            title: Text('Dark Theme'),
            leading: CupertinoRadio<SingingCharacter>(value: DepassThemeMode.dark),
          ),
          CupertinoListTile(
            title: Text('System Default'),
            leading: CupertinoRadio<SingingCharacter>(value: DepassThemeMode.system),
          ),
        ],
      ),
    ),
          ]
        )
      )
      );
  }
}