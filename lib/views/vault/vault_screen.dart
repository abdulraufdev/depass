import 'package:depass/providers/vault_provider.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/vault/create_vault.dart';
import 'package:depass/views/vault/edit_vault.dart';
import 'package:depass/widgets/custom_list_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
        vaultProvider.loadAllVaults();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text('Manage Vaults', style: TextStyle(fontFamily: 'Inter'),),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
                    color: DepassConstants.isDarkMode ? DepassConstants.darkSeparator : DepassConstants.lightSeparator,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Consumer<VaultProvider>(
                    builder: (context, vaultProvider, child) {
                      if (vaultProvider.isLoadingAllVaults) {
                        return Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: CupertinoActivityIndicator()),
                        );
                      }
                      
                      final vaults = vaultProvider.allVaults;
                      
                      if (vaults == null || vaults.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('No vaults found'),
                          ),
                        );
                      }
                      
                      return Column(
                        spacing: 2,
                        children: List.generate(vaults.length, (index) {
                          final vault = vaults[index];
                          return CustomListTile(
                            title: vault.VaultTitle,
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      EditVaultScreen(id: vault.VaultId.toString()),
                                ),
                              );
                            },
                          );
                        }),
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
