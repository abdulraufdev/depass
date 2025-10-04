import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text('About'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Image.asset('assets/images/depass.png',height: 200),
            SizedBox(height: 20),
            Text('Depass for Android', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Version 1.0.0', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: DepassConstants.fadedBackground,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: DepassConstants.barBackground,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/github.png', height: 20),
                    SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.all(0),
                      onPressed: () {
                        // Handle link tap, e.g., open URL
                        final url = Uri.parse('https://github.com/abdulraufdev/depass');
                        launchUrl(url);
                      },
                      child: Text(
                        'Release Notes',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.activeBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Developed by ', style: TextStyle(fontSize: 16)),
                  GestureDetector(
                    onTap: () {
                      final url = Uri.parse('https://github.com/abdulraufdev');
                      launchUrl(url);
                    },
                    child: Text(
                      'Abdul Rauf',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.activeBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(child: SizedBox()),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text('GPL License 3.0'),
              )
          ],
        ),
      ),
    );
  }
}