/// Constants matching Android's UpdateAvailability class
class PlayUpdateAvailability {
  const PlayUpdateAvailability._();

  static const int unknown = 0;
  static const int updateNotAvailable = 1;
  static const int updateAvailable = 2;
  static const int developerTriggeredUpdateInProgress = 3;
}

/// Result of [InAppUpdateService.checkUpdateAvailability]
class InAppUpdateInfo {
  /// Raw int from Android's [UpdateAvailability] — compare against [PlayUpdateAvailability]
  final int updateAvailability;

  /// Version code available in Play Store (may be 0 if not available)
  final int availableVersionCode;

  /// Whether IMMEDIATE update type is allowed on this device/version
  final bool isImmediateAllowed;

  /// Whether FLEXIBLE update type is allowed on this device/version
  final bool isFlexibleAllowed;

  const InAppUpdateInfo({
    required this.updateAvailability,
    required this.availableVersionCode,
    required this.isImmediateAllowed,
    required this.isFlexibleAllowed,
  });

  /// `true` if an update is available (either fresh or in-progress)
  bool get hasUpdate =>
      updateAvailability == PlayUpdateAvailability.updateAvailable ||
      updateAvailability ==
          PlayUpdateAvailability.developerTriggeredUpdateInProgress;

  factory InAppUpdateInfo.fromMap(Map<Object?, Object?> map) {
    return InAppUpdateInfo(
      updateAvailability: (map['updateAvailability'] as int?) ?? 0,
      availableVersionCode: (map['availableVersionCode'] as int?) ?? 0,
      isImmediateAllowed: (map['isImmediateAllowed'] as bool?) ?? false,
      isFlexibleAllowed: (map['isFlexibleAllowed'] as bool?) ?? false,
    );
  }
}
