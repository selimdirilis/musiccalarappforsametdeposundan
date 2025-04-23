package com.example.music

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class MusicWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_music)

            views.setOnClickPendingIntent(R.id.play_button, getPendingIntent(context, "PLAY"))
            views.setOnClickPendingIntent(R.id.next_button, getPendingIntent(context, "NEXT"))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun getPendingIntent(context: Context, action: String): PendingIntent {
        val intent = Intent(context, MusicWidgetReceiver::class.java).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(context, action.hashCode(), intent, PendingIntent.FLAG_IMMUTABLE)
    }
}
