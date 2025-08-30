import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/widgets/custom_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> colors = ['Red', 'Green', 'Blue', 'Yellow'];
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Text('Home'),
        trailing: Icon(LucideIcons.menu),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 32,
          children: [
            CupertinoButton.filled(
              minimumSize: const Size(double.infinity, 64),
              foregroundColor: DepassConstants.text,
              color: DepassConstants.dropdownButton,
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) {
                    return SizedBox(
                      height: 200.0,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: _selectedIndex),
                        backgroundColor: DepassConstants.background,
                        itemExtent: 42.0,
                        
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                          print("selected $index");
                        },
                        children: colors.map((color)=> Center(
                          child: Text(color
                          , 
                          style: TextStyle(
                            color: DepassConstants.text,
                            fontWeight: FontWeight.w600
                          ),),
                        )).toList(),
                      ),
                    );
                  },
                );
              },

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(colors[_selectedIndex], style: TextStyle(fontWeight: FontWeight.bold),),
                  Icon(LucideIcons.chevronsUpDown)
                ],
              ),
            ),
            Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Recently added", style: DepassTextTheme.heading2,),
                CustomList(),
              ],
            )
          ],
        ),
      ),
    );
  }
}
