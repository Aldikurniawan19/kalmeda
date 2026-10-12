import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/app_update/data/models/app_update_info.dart';
import 'package:menstracker/features/app_update/data/services/app_update_service.dart';

void main() {
  group('AppUpdateService Version Comparison', () {
    test('Correctly identifies newer patch versions', () {
      expect(AppUpdateService.isNewerVersion('2.0.5', '2.0.4'), isTrue);
      expect(AppUpdateService.isNewerVersion('v2.0.5', '2.0.4'), isTrue);
      expect(AppUpdateService.isNewerVersion('v2.0.5+6', '2.0.4+5'), isTrue);
    });

    test('Correctly identifies newer minor and major versions', () {
      expect(AppUpdateService.isNewerVersion('2.1.0', '2.0.4'), isTrue);
      expect(AppUpdateService.isNewerVersion('v3.0.0', '2.0.4'), isTrue);
    });

    test('Returns false for same or older versions', () {
      expect(AppUpdateService.isNewerVersion('2.0.4', '2.0.4'), isFalse);
      expect(AppUpdateService.isNewerVersion('v2.0.4', '2.0.4'), isFalse);
      expect(AppUpdateService.isNewerVersion('2.0.3', '2.0.4'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.9.8', '2.0.4'), isFalse);
    });
  });

  group('AppUpdateInfo JSON Parsing', () {
    test('Parses GitHub Actions release JSON with direct APK asset', () {
      final mockJson = {
        'tag_name': 'v2.0.5',
        'name': 'Release v2.0.5',
        'body': 'Pembaruan stabilitas dan peningkatan performa.',
        'html_url':
            'https://github.com/Aldikurniawan19/kalmeda/releases/tag/v2.0.5',
        'published_at': '2026-10-12T10:00:00Z',
        'assets': [
          {
            'name': 'app-release.apk',
            'browser_download_url':
                'https://github.com/Aldikurniawan19/kalmeda/releases/download/v2.0.5/app-release.apk',
            'size': 35651584,
          },
          {
            'name': 'app-release.aab',
            'browser_download_url':
                'https://github.com/Aldikurniawan19/kalmeda/releases/download/v2.0.5/app-release.aab',
            'size': 25000000,
          }
        ]
      };

      final info = AppUpdateInfo.fromGitHubJson(mockJson);
      expect(info.tagName, 'v2.0.5');
      expect(info.versionName, '2.0.5');
      expect(info.title, 'Release v2.0.5');
      expect(info.changelog, 'Pembaruan stabilitas dan peningkatan performa.');
      expect(info.hasDirectApk, isTrue);
      expect(
        info.apkDownloadUrl,
        'https://github.com/Aldikurniawan19/kalmeda/releases/download/v2.0.5/app-release.apk',
      );
      expect(info.formattedSize, '34.0 MB');
    });

    test('Falls back gracefully when no APK asset is present in release', () {
      final mockJson = {
        'tag_name': 'v2.0.6',
        'name': 'v2.0.6',
        'body': '',
        'html_url':
            'https://github.com/Aldikurniawan19/kalmeda/releases/tag/v2.0.6',
        'published_at': '2026-10-12T12:00:00Z',
        'assets': <dynamic>[]
      };

      final info = AppUpdateInfo.fromGitHubJson(mockJson);
      expect(info.versionName, '2.0.6');
      expect(info.hasDirectApk, isFalse);
      expect(info.apkDownloadUrl,
          'https://github.com/Aldikurniawan19/kalmeda/releases/tag/v2.0.6');
      expect(info.formattedSize, '');
    });
  });
}
