import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _storage = FlutterSecureStorage();
  static const String _masterPasswordKey = 'master_password_hash';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _autoLockTimeKey = 'auto_lock_time';
  static const String _lastActiveTimeKey = 'last_active_time';

  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isAuthenticated = false;
  DateTime? _lastActiveTime;
  int _autoLockMinutes = 5; // Default 5 minutes

  bool get isAuthenticated => _isAuthenticated;
  int get autoLockMinutes => _autoLockMinutes;

  // Initialize the auth service
  Future<void> initialize() async {
    await _loadSettings();
    _startAutoLockTimer();
  }

  Future<void> _loadSettings() async {
    final autoLockTime = await _storage.read(key: _autoLockTimeKey);
    if (autoLockTime != null) {
      _autoLockMinutes = int.tryParse(autoLockTime) ?? 5;
    }

    final lastActiveTimeStr = await _storage.read(key: _lastActiveTimeKey);
    if (lastActiveTimeStr != null) {
      _lastActiveTime = DateTime.tryParse(lastActiveTimeStr);
    }
  }

  // Check if master password is set
  Future<bool> isMasterPasswordSet() async {
    final hash = await _storage.read(key: _masterPasswordKey);
    return hash != null && hash.isNotEmpty;
  }

  // Set master password
  Future<void> setMasterPassword(String password) async {
    final hash = _hashPassword(password);
    await _storage.write(key: _masterPasswordKey, value: hash);
  }

  // Verify master password
  Future<bool> verifyMasterPassword(String password) async {
    final storedHash = await _storage.read(key: _masterPasswordKey);
    if (storedHash == null) return false;
    
    final inputHash = _hashPassword(password);
    return storedHash == inputHash;
  }

  // Authenticate with master password
  Future<bool> authenticateWithPassword(String password) async {
    final isValid = await verifyMasterPassword(password);
    if (isValid) {
      _isAuthenticated = true;
      await _updateLastActiveTime();
    }
    return isValid;
  }

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  // Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  // Authenticate with local authentication (biometrics, PIN, pattern, password)
  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!await isBiometricAvailable()) return false;

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your passwords',
        options: const AuthenticationOptions(
          biometricOnly: false,  // Allow all authentication methods
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        _isAuthenticated = true;
        await _updateLastActiveTime();
        
        // Auto-enable biometric authentication if it was successful and not enabled yet
        if (!await isBiometricEnabled()) {
          await setBiometricEnabled(true);
        }
      }

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  // Verify user identity without changing biometric settings
  Future<bool> verifyIdentityWithBiometrics() async {
    try {
      if (!await isBiometricAvailable()) {
        return false;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to change security settings',
        options: const AuthenticationOptions(
          biometricOnly: false,  // Allow all authentication methods
          stickyAuth: true,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      // Log error for debugging in development
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isAuthenticated = false;
    _lastActiveTime = null;
    await _storage.delete(key: _lastActiveTimeKey);
  }

  // Update last active time
  Future<void> _updateLastActiveTime() async {
    _lastActiveTime = DateTime.now();
    await _storage.write(
      key: _lastActiveTimeKey,
      value: _lastActiveTime!.toIso8601String(),
    );
  }

  // Check if app should be locked due to inactivity
  bool shouldAutoLock() {
    if (!_isAuthenticated || _lastActiveTime == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastActiveTime!);
    return difference.inMinutes >= _autoLockMinutes;
  }

  // Set auto-lock time
  Future<void> setAutoLockTime(int minutes) async {
    _autoLockMinutes = minutes;
    await _storage.write(key: _autoLockTimeKey, value: minutes.toString());
  }

  // Start auto-lock timer
  void _startAutoLockTimer() {
    // This would typically be handled by the app lifecycle
    // For now, we'll check on each app resume
  }

  // Update activity (call this on user interaction)
  Future<void> updateActivity() async {
    if (_isAuthenticated) {
      await _updateLastActiveTime();
    }
  }

  // Change master password
  Future<bool> changeMasterPassword(String currentPassword, String newPassword) async {
    if (!await verifyMasterPassword(currentPassword)) {
      return false;
    }
    
    await setMasterPassword(newPassword);
    return true;
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Clear all authentication data (for reset/uninstall)
  Future<void> clearAllData() async {
    await _storage.delete(key: _masterPasswordKey);
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _autoLockTimeKey);
    await _storage.delete(key: _lastActiveTimeKey);
    _isAuthenticated = false;
    _lastActiveTime = null;
  }

  // Export authentication settings (for backup)
  Future<Map<String, dynamic>> exportSettings() async {
    return {
      'biometric_enabled': await isBiometricEnabled(),
      'auto_lock_time': _autoLockMinutes,
    };
  }

  // Import authentication settings (from backup)
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('biometric_enabled')) {
      await setBiometricEnabled(settings['biometric_enabled'] as bool);
    }
    if (settings.containsKey('auto_lock_time')) {
      await setAutoLockTime(settings['auto_lock_time'] as int);
    }
  }
}

