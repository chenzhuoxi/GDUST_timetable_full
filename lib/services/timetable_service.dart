import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';

class TimetableService {
  static const _year = '2025';
  static const _semester = '12';
  static const _portalBase = 'https://portal.gdust.edu.cn';
  static const _apiPath = '/smart-admin-api/app/zf/get_student_course';

  /// 获取单周课表
  static Future<List<Course>> fetchWeek(String token, String jobNumber, int week) async {
    final uri = Uri.parse(
      '$_portalBase$_apiPath?jobNumber=$jobNumber&year=$_year&semester=$_semester&week=$week',
    );

    final headers = <String, String>{
      'TOKEN': token,
      'Accept': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    };

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: 获取第 $week 周课表失败');
    }

    final body = json.decode(resp.body);
    if (body['success'] != true) {
      throw Exception(body['msg'] ?? 'API 返回失败');
    }

    final courseList = body['data']?['courseList'] as List? ?? [];
    return courseList.map((c) => Course.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// 获取全部 20 周课表
  static Future<Map<String, List<Course>>> fetchAllWeeks(String token, String jobNumber) async {
    final result = <String, List<Course>>{};
    for (int week = 1; week <= 20; week++) {
      try {
        final courses = await fetchWeek(token, jobNumber, week);
        if (courses.isNotEmpty) {
          result['$week'] = courses;
        }
      } catch (_) {
        // 某周获取失败跳过
      }
    }
    return result;
  }

  /// 缓存课表到 SharedPreferences
  static Future<void> cacheTimetable(Map<String, List<Course>> timetable) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = <String, dynamic>{};
    timetable.forEach((week, courses) {
      jsonMap[week] = courses.map((c) => c.toJson()).toList();
    });
    await prefs.setString('timetable_json', json.encode(jsonMap));
  }

  /// 读取缓存
  static Future<Map<String, List<Course>>?> loadCachedTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('timetable_json');
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final result = <String, List<Course>>{};
      data.forEach((week, courses) {
        if (courses is List) {
          result[week] = courses.map((c) => Course.fromJson(c as Map<String, dynamic>)).toList();
        }
      });
      return result;
    } catch (_) {
      return null;
    }
  }

  /// 清除缓存
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('timetable_json');
  }
}
