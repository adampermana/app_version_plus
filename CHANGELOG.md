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
