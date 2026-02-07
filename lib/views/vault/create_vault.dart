import 'dart:ui';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateVaultScreen extends StatefulWidget {
  const CreateVaultScreen({super.key});

  @override
  State<CreateVaultScreen> createState() => _CreateVaultScreenState();
}

class _CreateVaultScreenState extends State<CreateVaultScreen> {
  late final TextEditingController _controller = TextEditingController();
  String _vaultIcon = 'vault';
  String _vaultColor = 'deepTeal';
  bool _isLoading = false;

  static const String _onboardingKey = 'hasSeenVaultOnboarding';

  @override
  void initState() {
    super.initState();
    _checkAndShowOnboarding();
  }

  Future<void> _checkAndShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;

    if (!hasSeenOnboarding && mounted) {
      // Small delay to ensure the screen is built
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _showOnboardingDialog();
        await prefs.setBool(_onboardingKey, true);
      }
    }
  }

  void _showOnboardingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OnboardingDialog(),
    );
  }

  Future<void> _createVault() async {
    setState(() {
      _isLoading = true;
    });

    if (_controller.text.isEmpty) {
      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
      await vaultProvider.createVault(
        _controller.text,
        _vaultIcon,
        _vaultColor,
      );
    } catch (e) {
      print('Error: $e :)');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(transitionBetweenRoutes: false),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Text('Create Vault', style: DepassTextTheme.heading1),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  spacing: 18,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Container(
                        width: 102,
                        height: 102,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color:
                              DepassConstants.profileColors[_vaultColor] ??
                              DepassConstants.deepTeal,
                        ),
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                DepassConstants.profileIcons[_vaultIcon] ??
                                    LucideIcons.vault,
                                size: 48,
                                color: CupertinoColors.white,
                              ),
                              Positioned(
                                bottom: -20,
                                right: -20,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      clipBehavior: Clip.none,
                                      decoration: BoxDecoration(
                                        color: DepassConstants.lightBackground
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Icon(
                                        LucideIcons.squarePen500,
                                        size: 12,
                                        color: DepassConstants.darkText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onPressed: () {
                        showCupertinoSheet(
                          context: context,
                          builder: (context) => CupertinoPageScaffold(
                            navigationBar: CupertinoNavigationBar(
                              middle: Text('Select Icon'),
                            ),
                            child: Wrap(
                              children: DepassConstants.profileIcons.values
                                  .toList()
                                  .map(
                                    (iconData) => CupertinoButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          _vaultIcon = DepassConstants
                                              .profileIcons
                                              .entries
                                              .firstWhere(
                                                (entry) =>
                                                    entry.value == iconData,
                                              )
                                              .key;
                                        });
                                      },
                                      child: Icon(iconData, size: 28),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 156,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.start,
                          runAlignment: WrapAlignment.center,
                          children: DepassConstants.profileColors.values.map((
                            color,
                          ) {
                            return CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 0),
                              onPressed: () {
                                setState(() {
                                  _vaultColor = DepassConstants
                                      .profileColors
                                      .entries
                                      .firstWhere(
                                        (entry) => entry.value == color,
                                      )
                                      .key;
                                });
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
                CupertinoTextField(
                  controller: _controller,
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  placeholder: "Your title...",
                ),
              ],
            ),
            CupertinoButton.filled(
              minimumSize: Size(double.infinity, 44),
              borderRadius: BorderRadius.circular(8),
              child: (_isLoading
                  ? CupertinoActivityIndicator(
                      color: DepassConstants.isDarkMode
                          ? DepassConstants.darkBackground
                          : DepassConstants.lightBackground,
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: DepassConstants.isDarkMode
                            ? DepassConstants.darkButtonText
                            : DepassConstants.lightButtonText,
                      ),
                    )),
              onPressed: () {
                // Save the edited vault
                if (_controller.text.trim().isEmpty) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) {
                      return CupertinoAlertDialog(
                        title: Text('Error'),
                        content: Text('Vault title cannot be empty.'),
                        actions: [
                          CupertinoDialogAction(
                            child: Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  _createVault();
                  Navigator.of(context).pushReplacement(
                    CupertinoPageRoute(builder: (context) => App()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingDialog extends StatefulWidget {
  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Start fade-in after build
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _opacity = 1.0);
      }
    });
  }

  void _closeDialog() {
    setState(() => _opacity = 0.0);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Dialog(
          backgroundColor: DepassConstants.isDarkMode
              ? DepassConstants.darkCardBackground
              : DepassConstants.lightCardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Illustration
                SvgPicture.asset(
                  'assets/images/vault-illustration.svg',
                  width: 160,
                  height: 160,
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Welcome to Vaults',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkText
                        : DepassConstants.lightText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'A vault is where all your passwords are stored securely. Vaults help you organize all your passwords, and when combined with Sync Chain, you can manage passwords for all your family members in separate vaults.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkText.withValues(alpha: 0.7)
                        : DepassConstants.lightText.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Hint text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkPrimary.withValues(alpha: 0.1)
                        : DepassConstants.lightPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.lightbulb,
                        size: 20,
                        color: DepassConstants.isDarkMode
                            ? DepassConstants.darkText
                            : DepassConstants.lightText,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create a vault now to start organizing your passwords!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: DepassConstants.isDarkMode
                                ? DepassConstants.darkText
                                : DepassConstants.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _closeDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DepassConstants.isDarkMode
                          ? DepassConstants.darkPrimary
                          : DepassConstants.lightPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text('Get Started', style: DepassTextTheme.button),
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
