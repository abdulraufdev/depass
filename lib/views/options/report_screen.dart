import 'package:depass/theme/text_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController issueController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    emailController.dispose();
    issueController.dispose();
    super.dispose();
  }

  sendMail() async {
    // Prevent multiple simultaneous sends
    if (_isSending) return;

    //validate email
    final email = emailController.text;
    final issue = issueController.text;
    if (email.isEmpty || !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email) || issue.isEmpty) {
      //show error
      _showDialog(
        title: 'Error',
        content: 'Please enter a valid email and describe the issue.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Create email URL
      final String recipient = 'editsabdulrauf5681@gmail.com';
      final String subject = Uri.encodeComponent('Bug Report - Depass App');
      final String body = Uri.encodeComponent(
        'Issue: ${issueController.text}\n\nReported by: ${emailController.text}\n\nApp: Depass Password Manager'
      );
      
      final Uri emailUri = Uri.parse('mailto:$recipient?subject=$subject&body=$body');
      
      // Try to launch email app
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        
        // Clear form fields after successful launch
        emailController.clear();
        issueController.clear();
        
        _showDialog(
          title: 'Thank you!',
          content: 'Your email app has been opened. Please send the email to complete your report.',
          isError: false,
        );
      } else {
        throw Exception('No email app available');
      }
    } catch (error) {
      _showDialog(
        title: 'Error',
        content: 'Failed to open email app. Please check if you have an email app installed and try again.',
        isError: true,
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showDialog({required String title, required String content, required bool isError}) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
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
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(transitionBetweenRoutes: false),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report a bug', style: DepassTextTheme.heading1),
            SizedBox(height: 12),
            Text(
              'If you encounter any bugs or issues while using the app, please report them to help us improve the app. Fill out the form below and tap "Open Email App" to send your report.',
            ),
            SizedBox(height: 20),
            //create a form containning user email and description of the bug
            CupertinoTextField(
              placeholder: 'Your Email',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              padding: EdgeInsets.all(12),
            ),
            SizedBox(height: 12),
            CupertinoTextField(
              controller: issueController,
              placeholder: 'Describe the issue',
              maxLines: 5,
              padding: EdgeInsets.all(12),
            ),
            SizedBox(height: 20),
            CupertinoListTile(
              title: Text(_isSending ? 'Opening Email App...' : 'Open Email App'),
              leading: _isSending 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CupertinoActivityIndicator(),
                  )
                : Icon(CupertinoIcons.mail),
              padding: EdgeInsets.symmetric(vertical: 20),
              onTap: _isSending ? null : () {
                sendMail();
              },
            ),
          ],
        ),
      ),
    );
  }
}
