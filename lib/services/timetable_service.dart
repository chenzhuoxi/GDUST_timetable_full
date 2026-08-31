import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';

class TimetableService {
  static const _portalBase = 'https://portal.gdust.edu.cn';
  static const _calendarPath = '/smart-admin-api/app/zf/get_school_calendar';
  static const _coursePath = '/smart-admin-api/app/zf/get_student_course';

  /// 读取教务系统当前学期参数。
  ///
  /// 不再硬编码 year/semester：门户前端也是先调用此接口，再把返回的
  /// year、semester、week 传给课程接口。新学期切换时由学校接口决定参数。
  static Future<SchoolCalendar> fetchSchoolCalendar(
      String token, String jobNumber) async {
    final uri = Uri.parse('$_portalBase$_calendarPath').replace(
      queryParameters: {'jobNumber': jobNumber},
    );
    final resp = await http.get(uri, headers: _headers(token));
    final body = _decodeResponse(resp, '获取校历失败');
    final data = body['data'];
    if (data is! Map) {
      throw Exception('获取校历失败：返回数据格式异常');
    }

    final year = '${data['year'] ?? ''}';
    final semester = '${data['semester'] ?? ''}';
    final allWeek = _parseInt(data['allWeek'], fallback: 20);
    if (year.isEmpty || semester.isEmpty) {
      throw Exception('获取校历失败：未返回当前学期参数');
    }
    return SchoolCalendar(
      year: year,
      semester: semester,
      week: _parseInt(data['week']),
      allWeek: allWeek.clamp(1, 30),
    );
  }

  /// 获取单周课表
  static Future<List<Course>> fetchWeek(
    String token,
    String jobNumber,
    int week, {
    SchoolCalendar? calendar,
  }) async {
    final current = calendar ?? await fetchSchoolCalendar(token, jobNumber);
    final uri = Uri.parse('$_portalBase$_coursePath').replace(
      queryParameters: {
        'jobNumber': jobNumber,
        'week': '$week',
        'year': current.year,
        'semester': current.semester,
      },
    );

    final resp = await http.get(uri, headers: _headers(token));
    final body = _decodeResponse(resp, '获取第 $week 周课表失败');
    final data = body['data'];
    final courseList = data is Map && data['courseList'] is List
        ? data['courseList'] as List
        : const [];
    return courseList
        .whereType<Map>()
        .map((c) => Course.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  /// 获取全部学期课表
  static Future<Map<String, List<Course>>> fetchAllWeeks(
      String token, String jobNumber) async {
    final result = <String, List<Course>>{};
    final calendar = await fetchSchoolCalendar(token, jobNumber);
    String? lastError;
    for (int week = 1; week <= calendar.allWeek; week++) {
      try {
        final courses =
            await fetchWeek(token, jobNumber, week, calendar: calendar);
        if (courses.isNotEmpty) {
          result['$week'] = courses;
        }
      } catch (e) {
        lastError = e.toString();
      }
    }
    if (result.isEmpty && lastError != null) {
      throw Exception('全学期课表获取失败：$lastError');
    }
    return result;
  }

  static Map<String, String> _headers(String token) => {
        'TOKEN': token,
        'Accept': 'application/json, text/plain, */*',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
      };

  static Map<String, dynamic> _decodeResponse(
      http.Response resp, String message) {
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: $message');
    }
    final decoded = json.decode(resp.body);
    if (decoded is! Map) throw Exception('$message：返回格式异常');
    final body = Map<String, dynamic>.from(decoded);
    // 兼容门户当前的 code 响应和旧版 success 响应。
    final success = body['success'];
    final code = body['code'];
    if (success == false ||
        (success != true && code != null && code != 1 && code != 0)) {
      throw Exception(body['msg'] ?? body['message'] ?? message);
    }
    return body;
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    final parsed = value is int ? value : int.tryParse('$value');
    return parsed ?? fallback;
  }

  /// 缓存课表到 SharedPreferences
  static Future<void> cacheTimetable(
      Map<String, List<Course>> timetable) async {
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
          result[week] = courses
              .map((c) => Course.fromJson(c as Map<String, dynamic>))
              .toList();
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

class SchoolCalendar {
  final String year;
  final String semester;
  final int week;
  final int allWeek;

  const SchoolCalendar({
    required this.year,
    required this.semester,
    required this.week,
    required this.allWeek,
  });
}
