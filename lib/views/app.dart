import 'package:depass/utils/constants.dart';
import 'package:depass/views/home/home_screen.dart';
import 'package:depass/views/search/search_screen.dart';
import 'package:depass/views/vault/vault_screen.dart';
import 'package:depass/widgets/animated_drawer.dart';
import 'package:depass/widgets/custom_drawer.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class App extends StatelessWidget {
  App({super.key});

  final GlobalKey<AnimatedDrawerState> _drawerKey = GlobalKey();

  // Method to toggle drawer from anywhere
  void _toggleDrawer() {
    _drawerKey.currentState?.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedDrawer(
      key: _drawerKey,
      drawer: CustomPopup(onMenu: _toggleDrawer),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        child: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            height: 56,
            backgroundColor: DepassConstants.isDarkMode
                ? DepassConstants.darkBackground
                : DepassConstants.lightBackground,
            border: Border.all(color: CupertinoColors.transparent),
            items: [
              BottomNavigationBarItem(icon: Icon(LucideIcons.house)),
              BottomNavigationBarItem(icon: Icon(LucideIcons.package)),
              BottomNavigationBarItem(icon: Icon(LucideIcons.search)),
            ],
          ),
          tabBuilder: (context, index) {
            return IndexedStack(
              index: index,
              children: [
                HomeScreen(onMenu: _toggleDrawer),
                VaultScreen(),
                SearchScreen(),
              ],
            );
          },
        ),
      ),
    );
  }
}
