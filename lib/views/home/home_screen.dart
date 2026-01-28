import 'package:depass/providers/password_provider.dart';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/widgets/custom_list.dart';
import 'package:depass/views/password/create_password.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:depass/models/vault.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  VoidCallback? get onMenu => widget.onMenu;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final vaultProvider = Provider.of<VaultProvider>(
          context,
          listen: false,
        );
        final passwordProvider = Provider.of<PasswordProvider>(
          context,
          listen: false,
        );

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
        VaultIcon: "folder",
        VaultColor: "blue",
        CreatedAt: DateTime.now().millisecondsSinceEpoch,
        UpdatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];

    if (providerVaults != null) {
      vaults.addAll(providerVaults);
    }

    return vaults;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        padding: EdgeInsetsDirectional.symmetric(horizontal: 4.0),
        leading: Row(
          children: [
            CupertinoButton(
              onPressed: () {
                onMenu!();
              },
              padding: EdgeInsets.zero,
              child: Icon(LucideIcons.menu),
            ),
            Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: SizedBox.expand(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 32,
                  children: [
                    Column(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Vault", style: DepassTextTheme.heading2),
                        Consumer<VaultProvider>(
                          builder: (context, vaultProvider, child) {
                            final allVaults = _buildVaultsList(
                              vaultProvider.allVaults,
                            );

                            // Ensure selected index is within bounds
                            if (_selectedIndex >= allVaults.length) {
                              _selectedIndex = 0;
                            }

                            return CupertinoButton.filled(
                              minimumSize: const Size(double.infinity, 64),
                              foregroundColor: DepassConstants.isDarkMode
                                  ? DepassConstants.darkText
                                  : DepassConstants.lightText,
                              color: DepassConstants.isDarkMode
                                  ? DepassConstants.darkDropdownButton
                                  : DepassConstants.lightDropdownButton,
                              onPressed: () {
                                showCupertinoModalPopup(
                                  context: context,
                                  builder: (context) {
                                    return SizedBox(
                                      height: 360.0,
                                      child: Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          CupertinoPicker(
                                            scrollController:
                                                FixedExtentScrollController(
                                                  initialItem: _selectedIndex,
                                                ),
                                            backgroundColor:
                                                DepassConstants.isDarkMode
                                                ? DepassConstants
                                                      .darkFadedBackground
                                                : DepassConstants
                                                      .lightFadedBackground,
                                            itemExtent: 42.0,

                                            onSelectedItemChanged: (int index) {
                                              setState(() {
                                                _selectedIndex = index;
                                              });

                                              // Update the password provider with the new vault selection
                                              final passwordProvider =
                                                  Provider.of<PasswordProvider>(
                                                    context,
                                                    listen: false,
                                                  );
                                              passwordProvider.setCurrentVault(
                                                allVaults[index].VaultId,
                                              );

                                              print("selected $index");
                                            },
                                            children: allVaults
                                                .map(
                                                  (vault) => Center(
                                                    child: Text(
                                                      vault.VaultTitle,
                                                      style: DepassTextTheme
                                                          .dropdown,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 24.0,
                                            ),
                                            child: Text(
                                              'Choose Vault',
                                              style: DepassTextTheme.heading2,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    allVaults.isNotEmpty
                                        ? allVaults[_selectedIndex].VaultTitle
                                        : "No Vaults",
                                    style: DepassTextTheme.boldLabel,
                                  ),
                                  Icon(LucideIcons.chevronsUpDown),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Column(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Passwords", style: DepassTextTheme.heading2),
                        CustomList(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => CreatePasswordScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: DepassConstants.darkDropdownButton,
                    borderRadius: BorderRadius.circular(42),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    color: CupertinoColors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
