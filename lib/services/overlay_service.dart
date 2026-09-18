import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  /// Check if the SYSTEM_ALERT_WINDOW permission is granted
  static Future<bool> isPermissionGranted() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  /// Request the SYSTEM_ALERT_WINDOW permission from Android system settings
  static Future<bool?> requestPermission() async {
    return await FlutterOverlayWindow.requestPermission();
  }

  /// Check if the overlay window is currently active/open
  static Future<bool> isActive() async {
    return await FlutterOverlayWindow.isActive();
  }

  /// Show the floating assistive touch bubble with full-screen capability
  static Future<void> showFloatingBubble({
    required double opacity,
    required String mode,
    required int colorValue,
    required double slitHeight,
    required double bubbleSize,
  }) async {
    final bool granted = await isPermissionGranted();
    if (!granted) {
      final bool? res = await requestPermission();
      if (res != true) return;
    }

    if (await isActive()) {
      await closeOverlay();
    }

    await FlutterOverlayWindow.showOverlay(
      enableDrag: false,
      overlayTitle: "Privacy Screen Active",
      overlayContent: "Tap assistive touch to toggle privacy filter",
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.center,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none,
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
    );

    // Sync initial configuration to overlay isolate
    await shareData({
      'action': 'CONFIG_UPDATE',
      'opacity': opacity,
      'mode': mode,
      'colorValue': colorValue,
      'slitHeight': slitHeight,
      'bubbleSize': bubbleSize,
    });
  }

  /// Show full-screen privacy screen with touch passthrough
  static Future<void> showPrivacyScreen({
    required double opacity,
    required String mode,
    required int colorValue,
    required double slitHeight,
  }) async {
    if (await isActive()) {
      await closeOverlay();
    }

    await FlutterOverlayWindow.showOverlay(
      enableDrag: false,
      overlayTitle: "Privacy Shield ON",
      overlayContent: "Screen privacy filter is protecting your screen",
      flag: OverlayFlag.clickThrough,
      alignment: OverlayAlignment.center,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none,
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
    );

    // Send initial configuration to the overlay entry point
    await shareData({
      'action': 'CONFIG_UPDATE',
      'opacity': opacity,
      'mode': mode,
      'colorValue': colorValue,
      'slitHeight': slitHeight,
    });
  }

  /// Send data to the overlay window
  static Future<void> shareData(dynamic data) async {
    await FlutterOverlayWindow.shareData(data);
  }

  /// Close any active overlay
  static Future<void> closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
