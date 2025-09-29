import 'package:depass/services/auth_service.dart';
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
  AuthService _authService = AuthService();

  bool bioEnabled = false;

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
    bool authent = await _authService.authenticateWithBiometrics();
    if (authent) {
      await _authService.setBiometricEnabled(enabled);
      setState(() {
        bioEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text('Security'),
      ),
      child:Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            
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
                color: DepassConstants.barBackground,
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
                  subtitle: Text('Enabled'),
                  trailing: CupertinoSwitch(value: bioEnabled, onChanged: (value) {
                    _updateBiometricSetting(value);
                  },
                  activeTrackColor: DepassConstants.toast,
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