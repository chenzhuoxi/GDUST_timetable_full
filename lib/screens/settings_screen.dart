import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course.dart';
import '../services/local_timetable_service.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool mergeCourses;
  final ValueChanged<bool> onMergeChanged;

  const SettingsScreen({
    super.key,
    required this.mergeCourses,
    required this.onMergeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DateTime? _week1Monday;
  String? _jobNumber;
  @override
  void initState() {
    super.initState();
    _loadWeek1();
    _loadJobNumber();
  }

  Future<void> _loadWeek1() async {
    final saved = await LocalTimetableService.loadWeek1Monday();
    setState(() => _week1Monday = saved ?? week1Monday);
  }

  Future<void> _loadJobNumber() async {
    final jn = await AuthService.getJobNumber();
    setState(() => _jobNumber = jn);
  }

  Future<void> _pickWeek1Monday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _week1Monday ?? week1Monday,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2028, 12, 31),
      helpText: '选择学期第一周的周一',
    );
    if (picked != null) {
      await LocalTimetableService.saveWeek1Monday(picked);
      setState(() {
        _week1Monday = picked;
        week1Monday = picked;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('学期起始日已设为 ${DateFormat('yyyy-MM-dd').format(picked)}')),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    await LocalTimetableService.clearCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存已清除')),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('退出后需要重新登录才能同步课表'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('退出', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
      await LocalTimetableService.clearCache();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已退出登录')),
        );
      }
    }
  }

  Future<void> _reLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result == true) {
      await _loadJobNumber();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重新登录成功')),
        );
      }
    }
  }

  Future<void> _checkUpdate() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('正在检查更新...'),
        ]),
        duration: Duration(seconds: 10),
      ),
    );

    final info = await UpdateService.checkUpdate();
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (info.hasUpdate) {
      _showUpdateDialog(info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已是最新版本 ✓')),
      );
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.system_update, color: Colors.orange),
          SizedBox(width: 8),
          Text('发现新版本'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前: v${info.currentVersion}  →  最新: v${info.latestVersion}'),
            if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('以后再说'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.download, size: 18),
            label: const Text('去下载'),
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse(info.downloadUrl),
                  mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader('账号'),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(_jobNumber ?? '未登录'),
            subtitle: const Text('当前学号'),
            trailing: TextButton(
              onPressed: _reLogin,
              child: const Text('重新登录'),
            ),
          ),
          const Divider(),

          const _SectionHeader('学期设置'),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('学期起始日'),
            subtitle: Text(
              _week1Monday != null
                  ? DateFormat('yyyy-MM-dd（E）').format(_week1Monday!)
                  : '未设置（默认 2026-03-09）',
            ),
            trailing: const Icon(Icons.edit),
            onTap: _pickWeek1Monday,
          ),
          const Divider(),

          const _SectionHeader('显示设置'),
          SwitchListTile(
            title: const Text('合并连续课程'),
            subtitle: const Text('将同一课程的连续小节合并显示'),
            value: widget.mergeCourses,
            onChanged: widget.onMergeChanged,
          ),
          const Divider(),

          const _SectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('清除课表缓存'),
            subtitle: const Text('清除本地保存的课表数据'),
            onTap: _clearCache,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
          const Divider(),

          const _SectionHeader('关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('课表 Full'),
            subtitle: const Text('版本 1.0.7\nCAS 登录 + 自动抓取 + 桌面小组件'),
          ),
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: const Text('检查更新'),
            subtitle: const Text('当前版本 1.0.7'),
            onTap: _checkUpdate,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
