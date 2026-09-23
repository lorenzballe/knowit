package com.astuto.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

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
        internal const val PREFS = "astut_widget"
        private const val PAPER = 0xFF141416.toInt()

        /// Keeps what the app handed over, all of it, for all three widgets:
        /// words and numbers as they come, and each day of a calendar map
        /// under its own key.
        fun store(context: Context, data: Map<*, *>) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            prefs.clear()
            for ((key, value) in data) {
                if (key !is String) continue
                when (value) {
                    is String -> prefs.putString(key, value)
                    is Boolean -> prefs.putBoolean(key, value)
                    is Number -> prefs.putInt(key, value.toInt())
                    is Map<*, *> -> value.forEach { (day, line) ->
                        if (day is String && line is String) prefs.putString("${key}_$day", line)
                    }
                }
            }
            prefs.apply()
        }

        /// Redraws every widget of Astute on the home screen.
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            fun ids(provider: Class<*>) = manager.getAppWidgetIds(ComponentName(context, provider))
            render(context, manager, ids(AstutWidget::class.java))
            AstutStreakWidget.render(context, manager, ids(AstutStreakWidget::class.java))
            AstutFiveWidget.render(context, manager, ids(AstutFiveWidget::class.java))
        }

        /// Draws every instance of the widget from what is stored.
        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val today = todayKey()
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
                streak > 0 -> "● " + (prefs.getString("footStreak", "") ?: "")
                else -> prefs.getString("footPlain", "") ?: ""
            }
            val eyebrow = if (topic.isEmpty()) "ASTUTE" else "✦ " + topic.uppercase(Locale.getDefault())
            val dim = (ink and 0x00FFFFFF) or (0xB8 shl 24)
            val faint = (ink and 0x00FFFFFF) or (0xC7 shl 24)

            val pending = openApp(context)
            val empty = context.getString(R.string.widget_card_empty)
            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.astut_widget)
                views.setInt(R.id.widget_bg, "setColorFilter", color)
                views.setTextViewText(R.id.widget_eyebrow, eyebrow)
                views.setTextColor(R.id.widget_eyebrow, dim)
                views.setTextViewText(R.id.widget_edition, if (edition > 0) "#$edition" else "")
                views.setTextColor(R.id.widget_edition, dim)
                views.setTextViewText(R.id.widget_question, question.ifEmpty { empty })
                views.setTextColor(R.id.widget_question, ink)
                views.setTextViewText(R.id.widget_foot, foot)
                views.setTextColor(R.id.widget_foot, faint)
                views.setOnClickPendingIntent(R.id.widget_root, pending)
                manager.updateAppWidget(id, views)
            }
        }

        /// Tapping any of the widgets opens the app.
        internal fun openApp(context: Context): PendingIntent = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        internal fun todayKey(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

        /// "#RRGGBB" as the app writes it, or the fallback when it did not.
        internal fun parse(hex: String, fallback: Int): Int {
            val s = hex.trim()
            if (s.length != 7 || !s.startsWith("#")) return fallback
            return try {
                Color.parseColor(s)
            } catch (e: IllegalArgumentException) {
                fallback
            }
        }

        /// Whole days from one date to another. Rounded, not cut: the day the
        /// clocks go forward is 23 hours long, and still a day.
        internal fun daysBetween(from: String, to: String): Int {
            if (from.isEmpty()) return 0
            return try {
                val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                val a = format.parse(from)?.time ?: return 0
                val b = format.parse(to)?.time ?: return 0
                ((b - a) / 86_400_000.0).roundToInt()
            } catch (e: Exception) {
                0
            }
        }
    }
}
