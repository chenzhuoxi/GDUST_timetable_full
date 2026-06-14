package com.jikuai.gdust_full

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/**
 * 2×2 小组件：课程节数 + 最近一节课
 */
class CompactWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            WidgetDataProvider.updateWidget(
                context, appWidgetManager, appWidgetId,
                R.layout.widget_compact, "compact"
            )
        }
    }

    override fun onReceive(context: Context, intent: android.content.Intent) {
        // 小米曝光刷新
        if ("miui.appwidget.action.APPWIDGET_UPDATE" == intent.action) {
            val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
            if (appWidgetIds != null) {
                val wm = AppWidgetManager.getInstance(context)
                for (id in appWidgetIds) {
                    WidgetDataProvider.updateWidget(context, wm, id, R.layout.widget_compact, "compact")
                }
            }
        } else {
            super.onReceive(context, intent)
        }
    }

    companion object {
        fun updateAll(context: Context) {
            val wm = AppWidgetManager.getInstance(context)
            val ids = wm.getAppWidgetIds(
                android.content.ComponentName(context, CompactWidgetProvider::class.java)
            )
            for (id in ids) {
                WidgetDataProvider.updateWidget(context, wm, id, R.layout.widget_compact, "compact")
            }
        }
    }
}
