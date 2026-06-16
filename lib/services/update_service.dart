import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String? releaseNotes;
  final String? publishedAt;

  const UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    this.releaseNotes,
    this.publishedAt,
  });
}

class UpdateService {
  static const _repoOwner = 'chenzhuoxi';
  static const _repoName = 'GDUST_timetable_full';
  static const _currentVersion = '1.0.10';

  /// 检查 GitHub Releases 最新版本
  static Future<UpdateInfo> checkUpdate() async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
      );
      final response = await http.get(uri, headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return UpdateInfo(
          hasUpdate: false,
          currentVersion: _currentVersion,
          latestVersion: _currentVersion,
          downloadUrl: _releasesPage(),
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (json['tag_name'] as String?) ?? '';
      // tag 格式如 "v1.0.5"，去掉前导 v
      final latestVersion = tagName.startsWith('v')
          ? tagName.substring(1)
          : tagName;

      final hasUpdate = _compareVersions(latestVersion, _currentVersion) > 0;

      // APK 下载地址：优先用 GitHub Release 的 asset，fallback 到 server4
      String downloadUrl = _releasesPage();
      final assets = json['assets'] as List<dynamic>?;
      if (assets != null && assets.isNotEmpty) {
        for (final a in assets) {
          final name = (a['name'] as String?) ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = (a['browser_download_url'] as String?) ?? downloadUrl;
            break;
          }
        }
      }

      return UpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: _currentVersion,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: json['body'] as String?,
        publishedAt: json['published_at'] as String?,
      );
    } catch (_) {
      // 网络错误 / JSON 解析失败 → 忽略，不骚扰用户
      return UpdateInfo(
        hasUpdate: false,
        currentVersion: _currentVersion,
        latestVersion: _currentVersion,
        downloadUrl: _releasesPage(),
      );
    }
  }

  /// 比较语义版本号。返回正数表示 a > b，负数 a < b，0 相等。
  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final bParts = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final aNum = i < aParts.length ? aParts[i] : 0;
      final bNum = i < bParts.length ? bParts[i] : 0;
      if (aNum != bNum) return aNum - bNum;
    }
    return 0;
  }

  static String _releasesPage() =>
      'https://github.com/$_repoOwner/$_repoName/releases';
}
