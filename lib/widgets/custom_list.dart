import 'package:depass/providers/password_provider.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/password/password_screen.dart';
import 'package:depass/widgets/custom_list_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class CustomList extends StatefulWidget {
  const CustomList({super.key, this.vaultId=0});
  final int vaultId;
  @override
  State<CustomList> createState() => _CustomListState();
}

class _CustomListState extends State<CustomList> {
  @override
  void initState() {
    super.initState();
    // Load passes when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PasswordProvider>();
      if (provider.allPasses == null) {
        provider.loadFilteredPasses(widget.vaultId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DepassConstants.separator,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Consumer<PasswordProvider>(
        builder: (context, passwordProvider, child) {
          final isLoading = passwordProvider.isLoadingAllPasses;
          final passes = passwordProvider.allPasses;

          if (isLoading) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CupertinoActivityIndicator(),
              ),
            );
          }

          if (passes == null || passes.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No items found'),
              ),
            );
          }

          return Column(
            spacing: 2,
            children: List.generate(passes.length, (index) {
              final pass = passes[index];
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
            }),
          );
        },
      ),
    );
  }
}
