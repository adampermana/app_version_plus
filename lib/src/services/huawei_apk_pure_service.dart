import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/store_urls.dart';
import '../enums/device_type.dart';
import '../models/version_info.dart';
import '../utils/date_utils.dart';
import '../utils/html_utils.dart';
import '../utils/string_utils.dart';

/// Service for scraping APK information from APK Pure
/// Used primarily for Huawei devices and alternative APK distribution
class ApkPureService {
  final String? appId;
  final String? forceAppVersion;
  final bool htmlReleaseNotes;
  final String? countryCode;

  ApkPureService({
    this.appId,
    this.forceAppVersion,
    this.htmlReleaseNotes = false,
    this.countryCode = 'en_US',
  });

  /// Gets app version and metadata from APK Pure
  ///
  /// Extracts the following data:
  /// - Version number (e.g., "1.0.5")
  /// - Release notes/What's New
  /// - App icon URL
  /// - App name
  /// - Developer/Publisher name
  /// - Direct APK download URL
  /// - Rating score (1-5)
  /// - Number of ratings
  /// - Download count
  /// - Age rating (e.g., "4+", "12+", "17+")
  /// - Content rating description
  /// - Last update date
  ///
  /// The [packageInfo] is used to get the package name if [appId] is not provided.
  /// Returns null if the page cannot be fetched or parsed.
  Future<VersionInfo?> getStoreVersion(
    PackageInfo packageInfo, {
    String? packageName,
  }) async {
    final id = appId ?? packageName ?? packageInfo.packageName;

    // Build APK Pure URL
    final uri = Uri.https('apkpure.com', '/flutter-app/$id');

    http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
        },
      );
    } catch (e) {
      debugPrint('Error fetching APK Pure page: $e');
      return null;
    }

    if (response.statusCode != 200) {
      debugPrint('APK Pure returned status code: ${response.statusCode}');
      return null;
    }

    try {
      // Extract version
      final String? storeVersion = _extractVersion(response.body);
      if (storeVersion == null) {
        debugPrint('Could not extract version from APK Pure');
        return null;
      }

      // Extract all other information
      String? releaseNotes = await _fetchReleaseNotesFromPlayStore(
        id,
        countryCode ?? 'en_US',
      );
      // Fetch icon from Play Store
      final playStoreUri =
          Uri.https(StoreUrls.playStore, "/store/apps/details", {
        "id": id.toString(),
        "hl": countryCode ?? "en_US",
        "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
      });
      String? appIconUrl;
      try {
        final playStoreResponse = await http.get(playStoreUri);
        if (playStoreResponse.statusCode == 200) {
          appIconUrl = _extractAppIconUrl(playStoreResponse.body);
        }
      } catch (e) {
        debugPrint('Error fetching Play Store icon for Huawei: $e');
      }
      // Fallback to APKPure icon if Play Store fetch failed
      appIconUrl ??= _extractAppIconUrl(response.body);

      final String? appName = _extractAppName(response.body);
      final String? developerName = _extractDeveloperName(response.body);
      var downloadUrl = _extractDownloadUrl(response.body);
      final Map<String, String?> metadata = _extractRatings(response.body);
      final DateTime? lastUpdateDate = _extractLastUpdateDate(response.body);

      // Fallback: If download URL not found or is invalid, generate a CDN template URL
      if (downloadUrl == null ||
          downloadUrl.isEmpty ||
          !_isValidDownloadUrl(downloadUrl)) {
        debugPrint(
            'Download URL not extracted or invalid from HTML, using fallback CDN template');
        // Use the APK Pure CDN template format with the package ID
        downloadUrl = 'https://d.apkpure.com/b/APK/$id?version=latest';
        debugPrint('Fallback download URL generated: $downloadUrl');
      }

      // Debug log all extracted data
      debugPrint('=== APK Pure Extraction Debug ===');
      debugPrint('URL: ${uri.toString()}');
      debugPrint('Version: $storeVersion');
      debugPrint('App Name: $appName');
      debugPrint('Developer: $developerName');
      debugPrint('Icon: $appIconUrl');
      debugPrint('Download URL: $downloadUrl');
      debugPrint('Rating: ${metadata['rating']}');
      debugPrint('Rating Count: ${metadata['ratingCount']}');
      debugPrint('Download Count: ${metadata['downloadCount']}');
      debugPrint('Age Rating: ${metadata['ageRating']}');
      debugPrint('Content Rating: ${metadata['contentRating']}');
      debugPrint('Last Update: $lastUpdateDate');
      debugPrint(
          'Release Notes: ${releaseNotes?.substring(0, math.min(releaseNotes.length, 100)) ?? 'null'}');
      debugPrint(
          'Download URL is using template: ${downloadUrl.contains('?version=latest')}');
      debugPrint('================================');

      return VersionInfo.fromStore(
        localVersion: StringUtils.getCleanVersion(packageInfo.version),
        storeVersion: StringUtils.getCleanVersion(
          forceAppVersion ?? storeVersion,
        ),
        originalStoreVersion: forceAppVersion ?? storeVersion,
        appStoreLink: uri.toString(),
        releaseNotes:
            HtmlUtils.formatReleaseNotes(releaseNotes, htmlReleaseNotes),
        lastUpdateDate: lastUpdateDate,
        appName: appName,
        developerName: developerName,
        appIconUrl: appIconUrl,
        rating: metadata['rating'] != null
            ? double.tryParse(metadata['rating']!)
            : null,
        ratingCount: metadata['ratingCount'] != null
            ? int.tryParse(metadata['ratingCount']!)
            : null,
        downloadCount: metadata['downloadCount'],
        ageRating: metadata['ageRating'],
        contentRating: metadata['contentRating'],
        deviceType: DeviceType.huawei,
        apkDownloadUrl: downloadUrl,
      );
    } catch (e) {
      debugPrint('Error parsing APK Pure response: $e');
      return null;
    }
  }

  /// Extracts version number from APK Pure HTML
  String? _extractVersion(String html) {
    try {
      // Pattern 1: Look for version in data attributes
      final regex1 = RegExp(
        r'data-version="([0-9]+\.[0-9]+(?:\.[0-9]+)?)"',
        caseSensitive: false,
      );
      final match1 = regex1.firstMatch(html);
      if (match1 != null) return match1.group(1);

      // Pattern 2: Look for version in specific div
      final regex2 = RegExp(
        r'<span[^>]*class="[^"]*version[^"]*"[^>]*>([0-9]+\.[0-9]+(?:\.[0-9]+)?)<\/span>',
        caseSensitive: false,
      );
      final match2 = regex2.firstMatch(html);
      if (match2 != null) return match2.group(1);

      // Pattern 3: Look for version number pattern
      final regex3 = RegExp(
        r'Version[:\s]+([0-9]+\.[0-9]+(?:\.[0-9]+)?)',
        caseSensitive: false,
      );
      final match3 = regex3.firstMatch(html);
      if (match3 != null) return match3.group(1);

      // Pattern 4: Search in common version patterns
      final regex4 = RegExp(
        r'"version"\s*:\s*"([0-9]+\.[0-9]+(?:\.[0-9]+)?)"',
        caseSensitive: false,
      );
      final match4 = regex4.firstMatch(html);
      if (match4 != null) return match4.group(1);

      return null;
    } catch (e) {
      debugPrint('Error extracting version: $e');
      return null;
    }
  }

  Future<String?> _fetchReleaseNotesFromPlayStore(
    String packageId,
    String countryCode,
  ) async {
    final uri = Uri.https('play.google.com', '/store/apps/details', {
      'id': packageId,
      'hl': countryCode,
      'gl': 'US',
    });

    try {
      final response = await http.get(uri, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
      });

      if (response.statusCode != 200) return null;

      return _extractReleaseNotesFromPlayStoreHtml(response.body);
    } catch (e) {
      debugPrint('Error fetching Play Store release notes: $e');
      return null;
    }
  }

  String? _extractReleaseNotesFromPlayStoreHtml(String html) {
    // Pattern 1: What's new section in Play Store HTML (JSON encoded)
    final regex1 = RegExp(
      r'\[\[\["(.*?)"\]\].*?recentChangesHtml',
      caseSensitive: false,
      dotAll: true,
    );
    final match1 = regex1.firstMatch(html);
    if (match1 != null) {
      return match1
          .group(1)
          ?.replaceAll(r'\n', '\n')
          .replaceAll(r'\"', '"')
          .trim();
    }

    // Pattern 2: Itemprop="description" after "What's new" heading
    final regex2 = RegExp(
      r"What.s [Nn]ew.*?<div[^>]*>(.*?)</div>",
      caseSensitive: false,
      dotAll: true,
    );
    final match2 = regex2.firstMatch(html);
    if (match2 != null) {
      return match2
          .group(1)
          ?.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
    }

    return null;
  }

  /// Extracts app icon URL from APK Pure HTML
  String? _extractAppIconUrl(String body) {
    try {
      // Method 1: Structured data
      final structuredIconRegex =
          RegExp(r'"image"\s*:\s*"([^"]*)"', caseSensitive: false);
      final structuredMatch = structuredIconRegex.firstMatch(body);
      if (structuredMatch != null) return structuredMatch.group(1);

      // Method 2: Meta tags
      final metaIconRegex = RegExp(
          r'<meta\s+property="og:image"\s+content="([^"]+)"',
          caseSensitive: false);
      final metaMatch = metaIconRegex.firstMatch(body);
      if (metaMatch != null) return metaMatch.group(1);

      // Method 3: Play Store patterns
      final playStoreIconPatterns = [
        RegExp(r'src="([^"]*play-lh\.googleusercontent\.com[^"]*=s512[^"]*)"'),
        RegExp(r'src="([^"]*play-lh\.googleusercontent\.com[^"]*=s256[^"]*)"'),
        RegExp(r'src="([^"]*play-lh\.googleusercontent\.com[^"]*=s128[^"]*)"'),
        RegExp(r'src="([^"]*play-lh\.googleusercontent\.com[^"]*)"'),
        RegExp(r'<img[^>]*class="[^"]*icon[^"]*"[^>]*src="([^"]*)"'),
        RegExp(r'<img[^>]*src="([^"]*)"[^>]*class="[^"]*icon[^"]*"'),
      ];

      for (final pattern in playStoreIconPatterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          var url = match.group(1);
          if (url != null && url.contains('play-lh.googleusercontent.com')) {
            url = url.replaceAll(RegExp(r'=s\d+'), '=s512');
            if (!url.contains('=s')) url += '=s512';
          }
          return url;
        }
      }

      // Method 4: JSON-LD
      final jsonLdPattern = RegExp(
          r'"@type"\s*:\s*"MobileApplication"[^}]*"image"\s*:\s*"([^"]*)"',
          caseSensitive: false,
          dotAll: true);
      final jsonLdMatch = jsonLdPattern.firstMatch(body);
      if (jsonLdMatch != null) {
        var url = jsonLdMatch.group(1);
        if (url != null && !url.startsWith('http')) {
          if (url.startsWith('//')) {
            url = 'https:$url';
          } else if (url.startsWith('/')) {
            url = 'https://play.google.com$url';
          }
        }
        return url;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Extracts app name from APK Pure HTML
  String? _extractAppName(String html) {
    try {
      // Pattern 1: In title tag, extract the app name part
      final regex1 = RegExp(r'<title>([^<]*)<\/title>', caseSensitive: false);
      final match1 = regex1.firstMatch(html);
      if (match1 != null) {
        var title = match1.group(1)?.trim() ?? '';
        // Common patterns to remove: " - Download APK", " APK for Android Download"
        title = title
            .replaceAll(RegExp(r'\s*-\s*[Dd]ownload.*$'), '')
            .replaceAll(
                RegExp(r'\s+APK(?:\s+for\s+Android)?\s+[Dd]ownload\s*$'), '')
            .trim();
        if (title.isNotEmpty) return title;
      }

      // Pattern 2: In og:title meta tag
      final regex2 = RegExp(
        r'<meta\s+property="og:title"\s+content="([^"]+)"',
        caseSensitive: false,
      );
      final match2 = regex2.firstMatch(html);
      if (match2 != null) {
        return match2.group(1)?.trim();
      }

      // Pattern 3: In specific app name container
      final regex3 = RegExp(
        r'<h1[^>]*class="[^"]*app[^"]*name[^"]*"[^>]*>([^<]+)<\/h1>',
        caseSensitive: false,
      );
      final match3 = regex3.firstMatch(html);
      if (match3 != null) return match3.group(1)?.trim();

      // Pattern 4: In app info header
      final regex4 = RegExp(
        r'<div[^>]*class="[^"]*app-info[^"]*"[^>]*>.*?<h[\d][^>]*>([^<]+)<\/h[\d]>',
        caseSensitive: false,
        dotAll: true,
      );
      final match4 = regex4.firstMatch(html);
      if (match4 != null) return match4.group(1)?.trim();

      return null;
    } catch (e) {
      debugPrint('Error extracting app name: $e');
      return null;
    }
  }

  /// Extracts developer name from APK Pure HTML
  String? _extractDeveloperName(String html) {
    try {
      // Pattern 1: Developer info in span with class
      final regex1 = RegExp(
        r'<span[^>]*class="[^"]*developer[^"]*"[^>]*>([^<]+)<\/span>',
        caseSensitive: false,
      );
      final match1 = regex1.firstMatch(html);
      if (match1 != null) return match1.group(1)?.trim();

      // Pattern 2: Developer in link
      final regex2 = RegExp(
        r'<a[^>]*class="[^"]*developer[^"]*"[^>]*>([^<]+)<\/a>',
        caseSensitive: false,
      );
      final match2 = regex2.firstMatch(html);
      if (match2 != null) return match2.group(1)?.trim();

      // Pattern 3: "Published by" or "Developed by" text pattern
      final regex3 = RegExp(
        r'(?:Developed\s+by|Published\s+by|Developer)[:\s]*<[^>]*>([^<]+)<\/[^>]*>',
        caseSensitive: false,
      );
      final match3 = regex3.firstMatch(html);
      if (match3 != null) return match3.group(1)?.trim();

      // Pattern 4: In publisher div
      final regex4 = RegExp(
        r'<div[^>]*class="[^"]*publisher[^"]*"[^>]*>([^<]+)<\/div>',
        caseSensitive: false,
      );
      final match4 = regex4.firstMatch(html);
      if (match4 != null) return match4.group(1)?.trim();

      // Pattern 5: In developer div with id
      final regex5 = RegExp(
        r'<div[^>]*id="[^"]*developer[^"]*"[^>]*>([^<]+)<\/div>',
        caseSensitive: false,
      );
      final match5 = regex5.firstMatch(html);
      if (match5 != null) return match5.group(1)?.trim();

      // Pattern 6: In app-info section with developer data
      final regex6 = RegExp(
        r'<div[^>]*class="[^"]*app-info[^"]*"[^>]*>.*?<(?:span|div)[^>]*class="[^"]*developer[^"]*"[^>]*>([^<]+)<\/(?:span|div)>',
        caseSensitive: false,
        dotAll: true,
      );
      final match6 = regex6.firstMatch(html);
      if (match6 != null) return match6.group(1)?.trim();

      // Pattern 7: Author info
      final regex7 = RegExp(
        r'Author[:\s]*<[^>]*>([^<]+)<\/[^>]*>',
        caseSensitive: false,
      );
      final match7 = regex7.firstMatch(html);
      if (match7 != null) return match7.group(1)?.trim();

      // Pattern 8: In meta tag (og:author or similar)
      final regex8 = RegExp(
        r'<meta\s+name="og:author"\s+content="([^"]+)"',
        caseSensitive: false,
      );
      final match8 = regex8.firstMatch(html);
      if (match8 != null) return match8.group(1)?.trim();

      return null;
    } catch (e) {
      debugPrint('Error extracting developer name: $e');
      return null;
    }
  }

  /// Extracts APK download URL from APK Pure HTML
  String? _extractDownloadUrl(String html) {
    try {
      // Pattern 1: Direct CDN download link (d.apkpure.com/b/APK/) - PRIORITY
      final regex1 = RegExp(
        r'https?://d\.apkpure\.com/b/APK/[^"\s<>)]+',
        caseSensitive: false,
      );
      final match1 = regex1.firstMatch(html);
      if (match1 != null) {
        final url = match1.group(0);
        if (url != null &&
            !url.contains('login') &&
            !url.contains('javascript') &&
            _isValidDownloadUrl(url)) {
          return url;
        }
      }

      // Pattern 2: CDN with any path (d.apkpure.com) - but must have /b/ path
      final regex2 = RegExp(
        r'https?://d\.apkpure\.com/b/[^"\s<>)]+',
        caseSensitive: false,
      );
      final match2 = regex2.firstMatch(html);
      if (match2 != null) {
        final url = match2.group(0);
        if (url != null &&
            !url.contains('login') &&
            !url.contains('javascript') &&
            _isValidDownloadUrl(url)) {
          return url;
        }
      }

      // Pattern 3: APK download in /b/APK/ path with query params
      final regex3 = RegExp(
        r'https?://apkpure\.com/b/APK/[^"\s<>]+',
        caseSensitive: false,
      );
      final match3 = regex3.firstMatch(html);
      if (match3 != null) {
        var url = match3.group(0);
        if (url != null &&
            !url.contains('login') &&
            !url.contains('javascript') &&
            _isValidDownloadUrl(url)) {
          return url;
        }
      }

      // Pattern 4: href with CDN link (avoid m.apkpure)
      final regex4 = RegExp(
        r'href="(https?://d\.apkpure\.com[^"]*)"',
        caseSensitive: false,
      );
      final match4 = regex4.firstMatch(html);
      if (match4 != null) {
        final url = match4.group(1);
        if (url != null &&
            !url.contains('login') &&
            !url.contains('javascript') &&
            _isValidDownloadUrl(url)) {
          return url;
        }
      }

      // Pattern 5: Look for direct download links with full URL structure (HTTPS)
      final regex5 = RegExp(
        r'href="(https?://[^"]*\.apk[^"]*)"',
        caseSensitive: false,
      );
      final match5 = regex5.firstMatch(html);
      if (match5 != null) {
        final url = match5.group(1);
        if (url != null &&
            !url.contains('login') &&
            !url.contains('javascript') &&
            !url.contains('m.apkpure') &&
            _isValidDownloadUrl(url)) {
          return url;
        }
      }

      // Pattern 6: Download button with data-href pointing to APK
      final regex6 = RegExp(
        r'data-href="([^"]*\.apk[^"]*)"',
        caseSensitive: false,
      );
      final match6 = regex6.firstMatch(html);
      if (match6 != null) {
        final url = match6.group(1);
        if (url != null &&
            !url.contains('login') &&
            !url.contains('javascript') &&
            _isValidDownloadUrl(_normalizeUrl(url))) {
          return _normalizeUrl(url);
        }
      }

      // Pattern 7: Look for specific download div/button patterns
      final regex7 = RegExp(
        r'<(?:a|button|div)[^>]*(?:data-url|data-download|data-apk)="([^"]+\.apk[^"]*)"',
        caseSensitive: false,
      );
      final match7 = regex7.firstMatch(html);
      if (match7 != null) {
        final url = match7.group(1);
        if (url != null &&
            !url.contains('login') &&
            !url.contains('javascript') &&
            _isValidDownloadUrl(_normalizeUrl(url))) {
          return _normalizeUrl(url);
        }
      }

      // Pattern 8: Look for relative paths with .apk (avoid javascript: and m.apkpure.com)
      final regex8 = RegExp(
        r'href="((?!javascript)(?!.*m\.apkpure)[^"]*\.apk[^"]*)"',
        caseSensitive: false,
      );
      final match8 = regex8.firstMatch(html);
      if (match8 != null) {
        final url = match8.group(1);
        if (url != null &&
            !url.contains('javascript') &&
            !url.contains('m.apkpure') &&
            _isValidDownloadUrl(_normalizeUrl(url))) {
          return _normalizeUrl(url);
        }
      }

      // Pattern 9: APK in data attributes
      final regex9 = RegExp(
        'apkUrl.*?:\\s*["\']([^"\']+\\.apk[^\'"]*)["\']}',
        caseSensitive: false,
      );
      final match9 = regex9.firstMatch(html);
      if (match9 != null) {
        final url = match9.group(1);
        if (url != null &&
            !url.contains('javascript') &&
            _isValidDownloadUrl(_normalizeUrl(url))) {
          return _normalizeUrl(url);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting download URL: $e');
      return null;
    }
  }

  /// Normalizes URL (adds protocol if needed)
  String _normalizeUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('/')) return 'https://apkpure.com$url';
    return 'https://apkpure.com/$url';
  }

  /// Validates if a URL is a valid APK download URL
  ///
  /// Checks:
  /// - URL has minimum length (not just domain)
  /// - URL contains meaningful path (not just https://a.apkpure.com)
  /// - URL contains /b/ or .apk extension
  bool _isValidDownloadUrl(String url) {
    // Minimum URL length check - should have path beyond just domain
    if (url.length < 40) {
      debugPrint('Invalid download URL - too short: $url');
      return false;
    }

    // Must contain /b/ path or .apk extension
    if (!url.contains('/b/') && !url.contains('.apk')) {
      debugPrint(
          'Invalid download URL - missing /b/ path or .apk extension: $url');
      return false;
    }

    // Should have some identifier after /b/ or before .apk
    if (url.contains('/b/')) {
      final afterB = url.split('/b/').last;
      if (afterB.isEmpty || afterB.length < 5) {
        debugPrint(
            'Invalid download URL - missing package identifier after /b/: $url');
        return false;
      }
    }

    return true;
  }

  /// Extracts ratings information from APK Pure HTML
  ///
  /// Extracts:
  /// - rating: App rating score (e.g., "4.5")
  /// - ratingCount: Number of ratings (e.g., "1200")
  /// - downloadCount: Total downloads (e.g., "100K+")
  /// - ageRating: Age rating category (e.g., "4+", "12+", "17+")
  /// - contentRating: Content rating description
  Map<String, String?> _extractRatings(String html) {
    Map<String, String?> result = {
      'rating': null,
      'ratingCount': null,
      'downloadCount': null,
      'ageRating': null,
      'contentRating': null,
    };

    try {
      // Extract rating score - Multiple patterns
      // Pattern 1: In span with class or data attribute (PRIORITY)
      final ratingRegex1 = RegExp(
        r'<span[^>]*(?:class="[^"]*rating[^"]*"|data-rating="([0-9.]+)")[^>]*>([0-9.]+)<\/span>|data-rating="([0-9.]+)"',
        caseSensitive: false,
      );
      var ratingMatch = ratingRegex1.firstMatch(html);
      if (ratingMatch != null) {
        var rating = ratingMatch.group(2) ??
            ratingMatch.group(1) ??
            ratingMatch.group(3);
        if (rating != null && rating.isNotEmpty) {
          result['rating'] = rating;
        }
      }

      // Pattern 2: Rating in container div
      if (result['rating'] == null) {
        final ratingContainerRegex = RegExp(
          r'<div[^>]*class="[^"]*rating[^"]*"[^>]*>\s*([0-9.]+)',
          caseSensitive: false,
        );
        ratingMatch = ratingContainerRegex.firstMatch(html);
        if (ratingMatch != null) result['rating'] = ratingMatch.group(1);
      }

      // Pattern 3: Rating text pattern
      if (result['rating'] == null) {
        final textRatingRegex = RegExp(
          r'Rating[:\s]*([0-9.]+)(?:\s*\/\s*5)?(?:\s|<)',
          caseSensitive: false,
        );
        ratingMatch = textRatingRegex.firstMatch(html);
        if (ratingMatch != null) result['rating'] = ratingMatch.group(1);
      }

      // Pattern 4: Stars representation
      if (result['rating'] == null) {
        final starsRegex = RegExp(
          r'★+(?:\s*\/\s*★{0,5})?|[\u2605]+|rating[:\s]*(\d(?:\.\d+)?)',
          caseSensitive: false,
        );
        final starsMatch = starsRegex.firstMatch(html);
        if (starsMatch != null && starsMatch.group(1) != null) {
          result['rating'] = starsMatch.group(1);
        }
      }

      // Pattern 5: Aggressive pattern - rating between 0-5 with decimal (anywhere in page)
      if (result['rating'] == null) {
        final aggressiveRatingRegex = RegExp(
          r'(?:rate|rating|score)[:\s>]*(?:<[^>]*>)*\s*([0-4](?:\.[0-9]+)?|5(?:\.0)?)\s*(?:\/\s*5)?',
          caseSensitive: false,
        );
        ratingMatch = aggressiveRatingRegex.firstMatch(html);
        if (ratingMatch != null) {
          var rating = ratingMatch.group(1);
          if (rating != null && rating.isNotEmpty) {
            // Validate it's a reasonable rating (between 0-5)
            double? ratingValue = double.tryParse(rating);
            if (ratingValue != null && ratingValue >= 0 && ratingValue <= 5) {
              result['rating'] = rating;
            }
          }
        }
      }

      // Pattern 6: Look for rating number in common HTML structures (span/div with score class)
      if (result['rating'] == null) {
        final scoreRegex = RegExp(
          r'<(?:span|div)[^>]*(?:class|id)="[^"]*(?:score|points|rate)[^"]*"[^>]*>(?:<[^>]*>)*?\s*([0-4](?:\.[0-9]+)?|5(?:\.0)?)\s*',
          caseSensitive: false,
        );
        ratingMatch = scoreRegex.firstMatch(html);
        if (ratingMatch != null) {
          result['rating'] = ratingMatch.group(1);
        }
      }

      // Extract rating count - Multiple patterns
      // Pattern 1: In span with class containing 'count' (extract only digits, min 2 digits)
      final ratingCountRegex1 = RegExp(
        r'<span[^>]*class="[^"]*rating[^"]*count[^"]*"[^>]*>([^<]+)<\/span>',
        caseSensitive: false,
      );
      var ratingCountMatch = ratingCountRegex1.firstMatch(html);
      if (ratingCountMatch != null) {
        final count =
            ratingCountMatch.group(1)?.replaceAll(RegExp(r'[^\d]'), '');
        // Only accept if it has at least 2 digits (filter out single digit noise)
        if (count != null && count.isNotEmpty && count.length >= 2) {
          result['ratingCount'] = count;
        }
      }

      // Pattern 2: Text pattern with votes/ratings (must be 2+ digits)
      if (result['ratingCount'] == null) {
        final altRatingCountRegex = RegExp(
          r'(\d{2,})\s*(?:votes?|ratings?)',
          caseSensitive: false,
        );
        ratingCountMatch = altRatingCountRegex.firstMatch(html);
        if (ratingCountMatch != null) {
          result['ratingCount'] = ratingCountMatch.group(1);
        }
      }

      // Pattern 3: In parentheses after rating (must be 2+ digits)
      if (result['ratingCount'] == null) {
        final parenRegex = RegExp(
          r'\(\s*(\d{2,})\s*\)(?:\s*(?:votes|ratings))?',
          caseSensitive: false,
        );
        ratingCountMatch = parenRegex.firstMatch(html);
        if (ratingCountMatch != null) {
          result['ratingCount'] = ratingCountMatch.group(1);
        }
      }

      // Pattern 4: In data attributes (must be 2+ digits)
      if (result['ratingCount'] == null) {
        final dataCountRegex = RegExp(
          r'data-rating-count="(\d{2,})"',
          caseSensitive: false,
        );
        ratingCountMatch = dataCountRegex.firstMatch(html);
        if (ratingCountMatch != null) {
          result['ratingCount'] = ratingCountMatch.group(1);
        }
      }

      // Extract download count - Multiple patterns
      // Pattern 1: "Downloads" text with count value (aggressive pattern - priority)
      final downloadCountRegex1 = RegExp(
        r'Download[s]?[^0-9]*?([0-9]+(?:\.[0-9]+)?[MKB]*\+?)',
        caseSensitive: false,
      );
      var downloadCountMatch = downloadCountRegex1.firstMatch(html);
      if (downloadCountMatch != null) {
        var count = downloadCountMatch.group(1)?.trim();
        if (count != null &&
            count.length > 1 &&
            !RegExp(r'^[.,;:]$').hasMatch(count)) {
          result['downloadCount'] = count;
        }
      }

      // Pattern 2: Downloads in text tag
      if (result['downloadCount'] == null) {
        final downloadTextRegex = RegExp(
          r'Downloads?[:\s]*<[^>]*>([^<]+)<\/[^>]*>',
          caseSensitive: false,
        );
        downloadCountMatch = downloadTextRegex.firstMatch(html);
        if (downloadCountMatch != null) {
          var count = downloadCountMatch.group(1)?.trim();
          if (count != null &&
              count.length > 1 &&
              !RegExp(r'^[.,;:]$').hasMatch(count)) {
            result['downloadCount'] = count;
          }
        }
      }

      // Pattern 3: Data attribute
      if (result['downloadCount'] == null) {
        final dataDownloadRegex = RegExp(
          r'data-downloads="([^"]+)"',
          caseSensitive: false,
        );
        downloadCountMatch = dataDownloadRegex.firstMatch(html);
        if (downloadCountMatch != null) {
          var count = downloadCountMatch.group(1);
          if (count != null && count.length > 1) {
            result['downloadCount'] = count;
          }
        }
      }

      // Pattern 4: In parent elements or data attributes
      if (result['downloadCount'] == null) {
        final altDownloadRegex = RegExp(
          r'<(?:div|span)[^>]*class="[^"]*download[^"]*"[^>]*>\s*([0-9]+(?:\.[0-9]+)?[MKB]*\+?)\s*<',
          caseSensitive: false,
        );
        downloadCountMatch = altDownloadRegex.firstMatch(html);
        if (downloadCountMatch != null) {
          result['downloadCount'] = downloadCountMatch.group(1);
        }
      }

      // Extract age rating - Multiple patterns
      // Pattern 1: Text tag pattern
      final ageRatingRegex1 = RegExp(
        r'(?:Age\s+Rating|Rated)[:\s]*<[^>]*>([^<]+)<\/[^>]*>',
        caseSensitive: false,
      );
      var ageRatingMatch = ageRatingRegex1.firstMatch(html);
      if (ageRatingMatch != null) {
        result['ageRating'] = ageRatingMatch.group(1)?.trim();
      }

      // Pattern 2: Span with age class
      if (result['ageRating'] == null) {
        final altAgeRatingRegex = RegExp(
          r'<span[^>]*class="[^"]*age[^"]*"[^>]*>([^<]+)<\/span>',
          caseSensitive: false,
        );
        ageRatingMatch = altAgeRatingRegex.firstMatch(html);
        if (ageRatingMatch != null) {
          result['ageRating'] = ageRatingMatch.group(1)?.trim();
        }
      }

      // Pattern 3: Common age rating patterns
      if (result['ageRating'] == null) {
        final commonAgeRegex = RegExp(
          r'(\d+\+|Everyone|Teen|Mature|12\+|17\+|4\+)',
          caseSensitive: false,
        );
        ageRatingMatch = commonAgeRegex.firstMatch(html);
        if (ageRatingMatch != null) {
          result['ageRating'] = ageRatingMatch.group(1);
        }
      }

      // Pattern 4: Data attribute
      if (result['ageRating'] == null) {
        final dataAgeRegex = RegExp(
          r'data-age-rating="([^"]+)"',
          caseSensitive: false,
        );
        ageRatingMatch = dataAgeRegex.firstMatch(html);
        if (ageRatingMatch != null) {
          result['ageRating'] = ageRatingMatch.group(1);
        }
      }

      // Extract content rating/description
      // Pattern 1: Text tag pattern
      final contentRatingRegex1 = RegExp(
        r'(?:Content\s+Rating|Rating)[:\s]*<[^>]*>([^<]+)<\/[^>]*>',
        caseSensitive: false,
      );
      var contentRatingMatch = contentRatingRegex1.firstMatch(html);
      if (contentRatingMatch != null) {
        result['contentRating'] = contentRatingMatch.group(1)?.trim();
      }

      // Pattern 2: Data attribute
      if (result['contentRating'] == null) {
        final dataContentRegex = RegExp(
          r'data-content-rating="([^"]+)"',
          caseSensitive: false,
        );
        contentRatingMatch = dataContentRegex.firstMatch(html);
        if (contentRatingMatch != null) {
          result['contentRating'] = contentRatingMatch.group(1);
        }
      }

      // Pattern 3: Content description span
      if (result['contentRating'] == null) {
        final contentDescRegex = RegExp(
          r'<span[^>]*class="[^"]*content[^"]*"[^>]*>([^<]+)<\/span>',
          caseSensitive: false,
        );
        contentRatingMatch = contentDescRegex.firstMatch(html);
        if (contentRatingMatch != null) {
          result['contentRating'] = contentRatingMatch.group(1)?.trim();
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error extracting ratings: $e');
      return result;
    }
  }

  /// Extracts last update date from APK Pure HTML
  DateTime? _extractLastUpdateDate(String html) {
    try {
      // Pattern 1: Look for update date in common sections
      final regex1 = RegExp(
        r'Updated?[:\s]*<[^>]*>([^<]+)<\/[^>]*>',
        caseSensitive: false,
      );
      final match1 = regex1.firstMatch(html);
      if (match1 != null) {
        final dateStr = match1.group(1)?.trim();
        if (dateStr != null && dateStr.isNotEmpty) {
          return DateUtil.parseMultiLanguageDate(
              dateStr, countryCode ?? 'en_US');
        }
      }

      // Pattern 2: Update date in data attribute
      final regex2 = RegExp(
        r'data-update-date="([^"]+)"',
        caseSensitive: false,
      );
      final match2 = regex2.firstMatch(html);
      if (match2 != null) {
        final dateStr = match2.group(1);
        if (dateStr != null && dateStr.isNotEmpty) {
          return DateTime.tryParse(dateStr);
        }
      }

      // Pattern 3: ISO format date
      final regex3 = RegExp(
        r'(\d{4}-\d{2}-\d{2})',
        caseSensitive: false,
      );
      final match3 = regex3.firstMatch(html);
      if (match3 != null) {
        final dateStr = match3.group(1);
        if (dateStr != null) {
          return DateTime.tryParse(dateStr);
        }
      }

      // Pattern 4: "Last updated" text pattern
      final regex4 = RegExp(
        r'[Ll]ast\s+updated?[:\s]*([^<]+)',
        caseSensitive: false,
      );
      final match4 = regex4.firstMatch(html);
      if (match4 != null) {
        final dateStr = match4.group(1)?.trim();
        if (dateStr != null && dateStr.isNotEmpty) {
          return DateUtil.parseMultiLanguageDate(
              dateStr, countryCode ?? 'en_US');
        }
      }

      // Pattern 5: Date in common format "Jan 1, 2024" or "1 Jan 2024"
      final regex5 = RegExp(
        r'(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[\s,]*\d{1,2}[\s,]*\d{4}',
        caseSensitive: false,
      );
      final match5 = regex5.firstMatch(html);
      if (match5 != null) {
        final dateStr = match5.group(0);
        if (dateStr != null && dateStr.isNotEmpty) {
          return DateUtil.parseMultiLanguageDate(
              dateStr, countryCode ?? 'en_US');
        }
      }

      // Pattern 6: Version and date together
      final regex6 = RegExp(
        r'[Vv]ersion\s+[\d.]+.*?Updated?[:\s]*([^<\n]+)',
        caseSensitive: false,
        dotAll: true,
      );
      final match6 = regex6.firstMatch(html);
      if (match6 != null) {
        final dateStr = match6.group(1)?.trim();
        if (dateStr != null && dateStr.isNotEmpty && !dateStr.contains('<')) {
          return DateUtil.parseMultiLanguageDate(
              dateStr, countryCode ?? 'en_US');
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting last update date: $e');
      return null;
    }
  }
}
