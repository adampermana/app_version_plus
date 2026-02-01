import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../enums/device_type.dart';
import '../models/version_info.dart';
import '../services/android_store_service.dart';
import '../services/huawei_store_service.dart';
import '../services/ios_store_service.dart';
import 'device_detector_service.dart';

/// Main service for checking app version updates across different platforms
///
/// This service automatically detects the device type (Android, iOS, Huawei)
/// and uses the appropriate store service to check for updates.
///
/// Example usage:
/// ```dart
/// final checker = AppVersionChecker();
/// final versionInfo = await checker.checkForUpdate();
///
/// if (versionInfo != null && versionInfo.canUpdate) {
///   print('Update available: ${versionInfo.storeVersion}');
///   await checker.launchStore();
/// }
/// ```
class AppVersionChecker {
  final DeviceDetectorService _deviceDetector = DeviceDetectorService();

  /// Android app ID (package name). If null, uses the current package name.
  final String? androidId;

  /// iOS app ID (bundle ID or numeric ID). If null, uses the current bundle ID.
  final String? iOSId;

  /// Huawei app ID (package name). If null, uses the current package name.
  final String? huaweiId;

  /// Country code for iOS App Store (e.g., 'US', 'ID')
  final String? iOSAppStoreCountry;

  /// Country code for Android Play Store (e.g., 'en_US', 'id_ID')
  final String? androidPlayStoreCountry;

  /// Country code for Huawei AppGallery (e.g., 'en_US', 'id_ID')
  final String? huaweiAppGalleryCountry;

  /// Force a specific version for testing purposes
  final String? forceAppVersion;

  /// Whether to return HTML-formatted release notes for Android
  final bool androidHtmlReleaseNotes;

  /// Whether to return HTML-formatted release notes for Huawei
  final bool huaweiHtmlReleaseNotes;

  /// Manually override device type detection (useful for testing)
  final DeviceType? overrideDeviceType;

  /// Cached version info to avoid repeated network calls
  VersionInfo? _cachedVersionInfo;

  /// Cached device type
  DeviceType? _cachedDeviceType;

  AppVersionChecker({
    this.androidId,
    this.iOSId,
    this.huaweiId,
    this.iOSAppStoreCountry,
    this.androidPlayStoreCountry,
    this.huaweiAppGalleryCountry,
    this.forceAppVersion,
    this.androidHtmlReleaseNotes = false,
    this.huaweiHtmlReleaseNotes = false,
    this.overrideDeviceType,
  });

  /// Checks for app updates and returns version information
  ///
  /// Returns `null` if:
  /// - The platform is not supported
  /// - Network request fails
  /// - Store page cannot be parsed
  ///
  /// Set [forceRefresh] to `true` to bypass the cache and fetch fresh data.
  Future<VersionInfo?> checkForUpdate({bool forceRefresh = false}) async {
    // Return cached version if available and not forcing refresh
    if (!forceRefresh && _cachedVersionInfo != null) {
      debugPrint('Returning cached version info');
      return _cachedVersionInfo;
    }

    try {
      final deviceType = await _getDeviceType();
      final packageInfo = await PackageInfo.fromPlatform();

      VersionInfo? versionInfo;

      switch (deviceType) {
        case DeviceType.android:
          debugPrint('Checking for updates on Google Play Store');
          versionInfo = await AndroidStoreService(
            androidId: androidId,
            androidPlayStoreCountry: androidPlayStoreCountry,
            forceAppVersion: forceAppVersion,
            androidHtmlReleaseNotes: androidHtmlReleaseNotes,
          ).getStoreVersion(packageInfo);
          break;

        case DeviceType.ios:
          debugPrint('Checking for updates on Apple App Store');
          versionInfo = await IosStoreService(
            iOSId: iOSId,
            iOSAppStoreCountry: iOSAppStoreCountry,
            forceAppVersion: forceAppVersion,
          ).getStoreVersion(packageInfo);
          break;

        case DeviceType.huawei:
          debugPrint('Checking for updates on Huawei AppGallery');
          versionInfo = await HuaweiStoreService(
            huaweiId: huaweiId,
            huaweiAppGalleryCountry: huaweiAppGalleryCountry,
            forceAppVersion: forceAppVersion,
            huaweiHtmlReleaseNotes: huaweiHtmlReleaseNotes,
          ).getStoreVersion(packageInfo);
          break;

        case DeviceType.unknown:
          debugPrint('Cannot check for updates: unknown device type');
          return null;
      }

      // Cache the result
      _cachedVersionInfo = versionInfo;
      return versionInfo;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  /// Launches the appropriate app store page
  ///
  /// Opens the store page in an external browser or app.
  /// If [versionInfo] is not provided, it will try to use the cached version info.
  ///
  /// Throws an exception if the store link cannot be launched.
  Future<void> launchStore({
    VersionInfo? versionInfo,
    LaunchMode launchMode = LaunchMode.externalApplication,
  }) async {
    final info = versionInfo ?? _cachedVersionInfo;

    if (info == null) {
      throw Exception(
          'No version info available. Call checkForUpdate() first.');
    }

    final uri = Uri.parse(info.appStoreLink);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: launchMode);
    } else {
      throw Exception('Could not launch store URL: ${info.appStoreLink}');
    }
  }

  /// Gets the detected device type
  Future<DeviceType> getDeviceType() async {
    return await _getDeviceType();
  }

  /// Internal method to get device type (with caching)
  Future<DeviceType> _getDeviceType() async {
    if (overrideDeviceType != null) {
      debugPrint('Using override device type: $overrideDeviceType');
      return overrideDeviceType!;
    }

    if (_cachedDeviceType != null) {
      return _cachedDeviceType!;
    }

    _cachedDeviceType = await _deviceDetector.detectDeviceType();
    return _cachedDeviceType!;
  }

  /// Clears the cached version info and device type
  void clearCache() {
    _cachedVersionInfo = null;
    _cachedDeviceType = null;
    debugPrint('Cache cleared');
  }
}
