package com.jikuai.gdust_full

import android.appwidget.AppWidgetManager
import android.content.ComponentName
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
                if (call.method == "addWidget") {
                    addWidget(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun addWidget(result: MethodChannel.Result) {
        // Android 8.0+ 尝试直接 pin
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            if (appWidgetManager.isRequestPinAppWidgetSupported) {
                val provider = ComponentName(this, MediumWidgetProvider::class.java)
                val success = appWidgetManager.requestPinAppWidget(provider, null, null)
                if (success) {
                    result.success("小组件已添加到桌面")
                    return
                }
            }
        }
        // fallback: 打开系统小组件选择器
        try {
            val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_PICK).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success("请在列表中搜索「广科课表」")
        } catch (e: Exception) {
            result.success("请长按桌面空白处 → 小组件 → 搜索「广科课表」")
        }
    }
}
