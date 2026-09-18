import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayEntryPoint extends StatefulWidget {
  const OverlayEntryPoint({super.key});

  @override
  State<OverlayEntryPoint> createState() => _OverlayEntryPointState();
}

class _OverlayEntryPointState extends State<OverlayEntryPoint> {
  // Privacy Shield State
  bool _isShieldActive = false;
  double _opacity = 0.75;
  String _mode = 'dim'; // 'dim' or 'slit'
  Color _tintColor = Colors.black;
  double _slitHeight = 130.0;
  double _bubbleSize = 58.0;

  // Responsive bubble coordinates (default: right side of screen)
  double _bubbleX = 300.0;
  double _bubbleY = 250.0;
  bool _isInitialPositionSet = false;

  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for real-time config updates from HomeScreen
    _dataSubscription = FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        setState(() {
          if (event['action'] == 'CONFIG_UPDATE') {
            _opacity = (event['opacity'] as num?)?.toDouble() ?? _opacity;
            _mode = event['mode'] as String? ?? _mode;
            final int? colorInt = event['colorValue'] as int?;
            if (colorInt != null) {
              _tintColor = Color(colorInt);
            }
            _slitHeight = (event['slitHeight'] as num?)?.toDouble() ?? _slitHeight;
            _bubbleSize = (event['bubbleSize'] as num?)?.toDouble() ?? _bubbleSize;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  /// Toggle privacy shade ON/OFF while KEEPING the bubble interactive
  Future<void> _togglePrivacyShield() async {
    setState(() {
      _isShieldActive = !_isShieldActive;
    });

    if (_isShieldActive) {
      // Keep touch modal / focus pointer so bubble ALWAYS captures touches
      await FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
    } else {
      await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top > 0 
        ? MediaQuery.of(context).padding.top 
        : 36.0; // fallback standard status bar height

    // Initialize responsive bubble position once screen size is known
    if (!_isInitialPositionSet && screenSize.width > 0) {
      _bubbleX = screenSize.width - _bubbleSize - 16.0;
      _bubbleY = screenSize.height * 0.35;
      _isInitialPositionSet = true;
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. PRIVACY SHIELD LAYER (Dim Shade / Reading Slit)
          // Starts strictly BELOW the status bar and extends all the way to the very bottom
          if (_isShieldActive)
            Positioned(
              top: statusBarHeight,
              left: 0,
              right: 0,
              bottom: -40.0, // Extend past navigation insets to cover 100% of bottom screen
              child: IgnorePointer(
                ignoring: true, // Touches on the shade pass through
                child: _buildShieldContent(screenSize, statusBarHeight),
              ),
            ),

          // 2. PERSISTENT FLOATING ASSISTIVE BUBBLE
          // Positioned on top, draggable, and tappable at all times
          Positioned(
            left: _bubbleX,
            top: _bubbleY,
            child: _buildAssistiveBubble(screenSize, statusBarHeight),
          ),
        ],
      ),
    );
  }

  /// Builds the Privacy Filter (Full Dim or Reading Slit)
  Widget _buildShieldContent(Size screenSize, double statusBarHeight) {
    if (_mode == 'dim') {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: _tintColor.withValues(alpha: _opacity),
      );
    } else {
      // Reading Slit Mode: Top blackout + Clear viewing window + Bottom blackout
      final responsiveSlitHeight = _slitHeight.clamp(80.0, screenSize.height * 0.35);
      return Column(
        children: [
          // Top dark area
          Expanded(
            child: Container(
              color: _tintColor.withValues(alpha: _opacity),
            ),
          ),
          // Clear viewing slot (allows dead-center reading of message/bank balance)
          Container(
            height: responsiveSlitHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Colors.cyanAccent.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Bottom dark area
          Expanded(
            child: Container(
              color: _tintColor.withValues(alpha: _opacity),
            ),
          ),
        ],
      );
    }
  }

  /// Builds the Assistive Touch Bubble with drag physics & active state glow
  Widget _buildAssistiveBubble(Size screenSize, double statusBarHeight) {
    return GestureDetector(
      onTap: _togglePrivacyShield,
      onPanUpdate: (details) {
        setState(() {
          _bubbleX += details.delta.dx;
          _bubbleY += details.delta.dy;

          // Responsive clamping to keep bubble safely within phone screen bounds
          _bubbleX = _bubbleX.clamp(8.0, (screenSize.width - _bubbleSize - 8.0).clamp(0.0, screenSize.width));
          _bubbleY = _bubbleY.clamp(statusBarHeight + 8.0, (screenSize.height - _bubbleSize - 16.0).clamp(0.0, screenSize.height));
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: _bubbleSize,
        height: _bubbleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: _isShieldActive
                ? [const Color(0xFF10B981), const Color(0xFF059669)] // Green glow when ACTIVE
                : [const Color(0xFF6366F1), const Color(0xFF3B82F6)], // Indigo/Blue when IDLE
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isShieldActive ? const Color(0xFF10B981) : const Color(0xFF6366F1))
                  .withValues(alpha: _isShieldActive ? 0.6 : 0.4),
              blurRadius: _isShieldActive ? 18 : 12,
              spreadRadius: _isShieldActive ? 3 : 1,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 2.0,
          ),
        ),
        child: Center(
          child: Icon(
            _isShieldActive ? Icons.shield : Icons.shield_outlined,
            color: Colors.white,
            size: _bubbleSize * 0.48, // Proportionally scales icon with bubble size
          ),
        ),
      ),
    );
  }
}
