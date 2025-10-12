import 'package:depass/providers/password_provider.dart';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/widgets/custom_drawer.dart';
import 'package:depass/widgets/custom_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:depass/models/vault.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
        final passwordProvider = Provider.of<PasswordProvider>(context, listen: false);
        
        // Load vaults first, then initialize passwords
        await vaultProvider.loadAllVaults();
        
        // Initialize password provider with "All Vaults" (vaultId = 0)
        await passwordProvider.setCurrentVault(0);
      }
    });
  }

  List<Vault> _buildVaultsList(List<Vault>? providerVaults) {
    List<Vault> vaults = [
      Vault(
        VaultId: 0,
        VaultTitle: "All Vaults",
        CreatedAt: DateTime.now().millisecondsSinceEpoch,
        UpdatedAt: DateTime.now().millisecondsSinceEpoch
      )
    ];
    
    if (providerVaults != null) {
      vaults.addAll(providerVaults);
    }
    
    return vaults;
  }


  void _showCustomPopup(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: CupertinoColors.black.withValues(alpha: 0.4),
        pageBuilder: (_, __, ___) => CustomPopup(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: Offset(1.0, 0.0), // from right
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.fastEaseInToSlowEaseOut,
          ));
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        padding: EdgeInsetsDirectional.symmetric(horizontal: 12.0),
        leading: Text('Home', style: TextStyle(fontWeight: FontWeight.bold),),
        trailing: CupertinoButton(onPressed: (){
          _showCustomPopup(context);
        },
        padding: EdgeInsets.zero,
         child: Icon(LucideIcons.menu)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            spacing: 32,
            children: [
              Consumer<VaultProvider>(
                builder: (context, vaultProvider, child) {
                  final allVaults = _buildVaultsList(vaultProvider.allVaults);
                  
                  // Ensure selected index is within bounds
                  if (_selectedIndex >= allVaults.length) {
                    _selectedIndex = 0;
                  }
                  
                  return CupertinoButton.filled(
                    minimumSize: const Size(double.infinity, 64),
                    foregroundColor: DepassConstants.isDarkMode ? DepassConstants.darkText : DepassConstants.lightText,
                    color: DepassConstants.isDarkMode ? DepassConstants.darkDropdownButton : DepassConstants.lightDropdownButton,
                    onPressed: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) {
                              return SizedBox(
                                height: 360.0,
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(initialItem: _selectedIndex),
                                  backgroundColor: DepassConstants.isDarkMode ? DepassConstants.darkFadedBackground : DepassConstants.lightFadedBackground,
                                  itemExtent: 42.0,
                                  
                                  onSelectedItemChanged: (int index) {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                    
                                    // Update the password provider with the new vault selection
                                    final passwordProvider = Provider.of<PasswordProvider>(context, listen: false);
                                    passwordProvider.setCurrentVault(allVaults[index].VaultId);
                                    
                                    print("selected $index");
                                  },
                                  children: allVaults.map((vault) => Center(
                                    child: Text(vault.VaultTitle, 
                                    style: DepassTextTheme.dropdown,),
                                  )).toList(),
                                ),
                              );
                            }
                      );
                    },
                  
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(allVaults.isNotEmpty ? allVaults[_selectedIndex].VaultTitle : "No Vaults", 
                             style: DepassTextTheme.boldLabel),
                        Icon(LucideIcons.chevronsUpDown)
                      ],
                    ),
                  );
                }
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
      ),
    );
  }
}