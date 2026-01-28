import 'dart:math';

import 'package:depass/theme/text_theme.dart';
import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GeneratePasswordScreen extends StatefulWidget {
  const GeneratePasswordScreen({super.key});

  @override
  State<GeneratePasswordScreen> createState() => _GeneratePasswordScreenState();
}

class _GeneratePasswordScreenState extends State<GeneratePasswordScreen>
    with SingleTickerProviderStateMixin {
  double maxChars = 16;
  late String password;
  late AnimationController _animationController;
  late Animation<double> _sliderAnimation;
  bool _isDragging = false;

  // Password options
  bool _includeLowercase = true;
  bool _includeUppercase = true;
  bool _includeNumbers = true;
  bool _includeSpecialChars = true;

  static const String _uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numberChars = '0123456789';
  static const String _specialChars = '!@#\$%^&*()_+-=[]{}|;:.<>?';

  String _generatePassword(int length) {
    String chars = '';
    if (_includeLowercase) chars += _lowercaseChars;
    if (_includeUppercase) chars += _uppercaseChars;
    if (_includeNumbers) chars += _numberChars;
    if (_includeSpecialChars) chars += _specialChars;

    if (chars.isEmpty) {
      chars = _lowercaseChars; // Fallback to lowercase if nothing selected
    }

    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  @override
  void initState() {
    super.initState();
    password = _generatePassword(16);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sliderAnimation = Tween<double>(begin: maxChars, end: maxChars).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateSliderValue(double newValue) {
    final clampedValue = newValue.clamp(8.0, 32.0);
    if (!_isDragging) {
      _sliderAnimation = Tween<double>(begin: maxChars, end: clampedValue)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          );
      _animationController.forward(from: 0).then((_) {
        setState(() {
          maxChars = clampedValue;
          password = _generatePassword(clampedValue.toInt());
        });
      });
    } else {
      setState(() {
        maxChars = clampedValue;
        password = _generatePassword(clampedValue.toInt());
      });
    }
  }

  double _getSliderValueFromPosition(double localX, double sliderWidth) {
    final ratio = (localX / sliderWidth).clamp(0.0, 1.0);
    return 8.0 + (ratio * (32.0 - 8.0));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(transitionBetweenRoutes: false),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            Text('Generate a secure password', style: DepassTextTheme.heading1),
            Container(
              decoration: BoxDecoration(
                color: DepassConstants.isDarkMode
                    ? DepassConstants.darkFadedBackground
                    : DepassConstants.lightFadedBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.only(left: 16),
              child: SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          password,
                          softWrap: true,
                          style: DepassTextTheme.heading3,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: CupertinoButton.tinted(
                        child: Icon(LucideIcons.refreshCcw, size: 24),
                        onPressed: () {
                          setState(() {
                            password = _generatePassword(maxChars.toInt());
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (details) {
                          final newValue = _getSliderValueFromPosition(
                            details.localPosition.dx,
                            constraints.maxWidth,
                          );
                          _updateSliderValue(newValue);
                        },
                        onPanStart: (details) {
                          _isDragging = true;
                          final newValue = _getSliderValueFromPosition(
                            details.localPosition.dx,
                            constraints.maxWidth,
                          );
                          _updateSliderValue(newValue);
                        },
                        onPanUpdate: (details) {
                          final newValue = _getSliderValueFromPosition(
                            details.localPosition.dx,
                            constraints.maxWidth,
                          );
                          _updateSliderValue(newValue);
                        },
                        onPanEnd: (details) {
                          _isDragging = false;
                        },
                        child: AnimatedBuilder(
                          animation: _sliderAnimation,
                          builder: (context, child) {
                            final currentValue = _isDragging
                                ? maxChars
                                : _sliderAnimation.value;
                            return CupertinoSlider(
                              divisions: 3,
                              value: currentValue,
                              min: 8,
                              max: 32,
                              onChanged: (value) {
                                _isDragging = true;
                                _updateSliderValue(value);
                              },
                              onChangeEnd: (value) {
                                _isDragging = false;
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('8', style: DepassTextTheme.caption),
                      Text('16', style: DepassTextTheme.caption),
                      Text('24', style: DepassTextTheme.caption),
                      Text('32', style: DepassTextTheme.caption),
                    ],
                  ),
                ),
              ],
            ),
            // Password Options
            Column(
              children: [
                _buildOptionRow('Lowercase Letters (a-z)', _includeLowercase, (
                  value,
                ) {
                  setState(() {
                    _includeLowercase = value;
                    password = _generatePassword(maxChars.toInt());
                  });
                }),
                _buildOptionRow('Uppercase Letters (A-Z)', _includeUppercase, (
                  value,
                ) {
                  setState(() {
                    _includeUppercase = value;
                    password = _generatePassword(maxChars.toInt());
                  });
                }),
                _buildOptionRow('Numbers (0-9)', _includeNumbers, (value) {
                  setState(() {
                    _includeNumbers = value;
                    password = _generatePassword(maxChars.toInt());
                  });
                }),
                _buildOptionRow(
                  'Special Characters (!@#\$%...)',
                  _includeSpecialChars,
                  (value) {
                    setState(() {
                      _includeSpecialChars = value;
                      password = _generatePassword(maxChars.toInt());
                    });
                  },
                ),
              ],
            ),
            CupertinoButton.filled(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Icon(
                    LucideIcons.copy,
                    size: 20,
                    color: DepassConstants.isDarkMode
                        ? DepassConstants.darkButtonText
                        : DepassConstants.lightButtonText,
                  ),
                  Text('Copy to Clipboard', style: DepassTextTheme.button),
                ],
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: password));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: DepassTextTheme.paragraph)),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: DepassConstants.isDarkMode
                ? DepassConstants.darkDropdownButton
                : DepassConstants.lightPrimary,
          ),
        ],
      ),
    );
  }
}
