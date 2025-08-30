import 'package:depass/utils/constants.dart';
import 'package:depass/widgets/custom_list_tile.dart';
import 'package:flutter/cupertino.dart';

class CustomList extends StatelessWidget {
  const CustomList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DepassConstants.separator,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        spacing: 2,
        children: List.generate(5, (index) {
          return CustomListTile(
            title: 'Item $index',
            subtitle: 'Subtitle $index',
          );
        }),
      ),
    );
  }
}
