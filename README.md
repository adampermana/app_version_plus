# app_version_plus

[![pub package](https://img.shields.io/pub/v/app_version_plus.svg)](https://pub.dev/packages/app_version_plus)
[![likes](https://img.shields.io/pub/likes/app_version_plus)](https://pub.dev/packages/app_version_plus/score)
[![pub points](https://img.shields.io/pub/points/app_version_plus)](https://pub.dev/packages/app_version_plus/score)
[![GitHub stars](https://img.shields.io/github/stars/adampermana/app_version_plus?logo=github)](https://github.com/adampermana/app_version_plus/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/adampermana/app_version_plus?logo=github)](https://github.com/adampermana/app_version_plus/network)

A comprehensive Flutter package for checking app version updates across **Android (Play Store)**, **iOS (App Store)**, and **Huawei (AppGallery)**. 

## ✨ Features

- ✅ **Multi-Platform Support**: Android, iOS, and Huawei AppGallery
- ✅ **Auto Device Detection**: Automatically detects Huawei devices
- ✅ **Two Usage Modes**: 
  - Ready-to-use UI widgets (simple integration)
  - Function-only approach (custom UI)
- ✅ **Rich Information**: Version, release notes, ratings, downloads, app icon, and more
- ✅ **Customizable**: Full control over UI and behavior
- ✅ **Type-Safe**: Full Dart null-safety support
- ✅ **Well-Documented**: Comprehensive examples and API documentation

## Supported platforms
- Android
- Apple
- Huawei

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  app_version_plus: ^0.1.0
```

Then run:
```bash
flutter pub get
```

## 🚀 Quick Start

### Option 1: Ready-to-Use UI (Simplest)

Just one line of code! The package will automatically check for updates and show a beautiful Material Design dialog:

```dart
import 'package:app_version_plus/app_version_plus.dart';

// In your app initialization or main screen
await VersionUpdateDialog.checkAndShow(
  context: context,
  checker: AppVersionChecker(),
);
```

That's it! The dialog will automatically:
- Detect your device type (Android/iOS/Huawei)
- Check the appropriate store for updates
- Show a dialog only if an update is available
- Handle opening the store when user taps "Update"

### Option 2: Custom UI (More Control)

Use the functions to get update information and build your own UI:

```dart
import 'package:app_version_plus/app_version_plus.dart';

final checker = AppVersionChecker();
final versionInfo = await checker.checkForUpdate();

if (versionInfo != null && versionInfo.canUpdate) {
  print('Update available!');
  print('Current: ${versionInfo.localVersion}');
  print('Latest: ${versionInfo.storeVersion}');
  print('Release notes: ${versionInfo.releaseNotes}');
  
  // Build your custom UI here
  showMyCustomDialog(
    title: 'New version available',
    message: 'Update to ${versionInfo.storeVersion}',
    onUpdate: () async {
      await checker.launchStore(versionInfo: versionInfo);
    },
  );
}
```

## 📖 Detailed Usage

### Auto Device Detection

The package automatically detects Huawei devices using `device_info_plus`:

```dart
final checker = AppVersionChecker();
final deviceType = await checker.getDeviceType();

print(deviceType); // DeviceType.android / DeviceType.ios / DeviceType.huawei
```

### Configuration

Customize store lookup with optional parameters:

```dart
final checker = AppVersionChecker(
  // Override package names for different stores
  androidId: 'com.example.app',
  iOSId: 'your-app-id',
  huaweiId: 'com.example.app',
  
  // Set country/locale for store lookup
  androidPlayStoreCountry: 'id_ID',
  iOSAppStoreCountry: 'ID',
  huaweiAppGalleryCountry: 'id_ID',
  
  // For testing: force a specific version
  forceAppVersion: '2.0.0',
  
  // Choose release notes format
  androidHtmlReleaseNotes: false,
  huaweiHtmlReleaseNotes: false,
);
```

### Version Information

The `VersionInfo` object contains rich information:

```dart
final versionInfo = await checker.checkForUpdate();

// Version comparison
print(versionInfo.canUpdate);           // bool
print(versionInfo.updateAvailability);  // UpdateAvailability enum
print(versionInfo.isMajorUpdate);       // bool
print(versionInfo.isMinorUpdate);       // bool
print(versionInfo.isPatchUpdate);       // bool

// App information
print(versionInfo.appName);             // String?
print(versionInfo.developerName);       // String?
print(versionInfo.appIconUrl);          // String?

// Store information  
print(versionInfo.rating);              // double? (1.0-5.0)
print(versionInfo.ratingCount);         // int?
print(versionInfo.downloadCount);       // String? (Android/Huawei only)
print(versionInfo.ageRating);           // String?

// Release information
print(versionInfo.releaseNotes);        // String?
print(versionInfo.lastUpdateDate);      // DateTime?
```

### Custom Dialog

Customize the ready-to-use dialog:

```dart
await VersionUpdateDialog.checkAndShow(
  context: context,
  checker: checker,
  title: 'Update Tersedia',
  message: 'Versi baru tersedia! Silakan update aplikasi.',
  updateButtonText: 'Update Sekarang',
  cancelButtonText: 'Nanti',
  showReleaseNotes: true,
  barrierDismissible: false,  // Force update
);
```

## 🔧 Platform-Specific Notes

### Android (Play Store)
- Uses web scraping to get app information
- Supports all locales
- Provides download count

### iOS (App Store)
- Uses official iTunes Lookup API
- More reliable than scraping
- No download count available

### Huawei (AppGallery)
- Automatically detected on Huawei/Honor devices
- Uses web scraping similar to Play Store
- Supports Chinese and international stores

## 🎯 Advanced Examples

### Force Update

Make updates mandatory:

```dart
final versionInfo = await checker.checkForUpdate();

if (versionInfo != null && versionInfo.canUpdate) {
  showDialog(
    context: context,
    barrierDismissible: false,  // Can't dismiss
    builder: (context) => WillPopScope(
      onWillPop: () async => false,  // Can't go back
      child: VersionUpdateDialog(
        versionInfo: versionInfo,
        title: 'Update Required',
        barrierDismissible: false,
      ),
    ),
  );
}
```

### Manual Device Override (Testing)

```dart
// Test Huawei flow on non-Huawei device
final checker = AppVersionChecker(
  overrideDeviceType: DeviceType.huawei,
  huaweiId: 'com.example.app',
);
```

### Cache Control

```dart
// Force fresh data
final versionInfo = await checker.checkForUpdate(forceRefresh: true);

// Clear cached data
checker.clearCache();
```

## 📝 Migration from Legacy API

If you were using the old `NewVersionPlus` class:

```dart
// Old way (deprecated)
final newVersionPlus = NewVersionPlus(...);
final status = await newVersionPlus.getVersionStatus();

// New way ✅
final checker = AppVersionChecker(...);
final versionInfo = await checker.checkForUpdate();
```

## ❓ FAQ

**Q: How does Huawei device detection work?**  
A: The package uses `device_info_plus` to check the device manufacturer. If it's "Huawei" or "Honor", it uses AppGallery instead of Play Store.

**Q: Can I use this for force updates?**  
A: Yes! Set `barrierDismissible` to `false` and use `WillPopScope` to prevent dismissal.

**Q: Does this work offline?**  
A: No, it requires an internet connection to check the store.

**Q: Can I customize the dialog UI?**  
A: Yes! Either use the customization options in `VersionUpdateDialog`, or use the function-only approach to build your own UI completely.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Credits

Inspired by and built upon the ideas from:
- Community feedback and contributions
