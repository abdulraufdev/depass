import 'package:depass/utils/constants.dart';
import 'package:depass/views/encryption/encryption.dart';
import 'package:depass/views/home/home_screen.dart';
import 'package:depass/views/password/create_password.dart';
import 'package:depass/views/search/search_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        height: 56,
        backgroundColor: DepassConstants.isDarkMode ? DepassConstants.darkBackground : DepassConstants.lightBackground,
        border: Border.all(color: CupertinoColors.transparent),
        onTap: (value){
          if(value == 2){
            Navigator.of(context).pushReplacement(
              CupertinoPageRoute(
                builder: (context) => const CreatePasswordScreen(),
              ),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.house),
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.lockKeyhole),
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.squarePen),
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.search),
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return IndexedStack(
          index: index,
          children: const [
            HomeScreen(),
            EncryptionScreen(),
            Center(child: Text('Create')),
            SearchScreen(),
          ],
        );
      },
    );
  }
}