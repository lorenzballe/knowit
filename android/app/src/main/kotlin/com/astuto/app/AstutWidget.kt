package com.astuto.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/// The question of the day, on the home screen.
///
/// Everything it shows was written down by the app the last time it ran:
/// the widget reads it back and picks the line for today's date, so it
/// turns over at midnight whether or not the app is opened. Tapping it
/// opens the app.
class AstutWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    companion object {
        private const val PREFS = "astut_widget"

        /// Keeps what the app handed over.
        fun store(context: Context, data: Map<*, *>) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            prefs.clear()
            prefs.putInt("edition", (data["edition"] as? Number)?.toInt() ?: 0)
            prefs.putString("date", data["date"] as? String ?: "")
            prefs.putString("question", data["question"] as? String ?: "")
            prefs.putString("topic", data["topic"] as? String ?: "")
            prefs.putInt("streak", (data["streak"] as? Number)?.toInt() ?: 0)
            prefs.putBoolean("done", data["done"] as? Boolean ?: false)
            val ahead = data["ahead"] as? Map<*, *>
            ahead?.forEach { (day, question) ->
                if (day is String && question is String) prefs.putString("ahead_$day", question)
            }
            prefs.apply()
        }

        /// Draws every instance of the widget from what is stored.
        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val stored = prefs.getString("date", "") ?: ""
            val sameDay = stored == today
            // Today's own question while the app has seen today; otherwise
            // the calendar's line for this date, handed over in advance.
            val question = if (sameDay) {
                prefs.getString("question", "") ?: ""
            } else {
                prefs.getString("ahead_$today", null)
                    ?: prefs.getString("question", "") ?: ""
            }
            val edition = prefs.getInt("edition", 0) + daysBetween(stored, today)
            val streak = prefs.getInt("streak", 0)
            val done = sameDay && prefs.getBoolean("done", false)

            val eyebrow = if (edition > 0) "ASTUT · #$edition" else "ASTUT"
            val foot = when {
                done -> "Done for today · 🔥$streak"
                streak > 0 -> "🔥$streak · five cards, two minutes"
                else -> "Five cards, two minutes"
            }

            val launch = Intent(context, MainActivity::class.java)
            val pending = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.astut_widget)
                views.setTextViewText(R.id.widget_eyebrow, eyebrow)
                views.setTextViewText(R.id.widget_question, question)
                views.setTextViewText(R.id.widget_foot, foot)
                views.setOnClickPendingIntent(R.id.widget_root, pending)
                manager.updateAppWidget(id, views)
            }
        }

        private fun daysBetween(from: String, to: String): Int {
            if (from.isEmpty()) return 0
            return try {
                val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                val a = format.parse(from)?.time ?: return 0
                val b = format.parse(to)?.time ?: return 0
                ((b - a) / 86_400_000L).toInt()
            } catch (_: Exception) {
                0
            }
        }
    }
}
