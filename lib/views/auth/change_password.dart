import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/text_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Focus nodes for tracking focus state
  final FocusNode _currentPasswordFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _currentPasswordVerified = false;
  
  // Focus state tracking
  bool _isCurrentPasswordFocused = false;
  bool _isNewPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;

  @override
  void initState() {
    super.initState();
    
    // Add focus listeners
    _currentPasswordFocus.addListener(() {
      setState(() {
        _isCurrentPasswordFocused = _currentPasswordFocus.hasFocus;
      });
    });
    
    _newPasswordFocus.addListener(() {
      setState(() {
        _isNewPasswordFocused = _newPasswordFocus.hasFocus;
      });
    });
    
    _confirmPasswordFocus.addListener(() {
      setState(() {
        _isConfirmPasswordFocused = _confirmPasswordFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    
    // Dispose focus nodes
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    
    super.dispose();
  }

  Future<void> _verifyCurrentPassword() async {
    if (_currentPasswordController.text.isEmpty) {
      _showErrorSnackBar(context, 'Please enter your current password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = await _authService.verifyMasterPassword(
        _currentPasswordController.text,
      );

      if (isValid) {
        setState(() {
          _currentPasswordVerified = true;
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar(context, 'Invalid current password');
        _currentPasswordController.clear();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(context, 'Failed to verify password: $e');
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.isEmpty) {
      _showErrorSnackBar(context, 'Please enter a new password');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar(context, 'Password must be at least 6 characters long');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar(context, 'Passwords do not match');
      return;
    }

    if (_newPasswordController.text == _currentPasswordController.text) {
      _showErrorSnackBar(context, 'New password must be different from current password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.changeMasterPassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(context, 'Failed to change password');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to change password: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Success'),
          content: const Text('Your password has been changed successfully.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to security screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing...'),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Change Password'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Icon
              Icon(
                Icons.lock_reset,
                size: 80,
                color: DepassConstants.isDarkMode ? DepassConstants.darkPrimary : DepassConstants.lightPrimary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _currentPasswordVerified
                    ? 'Enter New Password'
                    : 'Verify Current Password',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                _currentPasswordVerified
                    ? 'Please enter your new password'
                    : 'Enter your current password to continue',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Current Password Field (if not verified yet)
              if (!_currentPasswordVerified) ...[
                CupertinoTextField(
                  controller: _currentPasswordController,
                  focusNode: _currentPasswordFocus,
                  placeholder: 'Current Password',
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isCurrentPasswordFocused 
                          ? (DepassConstants.isDarkMode ? DepassConstants.darkPrimary : DepassConstants.lightPrimary)
                          : CupertinoColors.systemGrey4,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffix: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword 
                          ? Icons.visibility 
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                  obscureText: _obscureCurrentPassword,
                  onSubmitted: (_) => _verifyCurrentPassword(),
                ),
                const SizedBox(height: 24),
                CupertinoButton(
                  onPressed: _isLoading ? null : _verifyCurrentPassword,
                  color: DepassConstants.isDarkMode ? DepassConstants.darkPrimary : DepassConstants.lightPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Verify Password',
                    style: DepassTextTheme.button,
                  ),
                ),
              ],

              // New Password Fields (if current password is verified)
              if (_currentPasswordVerified) ...[
                CupertinoTextField(
                  controller: _newPasswordController,
                  focusNode: _newPasswordFocus,
                  placeholder: 'New Password',
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isNewPasswordFocused 
                          ? (DepassConstants.isDarkMode ? DepassConstants.darkPrimary : DepassConstants.lightPrimary)
                          : CupertinoColors.systemGrey4,
                      width:  1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffix: IconButton(
                    icon: Icon(
                      _obscureNewPassword 
                          ? Icons.visibility 
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  obscureText: _obscureNewPassword,
                ),
                const SizedBox(height: 16),

                CupertinoTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  placeholder: 'Confirm New Password',
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isConfirmPasswordFocused 
                          ? (DepassConstants.isDarkMode ? DepassConstants.darkPrimary : DepassConstants.lightPrimary)
                          : CupertinoColors.systemGrey4,
                      width:  1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword 
                          ? Icons.visibility 
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  obscureText: _obscureConfirmPassword,
                  onSubmitted: (_) => _changePassword(),
                ),
                const SizedBox(height: 24),

                CupertinoButton(
                  onPressed: _isLoading ? null : _changePassword,
                  color: DepassConstants.isDarkMode ? DepassConstants.darkPrimary : DepassConstants.lightPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Change Password',
                          style: DepassTextTheme.button,
                        ),
                ),

                const SizedBox(height: 32),

                // Password Requirements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DepassConstants.isDarkMode ? const Color.fromARGB(255, 6, 18, 29) : Colors.blue[50]!,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DepassConstants.isDarkMode ? DepassConstants.darkDropdownButton : Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Password Requirements',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('• At least 6 characters long'),
                      const Text('• Must be different from current password'),
                      const Text('• Use a strong, unique password'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
