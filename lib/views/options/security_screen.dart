import 'package:depass/services/auth_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/auth/change_password.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final AuthService _authService = AuthService();

  bool bioEnabled = false;
  bool _isUpdatingBiometric = false;

  @override
  void initState() {
    _authService.isBiometricEnabled().then((enabled) {
      setState(() {
        bioEnabled = enabled;
      });
    });
    super.initState();
  }

  Future<void> _updateBiometricSetting(bool enabled) async {
    if (_isUpdatingBiometric) return; // Prevent multiple simultaneous updates
    
    setState(() {
      _isUpdatingBiometric = true;
    });
    
    try {
      // First check if biometric is available
      bool isAvailable = await _authService.isBiometricAvailable();
      if (!isAvailable) {
        _showMessage('Biometric authentication is not available on this device');
        return;
      }

      // Use the new verification method that doesn't auto-enable biometrics
      bool authent = await _authService.verifyIdentityWithBiometrics();
      if (authent) {
        await _authService.setBiometricEnabled(enabled);
        setState(() {
          bioEnabled = enabled;
        });
        
        // Show success message
        _showMessage(enabled ? 'Biometric authentication enabled' : 'Biometric authentication disabled');
      } else {
        // Authentication failed or was cancelled - show message
        _showMessage('Authentication was cancelled or failed. Please try again.');
      }
    } catch (e) {
      // Handle any errors
      _showMessage('Error updating biometric setting: $e');
    } finally {
      setState(() {
        _isUpdatingBiometric = false;
      });
    }
  }

  void _showMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Biometric Authentication'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
      ),
      child:Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security', style: DepassTextTheme.heading1),
            SizedBox(height: 12,),
            CupertinoListTile(title: Text('Change password'),
            trailing: Icon(LucideIcons.chevronRight),
            padding: EdgeInsetsGeometry.symmetric(vertical: 20),
            onTap: (){
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => ChangePasswordScreen()
                )
              );
            },
            ),
            SizedBox(
              height: 2,
              child: Container(
                color: DepassConstants.isDarkMode ? DepassConstants.darkBarBackground : DepassConstants.lightBarBackground,
              ),
            ),
            FutureBuilder<bool>(
      future: _authService.isBiometricAvailable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CupertinoListTile(
            title: Text('Biometric Authentication'),
            subtitle: Text('Checking...'),
            padding: EdgeInsetsGeometry.symmetric(vertical: 20),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return snapshot.data == true
              ? CupertinoListTile(
                  title: Text('Biometric Authentication'),
                  subtitle: Text(_isUpdatingBiometric ? 'Authenticating...' : 'Enabled'),
                  trailing: _isUpdatingBiometric 
                    ? CupertinoActivityIndicator()
                    : CupertinoSwitch(
                        value: bioEnabled, 
                        onChanged: _isUpdatingBiometric ? null : (value) {
                          _updateBiometricSetting(value);
                        },
                        activeTrackColor: DepassConstants.isDarkMode ? DepassConstants.darkDropdownButton : DepassConstants.lightPrimary,
                      ),
                  padding: EdgeInsetsGeometry.symmetric(vertical: 20),
                )
              : Text('No biometric available');
        }
      },
    ),
          ],
        ),
      )
    );
  }
}