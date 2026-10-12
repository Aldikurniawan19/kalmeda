/// Data model containing information about an available app update from GitHub Actions / Releases.
class AppUpdateInfo {
  final String tagName;
  final String versionName;
  final String title;
  final String changelog;
  final String releaseUrl;
  final String apkDownloadUrl;
  final int? apkSizeBytes;
  final DateTime publishedAt;
  final bool isMandatory;

  const AppUpdateInfo({
    required this.tagName,
    required this.versionName,
    required this.title,
    required this.changelog,
    required this.releaseUrl,
    required this.apkDownloadUrl,
    this.apkSizeBytes,
    required this.publishedAt,
    this.isMandatory = false,
  });

  /// Formatted human-readable APK size (e.g. "32.5 MB").
  String get formattedSize {
    if (apkSizeBytes == null || apkSizeBytes! <= 0) return '';
    final mb = apkSizeBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Whether a direct .apk asset was detected in the GitHub release.
  bool get hasDirectApk => apkDownloadUrl.toLowerCase().endsWith('.apk');

  factory AppUpdateInfo.fromGitHubJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    final cleanVersion = tagName.replaceFirst(RegExp(r'^[vV]'), '').trim();
    final name = (json['name'] as String? ?? '').trim();
    final title = name.isNotEmpty ? name : 'Pembaruan Kalmeda $tagName';
    final body = (json['body'] as String? ?? '').trim();
    final changelog = body.isNotEmpty
        ? body
        : 'Peningkatan performa, stabilitas aplikasi, dan perbaikan bug.';
    final htmlUrl = (json['html_url'] as String? ??
            'https://github.com/Aldikurniawan19/kalmeda/releases')
        .trim();

    final publishedStr = json['published_at'] as String?;
    final publishedAt = publishedStr != null
        ? DateTime.tryParse(publishedStr) ?? DateTime.now()
        : DateTime.now();

    String? apkUrl;
    int? apkSize;
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final assetName = (asset['name'] as String? ?? '').toLowerCase();
          if (assetName.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            apkSize = (asset['size'] as num?)?.toInt();
            break;
          }
        }
      }
    }

    return AppUpdateInfo(
      tagName: tagName,
      versionName: cleanVersion,
      title: title,
      changelog: changelog,
      releaseUrl: htmlUrl,
      apkDownloadUrl: apkUrl ?? htmlUrl,
      apkSizeBytes: apkSize,
      publishedAt: publishedAt,
    );
  }
}
