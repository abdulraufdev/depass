import 'package:depass/providers/password_provider.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/password/create_password.dart';
import 'package:depass/views/password/password_screen.dart';
import 'package:depass/widgets/custom_list_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomList extends StatefulWidget {
  const CustomList({super.key});

  @override
  State<CustomList> createState() => _CustomListState();
}

class _CustomListState extends State<CustomList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PasswordProvider>(
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
              child: Column(
                spacing: 14,
                children: [
                  Text(
                "No passwords found. Add a new password to get started!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              CupertinoButton.filled(child: Text("Add Password", style: DepassTextTheme.button,), onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => CreatePasswordScreen(),
                  ),
                );
              })
                ],
              )
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: DepassConstants.isDarkMode
                ? DepassConstants.darkSeparator
                : DepassConstants.lightSeparator,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            spacing: 2,
            children: List.generate(passes.length, (index) {
              final pass = passes[index];
              return CustomListTile(
                title: pass.PassTitle,
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) =>
                          PasswordScreen(id: pass.PassId.toString()),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }
}
