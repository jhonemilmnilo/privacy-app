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

  /// Toggle privacy shade ON and OFF
  Future<void> _togglePrivacyShield() async {
    final nextState = !_isShieldActive;
    setState(() {
      _isShieldActive = nextState;
    });

    if (nextState) {
      // SHIELD ON: Expand window to full screen with clickThrough flag
      // so touches on underlying apps pass right through!
      await FlutterOverlayWindow.resizeOverlay(
        WindowSize.matchParent,
        WindowSize.matchParent,
        false,
      );
      await FlutterOverlayWindow.updateFlag(OverlayFlag.clickThrough);
    } else {
      // SHIELD OFF: Shrink window back to compact interactive bubble!
      final int size = _bubbleSize.toInt() + 16;
      await FlutterOverlayWindow.resizeOverlay(size, size, false);
      await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _isShieldActive ? _buildShieldOverlay() : _buildCompactBubble(),
    );
  }

  /// 1. COMPACT BUBBLE (IDLE MODE)
  /// Sized strictly to the bubble - zero blocking of underlying apps!
  Widget _buildCompactBubble() {
    return Center(
      child: GestureDetector(
        onTap: _togglePrivacyShield,
        child: Container(
          width: _bubbleSize,
          height: _bubbleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                blurRadius: 14,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2.2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: _bubbleSize * 0.48,
            ),
          ),
        ),
      ),
    );
  }

  /// 2. PRIVACY SHIELD (ACTIVE MODE)
  /// Full-screen dim tint with status-bar cutout and a floating Quick-Dismiss toggle!
  Widget _buildShieldOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top > 0 
        ? MediaQuery.of(context).padding.top 
        : 36.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Privacy Tint starting strictly BELOW the status bar, covering full bottom
        Positioned(
          top: statusBarHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: _mode == 'dim'
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: _tintColor.withValues(alpha: _opacity),
                )
              : Column(
                  children: [
                    Expanded(child: Container(color: _tintColor.withValues(alpha: _opacity))),
                    Container(
                      height: _slitHeight.clamp(80.0, screenSize.height * 0.35),
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
                    Expanded(child: Container(color: _tintColor.withValues(alpha: _opacity))),
                  ],
                ),
        ),

        // Floating Active Dismiss Bubble (Positioned conveniently on right edge)
        Positioned(
          right: 16,
          top: statusBarHeight + 20,
          child: GestureDetector(
            onTap: _togglePrivacyShield,
            child: Container(
              width: _bubbleSize,
              height: _bubbleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.6),
                    blurRadius: 16,
                    spreadRadius: 3,
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2.2),
              ),
              child: Center(
                child: Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: _bubbleSize * 0.48,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
