import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../models/in_app_update_info.dart';

/// Dart-side wrapper for the `app_version_plus/in_app_update` MethodChannel.
///
/// Only functional on Android devices that have the app distributed via
/// Google Play. On other platforms, all methods are no-ops / return null.
///
/// For local development without Play Store, use
/// [FakeAppUpdateManager](https://developer.android.com/reference/com/google/android/play/core/appupdate/testing/FakeAppUpdateManager)
/// from the Play Core test library in your app's test variant.
class InAppUpdateService {
  static const _channel = MethodChannel('app_version_plus/in_app_update');

  /// Optional callback invoked when a flexible update finishes downloading.
  /// Call [completeFlexibleUpdate] inside this callback to install.
  final VoidCallback? onFlexibleUpdateDownloaded;

  InAppUpdateService({this.onFlexibleUpdateDownloaded}) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onFlexibleUpdateDownloaded') {
      onFlexibleUpdateDownloaded?.call();
    }
  }

  /// Checks update availability from Play Store.
  ///
  /// Returns `null` on non-Android platforms or when Play Core is unavailable.
  Future<InAppUpdateInfo?> checkUpdateAvailability() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'checkUpdateAvailability',
      );
      if (result == null) return null;
      return InAppUpdateInfo.fromMap(result);
    } on PlatformException catch (e) {
      debugPrint('[InAppUpdateService] checkUpdateAvailability failed: $e');
      return null;
    } on MissingPluginException {
      // Running on non-Android or plugin not registered
      return null;
    }
  }

  /// Starts an IMMEDIATE update flow (fullscreen, blocking).
  ///
  /// Returns a [String] result token:
  /// - `"UPDATE_ACCEPTED"` — user accepted, Play Store handles install
  /// - `"UPDATE_CANCELED"` — user dismissed
  /// - `"UPDATE_NOT_AVAILABLE"` — no update in Play Store
  /// - `"UPDATE_TYPE_NOT_ALLOWED"` — immediate not supported on this device
  ///
  /// Returns `null` on non-Android or plugin error.
  Future<String?> startImmediateUpdate() async {
    try {
      return await _channel.invokeMethod<String>('startImmediateUpdate');
    } on PlatformException catch (e) {
      debugPrint('[InAppUpdateService] startImmediateUpdate failed: $e');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Starts a FLEXIBLE update flow (background download).
  ///
  /// Listen to [onFlexibleUpdateDownloaded] callback to know when download
  /// completes, then call [completeFlexibleUpdate] to install.
  ///
  /// Returns the same result tokens as [startImmediateUpdate].
  Future<String?> startFlexibleUpdate() async {
    try {
      return await _channel.invokeMethod<String>('startFlexibleUpdate');
    } on PlatformException catch (e) {
      debugPrint('[InAppUpdateService] startFlexibleUpdate failed: $e');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Completes a flexible update by restarting the app to apply the download.
  ///
  /// Call this after [onFlexibleUpdateDownloaded] fires and the user confirms.
  Future<void> completeFlexibleUpdate() async {
    try {
      await _channel.invokeMethod<String>('completeFlexibleUpdate');
    } on PlatformException catch (e) {
      debugPrint('[InAppUpdateService] completeFlexibleUpdate failed: $e');
    } on MissingPluginException {
      return;
    }
  }
}
