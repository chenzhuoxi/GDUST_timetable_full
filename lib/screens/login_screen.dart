import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _jobCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String? _uuid;
  Uint8List? _captchaBytes;
  bool _loadingCode = false;
  bool _loggingIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AuthService.getJobNumber().then((j) {
      if (j != null && j.isNotEmpty) _jobCtrl.text = j;
    });
  }

  @override
  void dispose() {
    _jobCtrl.dispose();
    _pwdCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCaptcha() async {
    setState(() { _loadingCode = true; _error = null; });
    try {
      final result = await AuthService.getLoginCode();
      _uuid = result['uuid'];
      final b64 = result['codeUrl']!;
      final pure = b64.contains(',') ? b64.split(',').last : b64;
      setState(() { _captchaBytes = base64.decode(pure); });
    } catch (e) {
      setState(() { _error = '获取验证码失败: $e'; });
    } finally {
      setState(() { _loadingCode = false; });
    }
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    if (msg.contains('获取验证码失败')) return '无法获取验证码，请检查是否连接了校园网';
    if (msg.contains('401') || msg.contains('Unauthorized')) return '学号或密码错误';
    if (msg.contains('验证码') || msg.contains('code')) return '验证码错误，请重新输入';
    if (msg.contains('TGC')) return '登录异常，请重试';
    if (msg.contains('Token') || msg.contains('token')) return 'Token 交换失败，请确认校园网连接正常';
    if (msg.contains('SocketException') || msg.contains('TimeoutException') || msg.contains('Connection')) return '网络连接失败，请连接校园网后重试';
    if (msg.contains('403')) return '访问被拒绝，可能需要连接校园网';
    if (msg.contains('500') || msg.contains('502') || msg.contains('503')) return '服务器暂时不可用，请稍后重试';
    return msg;
  }

  Future<void> _doLogin() async {
    if (_jobCtrl.text.isEmpty || _pwdCtrl.text.isEmpty || _codeCtrl.text.isEmpty || _uuid == null) {
      setState(() { _error = '请填写完整信息并获取验证码'; });
      return;
    }
    setState(() { _loggingIn = true; _error = null; });
    try {
      final tgc = await AuthService.loginByAccount(
        _jobCtrl.text.trim(),
        _pwdCtrl.text.trim(),
        _codeCtrl.text.trim(),
        _uuid!,
      );
      final result = await AuthService.exchangeToken(tgc);
      await AuthService.saveLogin(result.token, jobNumber: _jobCtrl.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = _friendlyError(e); });
      _fetchCaptcha();
    } finally {
      setState(() { _loggingIn = false; });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Icon(Icons.school, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),

            // 学号密码
            TextField(
              controller: _jobCtrl,
              decoration: const InputDecoration(
                labelText: '学号',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pwdCtrl,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // 校内直连模式提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text('校内直连模式', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 验证码输入
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: '验证码',
                      prefixIcon: Icon(Icons.verified),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _loadingCode ? null : _fetchCaptcha,
                  child: Container(
                    width: 160,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _loadingCode
                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : _captchaBytes != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_captchaBytes!, fit: BoxFit.cover))
                            : const Center(child: Text('获取验证码', style: TextStyle(fontSize: 12))),
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),

            // 提交按钮
            FilledButton(
              onPressed: _loggingIn ? null : _doLogin,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _loggingIn
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('登 录', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
