import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/overlay_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _hasPermission = false;
  bool _isOverlayActive = false;
  bool _pendingActivation = false;

  // Settings State
  double _opacity = 0.75;
  String _selectedMode = 'dim'; // 'dim' or 'slit'
  Color _selectedColor = Colors.black;
  final double _slitHeight = 130.0;
  double _bubbleSize = 58.0; // 46.0: Small, 58.0: Medium, 70.0: Large

  final List<Color> _availableColors = [
    Colors.black,
    const Color(0xFF0F172A), // Dark Slate
    const Color(0xFF1E1B4B), // Deep Indigo
    const Color(0xFF1C1917), // Charcoal
    const Color(0xFF2E1065), // Deep Violet
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettingsFromDb();
    _checkStatus();
  }

  Future<void> _loadSettingsFromDb() async {
    final settings = await DatabaseService.instance.getSettings();
    if (mounted) {
      setState(() {
        _opacity = settings.opacity;
        _selectedMode = settings.mode;
        _selectedColor = Color(settings.colorValue);
        _bubbleSize = settings.bubbleSize;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from Android Settings
    if (state == AppLifecycleState.resumed) {
      _checkStatusAndAutoActivate();
    }
  }

  Future<void> _checkStatusAndAutoActivate() async {
    final granted = await OverlayService.isPermissionGranted();
    final active = await OverlayService.isActive();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _isOverlayActive = active;
      });

      // If user attempted to toggle ON and just came back from granting permission
      if (granted && _pendingActivation && !active) {
        _pendingActivation = false;
        await _activateOverlay();
      }
    }
  }

  Future<void> _checkStatus() async {
    final granted = await OverlayService.isPermissionGranted();
    final active = await OverlayService.isActive();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _isOverlayActive = active;
      });
    }
  }

  Future<void> _requestPermission() async {
    _pendingActivation = true;
    final res = await OverlayService.requestPermission();
    if (res == true) {
      _checkStatusAndAutoActivate();
    }
  }

  Future<void> _activateOverlay() async {
    await OverlayService.showFloatingBubble(
      opacity: _opacity,
      mode: _selectedMode,
      colorValue: _selectedColor.toARGB32(),
      slitHeight: _slitHeight,
      bubbleSize: _bubbleSize,
    );
    if (mounted) {
      setState(() => _isOverlayActive = true);
    }
  }

  Future<void> _toggleService() async {
    if (!_hasPermission) {
      _pendingActivation = true;
      await _requestPermission();
      return;
    }

    if (_isOverlayActive) {
      await OverlayService.closeOverlay();
      setState(() => _isOverlayActive = false);
    } else {
      await _activateOverlay();
    }
  }

  void _syncConfigToOverlay() {
    // Save to SQLite
    DatabaseService.instance.saveSettings(
      PrivacySettings(
        opacity: _opacity,
        mode: _selectedMode,
        colorValue: _selectedColor.toARGB32(),
        slitHeight: _slitHeight,
        bubbleSize: _bubbleSize,
      ),
    );

    if (_isOverlayActive) {
      OverlayService.shareData({
        'action': 'CONFIG_UPDATE',
        'opacity': _opacity,
        'mode': _selectedMode,
        'colorValue': _selectedColor.toARGB32(),
        'slitHeight': _slitHeight,
        'bubbleSize': _bubbleSize,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar / Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Privacy Screen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Anti-Peep Jeep & Transit Shield',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                      onPressed: _checkStatus,
                    ),
                  ],
                ),
              ),
            ),

            // Permission Warning Card (if not granted)
            if (!_hasPermission)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          const Color(0xFFD97706).withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Action Required: Overlay Permission',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Para lumutang ang assistive touch bubble over other apps (GCash, Messenger), please enable "Display over other apps".',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _requestPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: const Text(
                            'Grant Permission Now',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Master Activation Toggle Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isOverlayActive
                          ? const Color(0xFF10B981).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (_isOverlayActive)
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isOverlayActive ? const Color(0xFF10B981) : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isOverlayActive ? 'ASSISTIVE TOUCH RUNNING' : 'SERVICE PAUSED',
                                  style: TextStyle(
                                    color: _isOverlayActive ? const Color(0xFF10B981) : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Floating Privacy Bubble',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the floating bubble to instantly shield screen. Status bar remains clear!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isOverlayActive,
                        activeThumbColor: const Color(0xFF10B981),
                        activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                        onChanged: (val) => _toggleService(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Live Simulator / Interactive Preview Box
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIVE SHIELD PREVIEW',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        color: const Color(0xFF182235),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Fake Phone Frame Content
                            Column(
                              children: [
                                // Unaffected Status Bar Header (Simulated)
                                Container(
                                  height: 28,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  color: Colors.black.withValues(alpha: 0.3),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('9:41', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      Row(
                                        children: [
                                          Icon(Icons.wifi, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Icon(Icons.battery_full, color: Colors.greenAccent, size: 14),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Sensitive content area
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'My Savings Account',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'GCash/Bank',
                                                style: TextStyle(color: Colors.cyanAccent, fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          '₱ 185,420.50',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Private message: "Transfer received. Passcode confirmed."',
                                          style: TextStyle(color: Colors.white60, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Applied Privacy Filter Overlay Preview (Starts BELOW status bar!)
                            Positioned(
                              top: 28, // Status bar stays clear
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: _selectedMode == 'dim'
                                  ? Container(
                                      color: _selectedColor.withValues(alpha: _opacity),
                                    )
                                  : Column(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            color: _selectedColor.withValues(alpha: _opacity),
                                          ),
                                        ),
                                        Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            border: Border.symmetric(
                                              horizontal: BorderSide(
                                                color: Colors.cyanAccent.withValues(alpha: 0.8),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              '👁️ Reading Slit Area',
                                              style: TextStyle(
                                                color: Colors.cyanAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            color: _selectedColor.withValues(alpha: _opacity),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),

                            // Floating Bubble Preview inside simulator
                            Positioned(
                              right: 14,
                              top: 70,
                              child: Container(
                                width: _bubbleSize * 0.6,
                                height: _bubbleSize * 0.6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Center(
                                  child: Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mode Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SHIELD TYPE',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModeCard(
                            mode: 'dim',
                            title: 'Full Dim Shade',
                            subtitle: 'Dims screen below status bar',
                            icon: Icons.brightness_medium_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModeCard(
                            mode: 'slit',
                            title: 'Reading Slit',
                            subtitle: 'Blinds all except active slot',
                            icon: Icons.view_headline_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bubble Size Selector Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Assistive Bubble Size',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _bubbleSize <= 48 ? 'Compact (46dp)' : (_bubbleSize >= 68 ? 'Large (70dp)' : 'Standard (58dp)'),
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildSizeOption('Compact', 46.0)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildSizeOption('Standard', 58.0)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildSizeOption('Large', 70.0)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Opacity Darkness Slider
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Protection Darkness',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(_opacity * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _opacity,
                        min: 0.20,
                        max: 0.95,
                        divisions: 15,
                        activeColor: const Color(0xFF38BDF8),
                        inactiveColor: Colors.white12,
                        onChanged: (val) {
                          setState(() => _opacity = val);
                          _syncConfigToOverlay();
                        },
                      ),
                      Text(
                        '💡 Pro-tip: 75% - 85% is the sweet spot para readable pa sayo pero pure black na sa katabi mo sa jeep!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Color Tint Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shield Color Tone',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _availableColors.map((color) {
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedColor = color);
                              _syncConfigToOverlay();
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF38BDF8) : Colors.white24,
                                  width: isSelected ? 3 : 1.2,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                      blurRadius: 10,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Color(0xFF38BDF8), size: 22)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeOption(String label, double size) {
    final isSelected = (_bubbleSize - size).abs() < 2.0;
    return GestureDetector(
      onTap: () {
        setState(() => _bubbleSize = size);
        _syncConfigToOverlay();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.white12,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF38BDF8) : Colors.white70,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMode = mode);
        _syncConfigToOverlay();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF818CF8) : Colors.white54,
              size: 26,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
