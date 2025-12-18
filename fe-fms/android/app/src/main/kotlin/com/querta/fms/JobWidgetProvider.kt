package com.querta.fms

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class JobWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_job).apply {
                // Deep Link melalui HomeWidget sehingga Flutter dapat menangkap URI
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("fms://job")
                )
                setOnClickPendingIntent(R.id.widget_job_root, pendingIntent)

                val open = widgetData.getInt("job_open_count", 0)
                val ongoing = widgetData.getInt("job_ongoing_count", 0)
                val complete = widgetData.getInt("job_complete_count", 0)

                setTextViewText(R.id.tv_open_count, open.toString())
                setTextViewText(R.id.tv_ongoing_count, ongoing.toString())
                setTextViewText(R.id.tv_complete_count, complete.toString())

                // Parse Recent Jobs
                val recentJobsJson = widgetData.getString("job_recent_list", "[]")
                try {
                    val jsonArray = org.json.JSONArray(recentJobsJson)
                    
                    // Item 1
                    if (jsonArray.length() > 0) {
                        val item = jsonArray.getJSONObject(0)
                        setViewVisibility(R.id.job_item_1, android.view.View.VISIBLE)
                        setTextViewText(R.id.tv_job_title_1, item.getString("title"))
                        setTextViewText(R.id.tv_job_status_1, item.getString("status"))
                    } else {
                        setViewVisibility(R.id.job_item_1, android.view.View.GONE)
                    }

                    // Item 2
                    if (jsonArray.length() > 1) {
                        val item = jsonArray.getJSONObject(1)
                        setViewVisibility(R.id.job_item_2, android.view.View.VISIBLE)
                        setTextViewText(R.id.tv_job_title_2, item.getString("title"))
                        setTextViewText(R.id.tv_job_status_2, item.getString("status"))
                    } else {
                        setViewVisibility(R.id.job_item_2, android.view.View.GONE)
                    }

                    // Item 3
                    if (jsonArray.length() > 2) {
                        val item = jsonArray.getJSONObject(2)
                        setViewVisibility(R.id.job_item_3, android.view.View.VISIBLE)
                        setTextViewText(R.id.tv_job_title_3, item.getString("title"))
                        setTextViewText(R.id.tv_job_status_3, item.getString("status"))
                    } else {
                        setViewVisibility(R.id.job_item_3, android.view.View.GONE)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
