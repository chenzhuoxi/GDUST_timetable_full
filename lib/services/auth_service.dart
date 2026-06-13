import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _casBase = 'https://cas.gdust.edu.cn/cas-api/cas';

  /// 获取验证码 (uuid + base64 图片)
  static Future<Map<String, String>> getLoginCode() async {
    final uri = Uri.parse('$_casBase/loginCode');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('获取验证码失败: ${resp.statusCode}');
    }
    final data = json.decode(resp.body);
    if (data['code'] != 0) {
      throw Exception(data['msg'] ?? '获取验证码失败');
    }
    final uuid = data['data']?['uuid'] ?? data['uuid'] ?? '';
    final codeUrl = data['data']?['codeUrl'] ?? data['codeUrl'] ?? '';
    if (uuid.isEmpty || codeUrl.isEmpty) {
      throw Exception('验证码数据格式异常');
    }
    return {'uuid': uuid, 'codeUrl': codeUrl};
  }

  /// CAS 登录，返回 TGC
  static Future<String> loginByAccount(String loginName, String loginPwd, String code, String uuid) async {
    final uri = Uri.parse('$_casBase/loginByAccount');
    final resp = await http.post(uri, headers: {
      'Content-Type': 'application/json',
    }, body: json.encode({
      'loginName': loginName,
      'loginPwd': loginPwd,
      'code': code,
      'uuid': uuid,
    }));
    if (resp.statusCode != 200) {
      throw Exception('登录请求失败: ${resp.statusCode}');
    }
    final data = json.decode(resp.body);
    if (data['code'] != 0) {
      throw Exception(data['msg'] ?? '登录失败');
    }
    final tgc = data['data'];
    if (tgc is! String || tgc.isEmpty) {
      throw Exception('登录成功但未获取到 TGC');
    }
    return tgc;
  }

  /// 用 TGC 换取 Portal TOKEN
  static Future<ExchangeResult> exchangeToken(String tgc) async {
    final uri = Uri.parse(
      'https://portal.gdust.edu.cn/smart-admin-api/user/login?loginCode=$tgc&appId=portalRemote',
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Token 交换失败: ${resp.statusCode}');
    }
    final body = json.decode(resp.body);
    if (body['success'] != true) {
      throw Exception(body['msg'] ?? 'Token 交换失败');
    }
    final userBase = body['data']?['userBase'];
    final token = userBase?['token'];
    if (token is! String || token.isEmpty) {
      throw Exception('Token 交换失败：未从响应中提取到 token');
    }
    return ExchangeResult(token: token);
  }

  /// 保存登录信息
  static Future<void> saveLogin(String token, {String? jobNumber}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('token_updated_at', DateTime.now().toIso8601String());
    if (jobNumber != null) {
      await prefs.setString('job_number', jobNumber);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<String?> getJobNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('job_number');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token_updated_at');
    await prefs.remove('job_number');
    await prefs.remove('vpn_cookies');
  }
}

class ExchangeResult {
  final String token;
  ExchangeResult({required this.token});
}
