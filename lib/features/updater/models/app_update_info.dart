class AppUpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String downloadUrl;
  final String releaseNotes;
  final bool isMandatory;
  final bool hasUpdate;
  final String updateId;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    this.isMandatory = false,
    required this.hasUpdate,
    this.updateId = '',
  });

  factory AppUpdateInfo.fromFirestore(
    Map<String, dynamic> map, {
    required String currentVersion,
    required int currentBuildNumber,
    String? lastDismissedUpdateId,
  }) {
    final latestVer = map['latestVersion'] as String? ?? currentVersion;
    final latestBuild = (map['latestBuildNumber'] as num?)?.toInt() ?? currentBuildNumber;
    final updateId = map['updateId'] as String? ?? '';
    final hasNewVersion = _compareVersions(latestVer, currentVersion) > 0 || latestBuild > currentBuildNumber;
    final isPushedUpdate = updateId.isNotEmpty && updateId != (lastDismissedUpdateId ?? '');

    return AppUpdateInfo(
      latestVersion: latestVer,
      latestBuildNumber: latestBuild,
      downloadUrl: map['downloadUrl'] as String? ?? '',
      releaseNotes: map['releaseNotes'] as String? ?? 'New update available.',
      isMandatory: map['isMandatory'] as bool? ?? false,
      hasUpdate: (hasNewVersion || isPushedUpdate) && (map['downloadUrl'] as String? ?? '').isNotEmpty,
      updateId: updateId,
    );
  }

  factory AppUpdateInfo.fromGitHubRelease(Map<String, dynamic> json, {required String currentVersion, required int currentBuildNumber}) {
    final rawTag = json['tag_name'] as String? ?? '';
    final latestVer = rawTag.replaceAll('v', '').trim();
    final body = json['body'] as String? ?? 'New version available with improvements.';

    // Look for .apk asset
    String apkUrl = '';
    final assets = json['assets'] as List<dynamic>? ?? [];
    for (final asset in assets) {
      final name = (asset['name'] as String? ?? '').toLowerCase();
      if (name.endsWith('.apk')) {
        apkUrl = asset['browser_download_url'] as String? ?? '';
        break;
      }
    }

    final hasNewVersion = _compareVersions(latestVer, currentVersion) > 0;

    return AppUpdateInfo(
      latestVersion: latestVer,
      latestBuildNumber: currentBuildNumber + (hasNewVersion ? 1 : 0),
      downloadUrl: apkUrl,
      releaseNotes: body,
      isMandatory: body.toLowerCase().contains('[mandatory]'),
      hasUpdate: hasNewVersion && apkUrl.isNotEmpty,
    );
  }

  /// Returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal
  static int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;

      for (int i = 0; i < maxLen; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;
        if (p1 > p2) return 1;
        if (p1 < p2) return -1;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
