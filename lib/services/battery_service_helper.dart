import 'package:flutter/services.dart';

class BatteryServiceHelper {
  static const MethodChannel _channel =
      MethodChannel('com.example.privacy_apps/system_permissions');

  /// Check if the app is already set to Unrestricted / Ignoring Battery Optimizations
  static Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final bool? isIgnored =
          await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return isIgnored ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Trigger the system prompt or settings to exempt the app from battery killing
  static Future<void> requestIgnoreBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimization');
    } on PlatformException catch (_) {}
  }
}
