import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../enums/android_update_type.dart';
import '../enums/device_type.dart';
import '../models/version_info.dart';
import '../services/android_store_service.dart';
import '../services/huawei_apk_pure_service.dart';
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

  /// Country code for ApkPure (e.g., 'en_US', 'id_ID')
  final String? huaweiApkPureCountry;

  /// Force a specific version for testing purposes
  final String? forceAppVersion;

  /// Whether to return HTML-formatted release notes for Android
  final bool androidHtmlReleaseNotes;

  /// Whether to return HTML-formatted release notes for Huawei
  final bool huaweiHtmlReleaseNotes;

  /// Manually override device type detection (useful for testing)
  final DeviceType? overrideDeviceType;

  /// Update type used for Android In-App Updates via Google Play Core.
  ///
  /// - [AndroidUpdateType.immediate] (default) — fullscreen blocking update.
  /// - [AndroidUpdateType.flexible] — background download; user stays in app.
  ///
  /// This value is passed to [VersionInfo] and read by [VersionUpdateDialog]
  /// when the Update button is tapped on Android.
  final AndroidUpdateType androidUpdateType;

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
    this.huaweiApkPureCountry,
    this.forceAppVersion,
    this.androidHtmlReleaseNotes = false,
    this.huaweiHtmlReleaseNotes = false,
    this.overrideDeviceType,
    this.androidUpdateType = AndroidUpdateType.immediate,
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
          debugPrint('Checking for updates on Huawei APk Pure');
          versionInfo = await ApkPureService(
            appId: huaweiId,
            forceAppVersion: forceAppVersion,
            htmlReleaseNotes: huaweiHtmlReleaseNotes,
            countryCode: huaweiApkPureCountry,
          ).getStoreVersion(packageInfo);
          break;

        case DeviceType.unknown:
          debugPrint('Cannot check for updates: unknown device type');
          return null;
      }

      // Attach androidUpdateType so VersionUpdateDialog can use the correct
      // Play Core flow without the caller needing to pass it separately.
      if (versionInfo != null && deviceType == DeviceType.android) {
        versionInfo = versionInfo.copyWith(androidUpdateType: androidUpdateType);
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

  /// Downloads APK directly (for Huawei/APK Pure)
  ///
  /// This method opens the APK download link in a browser,
  /// which triggers the automatic download on the device.
  /// 
  /// Primarily used for Huawei devices via APK Pure.
  /// If [versionInfo] is not provided, it will try to use the cached version info.
  ///
  /// Returns `true` if download was successfully initiated, `false` otherwise.
  Future<bool> downloadApk({
    VersionInfo? versionInfo,
    LaunchMode launchMode = LaunchMode.externalApplication,
  }) async {
    final info = versionInfo ?? _cachedVersionInfo;

    if (info == null) {
      debugPrint('No version info available. Call checkForUpdate() first.');
      return false;
    }

    // Check if APK download URL is available
    if (info.apkDownloadUrl == null || info.apkDownloadUrl!.isEmpty) {
      debugPrint('No APK download URL available');
      return false;
    }

    try {
      final urlString = info.apkDownloadUrl!;
      debugPrint('Attempting to download APK from: $urlString');
      
      // Validate URL format
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        debugPrint('Invalid APK download URL format (must start with http:// or https://)');
        return false;
      }

      final uri = Uri.parse(urlString);

      if (await canLaunchUrl(uri)) {
        debugPrint('Opening APK download URL: $urlString');
        await launchUrl(uri, mode: launchMode);
        return true;
      } else {
        debugPrint('Could not launch APK download URL (canLaunchUrl returned false): $urlString');
        return false;
      }
    } catch (e) {
      debugPrint('Error downloading APK: $e');
      return false;
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
