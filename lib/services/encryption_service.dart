import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

enum DepassAESMode { gcm, cbc, ctr }

enum AESKeyLength { key128, key192, key256 }

enum AESPadding { pkcs7, noPadding }

class EncryptionResult {
  final String encryptedText;
  final String? iv;
  final String? tag;

  EncryptionResult({required this.encryptedText, this.iv, this.tag});
}

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late encrypt_pkg.Encrypter _encrypter;
  late encrypt_pkg.IV _iv;
  bool _isInitialized = false;

  // Original password manager methods
  void initialize(String masterPassword) {
    // Generate key from master password using PBKDF2
    final key = _deriveKey(masterPassword);
    _encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key));
    _iv = encrypt_pkg.IV.fromSecureRandom(16);
    _isInitialized = true;
  }

  encrypt_pkg.Key _deriveKey(String password) {
    // Use PBKDF2 to derive a key from the master password
    final salt = utf8.encode('keypass_salt'); // In production, use a random salt
    final bytes = utf8.encode(password);
    
    // Simple key derivation (in production, use proper PBKDF2)
    var digest = sha256.convert(bytes + salt);
    for (int i = 0; i < 1000; i++) {
      digest = sha256.convert(digest.bytes);
    }
    
    return encrypt_pkg.Key(Uint8List.fromList(digest.bytes));
  }

  String encrypt(String plainText) {
    if (!_isInitialized) {
      throw Exception('Encryption service not initialized');
    }
    
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedText) {
    if (!_isInitialized) {
      throw Exception('Encryption service not initialized');
    }
    
    final encrypted = encrypt_pkg.Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  void dispose() {
    _isInitialized = false;
  }

  // New comprehensive encryption methods
  
  // Process key to match the specified length
  Uint8List _processKey(String key, AESKeyLength keyLength) {
    final keyBytes = utf8.encode(key);
    int targetLength;

    switch (keyLength) {
      case AESKeyLength.key128:
        targetLength = 16;
        break;
      case AESKeyLength.key192:
        targetLength = 24;
        break;
      case AESKeyLength.key256:
        targetLength = 32;
        break;
    }

    if (keyBytes.length == targetLength) {
      return Uint8List.fromList(keyBytes);
    } else if (keyBytes.length > targetLength) {
      // Truncate if too long
      return Uint8List.fromList(keyBytes.take(targetLength).toList());
    } else {
      // Pad with zeros if too short
      final paddedKey = List<int>.filled(targetLength, 0);
      paddedKey.setRange(0, keyBytes.length, keyBytes);
      return Uint8List.fromList(paddedKey);
    }
  }

  // Generate random IV
  String generateRandomIV() {
    final random = Random.secure();
    final iv = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(iv);
  }

  // Generate random key
  String generateRandomKey(AESKeyLength keyLength) {
    final random = Random.secure();
    int length;
    
    switch (keyLength) {
      case AESKeyLength.key128:
        length = 16;
        break;
      case AESKeyLength.key192:
        length = 24;
        break;
      case AESKeyLength.key256:
        length = 32;
        break;
    }
    
    final key = List<int>.generate(length, (i) => random.nextInt(256));
    return base64.encode(key);
  }

  // Convert custom AES mode to encrypt package mode
  encrypt_pkg.AESMode _convertToEncryptMode(DepassAESMode mode) {
    switch (mode) {
      case DepassAESMode.gcm:
        return encrypt_pkg.AESMode.gcm;
      case DepassAESMode.cbc:
        return encrypt_pkg.AESMode.cbc;
      case DepassAESMode.ctr:
        return encrypt_pkg.AESMode.ctr;
    }
  }

  // Encrypt text with advanced options
  Future<EncryptionResult> encryptTextAdvanced({
    required String plaintext,
    required String encryptionKey,
    required DepassAESMode mode,
    required AESKeyLength keyLength,
    String? initializationVector,
  }) async {
    try {
      final keyBytes = _processKey(encryptionKey, keyLength);
      final key = encrypt_pkg.Key(keyBytes);
      
      // Use provided IV or generate a new one
      final ivString = initializationVector ?? generateRandomIV();
      final ivBytes = base64.decode(ivString);
      final iv = encrypt_pkg.IV(ivBytes);

      final encryptMode = _convertToEncryptMode(mode);
      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encryptMode));

      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      return EncryptionResult(
        encryptedText: encrypted.base64,
        iv: ivString,
      );
    } catch (e) {
      throw Exception('Encryption failed: ${e.toString()}');
    }
  }

  // Decrypt text with advanced options
  Future<String> decryptTextAdvanced({
    required String ciphertext,
    required String encryptionKey,
    required DepassAESMode mode,
    required AESKeyLength keyLength,
    required String initializationVector,
  }) async {
    try {
      final keyBytes = _processKey(encryptionKey, keyLength);
      final key = encrypt_pkg.Key(keyBytes);
      final ivBytes = base64.decode(initializationVector);
      final iv = encrypt_pkg.IV(ivBytes);

      final encryptMode = _convertToEncryptMode(mode);
      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encryptMode));

      final encrypted = encrypt_pkg.Encrypted.fromBase64(ciphertext);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  // Validate IV format
  bool isValidIV(String iv) {
    try {
      final decoded = base64.decode(iv);
      return decoded.length == 16;
    } catch (e) {
      return false;
    }
  }

  // Validate key format for given length
  bool isValidKey(String key, AESKeyLength keyLength) {
    if (key.isEmpty) return false;
    
    // Check if it's base64 encoded
    try {
      final decoded = base64.decode(key);
      int expectedLength;
      switch (keyLength) {
        case AESKeyLength.key128:
          expectedLength = 16;
          break;
        case AESKeyLength.key192:
          expectedLength = 24;
          break;
        case AESKeyLength.key256:
          expectedLength = 32;
          break;
      }
      return decoded.length == expectedLength;
    } catch (e) {
      // If not base64, check if it's a regular string that can be processed
      return key.isNotEmpty;
    }
  }

  // Get key length description
  String getKeyLengthDescription(AESKeyLength keyLength) {
    switch (keyLength) {
      case AESKeyLength.key128:
        return '128-bit (16 bytes)';
      case AESKeyLength.key192:
        return '192-bit (24 bytes)';
      case AESKeyLength.key256:
        return '256-bit (32 bytes)';
    }
  }

  // Get mode description
  String getModeDescription(DepassAESMode mode) {
    switch (mode) {
      case DepassAESMode.gcm:
        return 'GCM (Galois/Counter Mode)';
      case DepassAESMode.cbc:
        return 'CBC (Cipher Block Chaining)';
      case DepassAESMode.ctr:
        return 'CTR (Counter Mode)';
    }
  }
}

