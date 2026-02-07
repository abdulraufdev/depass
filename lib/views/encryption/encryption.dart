import 'package:depass/services/encryption_service.dart';
import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum EncryptionMode { encrypt, decrypt }

class EncryptionScreen extends StatefulWidget {
  const EncryptionScreen({super.key});

  @override
  State<EncryptionScreen> createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  final EncryptionService _encryptionService = EncryptionService();

  // Controllers
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _ivController = TextEditingController();

  // State variables
  EncryptionMode _mode = EncryptionMode.encrypt;
  DepassAESMode _aesMode = DepassAESMode.gcm;
  AESKeyLength _keyLength = AESKeyLength.key256;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _keyController.dispose();
    _ivController.dispose();
    super.dispose();
  }

  void _generateRandomKey() {
    final key = _encryptionService.generateRandomKey(_keyLength);
    _keyController.text = key;
    setState(() {
      _errorMessage = null;
    });
  }

  void _generateRandomIV() {
    final iv = _encryptionService.generateRandomIV();
    _ivController.text = iv;
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _processText() async {
    if (_inputController.text.isEmpty) {
      setState(() {
        _errorMessage =
            'Please enter text to ${_mode == EncryptionMode.encrypt ? 'encrypt' : 'decrypt'}';
      });
      return;
    }

    if (_keyController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an encryption key';
      });
      return;
    }

    if (_mode == EncryptionMode.decrypt && _ivController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an initialization vector for decryption';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_mode == EncryptionMode.encrypt) {
        final result = await _encryptionService.encryptTextAdvanced(
          plaintext: _inputController.text,
          encryptionKey: _keyController.text,
          mode: _aesMode,
          keyLength: _keyLength,
          initializationVector: _ivController.text.isEmpty
              ? null
              : _ivController.text,
        );

        _outputController.text = result.encryptedText;
        if (result.iv != null && _ivController.text.isEmpty) {
          _ivController.text = result.iv!;
        }

        setState(() {
          _successMessage = 'Text encrypted successfully!';
        });
      } else {
        final decrypted = await _encryptionService.decryptTextAdvanced(
          ciphertext: _inputController.text,
          encryptionKey: _keyController.text,
          mode: _aesMode,
          keyLength: _keyLength,
          initializationVector: _ivController.text,
        );

        _outputController.text = decrypted;
        setState(() {
          _successMessage = 'Text decrypted successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _successMessage = 'Copied to clipboard!';
    });

    // Clear success message after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _successMessage = null;
        });
      }
    });
  }

  void _clearFields() {
    _inputController.clear();
    _outputController.clear();
    _keyController.clear();
    _ivController.clear();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: DepassConstants.isDarkMode
            ? DepassConstants.darkBarBackground
            : DepassConstants.lightBarBackground,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showEncryptionInfoDialog,
          child: Icon(
            LucideIcons.circleQuestionMark,
            color: DepassConstants.isDarkMode
                ? DepassConstants.darkText
                : DepassConstants.lightText,
            size: 20,
          ),
        ),
      ),
      backgroundColor: DepassConstants.isDarkMode
          ? DepassConstants.darkBackground
          : DepassConstants.lightBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    'Text Encryption',
                    style: DepassTextTheme.heading1,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Mode Selection
              _buildSectionTitle('Mode'),
              const SizedBox(height: 8),
              CupertinoSlidingSegmentedControl<EncryptionMode>(
                groupValue: _mode,
                backgroundColor: DepassConstants.isDarkMode
                    ? DepassConstants.darkFadedBackground
                    : DepassConstants.lightFadedBackground,
                children: {
                  EncryptionMode.encrypt: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Encrypt'),
                  ),
                  EncryptionMode.decrypt: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Decrypt',
                      style: TextStyle(
                        color: DepassConstants.isDarkMode
                            ? DepassConstants.darkText
                            : DepassConstants.lightText,
                      ),
                    ),
                  ),
                },
                onValueChanged: (value) {
                  setState(() {
                    _mode = value!;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                },
              ),

              const SizedBox(height: 24),

              _buildTextArea(
                _inputController,
                'Enter ${_mode == EncryptionMode.encrypt ? 'plain' : 'encrypted'} text...',
              ),

              const SizedBox(height: 16),

              // Configuration Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Configuration'),
                  const SizedBox(height: 12),

                  // AES Mode
                  _buildConfigRow(
                    'AES Mode',
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: DepassConstants.isDarkMode
                          ? DepassConstants.darkDropdownButton
                          : DepassConstants.lightDropdownButton,
                      onPressed: () => _showModePicker(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _encryptionService.getModeDescription(_aesMode),
                            style: TextStyle(
                              color: DepassConstants.isDarkMode
                                  ? DepassConstants.darkText
                                  : DepassConstants.lightText,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronDown,
                            size: 16,
                            color: DepassConstants.isDarkMode
                                ? DepassConstants.darkText
                                : DepassConstants.lightText,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Key Length
                  _buildConfigRow(
                    'Key Length',
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: DepassConstants.isDarkMode
                          ? DepassConstants.darkDropdownButton
                          : DepassConstants.lightDropdownButton,
                      onPressed: () => _showKeyLengthPicker(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _encryptionService.getKeyLengthDescription(
                              _keyLength,
                            ),
                            style: TextStyle(
                              color: DepassConstants.isDarkMode
                                  ? DepassConstants.darkText
                                  : DepassConstants.lightText,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronDown,
                            size: 16,
                            color: DepassConstants.isDarkMode
                                ? DepassConstants.darkText
                                : DepassConstants.lightText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Encryption Key
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_keyController, 'Encryption key...'),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkFadedBackground
                        : DepassConstants.lightFadedBackground,
                    onPressed: _generateRandomKey,
                    child: Icon(
                      LucideIcons.dices,
                      size: 16,
                      color: DepassConstants.isDarkMode
                          ? DepassConstants.darkText
                          : DepassConstants.lightText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Initialization Vector
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _ivController,
                      'Initialization Vector (IV)...',
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkFadedBackground
                        : DepassConstants.lightFadedBackground,
                    onPressed: _generateRandomIV,
                    child: Icon(
                      LucideIcons.dices,
                      size: 16,
                      color: DepassConstants.isDarkMode
                          ? DepassConstants.darkText
                          : DepassConstants.lightText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Process Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isProcessing ? null : _processText,
                  child: _isProcessing
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : Text(
                          _mode == EncryptionMode.encrypt
                              ? 'Encrypt'
                              : 'Decrypt',
                          style: TextStyle(
                            color: DepassConstants.isDarkMode
                                ? DepassConstants.darkButtonText
                                : DepassConstants.lightButtonText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Output Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Output'),
                  SizedBox(height: 8, width: double.infinity),
                  _outputController.text.isEmpty
                      ? Text(
                          'Output will appear here...',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        )
                      : Text(_outputController.text),
                  SizedBox(height: 16, width: double.infinity),
                  CupertinoButton.tinted(
                    onPressed: _clearFields,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Icon(LucideIcons.eraser, size: 20),
                        Text("Clear all fields", style: DepassTextTheme.label),
                      ],
                    ),
                  ),
                  if (_outputController.text.isNotEmpty) ...[
                    SizedBox(width: 8),
                    CupertinoButton(
                      alignment: AlignmentGeometry.center,
                      color: DepassConstants.isDarkMode
                          ? DepassConstants.darkFadedBackground
                          : DepassConstants.lightFadedBackground,
                      padding: const EdgeInsets.all(12),
                      onPressed: () => _copyToClipboard(_outputController.text),
                      child: Row(
                        spacing: 4,
                        children: [Icon(LucideIcons.copy), Text('Copy')],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Error/Success Messages
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoColors.systemRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.x,
                        color: CupertinoColors.systemRed,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_successMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoColors.systemGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.check,
                        color: CupertinoColors.systemGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: CupertinoColors.systemGreen,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: DepassConstants.isDarkMode
            ? DepassConstants.darkText
            : DepassConstants.lightText,
      ),
    );
  }

  Widget _buildConfigRow(String label, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: DepassConstants.isDarkMode
                  ? DepassConstants.darkText
                  : DepassConstants.lightText,
            ),
          ),
          control,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      style: TextStyle(
        color: DepassConstants.isDarkMode
            ? DepassConstants.darkText
            : DepassConstants.lightText,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DepassConstants.isDarkMode
              ? DepassConstants.darkSeparator
              : DepassConstants.lightSeparator,
        ),
      ),
      padding: const EdgeInsets.all(12),
    );
  }

  Widget _buildTextArea(
    TextEditingController controller,
    String placeholder, {
    bool readOnly = false,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: 4,
      readOnly: readOnly,
      style: TextStyle(
        color: DepassConstants.isDarkMode
            ? DepassConstants.darkText
            : DepassConstants.lightText,
      ),
      decoration: BoxDecoration(
        color: DepassConstants.isDarkMode
            ? DepassConstants.darkFadedBackground
            : DepassConstants.lightFadedBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DepassConstants.isDarkMode
              ? DepassConstants.darkSeparator
              : DepassConstants.lightSeparator,
        ),
      ),
      padding: const EdgeInsets.all(12),
    );
  }

  void _showModePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text(
            'Select AES Mode',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          actions: DepassAESMode.values.map((mode) {
            return CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _aesMode = mode;
                });
                Navigator.pop(context);
              },
              child: Text(
                _encryptionService.getModeDescription(mode),
                style: DepassTextTheme.dropdown,
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter')),
          ),
        );
      },
    );
  }

  void _showKeyLengthPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text(
            'Select Key Length',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          actions: AESKeyLength.values.map((length) {
            return CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _keyLength = length;
                });
                Navigator.pop(context);
              },
              child: Text(
                _encryptionService.getKeyLengthDescription(length),
                style: DepassTextTheme.dropdown,
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter')),
          ),
        );
      },
    );
  }

  void _showEncryptionInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _EncryptionInfoDialog(),
    );
  }
}

class _EncryptionInfoDialog extends StatefulWidget {
  const _EncryptionInfoDialog();

  @override
  State<_EncryptionInfoDialog> createState() => _EncryptionInfoDialogState();
}

class _EncryptionInfoDialogState extends State<_EncryptionInfoDialog> {
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
                Text(
                  'Text Encryption Tools',
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
                  'Encrypt or decrypt any text using AES encryption. Your data is processed locally on your device and never sent to any server.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkText.withValues(alpha: 0.7)
                        : DepassConstants.lightText.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Features
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkFadedBackground
                        : DepassConstants.lightFadedBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureRow(
                        LucideIcons.lock,
                        'AES-256 encryption standard',
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureRow(
                        LucideIcons.shuffle,
                        'Multiple AES modes (GCM, CBC, CTR)',
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureRow(
                        LucideIcons.key,
                        'Generate secure random keys & IVs',
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureRow(
                        LucideIcons.wifiOff,
                        '100% offline processing',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Got it Button
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
                    child: Text('Got it', style: DepassTextTheme.button),
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
