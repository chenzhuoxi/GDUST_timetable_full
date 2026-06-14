package com.jikuai.gdust_full

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

/**
 * 共享的小组件数据更新逻辑，支持 3 种尺寸：
 * - compact (2×2): 课程节数 + 下一节课
 * - medium  (4×2): 今日课表列表
 * - large   (4×4): 今日课表卡片（最多5节）
 */
object WidgetDataProvider {

    data class CourseInfo(
        val name: String,
        val section: Int,
        val room: String
    )

    fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        layoutId: Int,
        size: String // "compact", "medium", "large"
    ) {
        val views = RemoteViews(context.packageName, layoutId)

        // 点击打开 App
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(android.R.id.background, pendingIntent)

        try {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val timetableJson = prefs.getString("timetable_json", null)

            if (timetableJson != null) {
                val data = JSONObject(timetableJson)
                val week1MondayStr = prefs.getString("week1_monday", null)

                val week1Monday = parseWeek1Monday(week1MondayStr)
                val now = Calendar.getInstance()
                val diff = ((now.timeInMillis - week1Monday!!.time) / (1000 * 60 * 60 * 24)).toInt()
                val currentWeek = (diff / 7 + 1).coerceIn(1, 20)

                val weekday = getWeekday(now)
                val dayName = getDayName(weekday)

                // 查找今天的课程
                val courses = findTodayCourses(data, currentWeek, weekday, now)

                when (size) {
                    "compact" -> updateCompact(views, dayName, currentWeek, courses)
                    "medium" -> updateMedium(views, dayName, currentWeek, courses)
                    "large" -> updateLarge(views, dayName, currentWeek, courses)
                }
            } else {
                when (size) {
                    "compact" -> {
                        views.setTextViewText(R.id.widget_compact_weekday, "课表")
                        views.setTextViewText(R.id.widget_compact_count, "未导入")
                        views.setTextViewText(R.id.widget_compact_next, "请先导入课表 📥")
                    }
                    "medium" -> {
                        views.setTextViewText(R.id.widget_title, "今日课表")
                        views.setTextViewText(R.id.widget_week, "")
                        views.setTextViewText(R.id.widget_courses, "请先导入课表数据 📥")
                    }
                    "large" -> {
                        views.setTextViewText(R.id.widget_large_title, "今日课表")
                        views.setTextViewText(R.id.widget_large_week, "")
                        views.setTextViewText(R.id.widget_large_empty, "请先导入课表数据 📥")
                        views.setViewVisibility(R.id.widget_large_empty, View.VISIBLE)
                    }
                }
            }
        } catch (e: Exception) {
            when (size) {
                "compact" -> {
                    views.setTextViewText(R.id.widget_compact_weekday, "课表")
                    views.setTextViewText(R.id.widget_compact_count, "错误")
                    views.setTextViewText(R.id.widget_compact_next, "数据加载失败")
                }
                "medium" -> {
                    views.setTextViewText(R.id.widget_title, "今日课表")
                    views.setTextViewText(R.id.widget_week, "")
                    views.setTextViewText(R.id.widget_courses, "数据加载失败")
                }
                "large" -> {
                    views.setTextViewText(R.id.widget_large_title, "今日课表")
                    views.setTextViewText(R.id.widget_large_week, "")
                    views.setTextViewText(R.id.widget_large_empty, "数据加载失败")
                    views.setViewVisibility(R.id.widget_large_empty, View.VISIBLE)
                }
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    // ==================== Compact 2×2 ====================
    private fun updateCompact(views: RemoteViews, dayName: String, currentWeek: Int, courses: List<CourseInfo>) {
        views.setTextViewText(R.id.widget_compact_weekday, "第${currentWeek}周 · $dayName")
        views.setTextViewText(R.id.widget_compact_count, "${courses.size} 节课")

        if (courses.isEmpty()) {
            views.setTextViewText(R.id.widget_compact_next, "今天没有课程 🎉")
        } else {
            // 显示最近一节课
            val next = courses.first()
            views.setTextViewText(R.id.widget_compact_next, "${sectionTimeShort(next.section)}\n${next.name}")
        }
    }

    // ==================== Medium 4×2 ====================
    private fun updateMedium(views: RemoteViews, dayName: String, currentWeek: Int, courses: List<CourseInfo>) {
        views.setTextViewText(R.id.widget_title, "今日课表 · $dayName")
        views.setTextViewText(R.id.widget_week, "第${currentWeek}周")

        if (courses.isEmpty()) {
            views.setTextViewText(R.id.widget_courses, "今天没有课程 🎉")
        } else {
            val text = courses.joinToString("\n\n") { c ->
                "📌 ${sectionTime(c.section)}  ${c.name}\n    📍 ${c.room}"
            }
            views.setTextViewText(R.id.widget_courses, text)
        }
    }

    // ==================== Large 4×4 ====================
    private fun updateLarge(views: RemoteViews, dayName: String, currentWeek: Int, courses: List<CourseInfo>) {
        views.setTextViewText(R.id.widget_large_title, "今日课表 · $dayName")
        views.setTextViewText(R.id.widget_large_week, "第${currentWeek}周")

        if (courses.isEmpty()) {
            views.setTextViewText(R.id.widget_large_empty, "今天没有课程 🎉")
            views.setViewVisibility(R.id.widget_large_empty, View.VISIBLE)
            for (i in 1..5) {
                views.setViewVisibility(getCourseLayoutId(i), View.GONE)
            }
        } else {
            views.setViewVisibility(R.id.widget_large_empty, View.GONE)
            val maxCourses = courses.size.coerceAtMost(5)
            for (i in 1..5) {
                if (i <= maxCourses) {
                    val c = courses[i - 1]
                    views.setViewVisibility(getCourseLayoutId(i), View.VISIBLE)
                    views.setTextViewText(getCourseTimeId(i), "⏰ ${sectionTime(c.section)}")
                    views.setTextViewText(getCourseNameId(i), c.name)
                    views.setTextViewText(getCourseRoomId(i), "📍 ${c.room}")
                } else {
                    views.setViewVisibility(getCourseLayoutId(i), View.GONE)
                }
            }
        }
    }

    // ==================== Helper ====================
    private fun findTodayCourses(data: JSONObject, currentWeek: Int, weekday: Int, now: Calendar): List<CourseInfo> {
        val courses = mutableListOf<CourseInfo>()
        val weekStr = currentWeek.toString()

        if (data.has(weekStr)) {
            val weekCourses = data.getJSONArray(weekStr)
            for (i in 0 until weekCourses.length()) {
                val course = weekCourses.getJSONObject(i)
                val courseDay = course.optInt("dayWeek", 0)
                val courseDate = course.optString("courseDate", "")

                val isToday = if (courseDay > 0) {
                    courseDay == weekday
                } else if (courseDate.isNotEmpty()) {
                    val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(now.time)
                    courseDate == todayStr
                } else {
                    false
                }

                if (isToday) {
                    val name = course.optString("courseName", course.optString("kcmc", course.optString("name", "?")))
                    val section = course.optInt("whichSection", course.optInt("jcs", 0))
                    val room = course.optString("classroomName", course.optString("classroom", course.optString("jxdd", "")))
                    courses.add(CourseInfo(name, section, room))
                }
            }
        }
        return courses.sortedBy { it.section }
    }

    private fun parseWeek1Monday(week1MondayStr: String?): Date? {
        return if (week1MondayStr != null) {
            try {
                SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.getDefault()).parse(week1MondayStr)
                    ?: SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).parse("2026-03-09")
            } catch (e: Exception) {
                SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).parse("2026-03-09")
            }
        } else {
            SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).parse("2026-03-09")
        }
    }

    private fun getWeekday(now: Calendar): Int {
        return when (now.get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            Calendar.SUNDAY -> 7
            else -> 1
        }
    }

    private fun getDayName(weekday: Int): String {
        return when (weekday) {
            1 -> "周一"; 2 -> "周二"; 3 -> "周三"; 4 -> "周四"
            5 -> "周五"; 6 -> "周六"; 7 -> "周日"; else -> ""
        }
    }

    private fun sectionTime(section: Int): String {
        return when (section) {
            1 -> "08:30-09:15"; 2 -> "09:20-10:05"; 3 -> "10:25-11:10"
            4 -> "11:15-12:00"; 5 -> "14:40-15:25"; 6 -> "15:30-16:15"
            7 -> "16:30-17:15"; 8 -> "17:20-18:05"; 9 -> "19:30-20:15"
            10 -> "20:20-21:05"; else -> "第${section}节"
        }
    }

    private fun sectionTimeShort(section: Int): String {
        return when (section) {
            1 -> "08:30"; 2 -> "09:20"; 3 -> "10:25"; 4 -> "11:15"
            5 -> "14:40"; 6 -> "15:30"; 7 -> "16:30"; 8 -> "17:20"
            9 -> "19:30"; 10 -> "20:20"; else -> "第${section}节"
        }
    }

    private fun getCourseLayoutId(index: Int): Int {
        return when (index) {
            1 -> R.id.widget_large_course_1; 2 -> R.id.widget_large_course_2
            3 -> R.id.widget_large_course_3; 4 -> R.id.widget_large_course_4
            5 -> R.id.widget_large_course_5; else -> R.id.widget_large_course_1
        }
    }

    private fun getCourseTimeId(index: Int): Int {
        return when (index) {
            1 -> R.id.widget_large_course_1_time; 2 -> R.id.widget_large_course_2_time
            3 -> R.id.widget_large_course_3_time; 4 -> R.id.widget_large_course_4_time
            5 -> R.id.widget_large_course_5_time; else -> R.id.widget_large_course_1_time
        }
    }

    private fun getCourseNameId(index: Int): Int {
        return when (index) {
            1 -> R.id.widget_large_course_1_name; 2 -> R.id.widget_large_course_2_name
            3 -> R.id.widget_large_course_3_name; 4 -> R.id.widget_large_course_4_name
            5 -> R.id.widget_large_course_5_name; else -> R.id.widget_large_course_1_name
        }
    }

    private fun getCourseRoomId(index: Int): Int {
        return when (index) {
            1 -> R.id.widget_large_course_1_room; 2 -> R.id.widget_large_course_2_room
            3 -> R.id.widget_large_course_3_room; 4 -> R.id.widget_large_course_4_room
            5 -> R.id.widget_large_course_5_room; else -> R.id.widget_large_course_1_room
        }
    }
}
