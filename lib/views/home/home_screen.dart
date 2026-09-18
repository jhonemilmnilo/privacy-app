import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock state for UI presentation
  bool _overlayPermissionGranted = false;
  bool _accessibilityPermissionGranted = false;
  bool _isServiceEnabled = false; // Master toggle button in app bar

  @override
  Widget build(BuildContext context) {
    final allPermissionsGranted =
        _overlayPermissionGranted && _accessibilityPermissionGranted;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19), // Deep Matte Obsidian
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Header with Interactive Toggle Switch
              _buildHeader(),

              const SizedBox(height: 24),

              // Section Label
              const Text(
                'PERMISSIONS SETUP',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              // 2. Side-by-Side Compact 2-in-a-Line Cards
              Row(
                children: [
                  // Card 1: Overlay Permission
                  Expanded(
                    child: _buildCompactPermissionCard(
                      icon: Icons.layers_outlined,
                      accentColor: const Color(0xFF6366F1), // Electric Indigo
                      title: 'Overlay',
                      subtitle: 'Display on top',
                      isGranted: _overlayPermissionGranted,
                      onTap: () {
                        setState(() {
                          _overlayPermissionGranted = !_overlayPermissionGranted;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Card 2: Accessibility Permission
                  Expanded(
                    child: _buildCompactPermissionCard(
                      icon: Icons.accessibility_new_rounded,
                      accentColor: const Color(0xFF38BDF8), // Cyber Cyan
                      title: 'Accessibility',
                      subtitle: 'Smart gestures',
                      isGranted: _accessibilityPermissionGranted,
                      onTap: () {
                        setState(() {
                          _accessibilityPermissionGranted =
                              !_accessibilityPermissionGranted;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 3. Status Summary Pill
              _buildStatusFooter(allPermissionsGranted),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy Shade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _isServiceEnabled ? 'Shield Active' : 'Shield Inactive',
                  style: TextStyle(
                    color: _isServiceEnabled
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Interactive Toggle Button in App Bar
        GestureDetector(
          onTap: () {
            setState(() {
              _isServiceEnabled = !_isServiceEnabled;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isServiceEnabled
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : const Color(0xFF131B2E),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isServiceEnabled
                    ? const Color(0xFF10B981).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                if (_isServiceEnabled)
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isServiceEnabled
                        ? const Color(0xFF10B981)
                        : Colors.white38,
                    boxShadow: [
                      if (_isServiceEnabled)
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.7),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isServiceEnabled ? 'ACTIVE' : 'OFF',
                  style: TextStyle(
                    color: _isServiceEnabled
                        ? const Color(0xFF10B981)
                        : Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isServiceEnabled
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_rounded,
                  color: _isServiceEnabled
                      ? const Color(0xFF10B981)
                      : Colors.white38,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPermissionCard({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E), // Elevated Dark Charcoal
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isGranted
                  ? const Color(0xFF10B981).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
              width: isGranted ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isGranted)
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Icon + State Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isGranted
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isGranted
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      isGranted ? Icons.check_circle_rounded : icon,
                      color: isGranted ? const Color(0xFF10B981) : accentColor,
                      size: 20,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isGranted
                          ? const Color(0xFF10B981)
                          : Colors.white.withValues(alpha: 0.25),
                      boxShadow: [
                        if (isGranted)
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 3),

              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 14),

              // Action button inside card
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isGranted
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : accentColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: isGranted
                      ? Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          width: 1.0,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    isGranted ? 'Enabled' : 'Enable',
                    style: TextStyle(
                      color: isGranted ? const Color(0xFF10B981) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFooter(bool allGranted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allGranted
                ? Icons.verified_user_rounded
                : Icons.info_outline_rounded,
            color: allGranted ? const Color(0xFF10B981) : Colors.white54,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allGranted
                  ? (_isServiceEnabled
                      ? 'Privacy Shield is currently running'
                      : 'All permissions ready. Tap toggle to activate')
                  : 'Grant required permissions to enable shield',
              style: TextStyle(
                color: allGranted ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
