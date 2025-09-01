import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/vault/create_vault.dart';
import 'package:depass/views/vault/edit_vault.dart';
import 'package:depass/widgets/custom_list_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Vault'),
        transitionBetweenRoutes: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Vaults', style: DepassTextTheme.heading1),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(LucideIcons.plus,size: 24,),
                     onPressed: (){
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => CreateVaultScreen()
                    )
                  );
                },),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: DepassConstants.separator,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    spacing: 2,
                    children: List.generate(3, (index) {
                      return CustomListTile(
                        title: 'Vault $index',
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) =>
                                  EditVaultScreen(id: index.toString()),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
