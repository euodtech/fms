package com.querta.fms

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MapWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_map).apply {
                // Deep Link melalui HomeWidget sehingga Flutter dapat menangkap URI
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("fms://map")
                )
                setOnClickPendingIntent(R.id.widget_map_root, pendingIntent)

                val activeCount = widgetData.getInt("map_active_count", 0)
                setTextViewText(R.id.tv_active_count, "Active: $activeCount")
                
                val imagePath = widgetData.getString("map_image_path", null)
                if (imagePath != null) {
                    val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.iv_map_snapshot, bitmap)
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
