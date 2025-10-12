import 'package:depass/models/pass.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/password/password_screen.dart';
import 'package:depass/widgets/custom_list_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  FocusNode _focusNode = FocusNode();
  DBService db = DBService.instance;
  List<Pass> passes = [];
  List<Pass> filtered = [];
  @override
  void initState(){
    super.initState();
    _getPasses();
    _focusNode.requestFocus();
  }

  @override
  void dispose(){
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _getPasses()async {
    final allPasses =await db.getAllPasses();
    setState(() {
      passes = allPasses;
      filtered = passes;
    });
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        leading: Text('Search', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          children: [
            CupertinoSearchTextField(
              focusNode: _focusNode,
              prefixIcon: Icon(LucideIcons.search),
              suffixIcon: Icon(LucideIcons.x),
              onChanged: (value){
                setState(() {
                  filtered = passes.where((p) => p.PassTitle.contains(value)).toList();
                });
              },
            ),
            Container(
      decoration: BoxDecoration(
        color: DepassConstants.isDarkMode ? DepassConstants.darkSeparator : DepassConstants.lightSeparator,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
            spacing: 2,
            children: List.generate(filtered.length, (index) {
              final pass = filtered[index];
              return CustomListTile(
                title: pass.PassTitle,
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => PasswordScreen(id: pass.PassId.toString()),
                    ),
                  );
                },
              );
            },
            growable: true),
      ),
          ),
          ],
        ),
      )
    );
  }
}