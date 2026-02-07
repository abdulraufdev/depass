import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:depass/views/vault/create_vault.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../app.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

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

  static const String _welcomeOnboardingKey = 'hasSeenWelcomeOnboarding';

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

      // Show welcome onboarding if this is the first time (setting up)
      if (_isSettingUp) {
        _checkAndShowWelcomeOnboarding();
      }

      // Try device authentication if enabled and available
      if (!_isSettingUp && _biometricEnabled && _biometricAvailable) {
        _authenticateWithBiometrics();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(context, 'Failed to initialize authentication: $e');
    }
  }

  Future<void> _checkAndShowWelcomeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(_welcomeOnboardingKey) ?? false;

    if (!hasSeenOnboarding && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _showWelcomeDialog();
        await prefs.setBool(_welcomeOnboardingKey, true);
      }
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WelcomeOnboardingDialog(),
    );
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
      _showErrorSnackBar(
        context,
        'Password must be at least 6 characters long',
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar(context, 'Passwords do not match');
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
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Enable Device Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Would you like to enable device authentication (biometrics, PIN, pattern, or password) for faster access?',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip'),
          ),
          CupertinoDialogAction(
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
    ).pushReplacement(CupertinoPageRoute(builder: (context) => App()));
  }

  void _navigateToVaultCreation() {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (context) => const CreateVaultScreen()),
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
    setState(() {
      _isLoading = false;
    });
  }

  // Get the appropriate icon for authentication method
  IconData _getAuthenticationIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.visibility;
    } else if (_availableBiometrics.isNotEmpty) {
      return Icons.security;
    } else {
      // Fallback for device authentication (PIN, pattern, password)
      return Icons.lock;
    }
  }

  // Get the appropriate label for authentication method
  String _getAuthenticationLabel() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Use Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Use Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Use Iris';
    } else if (_availableBiometrics.isNotEmpty) {
      return 'Use Biometric';
    } else {
      // Fallback for device authentication (PIN, pattern, password)
      return 'Use Device Authentication';
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              // App Logo/Icon
              SvgPicture.asset(
                'assets/images/depass.svg',
                height: 120,
                colorFilter: ColorFilter.mode(
                  DepassConstants.isDarkMode
                      ? DepassConstants.darkText
                      : DepassConstants.lightText,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 16),

              // App Title
              Text(
                'Depass',
                style: DepassTextTheme.heading1,
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
                      Text(
                        '• At least 6 characters long',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                      Text(
                        '• Use a strong, unique password',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                      Text(
                        '• Remember this password - it cannot be recovered',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],

              // Primary Action Button
              CupertinoButton.filled(
                onPressed: _isLoading
                    ? null
                    : (_isSettingUp
                          ? _setupMasterPassword
                          : _authenticateWithPassword),

                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CupertinoActivityIndicator(radius: 10),
                      )
                    : Text(
                        _isSettingUp ? 'Setup Password' : 'Unlock',
                        style: DepassTextTheme.button,
                      ),
              ),

              // Local Authentication Button (Biometrics, PIN, Pattern, Password)
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DepassConstants.isDarkMode
                          ? DepassConstants.darkSeparator
                          : DepassConstants.lightSeparator,
                    ),
                  ),
                  child: CupertinoButton.tinted(
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkBackground
                        : DepassConstants.lightBackground,
                    onPressed: _isLoading ? null : _authenticateWithBiometrics,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getAuthenticationIcon()),
                        const SizedBox(width: 8),
                        Text(_getAuthenticationLabel()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeOnboardingDialog extends StatefulWidget {
  @override
  State<_WelcomeOnboardingDialog> createState() =>
      _WelcomeOnboardingDialogState();
}

class _WelcomeOnboardingDialogState extends State<_WelcomeOnboardingDialog> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
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
                  'assets/images/welcome-illustration.svg',
                  width: 160,
                  height: 160,
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Welcome to Depass',
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
                  'Depass is your secure, offline-first password manager. Unlike cloud-based alternatives, your passwords never leave your device unless you choose to sync them—giving you complete control over your sensitive data.',
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
                // Features hint
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkBarBackground
                        : DepassConstants.lightBarBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureRow(
                        LucideIcons.shieldCheck,
                        'Fully encrypted',
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureRow(
                        LucideIcons.wifiOff,
                        'Works completely offline',
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureRow(
                        LucideIcons.refreshCcw,
                        'Sync with family via Sync Chain',
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

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: DepassConstants.isDarkMode
              ? DepassConstants.darkText
              : DepassConstants.lightText,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
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
    );
  }
}
