import 'package:depass/models/pass.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/password/password_screen.dart';
import 'package:depass/widgets/custom_list_tile.dart';
import 'package:flutter/cupertino.dart';

class CustomList extends StatefulWidget {
  const CustomList({super.key});

  @override
  State<CustomList> createState() => _CustomListState();
}

class _CustomListState extends State<CustomList> {
  DBService db = DBService.instance;
  List<Pass> _passes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPasses();
  }

  Future<void> _loadPasses() async {
    setState(() {
      _isLoading = true;
    });
    try{
      final passes = await db.getAllPasses();
      setState(() {
        _passes = passes;
        print(_passes[0].toMap());
        _isLoading = false;
      });
    } catch(e){
      print('Failed to load passes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DepassConstants.separator,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: (_isLoading ?
          Center(
            child: CupertinoActivityIndicator(),
          ) :
          _passes.isEmpty ? Center(
            child: Text('No items found'),
          ) : Column(
            spacing: 2,
            children: List.generate(_passes.length, (index){
              return CustomListTile(
                title: _passes[index].PassTitle,
                onTap: (){
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => PasswordScreen(id: _passes[index].PassId.toString()),
                    )
                  );
                },
              );
            })
          )
      ),
    );
  }
}
