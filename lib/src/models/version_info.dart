import 'update_availability.dart';
import '../enums/device_type.dart';

/// Information about the app's current version and the most recent version
/// available in the app store (Play Store, App Store, or AppGallery).
class VersionInfo {
  /// The current version of the app installed on the device
  final String localVersion;

  /// The most recent version of the app available in the store
  final String storeVersion;

  /// The original store version string (before cleaning)
  final String? originalStoreVersion;

  /// A direct link to the app's store page
  final String appStoreLink;

  /// Release notes for the store version of the app
  final String? releaseNotes;

  /// The last update date of the store version
  final DateTime? lastUpdateDate;

  /// The name of the app as it appears in the store
  final String? appName;

  /// The developer/publisher name of the app
  final String? developerName;

  /// URL to the app icon image
  final String? appIconUrl;

  /// App rating (1.0 - 5.0)
  final double? rating;

  /// Number of ratings/reviews
  final int? ratingCount;

  /// Total download count (Android/Huawei only, iOS doesn't provide this)
  final String? downloadCount;

  /// Age rating (e.g., "4+", "12+", "17+" for iOS or "Everyone", "Teen" for Android)
  final String? ageRating;

  /// Content rating details (platform-specific descriptions)
  final String? contentRating;

  /// The device type/platform this version info belongs to
  final DeviceType? deviceType;

  VersionInfo._({
    required this.localVersion,
    required this.storeVersion,
    required this.appStoreLink,
    this.originalStoreVersion,
    this.releaseNotes,
    this.lastUpdateDate,
    this.appName,
    this.developerName,
    this.appIconUrl,
    this.rating,
    this.ratingCount,
    this.downloadCount,
    this.ageRating,
    this.contentRating,
    this.deviceType,
  });

  /// Creates a [VersionInfo] instance from store data
  factory VersionInfo.fromStore({
    required String localVersion,
    required String storeVersion,
    required String appStoreLink,
    String? originalStoreVersion,
    String? releaseNotes,
    DateTime? lastUpdateDate,
    String? appName,
    String? developerName,
    String? appIconUrl,
    double? rating,
    int? ratingCount,
    String? downloadCount,
    String? ageRating,
    String? contentRating,
    DeviceType? deviceType,
  }) {
    return VersionInfo._(
      localVersion: localVersion,
      storeVersion: storeVersion,
      appStoreLink: appStoreLink,
      originalStoreVersion: originalStoreVersion,
      releaseNotes: releaseNotes,
      lastUpdateDate: lastUpdateDate,
      appName: appName,
      developerName: developerName,
      appIconUrl: appIconUrl,
      rating: rating,
      ratingCount: ratingCount,
      downloadCount: downloadCount,
      ageRating: ageRating,
      contentRating: contentRating,
      deviceType: deviceType,
    );
  }

  /// Returns `true` if the store version is greater than the local version
  bool get canUpdate {
    final local = localVersion.split('.').map(int.parse).toList();
    final store = storeVersion.split('.').map(int.parse).toList();

    for (var i = 0; i < store.length; i++) {
      if (store[i] > local[i]) return true;
      if (local[i] > store[i]) return false;
    }

    return false;
  }

  /// Returns the update availability status
  UpdateAvailability get updateAvailability {
    if (!canUpdate) return UpdateAvailability.none;
    // For now, all updates are optional
    // You can implement force update logic based on version difference
    return UpdateAvailability.optional;
  }

  /// Checks if this is a major version update (first digit changed)
  bool get isMajorUpdate {
    if (!canUpdate) return false;
    final local = localVersion.split('.').map(int.parse).toList();
    final store = storeVersion.split('.').map(int.parse).toList();
    return store.isNotEmpty && local.isNotEmpty && store[0] > local[0];
  }

  /// Checks if this is a minor version update (second digit changed)
  bool get isMinorUpdate {
    if (!canUpdate || isMajorUpdate) return false;
    final local = localVersion.split('.').map(int.parse).toList();
    final store = storeVersion.split('.').map(int.parse).toList();
    return store.length > 1 && local.length > 1 && store[1] > local[1];
  }

  /// Checks if this is a patch version update (third digit changed)
  bool get isPatchUpdate {
    if (!canUpdate || isMajorUpdate || isMinorUpdate) return false;
    return true;
  }

  /// Creates a copy of this [VersionInfo] with the given fields replaced
  VersionInfo copyWith({
    String? localVersion,
    String? storeVersion,
    String? appStoreLink,
    String? originalStoreVersion,
    String? releaseNotes,
    DateTime? lastUpdateDate,
    String? appName,
    String? developerName,
    String? appIconUrl,
    double? rating,
    int? ratingCount,
    String? downloadCount,
    String? ageRating,
    String? contentRating,
    DeviceType? deviceType,
  }) {
    return VersionInfo._(
      localVersion: localVersion ?? this.localVersion,
      storeVersion: storeVersion ?? this.storeVersion,
      appStoreLink: appStoreLink ?? this.appStoreLink,
      originalStoreVersion: originalStoreVersion ?? this.originalStoreVersion,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      appName: appName ?? this.appName,
      developerName: developerName ?? this.developerName,
      appIconUrl: appIconUrl ?? this.appIconUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      downloadCount: downloadCount ?? this.downloadCount,
      ageRating: ageRating ?? this.ageRating,
      contentRating: contentRating ?? this.contentRating,
      deviceType: deviceType ?? this.deviceType,
    );
  }

  /// Converts this [VersionInfo] to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'localVersion': localVersion,
      'storeVersion': storeVersion,
      'originalStoreVersion': originalStoreVersion,
      'appStoreLink': appStoreLink,
      'releaseNotes': releaseNotes,
      'lastUpdateDate': lastUpdateDate?.toIso8601String(),
      'appName': appName,
      'developerName': developerName,
      'appIconUrl': appIconUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'downloadCount': downloadCount,
      'ageRating': ageRating,
      'contentRating': contentRating,
      'deviceType': deviceType?.name,
      'canUpdate': canUpdate,
      'updateAvailability': updateAvailability.name,
    };
  }

  /// Creates a [VersionInfo] from a JSON map
  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo._(
      localVersion: json['localVersion'] as String,
      storeVersion: json['storeVersion'] as String,
      appStoreLink: json['appStoreLink'] as String,
      originalStoreVersion: json['originalStoreVersion'] as String?,
      releaseNotes: json['releaseNotes'] as String?,
      lastUpdateDate: json['lastUpdateDate'] != null
          ? DateTime.parse(json['lastUpdateDate'] as String)
          : null,
      appName: json['appName'] as String?,
      developerName: json['developerName'] as String?,
      appIconUrl: json['appIconUrl'] as String?,
      rating: json['rating'] as double?,
      ratingCount: json['ratingCount'] as int?,
      downloadCount: json['downloadCount'] as String?,
      ageRating: json['ageRating'] as String?,
      contentRating: json['contentRating'] as String?,
      deviceType: json['deviceType'] != null
          ? DeviceType.values.firstWhere(
              (e) => e.name == json['deviceType'],
              orElse: () => DeviceType.unknown,
            )
          : null,
    );
  }

  @override
  String toString() {
    return 'VersionInfo(localVersion: $localVersion, storeVersion: $storeVersion, '
        'canUpdate: $canUpdate, updateAvailability: ${updateAvailability.name})';
  }
}
