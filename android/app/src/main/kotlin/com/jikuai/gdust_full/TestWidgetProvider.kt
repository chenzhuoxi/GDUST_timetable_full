package com.jikuai.gdust_full

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

class TestWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            WidgetDataProvider.updateWidget(
                context, appWidgetManager, appWidgetId,
                R.layout.widget_medium, "medium"
            )
        }
    }
}
