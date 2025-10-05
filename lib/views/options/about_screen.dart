import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: SvgPicture.asset('assets/images/depass-full.svg',width: 100, height: 180, 
              colorFilter: ColorFilter.mode(DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText, BlendMode.srcIn)),
            ),
            SizedBox(height: 20),
            Text('Depass for Android', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Version 1.0.0', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: DepassConstants.isDarkMode? DepassConstants.darkFadedBackground : DepassConstants.lightFadedBackground,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: DepassConstants.isDarkMode ? DepassConstants.darkBarBackground : DepassConstants.lightBarBackground,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/images/github.svg', height: 20, colorFilter: ColorFilter.mode(DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText, BlendMode.srcIn)),
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