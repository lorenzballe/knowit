package com.astuto.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import kotlin.math.max
import kotlin.math.min

/// The streak on the home screen: the days in a row, large, and the week
/// under it — seven dots, filled for a day read through, the last one
/// today's.
///
/// It reads what the app last wrote. A streak survives a day not read yet,
/// so the morning after the app last ran still shows it, with today's dot
/// open; two mornings on it cannot be vouched for, and the widget asks for
/// today's five instead. The week rolls on by itself: each new day pushes
/// the oldest dot out and an open one in.
class AstutStreakWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    companion object {
        private const val CREAM = 0xFFF2F1EC.toInt()
        private const val CAPTION = 0x9EF2F1EC.toInt()
        private const val LABEL = 0x6BF2F1EC.toInt()
        private const val LABEL_TODAY = 0xEBF2F1EC.toInt()

        private val DOTS = intArrayOf(
            R.id.week_dot_0, R.id.week_dot_1, R.id.week_dot_2, R.id.week_dot_3,
            R.id.week_dot_4, R.id.week_dot_5, R.id.week_dot_6,
        )
        private val LABELS = intArrayOf(
            R.id.week_label_0, R.id.week_label_1, R.id.week_label_2, R.id.week_label_3,
            R.id.week_label_4, R.id.week_label_5, R.id.week_label_6,
        )

        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val prefs = context.getSharedPreferences(AstutWidget.PREFS, Context.MODE_PRIVATE)
            val stored = prefs.getString("date", "") ?: ""
            val known = stored.isNotEmpty() && prefs.contains("weekDone")

            val gap = max(0, AstutWidget.daysBetween(stored, AstutWidget.todayKey()))
            var week = (prefs.getString("weekDone", "") ?: "").map { it == '1' }
            var labels = strings(prefs.getString("weekLabels", "") ?: "")
            if (gap > 0 && week.size == 7 && labels.size == 7) {
                val k = min(gap, 7)
                week = week.drop(k) + List(k) { false }
                // Initials come round every seven days.
                labels = labels.drop(k) + labels.take(k)
            }
            val alive = gap == 0 || (gap == 1 && prefs.getBoolean("done", false))
            val streak = if (alive) prefs.getInt("streak", 0) else 0

            val caption = if (known) prefs.getString("streakCaption", "") ?: "" else ""
            val start = if (known) {
                prefs.getString("streakStart", "") ?: ""
            } else {
                context.getString(R.string.widget_streak_open)
            }

            val pending = AstutWidget.openApp(context)
            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.astut_streak_widget)
                views.setTextViewText(R.id.streak_caption, caption.ifEmpty { "ASTUTE" })
                views.setTextColor(R.id.streak_caption, CAPTION)
                if (streak > 0) {
                    views.setTextViewText(R.id.streak_number, streak.toString())
                    views.setTextColor(R.id.streak_number, CREAM)
                    views.setViewVisibility(R.id.streak_number, View.VISIBLE)
                    views.setViewVisibility(R.id.streak_start, View.GONE)
                } else {
                    views.setTextViewText(R.id.streak_start, start)
                    views.setTextColor(R.id.streak_start, CREAM)
                    views.setViewVisibility(R.id.streak_start, View.VISIBLE)
                    views.setViewVisibility(R.id.streak_number, View.GONE)
                }
                if (known && week.size == 7) {
                    views.setViewVisibility(R.id.streak_week, View.VISIBLE)
                    for (i in 0 until 7) {
                        val today = i == 6
                        views.setImageViewResource(
                            DOTS[i],
                            when {
                                week[i] -> R.drawable.dot_done
                                today -> R.drawable.dot_today
                                else -> R.drawable.dot_open
                            },
                        )
                        views.setTextViewText(LABELS[i], labels.getOrElse(i) { "" })
                        views.setTextColor(LABELS[i], if (today) LABEL_TODAY else LABEL)
                    }
                } else {
                    views.setViewVisibility(R.id.streak_week, View.GONE)
                }
                views.setOnClickPendingIntent(R.id.streak_root, pending)
                manager.updateAppWidget(id, views)
            }
        }

        /// A JSON list of words, as the app writes the week's initials.
        private fun strings(json: String): List<String> = try {
            val list = JSONArray(json)
            List(list.length()) { list.optString(it, "") }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
