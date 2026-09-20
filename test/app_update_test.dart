import 'package:flutter_test/flutter_test.dart';
import 'package:fleetboard/features/updater/models/app_update_info.dart';

void main() {
  group('AppUpdateInfo Tests', () {
    test('fromGitHubRelease detects newer version and apk url', () {
      final githubJson = {
        'tag_name': 'v1.0.1',
        'body': 'Added new export feature\n[mandatory]',
        'assets': [
          {
            'name': 'source.zip',
            'browser_download_url': 'https://github.com/test/archive.zip'
          },
          {
            'name': 'app-release.apk',
            'browser_download_url': 'https://github.com/releases/app-release.apk'
          }
        ]
      };

      final info = AppUpdateInfo.fromGitHubRelease(
        githubJson,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
      );

      expect(info.latestVersion, '1.0.1');
      expect(info.hasUpdate, isTrue);
      expect(info.isMandatory, isTrue);
      expect(info.downloadUrl, 'https://github.com/releases/app-release.apk');
      expect(info.releaseNotes, contains('Added new export feature'));
    });

    test('fromGitHubRelease does not flag update if version is older or same', () {
      final githubJson = {
        'tag_name': 'v1.0.0',
        'body': 'Initial release',
        'assets': [
          {
            'name': 'app-release.apk',
            'browser_download_url': 'https://github.com/releases/app-release.apk'
          }
        ]
      };

      final info = AppUpdateInfo.fromGitHubRelease(
        githubJson,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
      );

      expect(info.hasUpdate, isFalse);
    });

    test('fromGitHubRelease handles missing apk asset gracefully', () {
      final githubJson = {
        'tag_name': 'v1.1.0',
        'body': 'Only tarballs',
        'assets': [
          {
            'name': 'source.tar.gz',
            'browser_download_url': 'https://github.com/test/archive.tar.gz'
          }
        ]
      };

      final info = AppUpdateInfo.fromGitHubRelease(
        githubJson,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
      );

      expect(info.hasUpdate, isFalse);
      expect(info.downloadUrl, isEmpty);
    });

    test('fromFirestore parses update document correctly', () {
      final firestoreDoc = {
        'latestVersion': '1.0.2',
        'latestBuildNumber': 3,
        'downloadUrl': 'https://example.com/app.apk',
        'releaseNotes': 'Performance upgrades',
        'isMandatory': false,
      };

      final info = AppUpdateInfo.fromFirestore(
        firestoreDoc,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
      );

      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, '1.0.2');
      expect(info.latestBuildNumber, 3);
      expect(info.isMandatory, isFalse);
      expect(info.downloadUrl, 'https://example.com/app.apk');
    });
  });
}
