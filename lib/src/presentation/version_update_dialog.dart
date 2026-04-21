import 'package:app_version_plus/src/presentation/submit_button_styless_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../core/app_version_checker.dart';
import '../models/version_info.dart';
import '../models/update_availability.dart';
import '../enums/device_type.dart';
import '../presentation/enum/age_rating.dart';

/// A ready-to-use Material Design dialog for displaying app update information
///
/// This widget automatically checks for updates and shows a dialog if an update
/// is available.
///
/// Example usage:
/// ```dart
/// // Show dialog automatically if update is available
/// await VersionUpdateDialog.checkAndShow(
///   context: context,
///   checker: AppVersionChecker(),
/// );
///
/// // Or create a custom dialog with specific version info
/// showDialog(
///   context: context,
///   builder: (context) => VersionUpdateDialog(
///     versionInfo: versionInfo,
///   ),
/// );
/// ```
class VersionUpdateDialog extends StatefulWidget {
  /// The version information to display
  final VersionInfo versionInfo;

  /// App logo/icon to display at the top. If null, uses app icon from version info
  final Widget? appLogo;

  /// Title of the dialog
  final String? title;

  /// Custom message to display. If null, a default message will be shown.
  final String? message;

  /// Label for the update button
  final String? updateButtonText;

  /// Label for the cancel button (for optional updates)
  final String? cancelButtonText;

  /// Whether to show release notes in the dialog
  final bool showReleaseNotes;

  /// Whether the dialog can be dismissed by tapping outside or pressing back
  final bool barrierDismissible;

  /// Background color of the dialog
  final Color? backgroundColor;

  /// Card background color
  final Color? cardColor;

  /// "What's New" label text
  final String? whatsNewLabel;

  /// Date format for last update (e.g., 'd MMMM yyyy')
  final String? dateFormat;

  /// Locale for date formatting (e.g., 'id' for Indonesian, 'en' for English)
  final String? dateLocale;

  // ========== Update Button Customization ==========
  /// Style for the update button
  final SubmitButtonStyle? updateButtonStyle;

  /// Primary color for the update button
  final Color? updateButtonColor;

  /// Gradient for the update button
  final Gradient? updateButtonGradient;

  /// Gradient for dot
  final Gradient? dotGradient;

  // ========== Cancel Button Customization ==========
  /// Style for the cancel button
  final SubmitButtonStyle? cancelButtonStyle;

  /// Primary color for the cancel button
  final Color? cancelButtonColor;

  /// Gradient for the cancel button
  final Gradient? cancelButtonGradient;

  const VersionUpdateDialog({
    super.key,
    required this.versionInfo,
    this.appLogo,
    this.title,
    this.message,
    this.updateButtonText,
    this.cancelButtonText,
    this.showReleaseNotes = true,
    this.barrierDismissible = false,
    this.backgroundColor,
    this.cardColor,
    this.whatsNewLabel,
    this.dateFormat,
    this.dateLocale,
    this.dotGradient,
    // Update button
    this.updateButtonStyle,
    this.updateButtonColor,
    this.updateButtonGradient,
    // Cancel button
    this.cancelButtonStyle,
    this.cancelButtonColor,
    this.cancelButtonGradient,
  });

  @override
  State<VersionUpdateDialog> createState() => _VersionUpdateDialogState();
}

