import 'package:depass/services/auth_service.dart';
import 'package:flutter/cupertino.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text('Security'),
      ),
      child:Column(
        children: [
          CupertinoListTile(title: Text('Delete'),
          onTap: (){
            _authService.clearAllData();
          },
          )
        ],
      )
    );
  }
}