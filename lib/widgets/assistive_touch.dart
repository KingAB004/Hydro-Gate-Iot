import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'chatbot_modal.dart';

class AssistiveTouch extends StatefulWidget {
  final Widget child;

  const AssistiveTouch({super.key, required this.child});

  @override
  State<AssistiveTouch> createState() => _AssistiveTouchState();
}

class _AssistiveTouchState extends State<AssistiveTouch>
    with SingleTickerProviderStateMixin {
  // Position (bottom-right by default)
  double _xPos = -1; // -1 means not initialized
  double _yPos = -1;
  bool _isDragging = false;
  bool _isPressed = false;

  // Button dimensions
  static const double _buttonSize = 52.0;
  static const double _edgePadding = 16.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initPosition(Size screenSize) {
    if (_xPos < 0 || _yPos < 0) {
      _xPos = screenSize.width - _buttonSize - _edgePadding;
      _yPos = screenSize.height * 0.72;
    }
  }

  void _snapToEdge(Size screenSize) {
    final double centerX = _xPos + _buttonSize / 2;
    final double halfWidth = screenSize.width / 2;

    setState(() {
      if (centerX < halfWidth) {
        // Snap to left
        _xPos = _edgePadding;
      } else {
        // Snap to right
        _xPos = screenSize.width - _buttonSize - _edgePadding;
      }

      // Clamp vertical position
      _yPos = _yPos.clamp(
        _edgePadding + MediaQuery.of(context).padding.top,
        screenSize.height - _buttonSize - _edgePadding - MediaQuery.of(context).padding.bottom - 110,
      );
    });
  }

  void _openChatbot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatbotModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _initPosition(screenSize);

    return Stack(
      children: [
        // Main content
        widget.child,

        // Assistive Touch Button
        Positioned(
          left: _xPos,
          top: _yPos,
          child: GestureDetector(
            onPanStart: (_) {
              setState(() => _isDragging = true);
            },
            onPanUpdate: (details) {
              setState(() {
                _xPos += details.delta.dx;
                _yPos += details.delta.dy;

                // Keep within screen bounds
                _xPos = _xPos.clamp(0, screenSize.width - _buttonSize);
                _yPos = _yPos.clamp(
                  MediaQuery.of(context).padding.top,
                  screenSize.height - _buttonSize - MediaQuery.of(context).padding.bottom - 110,
                );
              });
            },
            onPanEnd: (_) {
              _isDragging = false;
              _snapToEdge(screenSize);
            },
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              if (!_isDragging) _openChatbot();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final glowOpacity = 0.15 + (_pulseAnimation.value * 0.15);
                return AnimatedScale(
                  scale: _isPressed ? 0.88 : (_isDragging ? 1.1 : 1.0),
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedOpacity(
                    opacity: _isDragging ? 0.85 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: _buttonSize,
                      height: _buttonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          // Outer glow
                          BoxShadow(
                            color: const Color(0xFF007EAA).withOpacity(glowOpacity),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                          // Drop shadow
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF007EAA).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: SvgPicture.string(
                            '''
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                              <path d="M12 2L4 5V11C4 16.19 7.41 21.05 12 22C16.59 21.05 20 16.19 20 11V5L12 2Z" fill="#007EAA" fill-opacity="0.15" stroke="#007EAA" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                              <path d="M12 17C13.6569 17 15 15.6569 15 14C15 12 12 9 12 9C12 9 9 12 9 14C9 15.6569 10.3431 17 12 17Z" fill="#007EAA"/>
                            </svg>
                            ''',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
