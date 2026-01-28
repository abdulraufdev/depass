import 'package:depass/providers/password_provider.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/password/password_screen.dart';
import 'package:depass/widgets/custom_list_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortOption { alphabeticalAsc, alphabeticalDesc, createdFirst, createdLast }

class CustomList extends StatefulWidget {
  const CustomList({super.key});

  @override
  State<CustomList> createState() => _CustomListState();
}

class _CustomListState extends State<CustomList> {
  static const String _sortPrefKey = 'password_list_sort_option';
  SortOption _currentSort = SortOption.createdLast;

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    // Pre-load password data for all passes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final passwordProvider = context.read<PasswordProvider>();
      final passes = passwordProvider.allPasses;
      if (passes != null) {
        for (var pass in passes) {
          if (passwordProvider.getPasswordData(pass.PassId) == null) {
            passwordProvider.loadPasswordData(pass.PassId);
          }
        }
      }
    });
  }

  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final sortIndex = prefs.getInt(_sortPrefKey);
    if (sortIndex != null && sortIndex < SortOption.values.length) {
      setState(() {
        _currentSort = SortOption.values[sortIndex];
      });
    }
  }

  Future<void> _saveSortPreference(SortOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortPrefKey, option.index);
  }

  String _getEmailFromData(List<Map<String, dynamic>>? data) {
    if (data == null || data.isEmpty) return '';
    for (var item in data) {
      if (item['Type'] == 'email') {
        return item['Description'] ?? '';
      }
    }
    return '';
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.alphabeticalAsc:
        return 'A → Z';
      case SortOption.alphabeticalDesc:
        return 'Z → A';
      case SortOption.createdFirst:
        return 'Oldest First';
      case SortOption.createdLast:
        return 'Newest First';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PasswordProvider>(
      builder: (context, passwordProvider, child) {
        bool isLoading = passwordProvider.isLoadingAllPasses;
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (MediaQuery.of(context).size.width < 600 == false)
                    SizedBox(height: 20),
                  SvgPicture.asset(
                    'assets/images/mobile-screen.svg',
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.width * 0.4,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "No passwords yet? Add one now to protect your accounts.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.only(left: 84.0),
                    child: SvgPicture.asset(
                      'assets/images/arrow-create.svg',
                      width: MediaQuery.of(context).size.width < 380 ? 80 : 100,
                      height: MediaQuery.of(context).size.width < 380
                          ? 100
                          : 180,
                      colorFilter: ColorFilter.mode(
                        Colors.grey[500]!,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Sort the passes based on current sort option
        final sortedPasses = List.of(passes);
        switch (_currentSort) {
          case SortOption.alphabeticalAsc:
            sortedPasses.sort(
              (a, b) => a.PassTitle.toLowerCase().compareTo(
                b.PassTitle.toLowerCase(),
              ),
            );
            break;
          case SortOption.alphabeticalDesc:
            sortedPasses.sort(
              (a, b) => b.PassTitle.toLowerCase().compareTo(
                a.PassTitle.toLowerCase(),
              ),
            );
            break;
          case SortOption.createdFirst:
            sortedPasses.sort((a, b) => a.CreatedAt.compareTo(b.CreatedAt));
            break;
          case SortOption.createdLast:
            sortedPasses.sort((a, b) => b.CreatedAt.compareTo(a.CreatedAt));
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Sort', style: DepassTextTheme.boldLabel),
                Row(
                  spacing: 6,
                  children: [
                    Text(
                      '(press and hold)',
                      textAlign: TextAlign.right,
                      style: DepassTextTheme.bodyMedium,
                    ),
                    CupertinoContextMenu(
                      actions: SortOption.values.map((option) {
                        return CupertinoContextMenuAction(
                          onPressed: () {
                            setState(() {
                              _currentSort = option;
                            });
                            _saveSortPreference(option);
                            Navigator.pop(context);
                          },
                          trailingIcon: _currentSort == option
                              ? CupertinoIcons.checkmark
                              : null,
                          child: Text(_getSortLabel(option)),
                        );
                      }).toList(),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: DepassConstants.isDarkMode
                              ? DepassConstants.darkBarBackground
                              : DepassConstants.lightBarBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.arrowUpDown, size: 16),
                            SizedBox(width: 4),
                            Text(
                              _getSortLabel(_currentSort),
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: DepassConstants.isDarkMode
                    ? DepassConstants.darkSeparator
                    : DepassConstants.lightSeparator,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                spacing: 2,
                children: List.generate(sortedPasses.length, (index) {
                  final pass = sortedPasses[index];
                  final data = passwordProvider.getPasswordData(pass.PassId);
                  final email = _getEmailFromData(data);

                  // Load data if not cached
                  if (data == null &&
                      !passwordProvider.isLoadingPassword(pass.PassId)) {
                    passwordProvider.loadPasswordData(pass.PassId);
                  }

                  return CustomListTile(
                    title: pass.PassTitle,
                    subtitle: email,
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
            ),
          ],
        );
      },
    );
  }
}
