package com.astuto.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/// The card the morning opens on, on the home screen — drawn the way the
/// app draws a card: the subject's colour for a ground, the subject as an
/// eyebrow, the question set large, and a foot with the streak.
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
        private const val PAPER = 0xFF141416.toInt()

        /// Keeps what the app handed over.
        fun store(context: Context, data: Map<*, *>) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            prefs.clear()
            prefs.putInt("edition", (data["edition"] as? Number)?.toInt() ?: 0)
            for (key in listOf("date", "question", "topic", "color", "ink", "footPlain", "footStreak", "footDone")) {
                prefs.putString(key, data[key] as? String ?: "")
            }
            prefs.putInt("streak", (data["streak"] as? Number)?.toInt() ?: 0)
            prefs.putBoolean("done", data["done"] as? Boolean ?: false)
            for (map in listOf("ahead", "aheadTopic", "aheadColor", "aheadInk")) {
                (data[map] as? Map<*, *>)?.forEach { (day, value) ->
                    if (day is String && value is String) prefs.putString("${map}_$day", value)
                }
            }
            prefs.apply()
        }

        /// Draws every instance of the widget from what is stored.
        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val stored = prefs.getString("date", "") ?: ""
            val sameDay = stored == today
            fun today(key: String, aheadMap: String): String {
                val own = prefs.getString(key, "") ?: ""
                // Today's own line while the app has seen today; otherwise
                // the calendar's line for this date, handed over in advance.
                return if (sameDay) own else prefs.getString("${aheadMap}_$today", null) ?: own
            }
            val question = today("question", "ahead")
            val topic = today("topic", "aheadTopic")
            val color = parse(today("color", "aheadColor"), PAPER)
            val ink = parse(today("ink", "aheadInk"), Color.WHITE)
            val edition = prefs.getInt("edition", 0) + daysBetween(stored, today)
            val streak = prefs.getInt("streak", 0)
            val done = sameDay && prefs.getBoolean("done", false)
            // The streak is only known for the day the app last saw; a later
            // morning says what the day is, not what it did.
            val foot = when {
                !sameDay -> prefs.getString("footPlain", "") ?: ""
                done -> "✓ " + (prefs.getString("footDone", "") ?: "")
                streak > 0 -> "🔥 " + (prefs.getString("footStreak", "") ?: "")
                else -> prefs.getString("footPlain", "") ?: ""
            }
            val eyebrow = if (topic.isEmpty()) "ASTUTE" else "✦ " + topic.uppercase(Locale.getDefault())
            val dim = (ink and 0x00FFFFFF) or (0xB8 shl 24)
            val faint = (ink and 0x00FFFFFF) or (0xC7 shl 24)

            val launch = Intent(context, MainActivity::class.java)
            val pending = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.astut_widget)
                views.setInt(R.id.widget_bg, "setColorFilter", color)
                views.setTextViewText(R.id.widget_eyebrow, eyebrow)
                views.setTextColor(R.id.widget_eyebrow, dim)
                views.setTextViewText(R.id.widget_edition, if (edition > 0) "#$edition" else "")
                views.setTextColor(R.id.widget_edition, dim)
                views.setTextViewText(R.id.widget_question, question.ifEmpty { "Five cards a day, two minutes." })
                views.setTextColor(R.id.widget_question, ink)
                views.setTextViewText(R.id.widget_foot, foot)
                views.setTextColor(R.id.widget_foot, faint)
                views.setOnClickPendingIntent(R.id.widget_root, pending)
                manager.updateAppWidget(id, views)
            }
        }

        /// "#RRGGBB" as the app writes it, or the fallback when it did not.
        private fun parse(hex: String, fallback: Int): Int {
            val s = hex.trim()
            if (s.length != 7 || !s.startsWith("#")) return fallback
            return try {
                Color.parseColor(s)
            } catch (e: IllegalArgumentException) {
                fallback
            }
        }

        private fun daysBetween(from: String, to: String): Int {
            if (from.isEmpty()) return 0
            return try {
                val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                val a = format.parse(from)?.time ?: return 0
                val b = format.parse(to)?.time ?: return 0
                ((b - a) / 86_400_000L).toInt()
            } catch (e: Exception) {
                0
            }
        }
    }
}
