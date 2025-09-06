import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late Encrypter _encrypter;
  late IV _iv;
  bool _isInitialized = false;

  void initialize(String masterPassword) {
    // Generate key from master password using PBKDF2
    final key = _deriveKey(masterPassword);
    _encrypter = Encrypter(AES(key));
    _iv = IV.fromSecureRandom(16);
    _isInitialized = true;
  }

  Key _deriveKey(String password) {
    // Use PBKDF2 to derive a key from the master password
    final salt = utf8.encode('keypass_salt'); // In production, use a random salt
    final bytes = utf8.encode(password);
    
    // Simple key derivation (in production, use proper PBKDF2)
    var digest = sha256.convert(bytes + salt);
    for (int i = 0; i < 1000; i++) {
      digest = sha256.convert(digest.bytes);
    }
    
    return Key(Uint8List.fromList(digest.bytes));
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
    
    final encrypted = Encrypted.fromBase64(encryptedText);
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
}

