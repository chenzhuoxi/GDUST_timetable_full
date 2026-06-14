package com.jikuai.gdust_full

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import android.os.Bundle
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
                    pinWidget(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun pinWidget(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            if (appWidgetManager.isRequestPinAppWidgetSupported) {
                // 优先添加 4×2 标准小组件
                val provider = ComponentName(this, MediumWidgetProvider::class.java)
                val pinned = appWidgetManager.requestPinAppWidget(provider, null, null)
                if (pinned) {
                    result.success("正在添加小组件到桌面…")
                } else {
                    result.success("请长按桌面空白处 → 小组件 → 搜索「广科课表」")
                }
            } else {
                result.success("请长按桌面空白处 → 小组件 → 搜索「广科课表」")
            }
        } else {
            result.success("请长按桌面空白处 → 小组件 → 搜索「广科课表」")
        }
    }
}
