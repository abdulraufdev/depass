import 'package:depass/widgets/custom_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:depass/services/auth_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        leading: Text('Search'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          children: [
            CupertinoSearchTextField(
              prefixIcon: Icon(LucideIcons.search),
              suffixIcon: Icon(LucideIcons.x),
            ),
            CustomList(),
            CupertinoButton(child: Text('click to delete'),
             onPressed: (){
              _authService.clearAllData();
             })
          ],
        ),
      )
    );
  }
}