import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:menstracker/core/constants/app_info.dart';
import 'package:menstracker/features/app_update/data/models/app_update_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for checking and fetching application updates directly from GitHub Actions / Releases.
class AppUpdateService {
  static const String _owner = AppInfo.githubOwner;
  static const String _repo = AppInfo.githubRepo;
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  static const String _keyDismissedVersion = 'dismissed_update_version_v1';
  static const String _keyLastCheckedMillis = 'last_checked_update_millis_v1';

  static const MethodChannel _platform =
      MethodChannel('com.menstracker/app_update');

  /// Checks if a newer version of Kalmeda is published on GitHub Releases.
  /// Returns [AppUpdateInfo] if a newer version exists, or `null` otherwise.
  static Future<AppUpdateInfo?> checkLatestRelease({
    String currentVersion = AppInfo.appVersion,
  }) async {
    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 8);
      final uri = Uri.parse(_apiUrl);
      final request = await client.getUrl(uri);

      // GitHub API requires standard headers
      request.headers.set('User-Agent', 'Kalmeda-Menstracker-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response =
          await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final bodyString = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> json = jsonDecode(bodyString);
        final updateInfo = AppUpdateInfo.fromGitHubJson(json);

        if (isNewerVersion(updateInfo.versionName, currentVersion)) {
          return updateInfo;
        }
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Compares two semantic version strings (e.g. "2.0.5" vs "2.0.4").
  /// Returns `true` if [latest] is strictly newer than [current].
  static bool isNewerVersion(String latest, String current) {
    try {
      final cleanLatest = latest
          .replaceFirst(RegExp(r'^[vV]'), '')
          .split(RegExp(r'[\+\-]'))
          .first
          .trim();
      final cleanCurrent = current
          .replaceFirst(RegExp(r'^[vV]'), '')
          .split(RegExp(r'[\+\-]'))
          .first
          .trim();

      final latestParts = cleanLatest
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final currentParts = cleanCurrent
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Launches an external URL in the native Android browser or download manager.
  static Future<bool> launchUpdateUrl(String url) async {
    try {
      final success = await _platform.invokeMethod<bool>('openUrl', {
        'url': url,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether user previously dismissed the given version update.
  static Future<bool> isVersionDismissed(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getString(_keyDismissedVersion);
      return dismissedVersion == version;
    } catch (_) {
      return false;
    }
  }

  /// Saves the dismissed update version to prevent recurring popups.
  static Future<void> saveDismissedVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDismissedVersion, version);
    } catch (_) {}
  }

  /// Clears dismissed version preference (used when user manually checks for update).
  static Future<void> clearDismissedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDismissedVersion);
    } catch (_) {}
  }

  /// Records timestamp of last automatic update check.
  static Future<void> recordLastCheckedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _keyLastCheckedMillis,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Returns whether enough time has passed (e.g. 6 hours) since last auto-check.
  static Future<bool> shouldCheckAutomatically({
    Duration interval = const Duration(hours: 6),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMillis = prefs.getInt(_keyLastCheckedMillis);
      if (lastMillis == null) return true;
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      return DateTime.now().difference(lastDate) >= interval;
    } catch (_) {
      return true;
    }
  }
}
