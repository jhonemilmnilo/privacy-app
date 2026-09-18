import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayEntryPoint extends StatefulWidget {
  const OverlayEntryPoint({super.key});

  @override
  State<OverlayEntryPoint> createState() => _OverlayEntryPointState();
}

class _OverlayEntryPointState extends State<OverlayEntryPoint> {
  // State for privacy shield configuration
  bool _isShieldMode = false;
  double _opacity = 0.75;
  String _mode = 'dim'; // 'dim' or 'slit'
  Color _tintColor = Colors.black;
  double _slitHeight = 120.0;

  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for data coming from the main app
    _dataSubscription = FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        setState(() {
          if (event['action'] == 'CONFIG_UPDATE') {
            _isShieldMode = true;
            _opacity = (event['opacity'] as num?)?.toDouble() ?? _opacity;
            _mode = event['mode'] as String? ?? _mode;
            final int? colorInt = event['colorValue'] as int?;
            if (colorInt != null) {
              _tintColor = Color(colorInt);
            }
            _slitHeight = (event['slitHeight'] as num?)?.toDouble() ?? _slitHeight;
          } else if (event['action'] == 'SHOW_BUBBLE') {
            _isShieldMode = false;
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

  /// Toggle between Assistive Bubble and Privacy Screen
  Future<void> _togglePrivacyShield() async {
    setState(() {
      _isShieldMode = !_isShieldMode;
    });

    if (_isShieldMode) {
      // Resize overlay to fullscreen with touch passthrough
      await FlutterOverlayWindow.resizeOverlay(
        WindowSize.matchParent,
        WindowSize.matchParent,
        true, // enable drag or click through flag
      );
      await FlutterOverlayWindow.updateFlag(OverlayFlag.clickThrough);
    } else {
      // Switch back to floating compact bubble
      await FlutterOverlayWindow.resizeOverlay(160, 160, true);
      await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _isShieldMode ? _buildPrivacyShield() : _buildAssistiveBubble(),
    );
  }

  /// 1. Floating Assistive Touch Bubble
  Widget _buildAssistiveBubble() {
    return Center(
      child: GestureDetector(
        onTap: _togglePrivacyShield,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2.2,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  /// 2. Privacy Screen Shield Overlay (Touch Passthrough)
  Widget _buildPrivacyShield() {
    return Stack(
      children: [
        // Background Tint Layer
        if (_mode == 'dim') ...[
          Container(
            width: double.infinity,
            height: double.infinity,
            color: _tintColor.withValues(alpha: _opacity),
          ),
        ] else if (_mode == 'slit') ...[
          // Reading Slit Mode (Spotlight): Top Dark + Clear Slit + Bottom Dark
          Column(
            children: [
              // Top blackout
              Expanded(
                child: Container(
                  color: _tintColor.withValues(alpha: _opacity),
                ),
              ),
              // Clear viewing slit for reading active message or balance
              Container(
                height: _slitHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Colors.cyanAccent.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Bottom blackout
              Expanded(
                child: Container(
                  color: _tintColor.withValues(alpha: _opacity),
                ),
              ),
            ],
          ),
        ],

        // Floating Mini Exit/Restore Toggle (Top Right)
        Positioned(
          top: 45,
          right: 20,
          child: GestureDetector(
            onTap: _togglePrivacyShield,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_off, color: Colors.cyanAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Tap to Exit Shield',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
