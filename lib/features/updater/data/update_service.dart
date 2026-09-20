import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../models/app_update_info.dart';

class UpdateService {
  final FirebaseFirestore _firestore;
  final http.Client _client;

  UpdateService({
    FirebaseFirestore? firestore,
    http.Client? client,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client();

  static const String _prefDismissedUpdateId = 'dismissed_update_id';

  /// Checks for available updates by first looking in Firestore (app_config/update),
  /// and falling back to the GitHub Releases API.
  Future<AppUpdateInfo?> checkForUpdate({
    String owner = AppConstants.githubOwner,
    String repo = AppConstants.githubRepo,
  }) async {
    try {
      final pkgInfo = await PackageInfo.fromPlatform();
      final currentVersion = pkgInfo.version;
      final currentBuild = int.tryParse(pkgInfo.buildNumber) ?? 1;

      final prefs = await SharedPreferences.getInstance();
      final lastDismissedId = prefs.getString(_prefDismissedUpdateId);

      // 1. Check Firestore config override first
      try {
        final doc = await _firestore.collection('app_config').doc('update').get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['latestVersion'] != null || data['downloadUrl'] != null) {
            final info = AppUpdateInfo.fromFirestore(
              data,
              currentVersion: currentVersion,
              currentBuildNumber: currentBuild,
              lastDismissedUpdateId: lastDismissedId,
            );
            return info;
          }
        }
      } catch (_) {
        // Fall through to GitHub
      }

      // 2. Query GitHub Releases API
      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
      final response = await _client.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'FleetBoard-App-Updater',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AppUpdateInfo.fromGitHubRelease(
          json,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
        );
      }
    } catch (_) {
      // Network failure, rate limit or private repo
    }
    return null;
  }

  /// Mark an updateId as dismissed so the modal doesn't re-trigger unless pushed again
  Future<void> dismissUpdate(String updateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefDismissedUpdateId, updateId);
    } catch (_) {}
  }

  /// Broadcast a push update to all users from Super Admin Console
  Future<void> pushUpdateBroadcast({
    required String latestVersion,
    required int latestBuildNumber,
    required String downloadUrl,
    required String releaseNotes,
    bool isMandatory = false,
  }) async {
    final updateId = 'push_${DateTime.now().millisecondsSinceEpoch}';
    await _firestore.collection('app_config').doc('update').set({
      'updateId': updateId,
      'latestVersion': latestVersion.trim(),
      'latestBuildNumber': latestBuildNumber,
      'downloadUrl': downloadUrl.trim(),
      'releaseNotes': releaseNotes.trim(),
      'isMandatory': isMandatory,
      'pushedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream to watch real-time updates pushed by Super Admin
  Stream<AppUpdateInfo?> watchUpdateConfig() {
    return _firestore.collection('app_config').doc('update').snapshots().asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) return null;
      try {
        final pkgInfo = await PackageInfo.fromPlatform();
        final currentVersion = pkgInfo.version;
        final currentBuild = int.tryParse(pkgInfo.buildNumber) ?? 1;

        final prefs = await SharedPreferences.getInstance();
        final lastDismissedId = prefs.getString(_prefDismissedUpdateId);

        return AppUpdateInfo.fromFirestore(
          doc.data()!,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
          lastDismissedUpdateId: lastDismissedId,
        );
      } catch (_) {
        return null;
      }
    });
  }

  /// Downloads the APK from [downloadUrl] and launches the Android Package Installer.
  Future<bool> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await _client.send(request);

      if (response.statusCode != 200) {
        return false;
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/fleetboard-update.apk');

      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (contentLength > 0) {
          final progress = receivedBytes / contentLength;
          onProgress(progress.clamp(0.0, 1.0));
        }
      }

      await sink.flush();
      await sink.close();

      // Launch native Android package installer
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );

      return result.type == ResultType.done;
    } catch (e) {
      return false;
    }
  }
}
