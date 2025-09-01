import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GeneratePasswordScreen extends StatefulWidget {
  const GeneratePasswordScreen({super.key});

  @override
  State<GeneratePasswordScreen> createState() => _GeneratePasswordScreenState();
}

class _GeneratePasswordScreenState extends State<GeneratePasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          spacing: 24,
          children: [
            Text('Generate a secure password', style: DepassTextTheme.heading1),
            Container(
              decoration: BoxDecoration(
                color: DepassConstants.fadedBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.only(left: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('jfnjdfjnvfajr'),
                  CupertinoButton(
                    child: Icon(LucideIcons.copy),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlider(
                    divisions: 4,
                    value: 16,
                    min: 0,
                    max: 48,
                    onChanged: (value) {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('8', style: DepassTextTheme.caption),
                      Text('16', style: DepassTextTheme.caption),
                      Text('24', style: DepassTextTheme.caption),
                      Text('48', style: DepassTextTheme.caption),
                    ],
                  ),
                ),
              ],
            ),
            CupertinoButton(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: DepassConstants.separator),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Regenerate Password', textAlign: TextAlign.center),
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
