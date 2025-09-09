import 'package:depass/services/database_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/password/edit_password.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key, required this.id});

  final String id;

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  DBService db = DBService.instance;

  Widget _customTitle(Map<String, dynamic> note) {
    if (note['Type']) {
      return note['Type'] == "password"
          ? Text("***********")
          : Text(note['Description']);
    } else {
      return Text("not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Password ${widget.id}'),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: FutureBuilder(
          future: db.getNotesByPassId(int.parse(widget.id)),
          builder: (context, asyncSnapshot) {
            return Column(
              spacing: 32,
              children: [
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      asyncSnapshot.data![0]['PassTitle'],
                      style: DepassTextTheme.heading1,
                    ),
                    CupertinoButton(
                      child: Icon(LucideIcons.pen),
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => EditPasswordScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: DepassConstants.separator,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    spacing: 2,
                    children: List.generate(asyncSnapshot.data!.length, (
                      index,
                    ) {
                      return CupertinoListTile(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        backgroundColor: DepassConstants.fadedBackground,
                        title: _customTitle(asyncSnapshot.data![index]),
                        trailing: CupertinoButton(
                          child: Icon(LucideIcons.copy),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: asyncSnapshot.data![index]['Type'],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
