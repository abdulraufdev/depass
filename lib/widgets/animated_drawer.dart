import 'package:depass/utils/constants.dart';
import 'package:flutter/cupertino.dart';

class AnimatedDrawer extends StatefulWidget {
  final Widget child;
  final Widget drawer;
  final double drawerWidth;

  const AnimatedDrawer({
    super.key,
    required this.child,
    required this.drawer,
    this.drawerWidth = 300,
  });

  @override
  State<AnimatedDrawer> createState() => AnimatedDrawerState();
}

class AnimatedDrawerState extends State<AnimatedDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _mainScreenSlideAnimation;
  late Animation<double> _drawerSlideAnimation;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _setupAnimations();
  }

  void _setupAnimations() {
    // Main screen slides from left (0) to right (drawerWidth)
    _mainScreenSlideAnimation = Tween<double>(begin: 0, end: widget.drawerWidth)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
        );

    // Drawer slides from left (-drawerWidth) to its position (0)
    _drawerSlideAnimation = Tween<double>(begin: -widget.drawerWidth, end: 0)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
        );
  }

  @override
  void didUpdateWidget(AnimatedDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drawerWidth != widget.drawerWidth) {
      _setupAnimations();
    }
  }

  void toggle() {
    if (_isOpen) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    _isOpen = !_isOpen;
  }

  void open() {
    _controller.forward();
    _isOpen = true;
  }

  void close() {
    _controller.reverse();
    _isOpen = false;
  }

  bool get isOpen => _isOpen;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Drawer with slide animation from left
            Transform.translate(
              offset: Offset(_drawerSlideAnimation.value, 0),
              child: SizedBox(width: widget.drawerWidth, child: widget.drawer),
            ),

            // Main content with slide animation to right
            Transform.translate(
              offset: Offset(_mainScreenSlideAnimation.value, 0),
              child: GestureDetector(
                onTap: _isOpen ? close : null,
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 0 && !_isOpen) {
                    _controller.value += details.delta.dx / widget.drawerWidth;
                  } else if (details.delta.dx < 0 && _isOpen) {
                    _controller.value += details.delta.dx / widget.drawerWidth;
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (_controller.value > 0.5) {
                    open();
                  } else {
                    close();
                  }
                },
                child: Stack(
                  children: [
                    widget.child,
                    // Dark overlay when drawer is open
                    IgnorePointer(
                      ignoring: _controller.value == 0,
                      child: Container(
                        color: DepassConstants.isDarkMode
                            ? CupertinoColors.white.withValues(
                                alpha: 0.2 * _controller.value,
                              )
                            : CupertinoColors.black.withValues(
                                alpha: 0.5 * _controller.value,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
