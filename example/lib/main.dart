import 'package:app_version_plus/app_version_plus.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Version Plus Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isChecking = false;
  DeviceType? _deviceType;

  @override
  void initState() {
    super.initState();
    _detectDevice();
  }

  Future<void> _detectDevice() async {
    final checker = AppVersionChecker(
      // Override only if different from pubspec.yaml
      androidId: 'flutterapp.spinevishal.com.comman_project',
      androidHtmlReleaseNotes: true,
      androidPlayStoreCountry: 'en_US',
      iOSAppStoreCountry: 'en_US',
      huaweiHtmlReleaseNotes: true,
      iOSId: 'flutterapp.spinevishal.com.comman_project',
      huaweiId: 'com.solu.mobsen',
    );

    // Detect device type
    final deviceType = await checker.getDeviceType();
    if (mounted) {
      setState(() => _deviceType = deviceType);
    }

    // Auto check for update on app start
    final versionInfo = await checker.checkForUpdate();
    if (!mounted) return;

    if (versionInfo != null && versionInfo.canUpdate) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => VersionUpdateDialog(
          versionInfo: versionInfo,
          cancelButtonText: 'Later',
        ),
      );
    }
  }

  /// Check for updates and show dialog
  Future<void> _checkForUpdate() async {
    setState(() => _isChecking = true);

    // Step 1: Create checker with your app configuration
    final checker = AppVersionChecker(
// Override only if different!
      androidId: 'com.solu.mobsen',
      androidHtmlReleaseNotes: true,
      androidPlayStoreCountry: 'en_US',
      iOSAppStoreCountry: 'en_US',
      iOSId: 'com.solu.mobsen',
      huaweiId: 'com.solu.mobsen',
    );

    // Step 2: Check for update
    final versionInfo = await checker.checkForUpdate();

    if (!mounted) return;
    setState(() => _isChecking = false);

    // Step 3: Show dialog if update is available
    if (versionInfo != null && versionInfo.canUpdate) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => VersionUpdateDialog(
          versionInfo: versionInfo,
          // Optional customization:
          // title: 'New Update Available',
          // message: 'Please update to enjoy new features.',
          // updateButtonText: 'Update Now',
          // cancelButtonText: 'Later',
          // primaryColor: Colors.blue,
          // gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
        ),
      );
    } else {
      _showSnackBar('You are using the latest version!');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('App Version Plus'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Device Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        _getDeviceIcon(),
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _deviceType?.name.toUpperCase() ?? 'Detecting...',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStoreInfo(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Check Update Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isChecking ? null : _checkForUpdate,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_download),
                  label: Text(_isChecking ? 'Checking...' : 'Check for Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon() {
    switch (_deviceType) {
      case DeviceType.android:
        return Icons.android;
      case DeviceType.ios:
        return Icons.apple;
      case DeviceType.huawei:
        return Icons.phone_android;
      default:
        return Icons.devices;
    }
  }

  String _getStoreInfo() {
    switch (_deviceType) {
      case DeviceType.android:
        return 'Google Play Store';
      case DeviceType.ios:
        return 'Apple App Store';
      case DeviceType.huawei:
        return 'Huawei AppGallery';
      default:
        return 'Unknown';
    }
  }
}
