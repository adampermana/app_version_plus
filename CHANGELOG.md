## 0.1.3

* Added Swift Package Manager (SPM) support for iOS (>= 13.0) and macOS (>= 10.15).
* Migrated Android build configuration to support built-in Kotlin (AGP 9+ / KGP 2.0+ compatibility).
* Updated minimum platform targets to iOS 13.0 and macOS 10.15.
* Updated dependencies to latest compatible versions (`device_info_plus` ^13.2.0, `package_info_plus` ^10.2.1, `flutter_svg` ^2.3.0, `intl` ^0.20.3, `url_launcher` ^6.3.2).
* Cleaned up and reorganized iOS/macOS plugin native directory structure.

## 0.1.2

* Updated `device_info_plus` dependency to `^13.2.0`.
* Updated `package_info_plus` dependency to `^10.2.1`.

## 0.1.1

* Added iOS platform initialization (Podspec, Swift plugin, and PrivacyInfo manifest).
* Added macOS platform initialization (Podspec, Swift plugin, and PrivacyInfo manifest).
* Added `DeviceType.macos` enum and macOS detection in `DeviceDetectorService`.
* Enabled App Store version checking support for macOS in `AppVersionChecker`.

## 0.1.0

* Initial release.
* Multi-platform support (Android, iOS, Huawei).
* In-app update functionality for Android via Google Play Core.
* Rich version information including age ratings, downloads, and release notes.
* Auto device detection for Huawei devices.
* Ready-to-use UI dialog widget and custom UI functions.
* Refactored Kotlin version, Gradle plugins, and SDK versions.
* Fixed regex character escaping in HuaweiApkPureService.
* Full null-safety support.