class _VersionUpdateDialogState extends State<VersionUpdateDialog> {
  bool _isExpanded = false;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    final locale = widget.dateLocale ?? 'en_US';
    try {
      await initializeDateFormatting(locale, null);
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    } catch (e) {
      // Fallback to default locale if initialization fails
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRequired =
        widget.versionInfo.updateAvailability == UpdateAvailability.required;

    final dialogTitle = widget.title ?? _getDefaultTitle();
    final dialogMessage = widget.message ??
        'Enjoy better performance and new features by updating now.';
    final updateLabel = widget.updateButtonText ?? 'Update';
    final whatsNewLabel = widget.whatsNewLabel ?? 'What\'s New';

    // Dialog can only be closed via buttons, not back button or tap outside
    // canPop is false when barrierDismissible is false OR update is required
    final canPop = widget.barrierDismissible && !isRequired;

    return PopScope(
      canPop: canPop,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? const Color(0xFFF8F7FC),
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with logo and title
              Column(
                children: [
                  widget.appLogo ?? _buildDefaultLogo(),
                  const SizedBox(height: 8),
                  Text(
                    dialogTitle,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Main card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.cardColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message
                    Text(
                      dialogMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Info
                    _buildAppInfo(),
                    const SizedBox(height: 20),

                    // What's New section
                    if (widget.showReleaseNotes &&
                        widget.versionInfo.releaseNotes != null) ...[
                      _buildWhatsNewHeader(whatsNewLabel),
                      const SizedBox(height: 4),
                      _buildUpdateDateRow(),
                      const SizedBox(height: 8),
                      _buildReleaseNotes(),
                      const SizedBox(height: 25),
                    ] else
                      const SizedBox(height: 5),

                    // Update button
                    _buildUpdateButton(updateLabel, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    if (widget.versionInfo.appIconUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          widget.versionInfo.appIconUrl!,
          height: 100,
          width: 100,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.cloud_download_outlined,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }
    return Icon(
      Icons.cloud_download_outlined,
      size: 100,
      color: Theme.of(context).primaryColor,
    );
  }

  Widget _buildAppInfo() {
    return Row(
      children: [
        // App icon
        if (widget.versionInfo.appIconUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.versionInfo.appIconUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apps, color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.apps, color: Colors.grey),
          ),
        const SizedBox(width: 15),

        // App details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.versionInfo.appName ?? 'App',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              _buildAppMetadata(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppMetadata() {
    debugPrint(
        '_buildAppMetadata called - ageRating: ${widget.versionInfo.ageRating}, rating: ${widget.versionInfo.rating}');

    return Row(
      children: [
        if (widget.versionInfo.rating != null) ...[
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            widget.versionInfo.rating!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        if (widget.versionInfo.ageRating != null) ...[
          const SizedBox(width: 12),
          _buildAgeRatingImage(),
        ],
      ],
    );
  }

  /// Build age rating image widget
  Widget _buildAgeRatingImage() {
    final ageRatingPath = _getAgeRatingImagePath();

    if (ageRatingPath == null) {
      // Fallback to text if no image path found
      return Text(
        widget.versionInfo.ageRating!,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
      );
    }

    debugPrint('Attempting to load SVG from: $ageRatingPath');

    return SizedBox(
      height: 16,
      child: SvgPicture.asset(
        ageRatingPath,
        package: 'app_version_plus',
        height: 16,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Container(
          width: 16,
          height: 16,
          color: Colors.grey[300],
          child: const Icon(Icons.info_outline, size: 12),
        ),
      ),
    );
  }

  /// Get the appropriate age rating image path based on platform and age
  String? _getAgeRatingImagePath() {
    // Priority 1: Try contentRating (usually has format like "Rated for 3+", "Everyone", etc)
    final contentRating = widget.versionInfo.contentRating ?? '';
    final ageRating = widget.versionInfo.ageRating ?? '';
    // final rating = widget.versionInfo.rating;
    // final releaseNote = widget.versionInfo.releaseNotes;
    // final appStoreLink = widget.versionInfo.appStoreLink;
    // final storeVersion = widget.versionInfo.storeVersion;
    // final apkDownloadUrl = widget.versionInfo.apkDownloadUrl;
    // final appIcon = widget.versionInfo.appIconUrl;
    // final appName = widget.versionInfo.appName;
    // final developerName = widget.versionInfo.developerName;

    // Debug logging
    // debugPrint('=== Age Rating Debug ===');
    // debugPrint('contentRating: $contentRating');
    // debugPrint('ageRating: $ageRating');
    // debugPrint('deviceType: ${widget.versionInfo.deviceType?.name}');
    // debugPrint('rating: $rating');
    // debugPrint('releaseNote: $releaseNote');
    // debugPrint('appStoreLink: $appStoreLink');
    // debugPrint('storeVersion: $storeVersion');
    // debugPrint('apkDownloadUrl: $apkDownloadUrl');
    // debugPrint('appIcon: $appIcon');
    // debugPrint('appName: $appName');
    // debugPrint('developerName: $developerName');

    // Try to extract numeric age from either field
    int? ratingNumber;

    // First try contentRating - usually more reliable
    if (contentRating.isNotEmpty) {
      final match = RegExp(r'(\d+)\+').firstMatch(contentRating);
      if (match != null) {
        ratingNumber = int.tryParse(match.group(1) ?? '0');
      }
    }

    // If not found, try ageRating
    if (ratingNumber == null && ageRating.isNotEmpty) {
      final match = RegExp(r'(\d+)\+').firstMatch(ageRating);
      if (match != null) {
        ratingNumber = int.tryParse(match.group(1) ?? '0');
      }
    }

    // If still not found, try to map ESRB/PEGI ratings to age numbers
    // ratingNumber ??=
    //     _mapRatingToAge(contentRating) ?? _mapRatingToAge(ageRating);

    debugPrint('Extracted age number: $ratingNumber');

    if (ratingNumber == null || ratingNumber == 0) return null;

    // Determine device type from version info
    final isIOS = widget.versionInfo.deviceType == DeviceType.ios;
    final isAndroid = widget.versionInfo.deviceType == DeviceType.android;

    String? imagePath;
    if (isIOS) {
      final rating = AgeRatingIos.fromAge(ratingNumber);
      imagePath = rating.imagePath;
    } else if (isAndroid) {
      final rating = AgeRatingAndroid.fromAge(ratingNumber);
      imagePath = rating.imagePath;
    }

    debugPrint('Image path: $imagePath');
    return imagePath;
  }

  /// Map ESRB/PEGI rating strings to numeric ages
  // int? _mapRatingToAge(String rating) {
  //   final lowerRating = rating.toLowerCase();

  //   // ESRB ratings
  //   if (lowerRating.contains('everyone') && !lowerRating.contains('10')) {
  //     return 3;
  //   }
  //   if (lowerRating.contains('everyone 10+') || lowerRating.contains('e10+')) {
  //     return 12;
  //   }
  //   if (lowerRating.contains('teen') || lowerRating == 't') return 13;
  //   if (lowerRating.contains('mature') || lowerRa>ting == 'm') return 17;
  //   if (lowerRating.contains('adults only') || lowerRating == 'ao') return 18;

  //   // PEGI ratings
  //   if (lowerRating.contains('pegi 3')) return 3;
  //   if (lowerRating.contains('pegi 7')) return 7;
  //   if (lowerRating.contains('pegi 12')) return 12;
  //   if (lowerRating.contains('pegi 16')) return 16;
  //   if (lowerRating.contains('pegi 18')) return 18;

  //   return null;
  // }

  Widget _buildWhatsNewHeader(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: widget.dotGradient ??
                const LinearGradient(
                  begin: Alignment(0.50, 0.00),
                  end: Alignment(0.50, 1.00),
                  colors: [Color(0xFF64DF94), Color(0xFF02B693)],
                ),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateDateRow() {
    return InkWell(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
      },
      child: Row(
        children: [
          if (widget.versionInfo.lastUpdateDate != null)
            Text(
              _formatUpdateDate(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          const Spacer(),
          Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  String _formatUpdateDate() {
    if (widget.versionInfo.lastUpdateDate == null) return '';
    if (!_localeInitialized) return '';

    final format = widget.dateFormat ?? 'd MMMM yyyy';
    final locale = widget.dateLocale ?? 'en_US';

    try {
      return 'Updated on ${DateFormat(format, locale).format(widget.versionInfo.lastUpdateDate!)}';
    } catch (e) {
      // Fallback to simple date format if locale formatting fails
      return 'Updated on ${DateFormat('d MMMM yyyy').format(widget.versionInfo.lastUpdateDate!)}';
    }
  }

  Widget _buildReleaseNotes() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ConstrainedBox(
        constraints: _isExpanded
            ? const BoxConstraints()
            : const BoxConstraints(maxHeight: 0),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            widget.versionInfo.releaseNotes ?? '',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton(String label, ThemeData theme) {
    // If cancelButtonText is provided, show both buttons in a row
    if (widget.cancelButtonText != null) {
      return Row(
        children: [
          // Cancel Button
          Expanded(
            child: SubmitButtonStylesWidget(
              primaryColor:
                  widget.cancelButtonColor ?? Theme.of(context).primaryColor,
              style: widget.cancelButtonStyle ?? SubmitButtonStyle.outlined,
              gradient: widget.cancelButtonGradient,
              useGradient: widget.cancelButtonGradient != null,
              textButton: widget.cancelButtonText!,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(width: 12),
          // Update Button
          Expanded(
            child: SubmitButtonStylesWidget(
              primaryColor:
                  widget.updateButtonColor ?? Theme.of(context).primaryColor,
              style: widget.updateButtonStyle ?? SubmitButtonStyle.elevated,
              gradient: widget.updateButtonGradient,
              useGradient: widget.updateButtonGradient != null,
              textButton: label,
              onPressed: () async {
                final checker = AppVersionChecker();

                // For Huawei devices, use direct APK download
                if (widget.versionInfo.deviceType == DeviceType.huawei) {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening download...'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    final success = await checker.downloadApk(
                      versionInfo: widget.versionInfo,
                    );

                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Download started!'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Failed to open download. Please try again.'),
                            action: SnackBarAction(
                              label: 'Retry',
                              onPressed: () async {
                                final retrySuccess = await checker.downloadApk(
                                  versionInfo: widget.versionInfo,
                                );
                                if (retrySuccess && mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Error in download: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } else {
                  // For other platforms, launch the store
                  await checker.launchStore(versionInfo: widget.versionInfo);
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ),
        ],
      );
    }

    // Single update button (full width)
    return SubmitButtonStylesWidget(
      primaryColor: widget.updateButtonColor ?? Theme.of(context).primaryColor,
      style: widget.updateButtonStyle ?? SubmitButtonStyle.elevated,
      gradient: widget.updateButtonGradient,
      useGradient: widget.updateButtonGradient != null,
      textButton: label,
      onPressed: () async {
        final checker = AppVersionChecker();

        // For Huawei devices, use direct APK download
        if (widget.versionInfo.deviceType == DeviceType.huawei) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening download...'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );

            final success = await checker.downloadApk(
              versionInfo: widget.versionInfo,
            );

            if (mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download started!'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Failed to open download. Please try again.'),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () async {
                        final retrySuccess = await checker.downloadApk(
                          versionInfo: widget.versionInfo,
                        );
                        if (retrySuccess && mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error in download: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else {
          // For other platforms, launch the store
          await checker.launchStore(versionInfo: widget.versionInfo);
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
    );
  }

  String _getDefaultTitle() {
    if (widget.versionInfo.updateAvailability == UpdateAvailability.required) {
      return 'Update Required';
    }
    return 'Update Available';
  }
}
