import 'package:flutter/services.dart';

class AccessibilityServiceHelper {
  static const MethodChannel _channel =
      MethodChannel('com.example.privacy_apps/accessibility');

  /// Check if the accessibility service is turned on in Android settings
  static Future<bool> isAccessibilityEnabled() async {
    try {
      final bool? isEnabled =
          await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return isEnabled ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Jump straight to Android's native Accessibility Settings menu
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (_) {}
  }
}
