package com.jikuai.gdust_full

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.jikuai.gdust_full/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "addWidget" -> addWidget(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun addWidget(result: MethodChannel.Result) {
        // Android 8.0+ 使用 requestPinAppWidget（带 PendingIntent 回调）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            if (appWidgetManager.isRequestPinAppWidgetSupported) {
                // 按优先级尝试：Medium(4×2) → Compact(2×2) → Large(4×4)
                val providers = listOf(
                    ComponentName(this, MediumWidgetProvider::class.java),
                    ComponentName(this, CompactWidgetProvider::class.java),
                    ComponentName(this, LargeWidgetProvider::class.java),
                )
                for (provider in providers) {
                    try {
                        // 创建回调 PendingIntent（部分 Launcher 需要这个才能弹确认框）
                        val callbackIntent = Intent(this, MainActivity::class.java).apply {
                            action = "PIN_WIDGET_CALLBACK"
                        }
                        val pendingIntent = PendingIntent.getActivity(
                            this, 0, callbackIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        val success = appWidgetManager.requestPinAppWidget(
                            provider, null, pendingIntent
                        )
                        if (success) {
                            result.success("小组件已添加到桌面")
                            return
                        }
                    } catch (_: Exception) {
                        // 单个 provider 失败，继续尝试下一个
                    }
                }
            }
        }

        // Fallback：打开系统小组件选择器
        try {
            val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_PICK).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success("请在列表中搜索「广科课表」")
        } catch (_: Exception) {
            // 最终 fallback：给文字指引
            result.success("请长按桌面空白处 → 小组件 → 搜索「广科课表」")
        }
    }
}
