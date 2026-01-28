import 'package:depass/providers/vault_provider.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/password/passwords_screen.dart';
import 'package:depass/views/vault/create_vault.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
        final vaultProvider = Provider.of<VaultProvider>(
          context,
          listen: false,
        );
        vaultProvider.loadAllVaults();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        leading: Text('Vaults', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Consumer<VaultProvider>(
                builder: (context, vaultProvider, child) {
                  if (vaultProvider.isLoadingAllVaults) {
                    return Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }

                  final vaults = vaultProvider.allVaults;

                  if (vaults == null || vaults.isEmpty) {
                    return SizedBox(
                      width: double.infinity / 2,
                      height: 200,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => CreateVaultScreen(),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: DepassConstants.isDarkMode
                                ? DepassConstants.darkBarBackground
                                : DepassConstants.lightBarBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 12,
                              children: [
                                Icon(
                                  LucideIcons.plus,
                                  size: 48,
                                  color: DepassConstants.isDarkMode
                                      ? DepassConstants.lightButtonText
                                      : DepassConstants.darkButtonText,
                                ),
                                Text(
                                  "Create Vault",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: DepassConstants.isDarkMode
                                        ? DepassConstants.lightButtonText
                                        : DepassConstants.darkButtonText,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: vaults.length + 1,
                    itemBuilder: (context, index) {
                      if (index == vaults.length) {
                        return CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => CreateVaultScreen(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: DepassConstants.isDarkMode
                                  ? DepassConstants.darkBarBackground
                                  : DepassConstants.lightBarBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 12,
                                children: [
                                  Icon(
                                    LucideIcons.plus,
                                    size: 48,
                                    color: DepassConstants.isDarkMode
                                        ? DepassConstants.lightButtonText
                                        : DepassConstants.darkButtonText,
                                  ),
                                  Text(
                                    "Create Vault",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: DepassConstants.isDarkMode
                                          ? DepassConstants.lightButtonText
                                          : DepassConstants.darkButtonText,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      final vault = vaults[index];
                      final iconData =
                          DepassConstants.profileIcons[vault.VaultIcon] ??
                          LucideIcons.vault;
                      final color =
                          DepassConstants.profileColors[vault.VaultColor] ??
                          DepassConstants.slateGray;

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) =>
                                  PasswordsScreen(vault: vault),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 108,
                                height: 108,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(70),
                                ),
                                child: Icon(
                                  iconData,
                                  size: 42,
                                  color: Color(
                                    0xFFFFFFFF,
                                  ).withValues(alpha: 0.9),
                                ),
                              ),
                              SizedBox(height: 16),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  vault.VaultTitle,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
