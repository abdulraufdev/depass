import 'dart:convert';
import 'dart:math' as math;
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
    // More complex obfuscated salt - multiple layers of encoding
    List<int> obfuscatedSalt = [
      0x7B, 0x3F, 0x8C, 0x45, 0x92, 0x6E, 0x1A, 0xD7,
      0x5F, 0xB3, 0x28, 0x94, 0x7E, 0x41, 0xC5, 0x36,
      0x89, 0x2D, 0xF1, 0x65, 0xA8, 0x4C, 0x17, 0xDB,
      0x53, 0x9F, 0x74, 0x21, 0xE6, 0x38, 0xBC, 0x47
    ];

    // Apply multiple transformation layers to obfuscate the salt
    List<int> transformedSalt = obfuscatedSalt.map((byte) {
      // Apply XOR with a rotating key
      int rotatingKey = (byte.hashCode ^ 0xDEADBEEF) & 0xFF;
      return ((byte ^ rotatingKey) - 17 + 256) % 256;
    }).toList();

    // Additional entropy from app-specific constant
    String appSeed = "DepassSecure2024!@#";
    List<int> appSeedBytes = utf8.encode(appSeed);
    
    // Combine transformed salt with app seed
    List<int> finalSalt = [];
    for (int i = 0; i < transformedSalt.length; i++) {
      int combined = (transformedSalt[i] ^ appSeedBytes[i % appSeedBytes.length]) & 0xFF;
      finalSalt.add(combined);
    }

    // Implement PBKDF2 with HMAC-SHA256
    return _pbkdf2(password, Uint8List.fromList(finalSalt), 100000, 32);
  }

  /// PBKDF2 implementation using HMAC-SHA256
  /// [password] - The password to derive key from
  /// [salt] - Salt bytes
  /// [iterations] - Number of iterations (100,000 for security)
  /// [keyLength] - Desired key length in bytes (32 for AES-256)
  encrypt_pkg.Key _pbkdf2(String password, Uint8List salt, int iterations, int keyLength) {
    final passwordBytes = utf8.encode(password);
    final result = Uint8List(keyLength);
    
    // Number of complete blocks needed
    final blocks = (keyLength / 32).ceil();
    
    for (int block = 1; block <= blocks; block++) {
      // Create the block input: salt + block number (big-endian)
      final blockInput = Uint8List(salt.length + 4);
      blockInput.setRange(0, salt.length, salt);
      blockInput[salt.length] = (block >> 24) & 0xFF;
      blockInput[salt.length + 1] = (block >> 16) & 0xFF;
      blockInput[salt.length + 2] = (block >> 8) & 0xFF;
      blockInput[salt.length + 3] = block & 0xFF;
      
      // First iteration: HMAC(password, salt + block)
      var hmac = Hmac(sha256, passwordBytes);
      var u = hmac.convert(blockInput).bytes;
      var resultBlock = Uint8List.fromList(u);
      
      // Subsequent iterations: HMAC(password, previous_result)
      for (int i = 1; i < iterations; i++) {
        hmac = Hmac(sha256, passwordBytes);
        u = hmac.convert(u).bytes;
        
        // XOR with result block
        for (int j = 0; j < resultBlock.length; j++) {
          resultBlock[j] ^= u[j];
        }
      }
      
      // Copy the block to the final result
      final start = (block - 1) * 32;
      final end = math.min(start + 32, keyLength);
      result.setRange(start, end, resultBlock);
    }
    
    return encrypt_pkg.Key(result);
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
    final random = math.Random.secure();
    final iv = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(iv);
  }

  // Generate random key
  String generateRandomKey(AESKeyLength keyLength) {
    final random = math.Random.secure();
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

