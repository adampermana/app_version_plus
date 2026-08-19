import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../enums/device_type.dart';

/// Service to detect the device type (Android, iOS, Huawei)
class DeviceDetectorService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Detects the current device type
  ///
  /// Returns [DeviceType.huawei] if the device is a Huawei device,
  /// [DeviceType.android] for other Android devices,
  /// [DeviceType.ios] for iOS/iPadOS devices,
  /// [DeviceType.macos] for macOS devices,
  /// and [DeviceType.unknown] for unsupported platforms.
  Future<DeviceType> detectDeviceType() async {
    try {
      if (Platform.isAndroid) {
        return await _detectAndroidDeviceType();
      } else if (Platform.isIOS) {
        return DeviceType.ios;
      } else if (Platform.isMacOS) {
        return DeviceType.macos;
      } else {
        debugPrint(
            'Unsupported platform: ${Platform.operatingSystem}. Only Android, iOS, and macOS are supported.');
        return DeviceType.unknown;
      }
    } catch (e) {
      debugPrint('Error detecting device type: $e');
      return DeviceType.unknown;
    }
  }

  /// Detects if an Android device is a Huawei device
  Future<DeviceType> _detectAndroidDeviceType() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final brand = androidInfo.brand.toLowerCase();

      // Check if the device is manufactured by Huawei or Honor
      // Honor is a sub-brand of Huawei
      if (manufacturer.contains('huawei') || brand.contains('huawei')) {
        debugPrint(
            'Detected Huawei device: manufacturer=$manufacturer, brand=$brand');
        return DeviceType.huawei;
      }

      debugPrint(
          'Detected non-Huawei Android device: manufacturer=$manufacturer, brand=$brand');
      return DeviceType.android;
    } catch (e) {
      debugPrint('Error detecting Android device type: $e');
      // Default to Android if we can't determine
      return DeviceType.android;
    }
  }

  /// Check if Google Play Services is available (alternative detection method)
  /// This can be used as a fallback to detect Huawei devices
  /// Note: This requires additional implementation and platform-specific code
  Future<bool> isGooglePlayServicesAvailable() async {
    // This is a placeholder for future implementation
    // You would need to use method channels to check for Google Play Services
    // For now, we rely on manufacturer detection
    return true;
  }
}
