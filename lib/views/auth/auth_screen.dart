import 'package:depass/views/vault/create_vault.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/auth_service.dart';
import '../app.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isSettingUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    setState(() => _isLoading = true);

    try {
      await _authService.initialize();

      final isMasterPasswordSet = await _authService.isMasterPasswordSet();
      final biometricAvailable = await _authService.isBiometricAvailable();
      final biometricEnabled = await _authService.isBiometricEnabled();
      final availableBiometrics = await _authService.getAvailableBiometrics();

      setState(() {
        _isSettingUp = !isMasterPasswordSet;
        _biometricAvailable = biometricAvailable;
        _biometricEnabled = biometricEnabled;
        _availableBiometrics = availableBiometrics;
        _isLoading = false;
      });

      // Try biometric authentication if enabled and available
      if (!_isSettingUp && _biometricEnabled && _biometricAvailable) {
        _authenticateWithBiometrics();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(context, 'Failed to initialize authentication: $e');
    }
  }

  Future<void> _authenticateWithPassword() async {
    if (_passwordController.text.isEmpty) {
      _showErrorSnackBar(context, 'Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.authenticateWithPassword(
        _passwordController.text,
      );

      if (success) {
        _navigateToApp();
      } else {
        _showErrorSnackBar(context, 'Invalid password');
        _passwordController.clear();
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Authentication failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() => _isLoading = true);

    try {
      final success = await _authService.authenticateWithBiometrics();

      if (success) {
        _navigateToApp();
      } else {
        // User cancelled or authentication failed
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(context, 'Biometric authentication failed: $e');
    }
  }

  Future<void> _setupMasterPassword() async {
    if (_passwordController.text.isEmpty) {
      _showErrorSnackBar(context, 'Please enter a password');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorSnackBar(context,'Password must be at least 6 characters long');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar(context,'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.setMasterPassword(_passwordController.text);

      // Enable biometric authentication if available and user wants it
      if (_biometricAvailable) {
        final enableBiometric = await _showBiometricSetupDialog();
        if (enableBiometric) {
          await _authService.setBiometricEnabled(true);
        }
      }

      await _authService.authenticateWithPassword(_passwordController.text);
      _navigateToVaultCreation();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to setup master password: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showBiometricSetupDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Biometric Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Would you like to enable biometric authentication for faster access?',
            ),
            const SizedBox(height: 16),
            if (_availableBiometrics.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _availableBiometrics.map((type) {
                  return Chip(
                    label: Text(_getBiometricTypeName(type)),
                    avatar: Icon(_getBiometricTypeIcon(type)),
                  );
                }).toList(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _navigateToApp() {
    Navigator.of(
      context,
    ).pushReplacement(CupertinoPageRoute(builder: (context) => const App()));
  }

  void _navigateToVaultCreation() {
    Navigator.of(
      context,
    ).pushReplacement(CupertinoPageRoute(builder: (context) => const CreateVaultScreen()));
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

  String _getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.weak:
        return 'Weak Biometric';
      case BiometricType.strong:
        return 'Strong Biometric';
    }
  }

  IconData _getBiometricTypeIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.visibility;
      case BiometricType.weak:
      case BiometricType.strong:
        return Icons.security;
    }
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
              Text('Initializing...'),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Icon
              Icon(
                Icons.security,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),

              // App Title
              Text(
                'Depass',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                _isSettingUp
                    ? 'Setup your master password'
                    : 'Enter your master password',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Password Field
              CupertinoTextField(
                controller: _passwordController,
                placeholder: _isSettingUp ? 'Master Password' : 'Password',
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                obscureText: _obscurePassword,
                onSubmitted: (_) {
                  if (_isSettingUp) {
                    _setupMasterPassword();
                  } else {
                    _authenticateWithPassword();
                  }
                },
              ),

              // Confirm Password Field (only for setup)
              if (_isSettingUp) ...[
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _confirmPasswordController,
                  placeholder: 'Confirm Password',
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
                  onSubmitted: (_) => _setupMasterPassword(),
                ),
              ],

              const SizedBox(height: 24),

              // Primary Action Button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_isSettingUp
                          ? _setupMasterPassword
                          : _authenticateWithPassword),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isSettingUp ? 'Setup Password' : 'Unlock',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),

              // Biometric Authentication Button
              if (!_isSettingUp &&
                  _biometricAvailable &&
                  _biometricEnabled) ...[
                const SizedBox(height: 16),
                const Text(
                  'or',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _authenticateWithBiometrics,
                  icon: Icon(
                    _availableBiometrics.contains(BiometricType.face)
                        ? Icons.face
                        : Icons.fingerprint,
                  ),
                  label: Text(
                    _availableBiometrics.contains(BiometricType.face)
                        ? 'Use Face ID'
                        : 'Use Fingerprint',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],

              // Setup Instructions
              if (_isSettingUp) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
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
                      const Text('• Use a strong, unique password'),
                      const Text(
                        '• Remember this password - it cannot be recovered',
                      ),
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
